/**
 * Redirect do link de convite de paciente (link do e-mail → app ou web).
 *
 * O token é uma credencial de portador: quem o tem cria a conta do paciente.
 * Por isso este endpoint:
 * - só redireciona para destinos constantes (nada vem de query, Host, Origin,
 *   Referer ou variável de ambiente);
 * - só repassa o token depois de validar o formato exato;
 * - não consulta nem consome o convite (scanners de e-mail abrem a URL);
 * - não registra nada em log;
 * - não gera HTML (sem script, sem interpolação).
 */

/**
 * A web usa URL com `#` (hash strategy): sem o `#` o app abre o login e perde
 * o token. O que vem depois do `#` não é enviado ao servidor da web nem no
 * cabeçalho Referer.
 */
const WEB_ACCEPT_PREFIX =
  "https://app.esquemacore.com.br/#/accept-invitation?token=";

/** applicationId do app Android: só ele pode receber o intent. */
const ANDROID_PACKAGE = "br.com.esquemacore.app";

/** Formato de `generateInvitationToken`: 32 bytes em base64url. */
const TOKEN_PATTERN = /^[A-Za-z0-9_-]{43}$/;

export const SECURITY_HEADERS: Readonly<Record<string, string>> = {
  "Content-Security-Policy":
    "default-src 'none'; script-src 'none'; base-uri 'none'; form-action 'none'; frame-ancestors 'none'",
  "X-Frame-Options": "DENY",
  "X-Content-Type-Options": "nosniff",
  "Cache-Control": "no-store",
  "Referrer-Policy": "no-referrer",
};

const INVALID_MESSAGE =
  "Convite inválido. O link de convite não é válido. Solicite um novo convite à clínica.";

function textResponse(
  message: string,
  status: number,
  extra: Record<string, string> = {},
): Response {
  return new Response(message, {
    status,
    headers: {
      ...SECURITY_HEADERS,
      "Content-Type": "text/plain; charset=utf-8",
      ...extra,
    },
  });
}

/** Só chamar com token já validado por [TOKEN_PATTERN]. */
function webUrl(token: string): string {
  return WEB_ACCEPT_PREFIX + token;
}

/**
 * Android: abre o app; se não estiver instalado, o navegador segue para
 * `S.browser_fallback_url` (a mesma tela na web).
 */
function androidIntentUrl(token: string): string {
  return `intent://app/accept-invitation?token=${token}` +
    `#Intent;scheme=esquemacore;package=${ANDROID_PACKAGE};` +
    `S.browser_fallback_url=${encodeURIComponent(webUrl(token))};end`;
}

export function handleInviteRedirect(req: Request): Response {
  if (req.method !== "GET" && req.method !== "HEAD") {
    return textResponse("Método não permitido.", 405, { Allow: "GET, HEAD" });
  }

  const token = new URL(req.url).searchParams.get("token");
  if (token === null || !TOKEN_PATTERN.test(token)) {
    // Nunca ecoar o valor recebido.
    return textResponse(INVALID_MESSAGE, 400);
  }

  const isAndroid = /android/i.test(req.headers.get("user-agent") ?? "");
  return new Response(null, {
    status: 302,
    headers: {
      ...SECURITY_HEADERS,
      Location: isAndroid ? androidIntentUrl(token) : webUrl(token),
      Vary: "User-Agent",
    },
  });
}
