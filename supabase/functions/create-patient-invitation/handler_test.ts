// Autorização da criação de convite. Como a tabela não aceita mais escrita de
// usuários, o cliente do chamador aqui recusa qualquer escrita: se a função
// voltar a gravar com ele, os testes falham. Só dados fictícios.
import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { hashInvitationToken } from "../_shared/invitations.ts";
import {
  ADMIN_LEGACY,
  captureLogs,
  CLINIC,
  INVITATION,
  makeDb,
  OTHER_CLINIC,
  PATIENT_USER,
  pendingInvitation,
  PLATFORM,
  PSY,
  PSY_FOREIGN,
  PSY_INACTIVE,
  PSY_OTHER,
  type Row,
} from "../_shared/testing/fake_invitations_db.ts";
import { handleCreatePatientInvitation } from "./handler.ts";

Deno.env.delete("PATIENT_INVITATION_BASE_URL");

const EMAIL = "novo.paciente@example.test";
type Db = ReturnType<typeof makeDb>;
type Mail = { to: string; subject: string; html: string };

function setup(
  invitations: Row[] = [],
  mail: () => Promise<boolean> = () => Promise.resolve(true),
) {
  const db = makeDb(invitations);
  const userWrites: string[] = [];
  const sent: Mail[] = [];
  let serviceClients = 0;

  async function call(
    callerId: string | null,
    body: unknown = { email: EMAIL, responsible_psychologist_id: PSY },
    init: RequestInit = {},
  ) {
    const req = new Request("http://local/create-patient-invitation", {
      method: "POST",
      headers: { Authorization: "Bearer jwt-ficticio" },
      body: typeof body === "string" ? body : JSON.stringify(body),
      ...init,
    });
    const { result: res, logs } = await captureLogs(() =>
      handleCreatePatientInvitation(req, {
        createUserClient: () => {
          const client = db.client(callerId);
          const from = client.from;
          client.from = (table: string) => {
            const builder = from(table);
            for (const op of ["insert", "update", "upsert", "delete"]) {
              builder[op] = () => {
                userWrites.push(`${table}.${op}`);
                throw new Error("escrita negada ao usuário");
              };
            }
            return builder;
          };
          return client;
        },
        createServiceClient: () => (serviceClients++, db.client()),
        sendEmail: (payload) => (sent.push(payload), mail()),
      })
    );
    const text = await res.text();
    return {
      status: res.status,
      json: text ? JSON.parse(text) : null,
      logs,
    };
  }

  const inserted = () =>
    db.tables.patient_invitations.filter((r) => r.id !== INVITATION);
  return {
    db,
    call,
    inserted,
    userWrites,
    sent,
    serviceClients: () => serviceClients,
  };
}

const writes = (db: Db) =>
  db.calls.filter((c) => /\.(insert|update|upsert|delete)$/.test(c));

Deno.test("psicóloga cria o próprio convite; quem grava é o service role", async () => {
  const t = setup();
  const r = await t.call(PSY, {
    email: `  ${EMAIL.toUpperCase()} `,
    full_name: " Pessoa Nova ",
    phone: "000",
    responsible_psychologist_id: PSY,
  });
  assertEquals(r.status, 200);
  assertEquals(t.userWrites, []);
  const [row] = t.inserted();
  assertEquals(
    [
      row.clinic_id,
      row.invited_by,
      row.responsible_psychologist_id,
      row.email,
      row.full_name,
      row.phone,
    ],
    [CLINIC, PSY, PSY, EMAIL, "Pessoa Nova", "000"],
  );
  const token = new URL(r.json.data.invite_url).searchParams.get("token")!;
  assertEquals(row.token_hash, await hashInvitationToken(token));
  assertEquals(row.expires_at, r.json.data.expires_at);
  assertEquals(t.sent.length, 1);
  assertEquals(t.sent[0].to, EMAIL);
  assert(t.sent[0].html.includes(token));
  assert(!r.logs.includes(token));
});

Deno.test("clínica, quem convidou e demais campos do corpo são ignorados", async () => {
  const t = setup();
  const r = await t.call(PSY, {
    email: EMAIL,
    responsible_psychologist_id: PSY,
    clinic_id: OTHER_CLINIC,
    invited_by: PLATFORM,
    status: "accepted",
    token_hash: "do-cliente",
    expires_at: "2099-01-01T00:00:00Z",
    patient_id: "x",
    id: INVITATION,
  });
  assertEquals(r.status, 200);
  const [row] = t.inserted();
  assertEquals(row.clinic_id, CLINIC);
  assertEquals(row.invited_by, PSY);
  assert(row.token_hash !== "do-cliente");
  assert(row.expires_at !== "2099-01-01T00:00:00Z");
  assertEquals(row.patient_id, undefined);
  assert(row.status !== "accepted");
});

Deno.test("platform_admin cria na própria clínica, com psicóloga dela", async () => {
  const t = setup();
  const r = await t.call(PLATFORM, {
    email: EMAIL,
    responsible_psychologist_id: PSY_FOREIGN,
    clinic_id: CLINIC,
  });
  assertEquals(r.status, 200);
  const [row] = t.inserted();
  assertEquals(
    [row.clinic_id, row.invited_by, row.responsible_psychologist_id],
    [OTHER_CLINIC, PLATFORM, PSY_FOREIGN],
  );
  assertEquals(t.userWrites, []);
});

for (
  const [label, responsible] of [
    ["de outra clínica", PSY],
    ["que é paciente", PATIENT_USER],
    ["que é o próprio admin", PLATFORM],
  ]
) {
  Deno.test(`platform_admin com responsável ${label}: 400, sem convite`, async () => {
    const t = setup();
    const r = await t.call(PLATFORM, {
      email: EMAIL,
      responsible_psychologist_id: responsible,
    });
    assertEquals(r.status, 400);
    assertEquals(t.inserted(), []);
    assertEquals(t.sent, []);
  });
}

for (
  const [label, responsible] of [
    ["colega da clínica", PSY_OTHER],
    ["psicóloga de outra clínica", PSY_FOREIGN],
  ]
) {
  Deno.test(`psicóloga atribuindo a ${label}: 403 antes de usar o service role`, async () => {
    const t = setup();
    const r = await t.call(PSY, {
      email: EMAIL,
      responsible_psychologist_id: responsible,
    });
    assertEquals(r.status, 403);
    assertEquals(t.serviceClients(), 0);
    assertEquals(writes(t.db), []);
  });
}

for (
  const [label, callerId, status] of [
    ["paciente", PATIENT_USER, 403],
    ["papel antigo admin", ADMIN_LEGACY, 403],
    ["psicóloga inativa", PSY_INACTIVE, 403],
    ["sessão inválida", null, 401],
  ] as const
) {
  Deno.test(`${label}: ${status}, nada gravado`, async () => {
    const t = setup();
    const r = await t.call(callerId, {
      email: EMAIL,
      responsible_psychologist_id: callerId ?? PSY,
    });
    assertEquals(r.status, status);
    assertEquals(t.serviceClients(), 0);
    assertEquals(writes(t.db), []);
  });
}

Deno.test("sem Authorization: 401, nada gravado", async () => {
  const t = setup();
  const r = await t.call(PSY, undefined, { headers: {} });
  assertEquals(r.status, 401);
  assertEquals(t.serviceClients(), 0);
  assertEquals(writes(t.db), []);
});

Deno.test("GET: 405; OPTIONS: 204", async () => {
  const t = setup();
  const get = await t.call(PSY, undefined, { method: "GET", body: undefined });
  assertEquals(get.status, 405);
  const options = await t.call(PSY, undefined, {
    method: "OPTIONS",
    body: undefined,
  });
  assertEquals(options.status, 204);
  assertEquals(t.serviceClients(), 0);
});

for (
  const [label, body] of [
    ["corpo não JSON", "{"],
    ["sem e-mail", { responsible_psychologist_id: PSY }],
    ["e-mail sem @", { email: "x", responsible_psychologist_id: PSY }],
    ["responsável não uuid", {
      email: EMAIL,
      responsible_psychologist_id: "1",
    }],
  ] as const
) {
  Deno.test(`${label}: 400, nada gravado`, async () => {
    const t = setup();
    // platform_admin para o uuid inválido chegar à validação de formato
    const r = await t.call(PLATFORM, body);
    assertEquals(r.status, 400);
    assertEquals(writes(t.db), []);
  });
}

Deno.test("responsável bloqueada para novos pacientes: 400", async () => {
  const t = setup();
  t.db.tables.profiles.find((p) => p.id === PSY)!.can_receive_patients = false;
  const r = await t.call(PSY);
  assertEquals(r.status, 400);
  assertEquals(r.json.error.code, "INVALID_STATE");
  assertEquals(t.inserted(), []);
});

Deno.test("limite de pacientes conta convite pendente: 400", async () => {
  const t = setup([pendingInvitation()]);
  t.db.tables.profiles.find((p) => p.id === PSY)!.patient_assignment_limit = 1;
  const r = await t.call(PSY);
  assertEquals(r.status, 400);
  assertEquals(r.json.error.code, "INVALID_STATE");
  assertEquals(t.inserted(), []);
});

Deno.test("e-mail já cadastrado na clínica: 409", async () => {
  const t = setup();
  t.db.tables.profiles.find((p) => p.id === PATIENT_USER)!.email = EMAIL;
  const r = await t.call(PSY);
  assertEquals(r.status, 409);
  assertEquals(t.inserted(), []);
});

Deno.test("já há pendente para o e-mail: 409", async () => {
  const t = setup([pendingInvitation({ email: EMAIL })]);
  const r = await t.call(PSY);
  assertEquals(r.status, 409);
  assertEquals(t.inserted(), []);
});

Deno.test("pendente vencido é expirado pelo service role e não bloqueia", async () => {
  const t = setup([
    pendingInvitation({ email: EMAIL, expires_at: "2020-01-01T00:00:00Z" }),
  ]);
  const r = await t.call(PSY);
  assertEquals(r.status, 200);
  assertEquals(t.db.tables.patient_invitations[0].status, "expired");
  assertEquals(t.inserted().length, 1);
  assertEquals(t.userWrites, []);
});

for (
  const [code, status, apiCode] of [
    ["23505", 409, "CONFLICT"],
    ["42501", 500, "INTERNAL_ERROR"],
    ["P0001", 500, "INTERNAL_ERROR"],
  ] as const
) {
  Deno.test(`erro ${code} ao inserir: ${status}, sem e-mail enviado`, async () => {
    const t = setup();
    t.db.failOn("patient_invitations.insert", { code });
    const r = await t.call(PSY);
    assertEquals(r.status, status);
    assertEquals(r.json.error.code, apiCode);
    assertEquals(t.sent, []);
  });
}

for (
  const [label, mail] of [
    ["envio falha", () => Promise.reject(new Error("falha ficticia"))],
    ["envio desligado", () => Promise.resolve(false)],
  ] as const
) {
  Deno.test(`${label}: convite criado mesmo assim`, async () => {
    const t = setup([], mail);
    const r = await t.call(PSY);
    assertEquals(r.status, 200);
    assertEquals(t.inserted().length, 1);
  });
}
