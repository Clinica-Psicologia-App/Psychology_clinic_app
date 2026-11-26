// Sem rede, sem convite real: tokens fictícios. Rodar:
//   deno test supabase/functions/invite-redirect/
import { handleInviteRedirect, SECURITY_HEADERS } from "./handler.ts";

function assert(cond: unknown, msg: string): asserts cond {
  if (!cond) throw new Error(msg);
}
function eq(actual: unknown, expected: unknown, msg = "") {
  assert(
    actual === expected,
    `${msg} esperado ${JSON.stringify(expected)}, veio ${
      JSON.stringify(actual)
    }`,
  );
}

const TOKEN = "Ab3_-".repeat(8) + "xyz"; // 43 caracteres, fictício
const WEB = `https://app.esquemacore.com.br/#/accept-invitation?token=${TOKEN}`;
const INTENT = `intent://app/accept-invitation?token=${TOKEN}` +
  "#Intent;scheme=esquemacore;package=br.com.esquemacore.app;" +
  "S.browser_fallback_url=https%3A%2F%2Fapp.esquemacore.com.br%2F%23%2F" +
  `accept-invitation%3Ftoken%3D${TOKEN};end`;

const UA = {
  android:
    "Mozilla/5.0 (Linux; Android 14; SM-A546E) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Mobile Safari/537.36",
  iphone:
    "Mozilla/5.0 (iPhone; CPU iPhone OS 17_5 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Mobile/15E148 Safari/604.1",
  windows:
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/130.0 Safari/537.36",
  mac:
    "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15",
};

const BASE = "https://exemplo.supabase.co/functions/v1/invite-redirect";

function call(
  query: string,
  opts: { ua?: string; method?: string; headers?: Record<string, string> } = {},
) {
  const headers: Record<string, string> = { ...opts.headers };
  if (opts.ua !== undefined) headers["user-agent"] = opts.ua;
  return handleInviteRedirect(
    new Request(BASE + query, { method: opts.method ?? "GET", headers }),
  );
}

function assertSecurityHeaders(res: Response) {
  for (const [name, value] of Object.entries(SECURITY_HEADERS)) {
    eq(res.headers.get(name), value, name);
  }
  eq(res.headers.get("access-control-allow-origin"), null, "sem CORS");
}

Deno.test("cabeçalhos exigidos têm os valores exatos", () => {
  const h = call(`?token=${TOKEN}`).headers;
  const csp = h.get("content-security-policy") ?? "";
  for (
    const d of [
      "default-src 'none'",
      "script-src 'none'",
      "base-uri 'none'",
      "form-action 'none'",
      "frame-ancestors 'none'",
    ]
  ) assert(csp.includes(d), `CSP sem ${d}`);
  eq(h.get("x-frame-options"), "DENY");
  eq(h.get("x-content-type-options"), "nosniff");
  eq(h.get("cache-control"), "no-store");
  eq(h.get("referrer-policy"), "no-referrer");
});

for (const name of ["iphone", "windows", "mac"] as const) {
  Deno.test(`${name}: 302 direto para a web, sem corpo`, async () => {
    const res = call(`?token=${TOKEN}`, { ua: UA[name] });
    eq(res.status, 302);
    eq(res.headers.get("location"), WEB);
    eq(await res.text(), "");
    assertSecurityHeaders(res);
  });
}

Deno.test("sem User-Agent: vai para a web", () => {
  eq(call(`?token=${TOKEN}`).headers.get("location"), WEB);
});

Deno.test("Android: 302 para intent:// do app, com fallback para a web", async () => {
  const res = call(`?token=${TOKEN}`, { ua: UA.android });
  eq(res.status, 302);
  eq(res.headers.get("location"), INTENT);
  eq(await res.text(), "");
  assertSecurityHeaders(res);
  const fallback = /S\.browser_fallback_url=([^;]+);end$/.exec(INTENT)![1];
  eq(decodeURIComponent(fallback), WEB, "fallback decodificado");
});

Deno.test("302 preserva o # no Location e o token fica só no fragmento", () => {
  const location = call(`?token=${TOKEN}`, { ua: UA.windows })
    .headers.get("location")!;
  assert(location.includes("/#/accept-invitation?token="), "perdeu o #");
  assert(!location.includes("%23"), "# foi codificado");
  const u = new URL(location);
  eq(u.origin, "https://app.esquemacore.com.br");
  eq(u.pathname, "/");
  eq(u.search, "", "token não pode ir na query enviada ao servidor");
  eq(u.hash, `#/accept-invitation?token=${TOKEN}`);
});

const INVALID: Record<string, string> = {
  "sem token": "",
  "token vazio": "?token=",
  "só espaços": "?token=%20%20",
  "42 caracteres": `?token=${TOKEN.slice(1)}`,
  "44 caracteres": `?token=${TOKEN}a`,
  "espaço no fim": `?token=${TOKEN}%20`,
  "quebra de linha no fim": `?token=${TOKEN}%0A`,
  "CRLF com cabeçalho": `?token=${TOKEN}%0D%0ASet-Cookie:x=1`,
  "URL externa //evil": "?token=//evil.example/x",
  "URL externa de 43 caracteres": `?token=${
    encodeURIComponent("//evil.example/".padEnd(43, "a"))
  }`,
  "HTML/script": `?token=${encodeURIComponent("<script>alert(1)</script>")}`,
  "separador de intent": `?token=${
    encodeURIComponent(";S.browser_fallback_url=//evil;end".padEnd(43, "a"))
  }`,
  "parâmetro com outro nome": `?Token=${TOKEN}`,
};

for (const [label, query] of Object.entries(INVALID)) {
  Deno.test(`inválido (${label}): 400, sem redirect e sem eco`, async () => {
    for (const ua of Object.values(UA)) {
      const res = call(query, { ua });
      eq(res.status, 400);
      eq(res.headers.get("location"), null);
      assertSecurityHeaders(res);
      assert(
        res.headers.get("content-type")!.startsWith("text/plain"),
        "erro deve ser texto puro",
      );
      const body = await res.text();
      assert(body.startsWith("Convite inválido."), "mensagem inesperada");
      assert(!body.includes("evil") && !body.includes("<"), "ecoou a entrada");
      assert(!body.includes(TOKEN.slice(1)), "ecoou o token");
    }
  });
}

Deno.test("sem redirect aberto: next/redirect/Host/Origin/Referer não mudam o destino", () => {
  const hostile = {
    host: "evil.example",
    origin: "https://evil.example",
    referer: "https://evil.example/",
    "x-forwarded-host": "evil.example",
  };
  const query =
    `?token=${TOKEN}&next=//evil&redirect=https://evil.example&url=//evil`;
  const web = call(query, { ua: UA.windows, headers: hostile });
  eq(web.headers.get("location"), WEB);
  const android = call(query, { ua: UA.android, headers: hostile });
  eq(android.headers.get("location"), INTENT);
});

Deno.test("variável de ambiente não muda o destino", () => {
  const source = Deno.readTextFileSync(
    new URL("./handler.ts", import.meta.url),
  );
  assert(!source.includes("Deno.env"), "handler não pode ler ambiente");
});

Deno.test("primeiro token inválido não é substituído por um segundo", () => {
  eq(call(`?token=//evil&token=${TOKEN}`).status, 400);
});

Deno.test("GET sem efeito: sem rede, e a mesma resposta a cada abertura", () => {
  const originalFetch = globalThis.fetch;
  let fetched = 0;
  globalThis.fetch = () => {
    fetched++;
    return Promise.reject(new Error("rede proibida"));
  };
  try {
    const a = call(`?token=${TOKEN}`, { ua: UA.windows });
    const b = call(`?token=${TOKEN}`, { ua: UA.windows });
    const head = call(`?token=${TOKEN}`, { ua: UA.windows, method: "HEAD" });
    for (const res of [a, b, head]) {
      eq(res.status, 302);
      eq(res.headers.get("location"), WEB);
    }
    eq(fetched, 0, "não pode chamar rede");
  } finally {
    globalThis.fetch = originalFetch;
  }
  const source = Deno.readTextFileSync(
    new URL("./handler.ts", import.meta.url),
  );
  assert(
    !/^import /m.test(source),
    "handler não deve importar nada (sem banco)",
  );
});

Deno.test("outros métodos: 405, sem redirect, com cabeçalhos e sem CORS", () => {
  for (const method of ["POST", "PUT", "DELETE", "PATCH", "OPTIONS"]) {
    const res = call(`?token=${TOKEN}`, { method });
    eq(res.status, 405, method);
    eq(res.headers.get("location"), null);
    eq(res.headers.get("allow"), "GET, HEAD");
    assertSecurityHeaders(res);
  }
});

Deno.test("nenhum log em nenhum caminho (token nunca registrado)", () => {
  const methods = ["log", "info", "warn", "error", "debug", "trace"] as const;
  const original = methods.map((m) => console[m]);
  const logged: string[] = [];
  methods.forEach((m) => {
    console[m] = (...args: unknown[]) => {
      logged.push(args.map(String).join(" "));
    };
  });
  try {
    for (const ua of Object.values(UA)) {
      call(`?token=${TOKEN}`, { ua });
      call(`?token=${TOKEN}x`, { ua });
      call("", { ua });
      call(`?token=${TOKEN}`, { ua, method: "POST" });
    }
  } finally {
    methods.forEach((m, i) => console[m] = original[i]);
  }
  eq(logged.length, 0, `houve log: ${logged.length}`);
  for (const file of ["./handler.ts", "./index.ts"]) {
    const source = Deno.readTextFileSync(new URL(file, import.meta.url));
    assert(!source.includes("console."), `${file} usa console`);
  }
});
