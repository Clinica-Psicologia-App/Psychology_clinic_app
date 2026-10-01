import { serve } from "https://deno.land/std@0.224.0/http/server.ts";

/**
 * Página de redirect para convites de paciente.
 *
 * O e-mail envia um link HTTPS (este endpoint). O browser o abre e o JS
 * redireciona imediatamente para o deep link do app
 * (esquemacore://app/accept-invitation?token=…).
 *
 * Isso contorna a limitação de clientes de e-mail em browsers que bloqueiam
 * custom URI schemes em <a href> diretamente.
 *
 * Configurar PATIENT_INVITATION_BASE_URL como:
 *   https://<project-ref>.supabase.co/functions/v1/invite-redirect
 */

const CORS_HEADERS = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey",
};

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: CORS_HEADERS });
  }

  const url = new URL(req.url);
  const token = url.searchParams.get("token");

  if (!token || token.trim() === "") {
    return new Response(
      buildHtml({
        title: "Convite inválido",
        body: "<p>O link de convite não é válido. Solicite um novo convite à clínica.</p>",
        deepLink: null,
      }),
      { status: 400, headers: { "Content-Type": "text/html; charset=utf-8" } },
    );
  }

  const deepLink =
    `esquemacore://app/accept-invitation?token=${encodeURIComponent(token)}`;

  return new Response(
    buildHtml({ title: "Abrindo EsquemaCore…", body: "", deepLink }),
    { status: 200, headers: { "Content-Type": "text/html; charset=utf-8" } },
  );
});

function buildHtml(opts: {
  title: string;
  body: string;
  deepLink: string | null;
}): string {
  const { title, body, deepLink } = opts;

  const autoRedirect = deepLink
    ? `<script>
        // Tenta abrir o app imediatamente
        window.location.href = ${JSON.stringify(deepLink)};
        // Fallback: exibe botão após 1.5 s caso o app não abra
        setTimeout(function() {
          var btn = document.getElementById('btn');
          if (btn) btn.style.display = 'inline-block';
          var msg = document.getElementById('msg');
          if (msg) msg.textContent = 'Se o aplicativo não abriu automaticamente, toque no botão abaixo:';
        }, 1500);
      </script>`
    : "";

  const button = deepLink
    ? `<a id="btn" href="${deepLink}"
          style="display:none;margin-top:24px;background:#1a1a2e;color:#fff;text-decoration:none;
                 padding:14px 32px;border-radius:8px;font-size:16px;font-weight:600;">
         Abrir no EsquemaCore
       </a>`
    : "";

  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>${title}</title>
  <style>
    *{box-sizing:border-box;margin:0;padding:0}
    body{font-family:Arial,sans-serif;background:#f5f5f5;display:flex;align-items:center;
         justify-content:center;min-height:100vh;padding:24px}
    .card{background:#fff;border-radius:12px;padding:40px 32px;max-width:420px;width:100%;
          text-align:center;box-shadow:0 2px 12px rgba(0,0,0,.1)}
    .logo{font-size:22px;font-weight:700;color:#1a1a2e;margin-bottom:24px}
    .spinner{width:40px;height:40px;border:3px solid #e0e0e0;border-top-color:#1a1a2e;
             border-radius:50%;animation:spin .8s linear infinite;margin:0 auto 20px}
    @keyframes spin{to{transform:rotate(360deg)}}
    p{color:#555;line-height:1.6;font-size:15px}
    a{display:inline-block}
  </style>
  ${autoRedirect}
</head>
<body>
  <div class="card">
    <div class="logo">EsquemaCore</div>
    ${deepLink ? '<div class="spinner"></div>' : ''}
    <p id="msg">${deepLink ? "Abrindo o aplicativo…" : body}</p>
    ${button}
    ${deepLink ? `<p style="margin-top:32px;font-size:12px;color:#aaa">
      Certifique-se de ter o aplicativo <strong>EsquemaCore</strong> instalado no seu celular.
    </p>` : ""}
  </div>
</body>
</html>`;
}
