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
/** Template HTML para convite de paciente. */ export function buildPatientInviteEmail(opts) {
  const name = opts.fullName ? `, ${opts.fullName.split(" ")[0]}` : "";
  const expiry = new Date(opts.expiresAt).toLocaleDateString("pt-BR", {
    day: "2-digit",
    month: "2-digit",
    year: "numeric"
  });
  return `<!DOCTYPE html>
<html lang="pt-BR">
<head><meta charset="UTF-8"><meta name="viewport" content="width=device-width,initial-scale=1"></head>
<body style="margin:0;padding:0;background:#f5f5f5;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f5f5f5;padding:40px 0;">
    <tr><td align="center">
      <table width="520" cellpadding="0" cellspacing="0" style="background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:#1a1a2e;padding:32px 40px;text-align:center;">
            <h1 style="color:#ffffff;margin:0;font-size:22px;font-weight:700;letter-spacing:0.5px;">EsquemaCore</h1>
          </td>
        </tr>
        <tr>
          <td style="padding:40px 40px 24px;">
            <h2 style="color:#1a1a2e;margin:0 0 16px;font-size:20px;">Você foi convidado${name}!</h2>
            <p style="color:#444;line-height:1.6;margin:0 0 16px;">
              Seu psicólogo criou um acesso para você no <strong>EsquemaCore</strong>,
              o aplicativo de acompanhamento terapêutico.
            </p>
            <p style="color:#444;line-height:1.6;margin:0 0 32px;">
              Clique no botão abaixo para criar sua conta e começar:
            </p>
            <table width="100%" cellpadding="0" cellspacing="0">
              <tr><td align="center">
                <a href="${opts.inviteUrl}"
                   style="display:inline-block;background:#1a1a2e;color:#ffffff;text-decoration:none;padding:14px 36px;border-radius:8px;font-size:16px;font-weight:600;">
                  Criar minha conta
                </a>
              </td></tr>
            </table>
          </td>
        </tr>
        <tr>
          <td style="padding:0 40px 32px;">
            <p style="color:#888;font-size:13px;line-height:1.5;margin:24px 0 0;">
              Este convite expira em <strong>${expiry}</strong>.<br>
              Se você não esperava este e-mail, pode ignorá-lo com segurança.
            </p>
            <p style="color:#bbb;font-size:12px;margin:12px 0 0;">
              Caso o botão não funcione, copie e cole este link no navegador do seu celular:<br>
              <span style="color:#555;word-break:break-all;">${opts.inviteUrl}</span>
            </p>
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`;
}
