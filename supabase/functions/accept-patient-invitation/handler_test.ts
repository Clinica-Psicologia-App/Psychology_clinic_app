// Sem rede, só dados fictícios. Rodar em supabase/functions:
//   deno test revoke-patient-invitation/ accept-patient-invitation/
import {
  assert,
  assertEquals,
} from "https://deno.land/std@0.224.0/assert/mod.ts";
import { hashInvitationToken } from "../_shared/invitations.ts";
import { handleRevokePatientInvitation } from "../revoke-patient-invitation/handler.ts";
import { handleAcceptPatientInvitation } from "./handler.ts";
import {
  captureLogs,
  CLINIC,
  INVITATION,
  INVITE_EMAIL,
  INVITE_NAME,
  makeDb,
  pendingInvitation,
  PSY,
  type Row,
} from "../_shared/testing/fake_invitations_db.ts";

const TOKEN = "T".repeat(43); // fictício
const PASSWORD = "SenhaFicticia9";
const UNAVAILABLE = "Convite não está mais disponível.";
const RELEASE_FAILED =
  "Não foi possível concluir o cadastro. Peça um novo convite à clínica.";
const STUCK = "Não foi possível concluir o cadastro. Fale com a clínica.";

type Db = ReturnType<typeof makeDb>;

async function setup(patch: Row = {}) {
  const token_hash = await hashInvitationToken(TOKEN);
  return makeDb([pendingInvitation({ token_hash, ...patch })]);
}

async function accept(
  db: Db,
  body: Row = {},
  pushResult: () => Promise<unknown> = () => Promise.resolve(),
) {
  const pushes: string[] = [];
  const { result: res, logs } = await captureLogs(() =>
    handleAcceptPatientInvitation(
      new Request("http://x/accept-patient-invitation", {
        method: "POST",
        body: JSON.stringify({
          token: TOKEN,
          password: PASSWORD,
          profile: {},
          legal_consent: { terms_version: "1", privacy_version: "1" },
          ...body,
        }),
      }),
      {
        createServiceClient: () => db.client(),
        sendPush: (_client, userId) => {
          pushes.push(userId);
          return pushResult() as ReturnType<
            Parameters<typeof handleAcceptPatientInvitation>[1]["sendPush"]
          >;
        },
      },
    )
  );
  return { status: res.status, body: await res.json(), logs, pushes };
}

async function revoke(db: Db) {
  const res = await handleRevokePatientInvitation(
    new Request("http://x/revoke-patient-invitation", {
      method: "POST",
      headers: { Authorization: "Bearer t" },
      body: JSON.stringify({ invitation_id: INVITATION }),
    }),
    {
      createUserClient: () => db.client(PSY),
      createServiceClient: () => db.client(),
    },
  );
  return { status: res.status, body: await res.json() };
}

const invitation = (db: Db) => db.tables.patient_invitations[0];

function assertNothingCreated(db: Db) {
  assert(!db.calls.includes("auth.createUser"), "chamou createUser");
  assertEquals(db.authUsers, {});
  assertEquals(db.tables.patients, []);
  assertEquals(db.tables.legal_consents, []);
}

Deno.test("aceite normal: reserva antes de criar a conta e vincula os ids", async () => {
  const db = await setup();
  const out = await accept(db);
  assertEquals(out.status, 200);
  assertEquals(invitation(db).status, "accepted");
  assert(invitation(db).accepted_at);
  assertEquals(invitation(db).patient_id, out.body.data.patient_id);
  assertEquals(invitation(db).patient_profile_id, out.body.data.profile_id);
  assertEquals(db.tables.patients.length, 1);
  assertEquals(db.tables.legal_consents.length, 2);
  assertEquals(out.pushes, [PSY]);
  assert(
    db.calls.indexOf("patient_invitations.update") <
      db.calls.indexOf("auth.createUser"),
    "reservou depois de criar",
  );
});

for (const state of ["revoked", "accepted", "expired"]) {
  Deno.test(`convite ${state}: recusa e não cria nada`, async () => {
    const db = await setup({ status: state });
    const out = await accept(db);
    assertEquals(out.status, 400);
    assertEquals(invitation(db).status, state);
    assertNothingCreated(db);
  });
}

Deno.test("pendente vencido: marca expired e não cria nada", async () => {
  const db = await setup({ expires_at: "2020-01-01T00:00:00Z" });
  assertEquals((await accept(db)).status, 400);
  assertEquals(invitation(db).status, "expired");
  assertNothingCreated(db);
});

Deno.test("corrida: cancelado entre a leitura e a reserva => nada criado", async () => {
  const db = await setup();
  let cancel: Awaited<ReturnType<typeof revoke>> | undefined;
  db.before("patient_invitations.update", async () => {
    cancel = await revoke(db);
  });
  const out = await accept(db);
  assertEquals(cancel!.status, 200);
  assertEquals(out.status, 409);
  assertEquals(out.body.error.message, UNAVAILABLE);
  assertEquals(invitation(db).status, "revoked");
  assertNothingCreated(db);
  assertEquals(out.pushes, []);
});

Deno.test("corrida: cancelar depois da reserva => 'já aceito', conta criada uma vez", async () => {
  const db = await setup();
  let cancel: Awaited<ReturnType<typeof revoke>> | undefined;
  db.before("auth.createUser", async () => {
    cancel = await revoke(db);
  });
  const out = await accept(db);
  assertEquals(cancel!.status, 409);
  assertEquals(cancel!.body.error.message, "Este convite já foi aceito.");
  assertEquals(out.status, 200);
  assertEquals(invitation(db).status, "accepted");
  assertEquals(db.tables.patients.length, 1);
});

Deno.test("corrida: outro aceite entra entre a leitura e a reserva => uma conta só", async () => {
  const db = await setup();
  let second: Awaited<ReturnType<typeof accept>> | undefined;
  db.before("patient_invitations.update", async () => {
    second = await accept(db);
  });
  const first = await accept(db);
  assertEquals(second!.status, 200);
  assertEquals(first.status, 409);
  assertEquals(first.body.error.message, UNAVAILABLE);
  assertEquals(db.calls.filter((c) => c === "auth.createUser").length, 1);
  assertEquals(invitation(db).status, "accepted");
  assertEquals(db.tables.patients.length, 1);
});

Deno.test("corrida: aceite x cancelamento em paralelo => nunca os dois com sucesso", async () => {
  for (let delay = 0; delay < 12; delay++) {
    const db = await setup();
    const later = async () => {
      for (let i = 0; i < delay; i++) await Promise.resolve();
      return await revoke(db);
    };
    const { result: [a, r] } = await captureLogs(() =>
      Promise.all([accept(db), later()])
    );
    assertEquals(
      [a.status, r.status].filter((s) => s === 200).length,
      1,
      `delay ${delay}: aceite ${a.status}, cancelamento ${r.status}`,
    );
    assertEquals(
      db.tables.patients.length,
      a.status === 200 ? 1 : 0,
    );
    assertEquals(
      invitation(db).status,
      a.status === 200 ? "accepted" : "revoked",
    );
  }
});

Deno.test("corrida: venceu entre a leitura e a reserva => nada criado", async () => {
  const db = await setup();
  db.before("patient_invitations.update", () => {
    invitation(db).expires_at = "2020-01-01T00:00:00Z";
  });
  const out = await accept(db);
  assertEquals(out.status, 409);
  assertNothingCreated(db);
});

Deno.test("erro na reserva: 500 sem mensagem do banco, nada criado", async () => {
  const db = await setup();
  db.failOn("patient_invitations.update", { message: `x ${INVITE_EMAIL}` });
  const out = await accept(db);
  assertEquals(out.status, 500);
  assert(!JSON.stringify(out.body).includes(INVITE_EMAIL));
  assert(!out.logs.includes(INVITE_EMAIL));
  assertNothingCreated(db);
});

const FAILURES: Array<[string, boolean]> = [
  ["auth.createUser", false],
  ["profiles.upsert", true],
  ["patients.insert", true],
  ["legal_consents.insert", true],
];
for (const [key, deletes] of FAILURES) {
  Deno.test(`falha em ${key}: convite volta a pending e pode tentar de novo`, async () => {
    const db = await setup();
    db.failOn(key, { message: "falha ficticia", times: 1 });
    const out = await accept(db);
    assertEquals(out.status, 500);
    assertEquals(invitation(db).status, "pending");
    assertEquals(invitation(db).accepted_at, null);
    assertEquals(db.calls.includes("auth.deleteUser"), deletes);
    assertEquals(db.authUsers, {});
    assertEquals(out.pushes, []);
    assertEquals((await accept(db)).status, 200);
  });
}

Deno.test("exceção durante a criação também devolve a pending", async () => {
  const db = await setup();
  db.before("auth.createUser", () => {
    throw new Error("rede ficticia");
  });
  assertEquals((await accept(db)).status, 500);
  assertEquals(invitation(db).status, "pending");
});

Deno.test("e-mail já em uso: 409 como antes e convite volta a pending", async () => {
  const db = await setup();
  db.authUsers["ja-existe"] = INVITE_EMAIL;
  const out = await accept(db);
  assertEquals(out.status, 409);
  assertEquals(out.body.error.message, "Este e-mail já está em uso.");
  assertEquals(invitation(db).status, "pending");
});

const RELEASE_BLOCKERS: Record<string, (db: Db) => void> = {
  "venceu no meio (gatilho)": (db) => {
    invitation(db).expires_at = "2020-01-01T00:00:00Z";
  },
  "outro pendente para o e-mail (índice único)": (db) => {
    db.tables.patient_invitations.push(
      pendingInvitation({ id: "outro", token_hash: "outro-hash" }),
    );
  },
};
for (const [label, block] of Object.entries(RELEASE_BLOCKERS)) {
  Deno.test(`não dá para devolver a pending: ${label}`, async () => {
    const db = await setup();
    db.before("auth.createUser", () => block(db));
    db.failOn("auth.createUser", { message: "falha ficticia" });
    const out = await accept(db);
    assertEquals(out.status, 409);
    assertEquals(out.body.error.message, RELEASE_FAILED);
    assertEquals(out.body.error.details, undefined);
    assertEquals(invitation(db).status, "accepted");
    assertEquals(invitation(db).patient_id, null);
    assert(out.logs.includes("accept-patient-invitation.release_failed"));
    const line = out.logs.split("\n").find((l) =>
      l.includes("release_failed")
    )!;
    for (const secret of [INVITE_EMAIL, INVITE_NAME, TOKEN, PASSWORD]) {
      assert(!line.includes(secret), secret);
    }
  });
}

/** Linha de log estruturada do evento, sem o carimbo de hora. */
function logEntry(logs: string, event: string) {
  const line = logs.split("\n").find((l) => l.includes(`"event":"${event}"`));
  assert(line, `sem log ${event}`);
  const { ts: _ts, ...entry } = JSON.parse(line);
  return entry;
}

const LINK_FAILURES: Record<string, (db: Db) => void> = {
  "erro do banco": (db) =>
    db.failOn("patient_invitations.update", {
      code: "XX001",
      message: `x ${INVITE_EMAIL}`,
    }),
  "exceção": (db) =>
    db.before("patient_invitations.update", () => {
      throw new Error(`rede ${INVITE_EMAIL}`);
    }),
};
for (const [label, breakLink] of Object.entries(LINK_FAILURES)) {
  Deno.test(`falha ao vincular os ids (${label}): 200 e accept_link_failed só com ids`, async () => {
    const db = await setup();
    // arma a falha depois da reserva, para atingir só o UPDATE de vínculo
    db.before("legal_consents.insert", () => breakLink(db));
    const out = await accept(db);
    assertEquals(out.status, 200);
    assertEquals(invitation(db).status, "accepted");
    assertEquals(invitation(db).patient_id, null);
    const { db_code: _code, ...entry } = logEntry(
      out.logs,
      "accept_link_failed",
    );
    assertEquals(entry, {
      level: "error",
      event: "accept_link_failed",
      invitation_id: INVITATION,
      clinic_id: CLINIC,
      patient_id: out.body.data.patient_id,
      profile_id: out.body.data.profile_id,
    });
    assert(!out.logs.includes(INVITE_EMAIL));
  });
}

const DELETE_FAILURES: Record<string, (db: Db) => void> = {
  "devolve erro": (db) =>
    db.failOn("auth.deleteUser", { message: `x ${INVITE_EMAIL}` }),
  "lança exceção": (db) =>
    db.before("auth.deleteUser", () => {
      throw new Error(`rede ${INVITE_EMAIL}`);
    }),
};
for (
  const step of ["profiles.upsert", "patients.insert", "legal_consents.insert"]
) {
  for (const [label, breakDelete] of Object.entries(DELETE_FAILURES)) {
    Deno.test(`compensação falha (${step}; deleteUser ${label}): fica accepted, não volta a pending`, async () => {
      const db = await setup();
      db.failOn(step, { message: "falha ficticia", times: 1 });
      breakDelete(db);
      const out = await accept(db);
      assertEquals(out.status, 409);
      assertEquals(out.body, {
        ok: false,
        error: { code: "CONFLICT", message: STUCK },
      });
      assertEquals(invitation(db).status, "accepted");
      assertEquals(invitation(db).patient_id, null);
      assertEquals(
        db.calls.filter((c) => c === "patient_invitations.update").length,
        1,
        "só a reserva: nada de devolver",
      );
      const [userId] = Object.keys(db.authUsers);
      assertEquals(logEntry(out.logs, "accept_compensation_failed"), {
        level: "error",
        event: "accept_compensation_failed",
        invitation_id: INVITATION,
        clinic_id: CLINIC,
        profile_id: userId,
      });
      assert(!out.logs.includes(INVITE_EMAIL));
      assertEquals(out.pushes, []);
      // nova tentativa não cria segunda conta
      assertEquals((await accept(db)).status, 400);
      assertEquals(
        db.calls.filter((c) => c === "auth.createUser").length,
        1,
      );
    });
  }
}

Deno.test("exceção depois de criar o usuário: apaga a conta e devolve a pending", async () => {
  const db = await setup();
  db.before("patients.insert", () => {
    throw new Error("rede ficticia");
  });
  const out = await accept(db);
  assertEquals(out.status, 500);
  assert(db.calls.includes("auth.deleteUser"));
  assertEquals(db.authUsers, {});
  assertEquals(invitation(db).status, "pending");
});

// ---------- anônimo: nenhum dado pessoal nem detalhe interno ----------
const PHONE = "+55 11 90000-0000";
const CPF = "000.000.000-00";
const SECRETS = [INVITE_EMAIL, INVITE_NAME, TOKEN, PASSWORD, PHONE, CPF];
// mensagem "do banco/Auth" carregada de tudo que não pode vazar
const LEAK = `falha para ${SECRETS.join(" ")}`;

const fail = (key: string) => (db: Db) => db.failOn(key, { message: LEAK });
const explode = (key: string) => (db: Db) =>
  db.before(key, () => {
    throw new Error(LEAK);
  });

const LEAK_PATHS: Record<string, (db: Db) => void> = {
  "leitura do convite": fail("patient_invitations.select"),
  "reserva": fail("patient_invitations.update"),
  "createUser": fail("auth.createUser"),
  "createUser já existe": (db) =>
    db.failOn("auth.createUser", { message: `already registered ${LEAK}` }),
  "createUser lança": explode("auth.createUser"),
  "perfil": fail("profiles.upsert"),
  "paciente": fail("patients.insert"),
  "paciente lança": explode("patients.insert"),
  "consentimento": fail("legal_consents.insert"),
  "compensação": (db) => {
    fail("patients.insert")(db);
    fail("auth.deleteUser")(db);
  },
  "devolução": (db) => {
    db.before("auth.createUser", () => fail("patient_invitations.update")(db));
    fail("auth.createUser")(db);
  },
  "vínculo": (db) =>
    db.before("legal_consents.insert", () => {
      fail("patient_invitations.update")(db);
    }),
  "leitura lança": explode("patient_invitations.select"),
};
for (const [label, arm] of Object.entries(LEAK_PATHS)) {
  Deno.test(`anônimo, sem PII em log e resposta: ${label}`, async () => {
    const db = await setup();
    arm(db);
    const out = await accept(db, { profile: { phone: PHONE, cpf: CPF } });
    const everything = out.logs + JSON.stringify(out.body);
    for (const secret of SECRETS) assert(!everything.includes(secret), secret);
    assert(!/"(hint|details|message)":"falha/.test(everything));
    assert(!everything.includes('"hint"'), "hint");
    assert(!everything.includes('"details"'), "details");
    if (!out.body.ok) {
      assertEquals(Object.keys(out.body.error).sort(), ["code", "message"]);
      if (out.status >= 500) {
        assertEquals(out.body.error.message, "Internal server error");
      }
    }
  });
}

Deno.test("anônimo: push que falha não vaza para o log", async () => {
  const db = await setup();
  const out = await accept(db, {}, () => Promise.reject(new Error(LEAK)));
  assertEquals(out.status, 200);
  for (const secret of SECRETS) assert(!out.logs.includes(secret), secret);
  assert(out.logs.includes("accept-patient-invitation.push_failed"));
});

Deno.test("validação (nome ausente) falha antes da reserva", async () => {
  const db = await setup({ full_name: null });
  assertEquals((await accept(db)).status, 400);
  assertEquals(invitation(db).status, "pending");
  assertNothingCreated(db);
});
