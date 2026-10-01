/**
 * Helper para envio de e-mails transacionais via Resend.
 * Requer o secret RESEND_API_KEY configurado no projeto Supabase.
 * Sem a chave, o envio é silenciosamente ignorado (modo degradado).
 */ const RESEND_API_URL = "https://api.resend.com/emails";
/**
 * Envia um e-mail via Resend.
 * Retorna true se enviado com sucesso, false se RESEND_API_KEY não está
 * configurado. Lança erro em caso de falha de API.
 */ export async function sendEmail(payload) {
  const apiKey = Deno.env.get("RESEND_API_KEY");
  if (!apiKey) {
    console.warn("[email] RESEND_API_KEY não configurado — e-mail ignorado.");
    return false;
  }
  const from = payload.from ?? Deno.env.get("EMAIL_FROM") ?? "EsquemaCore <noreply@esquemacore.app>";
  const res = await fetch(RESEND_API_URL, {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json"
    },
    body: JSON.stringify({
      from,
      to: [
        payload.to
      ],
      subject: payload.subject,
      html: payload.html
    })
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Resend API error ${res.status}: ${body}`);
  }
  return true;
}
/** Template HTML para convite de paciente. */
export function buildPatientInviteEmail(opts) {
  const firstName = opts.fullName ? opts.fullName.split(" ")[0] : "";
  const greeting = firstName ? `Olá, ${firstName}!` : "Olá!";
  const expiry = new Date(opts.expiresAt).toLocaleDateString("pt-BR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric",
  });

  const logoUrl = "https://wxotrgmhevztoquqqmno.supabase.co/storage/v1/object/public/psychoeducation-cards/brand/logo.png";

  return `<!DOCTYPE html>

<html lang="pt-BR">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Seu acesso ao EsquemaCore está pronto</title>
</head>
<body style="margin:0;padding:0;background:#EEF0F5;font-family:Arial,Helvetica,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#EEF0F5;padding:40px 16px;">
    <tr><td align="center">
      <table width="520" cellpadding="0" cellspacing="0" style="max-width:520px;width:100%;background:#ffffff;border-radius:16px;overflow:hidden;box-shadow:0 4px 24px rgba(13,27,61,0.12);">

        <!-- Header branco com barra teal no topo -->
        <tr>
          <td style="background:#ffffff;padding:0;border-bottom:1px solid #E8EAF0;">
            <div style="height:5px;background:linear-gradient(90deg,#00B2A9,#6C63FF);"></div>
            <table width="100%" cellpadding="0" cellspacing="0">
              <tr>
                <td style="padding:28px 40px 28px;text-align:center;">
                  <img src="${logoUrl}" width="200" alt="EsquemaCore" style="display:block;margin:0 auto;max-width:200px;">
                </td>
              </tr>
            </table>
          </td>
        </tr>

        <!-- Faixa de destaque teal -->
        <tr>
          <td style="background:#00B2A9;padding:12px 40px;text-align:center;">
            <span style="color:#ffffff;font-size:13px;font-weight:600;letter-spacing:0.5px;">Convite de acesso ao aplicativo</span>
          </td>
        </tr>

        <!-- Corpo -->
        <tr>
          <td style="padding:40px 40px 8px;">
            <h2 style="color:#0D1B3D;margin:0 0 16px;font-size:22px;font-weight:700;">${greeting}</h2>
            <p style="color:#444;line-height:1.7;margin:0 0 16px;font-size:15px;">
              Seu psicólogo criou um acesso personalizado para você no <strong style="color:#0D1B3D;">EsquemaCore</strong>,
              o aplicativo de acompanhamento terapêutico.
            </p>
            <p style="color:#444;line-height:1.7;margin:0 0 32px;font-size:15px;">
              Toque no botão abaixo para criar sua conta e começar sua jornada:
            </p>

            <!-- CTA -->
            <table width="100%" cellpadding="0" cellspacing="0">
              <tr><td align="center" style="padding-bottom:8px;">
                <a href="${opts.inviteUrl}"
                   style="display:inline-block;background:#00B2A9;color:#ffffff;text-decoration:none;padding:16px 48px;border-radius:10px;font-size:16px;font-weight:700;letter-spacing:0.3px;">
                  Criar minha conta
                </a>
              </td></tr>
            </table>
          </td>
        </tr>

        <!-- Divisor -->
        <tr>
          <td style="padding:24px 40px 0;">
            <div style="height:1px;background:#E8EAF0;"></div>
          </td>
        </tr>

        <!-- Rodapé -->
        <tr>
          <td style="padding:20px 40px 36px;">
            <p style="color:#888;font-size:13px;line-height:1.6;margin:0 0 10px;">
              Este convite expira em <strong style="color:#555;">${expiry}</strong>.
              Se você não esperava este e-mail, pode ignorá-lo com segurança.
            </p>
            <p style="color:#aaa;font-size:12px;line-height:1.5;margin:0;">
              Caso o botão não funcione, acesse diretamente:<br>
              <span style="color:#00B2A9;word-break:break-all;">${opts.inviteUrl}</span>
            </p>
          </td>
        </tr>

        <!-- Footer branding -->
        <tr>
          <td style="background:#F7F8FA;padding:16px 40px;text-align:center;border-top:1px solid #E8EAF0;">
            <span style="color:#aaa;font-size:11px;">© EsquemaCore · noreply@esquemacore.com.br</span>
          </td>
        </tr>

      </table>
    </td></tr>
  </table>
</body>
</html>`;
}
