// Sem rede, só dados fictícios. Rodar em supabase/functions:
//   deno test revoke-patient-invitation/ accept-patient-invitation/
import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { handleRevokePatientInvitation } from "./handler.ts";
import {
  ADMIN_LEGACY,
  captureLogs,
  CLINIC,
  INVITATION,
  INVITE_EMAIL,
  INVITE_NAME,
  makeDb,
  OTHER_CLINIC,
  PATIENT_USER,
  pendingInvitation,
  PLATFORM,
  PSY,
  PSY_FOREIGN,
  PSY_INACTIVE,
  PSY_INVITER,
  PSY_OTHER,
  type Row,
} from "../_shared/testing/fake_invitations_db.ts";

type Db = ReturnType<typeof makeDb>;

function request(
  body: unknown,
  headers: Record<string, string> = { Authorization: "Bearer t" },
  method = "POST",
) {
  return new Request("http://x/revoke-patient-invitation", {
    method,
    headers,
    body: method === "GET" ? undefined : JSON.stringify(body),
  });
}

async function revoke(
  db: Db,
  caller: string | null,
  req = request({ invitation_id: INVITATION }),
) {
  const { result: res, logs } = await captureLogs(() =>
    handleRevokePatientInvitation(req, {
      createUserClient: () => db.client(caller),
      createServiceClient: () => db.client(),
    })
  );
  return { status: res.status, body: await res.json(), logs };
}

const status = (db: Db) => db.tables.patient_invitations[0].status;
const writes = (db: Db) =>
  db.calls.filter((c) => /\.(update|insert|upsert)$/.test(c));

function assertRevoked(db: Db, caller: string, out: { body: unknown }) {
  assertEquals(out.body, {
    ok: true,
    data: { id: INVITATION, status: "revoked" },
  });
  assertEquals(status(db), "revoked");
  assertEquals(db.tables.patient_invitations.length, 1, "não apaga a linha");
  assertEquals(db.tables.audit_events.length, 1);
  const { id: _id, ...audit } = db.tables.audit_events[0];
  assertEquals(audit, {
    clinic_id: CLINIC,
    actor_profile_id: caller,
    action: "patient_invitation_revoked",
    entity_type: "patient_invitation",
    entity_id: INVITATION,
    metadata: {},
  });
}

const ALLOWED: Array<[string, string, Row]> = [
  ["psicóloga responsável (quem convidou)", PSY, {}],
  ["psicóloga responsável que não convidou", PSY, { invited_by: PLATFORM }],
  ["psicóloga que convidou, mesma clínica", PSY_INVITER, {
    invited_by: PSY_INVITER,
  }],
  ["platform_admin de outra clínica (global)", PLATFORM, {}],
];
for (const [label, caller, patch] of ALLOWED) {
  Deno.test(`cancela: ${label}`, async () => {
    const db = makeDb([pendingInvitation(patch)]);
    const out = await revoke(db, caller);
    assertEquals(out.status, 200);
    assertRevoked(db, caller, out);
    assert(out.logs.includes("revoke-patient-invitation.revoke_success"));
    assert(out.logs.includes(`"caller_id":"${caller}"`));
  });
}

const NOT_VISIBLE: Array<[string, string, Row]> = [
  ["outra psicóloga da mesma clínica", PSY_OTHER, {}],
  ["psicóloga de outra clínica", PSY_FOREIGN, {}],
  ["responsável cujo convite é de outra clínica", PSY, {
    clinic_id: OTHER_CLINIC,
  }],
  ["quem convidou, mas convite de outra clínica", PSY_INVITER, {
    clinic_id: OTHER_CLINIC,
    invited_by: PSY_INVITER,
  }],
  ["convite inexistente", PSY, {
    id: "77777777-7777-4777-8777-777777777777",
  }],
];
for (const [label, caller, patch] of NOT_VISIBLE) {
  // Mesma resposta para todos, em qualquer estado: não permite sondar ids.
  for (const state of ["pending", "accepted", "revoked"]) {
    Deno.test(`404 genérico (${state}): ${label}`, async () => {
      const db = makeDb([pendingInvitation({ ...patch, status: state })]);
      const out = await revoke(db, caller);
      assertEquals(out.status, 404);
      assertEquals(out.body, {
        ok: false,
        error: { code: "NOT_FOUND", message: "Convite não encontrado." },
      });
      assertEquals(status(db), state);
      assertEquals(db.tables.audit_events.length, 0);
    });
  }
}

const REFUSED: Array<[string, string | null, number, string]> = [
  ["paciente", PATIENT_USER, 403, "FORBIDDEN"],
  ["admin legado (não é papel ativo)", ADMIN_LEGACY, 403, "FORBIDDEN"],
  ["psicóloga inativa", PSY_INACTIVE, 403, "FORBIDDEN"],
  ["anônimo (JWT sem usuário)", null, 401, "UNAUTHORIZED"],
];
for (const [label, caller, code, errorCode] of REFUSED) {
  Deno.test(`recusa sem tocar no banco: ${label}`, async () => {
    // inativa é a responsável: só o estado do perfil a barra
    const db = makeDb([
      pendingInvitation({ responsible_psychologist_id: caller ?? PSY }),
    ]);
    const out = await revoke(db, caller);
    assertEquals(out.status, code);
    assertEquals(out.body.error.code, errorCode);
    assertEquals(status(db), "pending");
    assertEquals(writes(db), []);
    assert(!db.calls.some((c) => c.startsWith("patient_invitations")));
  });
}

Deno.test("sem cabeçalho Authorization: 401, nada consultado", async () => {
  const db = makeDb();
  const out = await revoke(
    db,
    PSY,
    request({ invitation_id: INVITATION }, {}),
  );
  assertEquals(out.status, 401);
  assertEquals(db.calls, []);
});

Deno.test("método diferente de POST: 405", async () => {
  const db = makeDb();
  const out = await revoke(db, PSY, request(null, undefined, "GET"));
  assertEquals(out.status, 405);
  assertEquals(db.calls, []);
});

const BAD_BODIES: Record<string, unknown> = {
  "uuid inválido": { invitation_id: "123" },
  "injeção no filtro": {
    invitation_id: `${INVITATION},status.eq.accepted`,
  },
  "sem invitation_id": {},
  "invitation_id não é texto": { invitation_id: [INVITATION] },
  "campo extra": { invitation_id: INVITATION, status: "pending" },
  "corpo nulo": null,
  "corpo lista": [INVITATION],
};
for (const [label, body] of Object.entries(BAD_BODIES)) {
  Deno.test(`400 sem tocar no convite: ${label}`, async () => {
    const db = makeDb();
    const out = await revoke(db, PSY, request(body));
    assertEquals(out.status, 400);
    assertEquals(out.body.error.code, "VALIDATION_ERROR");
    assertEquals(out.body.error.details, undefined);
    assertEquals(writes(db), []);
  });
}

const STATES: Record<string, string> = {
  accepted: "Este convite já foi aceito.",
  expired: "Este convite já expirou.",
  revoked: "Este convite já foi cancelado.",
};
for (const [state, message] of Object.entries(STATES)) {
  for (const caller of [PSY, PLATFORM]) {
    Deno.test(`409 e sem efeito: ${state} (${caller.slice(0, 4)})`, async () => {
      const db = makeDb([pendingInvitation({ status: state })]);
      const before = { ...db.tables.patient_invitations[0] };
      const out = await revoke(db, caller);
      assertEquals(out.status, 409);
      assertEquals(out.body, {
        ok: false,
        error: { code: "CONFLICT", message },
      });
      assertEquals(db.tables.patient_invitations[0], before);
      assertEquals(db.tables.audit_events.length, 0);
    });
  }
}

Deno.test("pendente já vencido (status ainda pending) pode ser cancelado", async () => {
  const db = makeDb([
    pendingInvitation({ expires_at: "2020-01-01T00:00:00Z" }),
  ]);
  assertEquals((await revoke(db, PSY)).status, 200);
  assertEquals(status(db), "revoked");
});

Deno.test("idempotência: segunda chamada diz já cancelado e não audita de novo", async () => {
  const db = makeDb();
  assertEquals((await revoke(db, PSY)).status, 200);
  const again = await revoke(db, PSY);
  assertEquals(again.status, 409);
  assertEquals(again.body.error.message, STATES.revoked);
  assertEquals(db.tables.audit_events.length, 1);
});

Deno.test("duas chamadas simultâneas: um sucesso, um 'já cancelado'", async () => {
  const db = makeDb();
  const both = await Promise.all([revoke(db, PSY), revoke(db, PLATFORM)]);
  assertEquals(both.map((r) => r.status).sort(), [200, 409]);
  assertEquals(db.tables.audit_events.length, 1);
});

Deno.test("aceito entre a autorização e o UPDATE: nunca responde ok", async () => {
  const db = makeDb();
  db.before("patient_invitations.update", () => {
    db.tables.patient_invitations[0].status = "accepted";
  });
  const out = await revoke(db, PSY);
  assertEquals(out.status, 409);
  assertEquals(out.body.error.message, STATES.accepted);
  assertEquals(status(db), "accepted");
});

Deno.test("0 linhas e releitura volta a ver pendente: pede nova tentativa", async () => {
  const db = makeDb([pendingInvitation({ status: "accepted" })]);
  db.before("patient_invitations.select", () => {
    db.tables.patient_invitations[0].status = "pending";
  });
  const out = await revoke(db, PSY);
  assertEquals(out.status, 409);
  assertEquals(
    out.body.error.message,
    "Não foi possível cancelar o convite. Tente novamente.",
  );
});

const DB_FAILURES = [
  "patient_invitations.update",
  "patient_invitations.select",
  "profiles.select",
];
for (const key of DB_FAILURES) {
  Deno.test(`falha do banco em ${key}: 500 sem mensagem do banco`, async () => {
    // para chegar à releitura, o UPDATE precisa não achar nada
    const db = makeDb([
      pendingInvitation(
        key === "patient_invitations.select" ? { status: "revoked" } : {},
      ),
    ]);
    db.failOn(key, { message: `erro com ${INVITE_EMAIL}` });
    const out = await revoke(db, PSY);
    assertEquals(out.status, 500);
    assertEquals(out.body.error.details, undefined);
    assert(!JSON.stringify(out.body).includes(INVITE_EMAIL));
    assert(!out.logs.includes(INVITE_EMAIL), "PII no log");
    assertEquals(db.tables.audit_events.length, 0);
  });
}

const auditInserts = (db: Db) =>
  db.calls.filter((c) => c === "audit_events.insert").length;

Deno.test("auditoria falha uma vez: a nova tentativa grava, sem log de falha", async () => {
  const db = makeDb();
  db.failOn("audit_events.insert", { times: 1 });
  const out = await revoke(db, PSY);
  assertEquals(out.status, 200);
  assertEquals(auditInserts(db), 2);
  assertRevoked(db, PSY, out);
  assert(!out.logs.includes("revoke_audit_failed"));
});

Deno.test("auditoria lança exceção uma vez: tenta de novo e grava", async () => {
  const db = makeDb();
  db.before("audit_events.insert", () => {
    throw new Error(`rede ${INVITE_EMAIL}`);
  });
  const out = await revoke(db, PSY);
  assertEquals(out.status, 200);
  assertEquals(auditInserts(db), 2);
  assertEquals(db.tables.audit_events.length, 1);
  assert(!out.logs.includes(INVITE_EMAIL));
});

Deno.test("auditoria falha duas vezes: cancelamento vale, revoke_audit_failed só com ids", async () => {
  const db = makeDb();
  db.failOn("audit_events.insert", {
    code: "42501",
    message: `erro ${INVITE_EMAIL}`,
  });
  const out = await revoke(db, PSY);
  assertEquals(out.status, 200);
  assertEquals(status(db), "revoked");
  assertEquals(auditInserts(db), 2, "só uma nova tentativa");
  const line = out.logs.split("\n").find((l) =>
    l.includes("revoke_audit_failed")
  )!;
  const { ts: _ts, ...entry } = JSON.parse(line);
  assertEquals(entry, {
    level: "error",
    event: "revoke_audit_failed",
    invitation_id: INVITATION,
    caller_id: PSY,
    clinic_id: CLINIC,
    db_code: "42501",
  });
  assert(!out.logs.includes(INVITE_EMAIL));
});

Deno.test("exceção inesperada: 500 genérico, sem repassar a mensagem", async () => {
  const db = makeDb();
  db.before("patient_invitations.update", () => {
    throw new Error(`falha com ${INVITE_EMAIL}`);
  });
  const out = await revoke(db, PSY);
  assertEquals(out.status, 500);
  assert(!JSON.stringify(out.body).includes(INVITE_EMAIL));
  assert(!out.logs.includes(INVITE_EMAIL));
});

Deno.test("sem PII nem token em log, resposta e auditoria (todos os caminhos)", async () => {
  const secrets = [INVITE_EMAIL, INVITE_NAME, "hash-ficticio", "Bearer"];
  let seen = "";
  for (
    const [caller, state] of [
      [PSY, "pending"],
      [PSY, "accepted"],
      [PSY_OTHER, "pending"],
      [PATIENT_USER, "pending"],
    ]
  ) {
    const db = makeDb([pendingInvitation({ status: state })]);
    const out = await revoke(db, caller);
    seen += out.logs + JSON.stringify(out.body) +
      JSON.stringify(db.tables.audit_events);
  }
  for (const secret of secrets) assert(!seen.includes(secret), secret);
});
