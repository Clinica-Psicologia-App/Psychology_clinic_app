// Banco falso em memória para os testes de convite (só dados fictícios).
// Reproduz o que importa das regras reais: UPDATE condicional devolvendo as
// linhas mudadas, o gatilho (pendente não pode estar vencido) e o índice único
// de pendente por (clínica, e-mail).

export type Row = Record<string, unknown>;
export type Op = "select" | "update" | "insert" | "upsert";
type Hook = () => unknown;
type Fail = { code?: string; message?: string; times?: number };

export const CLINIC = "11111111-1111-4111-8111-111111111111";
export const OTHER_CLINIC = "22222222-2222-4222-8222-222222222222";
export const PSY = "aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa"; // responsável
export const PSY_INVITER = "abababab-abab-4bab-8bab-abababababab";
export const PSY_OTHER = "bbbbbbbb-bbbb-4bbb-8bbb-bbbbbbbbbbbb";
export const PSY_FOREIGN = "bcbcbcbc-bcbc-4cbc-8cbc-bcbcbcbcbcbc";
export const PSY_INACTIVE = "babababa-baba-4aba-8aba-babababababa";
export const ADMIN_LEGACY = "cccccccc-cccc-4ccc-8ccc-cccccccccccc";
export const PLATFORM = "dddddddd-dddd-4ddd-8ddd-dddddddddddd";
export const PATIENT_USER = "eeeeeeee-eeee-4eee-8eee-eeeeeeeeeeee";
export const INVITATION = "99999999-9999-4999-8999-999999999999";
export const INVITE_EMAIL = "convidado.fake@example.test";
export const INVITE_NAME = "Pessoa Ficticia";

const future = () => new Date(Date.now() + 86_400_000).toISOString();

export function pendingInvitation(patch: Row = {}): Row {
  return {
    id: INVITATION,
    clinic_id: CLINIC,
    invited_by: PSY,
    responsible_psychologist_id: PSY,
    email: INVITE_EMAIL,
    full_name: INVITE_NAME,
    phone: null,
    token_hash: "hash-ficticio",
    status: "pending",
    expires_at: future(),
    accepted_at: null,
    patient_profile_id: null,
    patient_id: null,
    ...patch,
  };
}

function profile(id: string, clinic: string, role: string, active = true): Row {
  return {
    id,
    clinic_id: clinic,
    role,
    full_name: "Equipe Ficticia",
    email: `${id.slice(0, 4)}@example.test`,
    is_active: active,
  };
}

export function makeDb(invitations: Row[] = [pendingInvitation()]) {
  const tables: Record<string, Row[]> = {
    profiles: [
      profile(PSY, CLINIC, "psychologist"),
      profile(PSY_INVITER, CLINIC, "psychologist"),
      profile(PSY_OTHER, CLINIC, "psychologist"),
      profile(PSY_FOREIGN, OTHER_CLINIC, "psychologist"),
      profile(PSY_INACTIVE, CLINIC, "psychologist", false),
      profile(ADMIN_LEGACY, CLINIC, "admin"),
      profile(PLATFORM, OTHER_CLINIC, "platform_admin"),
      profile(PATIENT_USER, CLINIC, "patient"),
    ],
    patient_invitations: invitations,
    patients: [],
    legal_consents: [],
    audit_events: [],
  };
  const authUsers: Record<string, string> = {}; // id -> e-mail
  const calls: string[] = []; // "tabela.op" e "auth.metodo", na ordem
  const hooks = new Map<string, Hook[]>();
  const fails = new Map<string, Fail>();
  let seq = 0;

  /** Roda `hook` uma vez, imediatamente antes da próxima chamada `key`. */
  function before(key: string, hook: Hook) {
    hooks.set(key, [...(hooks.get(key) ?? []), hook]);
  }
  function failOn(key: string, fail: Fail = {}) {
    fails.set(key, fail);
  }
  async function enter(key: string): Promise<Fail | null> {
    calls.push(key);
    const hook = hooks.get(key)?.shift();
    if (hook) await hook();
    const fail = fails.get(key);
    if (!fail || fail.times === 0) return null;
    if (fail.times !== undefined) fail.times--;
    return fail;
  }

  function constraintError(row: Row, others: Row[]) {
    if (row.status !== "pending") return null;
    if (Date.parse(String(row.expires_at)) <= Date.now()) {
      return {
        code: "P0001",
        message: "expires_at deve estar no futuro para convites pendentes",
      };
    }
    const clash = others.some((o) =>
      o.id !== row.id && o.status === "pending" &&
      o.clinic_id === row.clinic_id && o.email === row.email
    );
    return clash
      ? {
        code: "23505",
        message: `duplicate key (${row.email}) already exists`,
      }
      : null;
  }

  function from(table: string) {
    const filters: Array<(r: Row) => boolean> = [];
    let op: Op = "select";
    let payload: Row | Row[] = {};
    let returning = false;
    let single = false;
    // deno-lint-ignore no-explicit-any
    const b: any = {
      select: () => (returning = true, b),
      insert: (p: Row | Row[]) => (op = "insert", payload = p, b),
      upsert: (p: Row) => (op = "upsert", payload = p, b),
      update: (p: Row) => (op = "update", payload = p, b),
      eq: (k: string, v: unknown) => (filters.push((r) => r[k] === v), b),
      is: (k: string, v: unknown) => (filters.push((r) => r[k] === v), b),
      gt: (k: string, v: string) => (
        filters.push((r) => Date.parse(String(r[k])) > Date.parse(v)), b
      ),
      or: (expr: string) => {
        const parts = expr.split(",").map((part) => {
          const m = /^(\w+)\.eq\.(.+)$/.exec(part);
          if (!m) throw new Error(`or() não suportado no fake: ${part}`);
          return [m[1], m[2]] as const;
        });
        filters.push((r) => parts.some(([k, v]) => r[k] === v));
        return b;
      },
      maybeSingle: () => (single = true, b),
      single: () => (single = true, b),
      then: (
        res: (v: unknown) => unknown,
        rej?: (e: unknown) => unknown,
      ) => run().then(res, rej),
    };

    async function run() {
      const fail = await enter(`${table}.${op}`);
      if (fail) {
        return {
          data: null,
          error: {
            code: fail.code ?? "XX000",
            message: fail.message ?? "falha injetada",
          },
        };
      }
      // Daqui em diante não há await: cada comando é atômico, como no banco.
      const all = tables[table];
      if (op === "insert" || op === "upsert") {
        const list = (Array.isArray(payload) ? payload : [payload]).map((
          p,
        ) => ({
          id: p.id ?? `row-${++seq}`,
          ...p,
        }));
        all.push(...list);
        return {
          data: single ? list[0] : returning ? list : null,
          error: null,
        };
      }
      const rows = all.filter((r) => filters.every((f) => f(r)));
      if (op === "update") {
        if (table === "patient_invitations") {
          for (const row of rows) {
            const error = constraintError({ ...row, ...payload as Row }, all);
            if (error) return { data: null, error };
          }
        }
        rows.forEach((r) => Object.assign(r, payload));
        if (!returning) return { data: null, error: null };
      }
      const out = rows.map((r) => ({ ...r }));
      return { data: single ? (out[0] ?? null) : out, error: null };
    }
    return b;
  }

  const admin = {
    createUser: async ({ email }: { email: string }) => {
      const fail = await enter("auth.createUser");
      if (fail) {
        return { data: { user: null }, error: { message: fail.message } };
      }
      if (Object.values(authUsers).includes(email)) {
        return {
          data: { user: null },
          error: { message: "User already registered" },
        };
      }
      const id = `auth-${++seq}`;
      authUsers[id] = email;
      return { data: { user: { id } }, error: null };
    },
    deleteUser: async (id: string) => {
      const fail = await enter("auth.deleteUser");
      if (fail) return { data: null, error: { message: fail.message } };
      delete authUsers[id];
      return { data: null, error: null };
    },
  };

  /** Cliente falso; `callerId` é quem o `auth.getUser` devolve. */
  // deno-lint-ignore no-explicit-any
  function client(callerId: string | null = null): any {
    return {
      from,
      auth: {
        admin,
        getUser: () =>
          Promise.resolve(
            callerId
              ? { data: { user: { id: callerId } }, error: null }
              : { data: { user: null }, error: { message: "invalid JWT" } },
          ),
      },
    };
  }

  return { tables, authUsers, calls, before, failOn, client };
}

/** Captura tudo que vai para o console durante `run`. */
export async function captureLogs<T>(run: () => Promise<T>) {
  const methods = ["log", "info", "warn", "error", "debug"] as const;
  const original = methods.map((m) => console[m]);
  const lines: string[] = [];
  methods.forEach((m) => {
    console[m] = (...args: unknown[]) => {
      lines.push(args.map(String).join(" "));
    };
  });
  try {
    const result = await run();
    return { result, logs: lines.join("\n") };
  } finally {
    methods.forEach((m, i) => console[m] = original[i]);
  }
}
