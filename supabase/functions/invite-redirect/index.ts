/**
 * Redirect do link de convite de paciente. Regras em ./handler.ts.
 *
 * O e-mail envia um link HTTPS (este endpoint), porque clientes de e-mail
 * bloqueiam esquemas próprios em links. Configurar PATIENT_INVITATION_BASE_URL
 * como: https://<project-ref>.supabase.co/functions/v1/invite-redirect
 */
import { handleInviteRedirect } from "./handler.ts";

Deno.serve((req) => handleInviteRedirect(req));
