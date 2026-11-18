import {
  assert,
  assertEquals,
  assertFalse,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { escapeLike, handleUpdatePatientCredentials } from "./handler.ts";

// ---------- fakes (dados fictícios) ----------
const CLINIC = "11111111-1111-4111-8111-111111111111";
const OTHER_CLINIC = "22222222-2222-4222-8222-222222222222";
const PSY = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa";
const PSY2 = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
const ADMIN = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";
const PLAT = "dddddddd-dddd-4ddd-8ddd-dddddddddddd";
const PAT_USER = "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee";
const STAFF_USER = "ffffffff-ffff-4fff-8fff-ffffffffffff";
const PATIENT = "99999999-9999-4999-8999-999999999999";
const PATIENT_NOACC = "88888888-8888-4888-8888-888888888888";
const PATIENT_STAFF = "66666666-6666-4666-8666-666666666666";
const OLD_EMAIL = "errado.fake@example.test";
const NEW_EMAIL = "Certo.Fake@Example.TEST ";
const NEW_NORM = "certo.fake@example.test";
const PASS = "SenhaFicticia9";

type Row = Record<string, unknown>;
// fail: falha injetada. `times` = quantas vezes (padrão: sempre).
type Fail = { table?: string; op?: string; times?: number; skip?: number; msg?: string; auth?: string; throwOnGetUser?: boolean };

function likeToRegex(pattern: string) {
  let out = "^";
  const lit = (c: string) => c.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  for (let i = 0; i < pattern.length; i++) {
    const c = pattern[i];
    if (c === "\\" && i + 1 < pattern.length) out += lit(pattern[++i]);
    else if (c === "%") out += ".*";
    else if (c === "_") out += ".";
    else out += lit(c);
  }
  return new RegExp(out + "$", "i");
}

function makeEnv(callerId: string, fail: Fail = {}, extra: Partial<Record<string, Row[]>> = {}) {
  const tables: Record<string, Row[]> = {
    profiles: [
      { id: PSY, clinic_id: CLINIC, role: "psychologist", full_name: "Psi", email: "psi@example.test", is_active: true },
      { id: PSY2, clinic_id: CLINIC, role: "psychologist", full_name: "Psi2", email: "psi2@example.test", is_active: true },
      { id: ADMIN, clinic_id: CLINIC, role: "admin", full_name: "Adm", email: "adm@example.test", is_active: true },
      { id: PLAT, clinic_id: OTHER_CLINIC, role: "platform_admin", full_name: "Plat", email: "plat@example.test", is_active: true },
      { id: PAT_USER, clinic_id: CLINIC, role: "patient", full_name: "Pac", email: OLD_EMAIL, is_active: true },
      { id: STAFF_USER, clinic_id: CLINIC, role: "psychologist", full_name: "Outro", email: "staff.conta@example.test", is_active: true },
    ],
    patients: [
      { id: PATIENT, clinic_id: CLINIC, profile_id: PAT_USER, responsible_psychologist_id: PSY, email: OLD_EMAIL },
      { id: PATIENT_NOACC, clinic_id: CLINIC, profile_id: null, responsible_psychologist_id: PSY, email: "sem.conta@example.test" },
      // patient apontando para um profile que NÃO é de paciente
      { id: PATIENT_STAFF, clinic_id: CLINIC, profile_id: STAFF_USER, responsible_psychologist_id: PSY, email: "x@example.test" },
    ],
    patient_invitations: [],
    audit_events: [],
    ...extra as Record<string, Row[]>,
  };
  const authUsers: Record<string, { email: string; password?: string }> = {
    [PAT_USER]: { email: OLD_EMAIL },
    [STAFF_USER]: { email: "staff.conta@example.test" },
  };
  const authCalls: Row[] = [];
  const failCount: Record<string, number> = {};
  const shouldFail = (table: string, op: string) => {
    if (fail.table !== table || fail.op !== op) return false;
    const k = `${table}.${op}`;
    failCount[k] = (failCount[k] ?? 0) + 1;
    const n = failCount[k] - (fail.skip ?? 0); // skip: deixa passar as N primeiras chamadas
    return n > 0 && (fail.times === undefined || n <= fail.times);
  };
  let seq = 0;

  function from(table: string) {
    const filters: Array<(r: Row) => boolean> = [];
    let op = "select";
    let payload: Row = {};
    let single = false;
    let desc = false;
    const b: any = {
      select: () => b,
      insert: (p: Row) => { op = "insert"; payload = p; return b; },
      update: (p: Row) => { op = "update"; payload = p; return b; },
      eq: (k: string, v: unknown) => { filters.push((r) => r[k] === v); return b; },
      neq: (k: string, v: unknown) => { filters.push((r) => r[k] !== v); return b; },
      ilike: (k: string, pat: string) => { const re = likeToRegex(pat); filters.push((r) => re.test(String(r[k] ?? ""))); return b; },
      order: (_k: string, o?: { ascending?: boolean }) => { desc = o?.ascending === false; return b; },
      limit: () => b,
      maybeSingle: () => { single = true; return b; },
      then: (res: (v: unknown) => unknown, rej?: (e: unknown) => unknown) => {
        const run = () => {
          if (shouldFail(table, op)) return { data: null, error: { message: fail.msg ?? "boom" } };
          const rows = tables[table].filter((r) => filters.every((f) => f(r)));
          if (op === "insert") { tables[table].push({ ...payload, occurred_at: ++seq }); return { data: null, error: null }; }
          if (op === "update") { rows.forEach((r) => Object.assign(r, payload)); return { data: null, error: null }; }
          const out = desc ? [...rows].sort((a, c) => Number(c.occurred_at ?? 0) - Number(a.occurred_at ?? 0)) : rows;
          return { data: single ? (out[0] ?? null) : out, error: null };
        };
        return Promise.resolve(run()).then(res, rej);
      },
    };
    return b;
  }

  const admin = {
    getUserById: (id: string) => {
      if (fail.throwOnGetUser) throw new Error(`falha inesperada para ${NEW_NORM} ${PASS}`);
      return Promise.resolve({ data: { user: { id, ...authUsers[id] } }, error: null });
    },
    updateUserById: (id: string, patch: Row) => {
      authCalls.push({ id, keys: Object.keys(patch) });
      if (fail.auth === "dup") return Promise.resolve({ data: null, error: { message: "A user with this email address has already been registered", status: 422 } });
      if (fail.auth === "weak") return Promise.resolve({ data: null, error: { message: "Password is known to be weak" } });
      if (typeof patch.email === "string") {
        authUsers[id].email = patch.email;
        // gatilho on_auth_user_email_updated -> handle_user_email_updated
        const p = tables.profiles.find((r) => r.id === id);
        if (p) p.email = patch.email;
      }
      if (typeof patch.password === "string") authUsers[id].password = patch.password;
      return Promise.resolve({ data: { user: { id } }, error: null });
    },
  };
  const client: any = {
    from,
    auth: {
      admin,
      getUser: () => Promise.resolve({ data: { user: { id: callerId } }, error: null }),
    },
  };
  return { client, tables, authUsers, authCalls };
}

function req(body: unknown, headers: Record<string, string> = { Authorization: "Bearer t" }, method = "POST") {
  return new Request("http://x/update-patient-credentials", {
    method,
    headers,
    body: method === "POST" ? JSON.stringify(body) : undefined,
  });
}

type Env = ReturnType<typeof makeEnv>;

async function call(env: Env, body: unknown) {
  const logs: string[] = [];
  const orig = [console.log, console.warn, console.error];
  const cap = (...a: unknown[]) => { logs.push(a.map(String).join(" ")); };
  console.log = cap; console.warn = cap; console.error = cap;
  let res: Response;
  try {
    res = await handleUpdatePatientCredentials(req(body), {
      createUserClient: () => env.client,
      createServiceClient: () => env.client,
    });
  } finally {
    [console.log, console.warn, console.error] = orig;
  }
  const text = await res.text();
  return { env, status: res.status, text, json: JSON.parse(text), logs };
}

async function run(callerId: string, body: unknown, fail: Fail = {}, extra: Partial<Record<string, Row[]>> = {}) {
  return await call(makeEnv(callerId, fail, extra), body);
}

function noLeak(r: { text: string; logs: string[]; env: Env }) {
  const all = r.text + r.logs.join("\n") + JSON.stringify(r.env.tables.audit_events) +
    JSON.stringify(r.env.authCalls);
  for (const s of [PASS, NEW_NORM, OLD_EMAIL]) {
    assertFalse(all.includes(s), `vazou: ${s === PASS ? "senha" : "e-mail"}`);
  }
}

const profileEmail = (r: { env: Env }) => r.env.tables.profiles.find((p) => p.id === PAT_USER)!.email;
const patientEmail = (r: { env: Env }) => r.env.tables.patients.find((p) => p.id === PATIENT)!.email;

// ---------- papéis permitidos ----------
for (const [nome, id] of [["psicólogo responsável", PSY], ["admin da clínica", ADMIN], ["platform_admin", PLAT]]) {
  Deno.test(`permitido: ${nome} troca e-mail e senha (Auth; profiles pelo gatilho; patients; auditoria sem PII)`, async () => {
    const r = await run(id, { patient_id: PATIENT, email: NEW_EMAIL, password: PASS });
    assertEquals(r.status, 200, r.text);
    assertEquals(r.json.data.changed, ["email", "password", "patient_email"]);
    assertEquals(r.env.authUsers[PAT_USER].email, NEW_NORM);
    assertEquals(r.env.authUsers[PAT_USER].password, PASS);
    assertEquals(profileEmail(r), NEW_NORM); // veio do gatilho, nenhum update manual
    assertEquals(patientEmail(r), NEW_NORM);
    assertEquals(r.env.authCalls.length, 1, "um único updateUserById, sem compensação");
    const evs = r.env.tables.audit_events;
    assertEquals(evs.map((e) => e.action), ["patient_credentials_update_requested", "patient_credentials_update_completed"]);
    for (const e of evs) {
      assertEquals(e.metadata, { changed: ["email", "password", "patient_email"] });
      assertEquals(e.actor_profile_id, id);
    }
    noLeak(r);
  });
}

Deno.test("só senha: não mexe em e-mail, profiles nem patients", async () => {
  const r = await run(PSY, { patient_id: PATIENT, password: PASS });
  assertEquals(r.status, 200);
  assertEquals(r.json.data.changed, ["password"]);
  assertEquals(r.env.authUsers[PAT_USER].email, OLD_EMAIL);
  assertEquals(patientEmail(r), OLD_EMAIL);
  noLeak(r);
});

Deno.test("e-mail igual ao atual (tudo convergido) e sem senha: 400 sem alterar nem auditar", async () => {
  const r = await run(PSY, { patient_id: PATIENT, email: OLD_EMAIL.toUpperCase() });
  assertEquals(r.status, 400);
  assertEquals(r.env.authCalls.length, 0);
  assertEquals(r.env.tables.audit_events.length, 0);
});

// ---------- papéis e vínculos negados ----------
Deno.test("negado: paciente (nem o próprio)", async () => {
  const r = await run(PAT_USER, { patient_id: PATIENT, password: PASS });
  assertEquals(r.status, 403);
  assertEquals(r.env.authCalls.length, 0);
});

Deno.test("negado: outro psicólogo da mesma clínica (não responsável)", async () => {
  const r = await run(PSY2, { patient_id: PATIENT, password: PASS });
  assertEquals(r.status, 403);
  assertEquals(r.env.authCalls.length, 0);
});

Deno.test("negado: admin e psicólogo de outra clínica", async () => {
  for (const [id, role] of [[ADMIN, "admin"], [PSY, "psychologist"]]) {
    const env = makeEnv(id);
    env.tables.profiles.find((p) => p.id === id)!.clinic_id = OTHER_CLINIC;
    const r = await call(env, { patient_id: PATIENT, password: PASS });
    assertEquals(r.status, 403, role);
    assertEquals(env.authCalls.length, 0);
  }
});

Deno.test("negado: staff inativo", async () => {
  const env = makeEnv(PSY);
  env.tables.profiles.find((p) => p.id === PSY)!.is_active = false;
  const r = await call(env, { patient_id: PATIENT, password: PASS });
  assertEquals(r.status, 403);
  assertEquals(env.authCalls.length, 0);
});

Deno.test("negado: patient aponta para profile que não é de paciente / profile de outra clínica", async () => {
  const r1 = await run(PSY, { patient_id: PATIENT_STAFF, password: PASS });
  assertEquals(r1.status, 403);
  assertEquals(r1.env.authCalls.length, 0);
  const env = makeEnv(PSY);
  env.tables.profiles.find((p) => p.id === PAT_USER)!.clinic_id = OTHER_CLINIC;
  const r2 = await call(env, { patient_id: PATIENT, password: PASS });
  assertEquals(r2.status, 403);
  assertEquals(env.authCalls.length, 0);
});

Deno.test("negado: sem token (401) e método diferente de POST", async () => {
  const env = makeEnv(PSY);
  const deps = { createUserClient: () => env.client, createServiceClient: () => env.client };
  const r1 = await handleUpdatePatientCredentials(req({ patient_id: PATIENT, password: PASS }, {}), deps);
  assertEquals(r1.status, 401);
  await r1.text();
  const r2 = await handleUpdatePatientCredentials(req({}, { Authorization: "Bearer t" }, "GET"), deps);
  assertEquals(r2.status, 405);
  await r2.text();
});

Deno.test("paciente inexistente: 403 genérico", async () => {
  const r = await run(PSY, { patient_id: "77777777-7777-4777-8777-777777777777", password: PASS });
  assertEquals(r.status, 403);
});

Deno.test("paciente sem conta (convite não aceito): 409 com mensagem de convite", async () => {
  const r = await run(PSY, { patient_id: PATIENT_NOACC, email: NEW_EMAIL });
  assertEquals(r.status, 409);
  assert(r.json.error.message.includes("convite"));
  assertEquals(r.env.authCalls.length, 0);
});

// ---------- validação ----------
Deno.test("validação: sem email e senha, senha curta/longa, e-mail inválido, uuid inválido", async () => {
  assertEquals((await run(PSY, { patient_id: PATIENT })).status, 400);
  assertEquals((await run(PSY, { patient_id: PATIENT, password: "curta12" })).status, 400);
  assertEquals((await run(PSY, { patient_id: PATIENT, password: "x".repeat(73) })).status, 400);
  assertEquals((await run(PSY, { patient_id: PATIENT, email: "sem-arroba" })).status, 400);
  assertEquals((await run(PSY, { patient_id: PATIENT, email: 123 })).status, 400);
  assertEquals((await run(PSY, { patient_id: "nao-uuid", password: PASS })).status, 400);
});

Deno.test("senha curta: resposta e logs não contêm a senha; mensagem não promete regra não validada", async () => {
  const r = await run(PSY, { patient_id: PATIENT, password: "curta1" });
  assertEquals(r.status, 400);
  assertFalse((r.text + r.logs.join("")).includes("curta1"));
  assertFalse(r.json.error.message.includes("letras e números"));
  assert(r.json.error.message.includes("8"));
});

// ---------- conflitos (sem caixa, curingas escapados) ----------
const comPerfilExtra = (email: string) => {
  const env = makeEnv(PSY);
  env.tables.profiles.push({ id: "55555555-5555-4555-8555-555555555555", clinic_id: CLINIC, role: "patient", full_name: "Outro", email, is_active: true });
  return env;
};

Deno.test("e-mail já usado na clínica, mesmo com outra caixa: 409 genérico, nada alterado nem auditado", async () => {
  const env = comPerfilExtra("CERTO.fake@example.test");
  const r = await call(env, { patient_id: PATIENT, email: NEW_EMAIL });
  assertEquals(r.status, 409);
  assertEquals(r.json.error.message, "Este e-mail não pode ser usado.");
  assertEquals(env.authCalls.length, 0);
  assertEquals(env.tables.audit_events.length, 0);
  noLeak(r);
});

Deno.test("ilike: '_' e '%' do e-mail novo NÃO viram curinga (sem falso conflito); '_' literal ainda conflita", async () => {
  const r1 = await call(comPerfilExtra("axb@example.test"), { patient_id: PATIENT, email: "a_b@example.test" });
  assertEquals(r1.status, 200, r1.text);
  const r2 = await call(comPerfilExtra("qualquer.coisa@example.test"), { patient_id: PATIENT, email: "%@example.test" });
  assertEquals(r2.status, 200, r2.text);
  const r3 = await call(comPerfilExtra("a_b@example.test"), { patient_id: PATIENT, email: "A_B@example.test" });
  assertEquals(r3.status, 409);
});

Deno.test("escapeLike escapa \\, % e _", () => {
  assertEquals(escapeLike("a_b%c\\d"), "a\\_b\\%c\\\\d");
});

Deno.test("e-mail duplicado global (Auth 422): 409 genérico sem revelar outra clínica; profiles/patients intactos", async () => {
  const r = await run(PSY, { patient_id: PATIENT, email: NEW_EMAIL }, { auth: "dup" });
  assertEquals(r.status, 409);
  assertEquals(r.json.error.message, "Este e-mail não pode ser usado.");
  assertEquals(profileEmail(r), OLD_EMAIL);
  assertEquals(patientEmail(r), OLD_EMAIL);
  noLeak(r);
});

Deno.test("convite pendente com o mesmo e-mail (qualquer caixa) na clínica: 409; outra clínica ou aceito não bloqueia", async () => {
  const pend = (clinic: string, status: string, email = NEW_NORM) => ({ id: "i", clinic_id: clinic, email, status });
  assertEquals((await run(PSY, { patient_id: PATIENT, email: NEW_EMAIL }, {}, { patient_invitations: [pend(CLINIC, "pending", "Certo.Fake@example.test")] })).status, 409);
  assertEquals((await run(PSY, { patient_id: PATIENT, email: NEW_EMAIL }, {}, { patient_invitations: [pend(OTHER_CLINIC, "pending")] })).status, 200);
  assertEquals((await run(PSY, { patient_id: PATIENT, email: NEW_EMAIL }, {}, { patient_invitations: [pend(CLINIC, "accepted")] })).status, 200);
});

Deno.test("senha rejeitada pelo Auth (fraca/vazada): 400 com mensagem fixa", async () => {
  const r = await run(PSY, { patient_id: PATIENT, password: PASS }, { auth: "weak" });
  assertEquals(r.status, 400);
  noLeak(r);
});

// ---------- auditoria fail-closed ----------
Deno.test("auditoria falha: 500 e NADA muda (Auth, profiles, patients)", async () => {
  const r = await run(PSY, { patient_id: PATIENT, email: NEW_EMAIL, password: PASS }, { table: "audit_events", op: "insert" });
  assertEquals(r.status, 500);
  assertEquals(r.env.authCalls.length, 0);
  assertEquals(r.env.authUsers[PAT_USER].email, OLD_EMAIL);
  assertEquals(r.env.authUsers[PAT_USER].password, undefined);
  assertEquals(profileEmail(r), OLD_EMAIL);
  assertEquals(patientEmail(r), OLD_EMAIL);
  assert(r.logs.some((l) => l.includes("audit_failed")));
  noLeak(r);
});

// ---------- patients falha: 500 claro e repetir converge ----------
Deno.test("patients falha: 500 'login já alterado'; Auth/profiles ficam novos; a repetição conclui a ficha", async () => {
  const env = makeEnv(PSY, { table: "patients", op: "update", times: 1 });
  const r1 = await call(env, { patient_id: PATIENT, email: NEW_EMAIL });
  assertEquals(r1.status, 500);
  assert(r1.json.error.message.includes("login já foi alterado"));
  assertEquals(env.authUsers[PAT_USER].email, NEW_NORM);
  assertEquals(env.tables.profiles.find((p) => p.id === PAT_USER)!.email, NEW_NORM);
  assertEquals(env.tables.patients.find((p) => p.id === PATIENT)!.email, OLD_EMAIL);
  noLeak(r1);

  const r2 = await call(env, { patient_id: PATIENT, email: NEW_EMAIL });
  assertEquals(r2.status, 200, r2.text);
  assertEquals(r2.json.data.changed, ["patient_email"]);
  assertEquals(env.tables.patients.find((p) => p.id === PATIENT)!.email, NEW_NORM);
  assertEquals(env.authCalls.length, 1, "a repetição não mexe no Auth de novo");

  // tudo convergido: nova repetição = 400 sem efeito
  const r3 = await call(env, { patient_id: PATIENT, email: NEW_EMAIL });
  assertEquals(r3.status, 400);
  noLeak(r2);
});

Deno.test("patients.email sempre acompanha o login: contato diferente ou nulo também passa a ser o novo e-mail", async () => {
  for (const contato of ["contato.fake@example.test", null]) {
    const extra = { patients: [{ id: PATIENT, clinic_id: CLINIC, profile_id: PAT_USER, responsible_psychologist_id: PSY, email: contato }] };
    const r = await run(PSY, { patient_id: PATIENT, email: NEW_EMAIL }, {}, extra);
    assertEquals(r.status, 200, r.text);
    assertEquals(r.json.data.changed, ["email", "patient_email"]);
    assertEquals(profileEmail(r), NEW_NORM);
    assertEquals(r.env.tables.patients[0].email, NEW_NORM);
  }
});

Deno.test("patients.email igual ao login antigo (ignorando caixa/espaços): acompanha a troca", async () => {
  const extra = { patients: [{ id: PATIENT, clinic_id: CLINIC, profile_id: PAT_USER, responsible_psychologist_id: PSY, email: " " + OLD_EMAIL.toUpperCase() + " " }] };
  const r = await run(PSY, { patient_id: PATIENT, email: NEW_EMAIL }, {}, extra);
  assertEquals(r.status, 200, r.text);
  assertEquals(r.env.tables.patients[0].email, NEW_NORM);
});

// ---------- exceção inesperada ----------
Deno.test("exceção não-AppError contendo e-mail e senha: 500 genérico, sem a mensagem original em resposta nem logs", async () => {
  const r = await run(PSY, { patient_id: PATIENT, email: NEW_EMAIL, password: PASS }, { throwOnGetUser: true });
  assertEquals(r.status, 500);
  assertEquals(r.json.error.message, "Internal server error");
  assert(r.logs.some((l) => l.includes("unhandled")));
  noLeak(r);
});

Deno.test("nenhum log do caminho feliz contém senha ou e-mail", async () => {
  const r = await run(ADMIN, { patient_id: PATIENT, email: NEW_EMAIL, password: PASS });
  assert(r.logs.length > 0);
  noLeak(r);
});

// ---------- Decisão do Bruno: convergência A→B→C, auditoria em 2 tempos, sem details, EMAIL_RE ----------
const B_EMAIL = "b.fake@example.test";
const C_EMAIL = "c.fake@example.test";

Deno.test("A→B com falha em patients → pedido só de senha → repetir B conclui", async () => {
  const env = makeEnv(PSY, { table: "patients", op: "update", times: 1 });
  const r1 = await call(env, { patient_id: PATIENT, email: B_EMAIL });
  assertEquals(r1.status, 500);
  assertEquals(env.authUsers[PAT_USER].email, B_EMAIL);
  assertEquals(env.tables.patients.find((p) => p.id === PATIENT)!.email, OLD_EMAIL);

  const r2 = await call(env, { patient_id: PATIENT, password: PASS });
  assertEquals(r2.status, 200, r2.text);
  assertEquals(r2.json.data.changed, ["password"]);
  assertEquals(env.tables.patients.find((p) => p.id === PATIENT)!.email, OLD_EMAIL, "só senha não conclui a ficha");

  const r3 = await call(env, { patient_id: PATIENT, email: B_EMAIL });
  assertEquals(r3.status, 200, r3.text);
  assertEquals(r3.json.data.changed, ["patient_email"]);
  assertEquals(env.tables.patients.find((p) => p.id === PATIENT)!.email, B_EMAIL);
  assertEquals(env.tables.profiles.find((p) => p.id === PAT_USER)!.email, B_EMAIL);
});

Deno.test("A→B parcial (patients falhou) → C deixa Auth, profiles e patients em C", async () => {
  const env = makeEnv(PSY, { table: "patients", op: "update", times: 1 });
  assertEquals((await call(env, { patient_id: PATIENT, email: B_EMAIL })).status, 500);
  const r = await call(env, { patient_id: PATIENT, email: C_EMAIL });
  assertEquals(r.status, 200, r.text);
  assertEquals(r.json.data.changed, ["email", "patient_email"]);
  assertEquals(env.authUsers[PAT_USER].email, C_EMAIL);
  assertEquals(env.tables.profiles.find((p) => p.id === PAT_USER)!.email, C_EMAIL);
  assertEquals(env.tables.patients.find((p) => p.id === PATIENT)!.email, C_EMAIL);
});

Deno.test("auditoria: 'solicitado' antes (fail-closed) e 'concluído' no sucesso; falha do segundo só loga ids", async () => {
  // o 2º insert falha: a troca já aconteceu, resposta 200
  const r = await run(PSY, { patient_id: PATIENT, email: NEW_EMAIL, password: PASS }, { table: "audit_events", op: "insert", skip: 1 });
  assertEquals(r.status, 200, r.text);
  assertEquals(r.env.tables.audit_events.map((e) => e.action), ["patient_credentials_update_requested"]);
  assertEquals(r.env.authUsers[PAT_USER].email, NEW_NORM);
  assert(r.logs.some((l) => l.includes("audit_completed_failed")));
  noLeak(r);
});

Deno.test("falha da requisição (patients) deixa só 'solicitado', sem 'concluído'", async () => {
  const r = await run(PSY, { patient_id: PATIENT, email: NEW_EMAIL }, { table: "patients", op: "update" });
  assertEquals(r.status, 500);
  assertEquals(r.env.tables.audit_events.map((e) => e.action), ["patient_credentials_update_requested"]);
});

Deno.test("AppError sai sem details (log e resposta), inclusive os de getCallerProfile, mesmo com hint contendo e-mail", async () => {
  // getCallerProfile devolve AppError com details.hint = mensagem do banco
  const r = await run(PSY, { patient_id: PATIENT, password: PASS }, { table: "profiles", op: "select", msg: `erro com ${NEW_NORM} e ${OLD_EMAIL}` });
  assertEquals(r.status, 500);
  assertEquals(r.json.error.details, undefined);
  assertFalse(r.text.includes("hint"));
  assertFalse(r.logs.join(" ").includes("details"));
  noLeak(r);
  // erro de validação também não traz details
  const v = await run(PSY, { patient_id: PATIENT, email: "sem-arroba" });
  assertEquals(v.status, 400);
  assertEquals(v.json.error.details, undefined);
});

Deno.test("EMAIL_RE recusa '*' e ',' (curinga/lista do PostgREST)", async () => {
  for (const e of ["a*@example.test", "*@example.test", "a,b@example.test", "ab@exa*mple.test", "ab@example.t,est"]) {
    const r = await run(PSY, { patient_id: PATIENT, email: e });
    assertEquals(r.status, 400, e);
    assertEquals(r.env.authCalls.length, 0);
    assertEquals(r.env.tables.audit_events.length, 0);
  }
});
