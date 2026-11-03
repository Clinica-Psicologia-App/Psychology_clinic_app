import { AppError } from "./errors.ts";
const DEFAULT_EXPIRY_DAYS = 7;
function bytesToHex(bytes) {
  return Array.from(bytes).map((byte)=>byte.toString(16).padStart(2, "0")).join("");
}
function toBase64Url(bytes) {
  return btoa(String.fromCharCode(...bytes)).replace(/\+/g, "-").replace(/\//g, "_").replace(/=+$/g, "");
}
export function generateInvitationToken() {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return toBase64Url(bytes);
}
export async function hashInvitationToken(token) {
  const normalized = token.trim();
  if (!normalized) {
    throw new AppError("VALIDATION_ERROR", "Invitation token is required", 400);
  }
  const digest = await crypto.subtle.digest("SHA-256", new TextEncoder().encode(normalized));
  return bytesToHex(new Uint8Array(digest));
}
export function invitationExpiresAt(days = DEFAULT_EXPIRY_DAYS) {
  const expiresAt = new Date();
  expiresAt.setUTCDate(expiresAt.getUTCDate() + days);
  return expiresAt.toISOString();
}
// Marca como 'expired' os convites pendentes da clínica que já passaram do
// prazo. Libera a vaga do psicólogo e o e-mail (índice único de pendente).
// Usa service role porque o psicólogo não tem UPDATE em convites.
export async function expireStalePendingInvitations(serviceClient, clinicId) {
  const { error } = await serviceClient.from("patient_invitations").update({
    status: "expired"
  }).eq("clinic_id", clinicId).eq("status", "pending").lte("expires_at", new Date().toISOString());
  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to expire stale invitations", 500, {
      hint: error.message
    });
  }
}
export function buildInviteUrl(token) {
  const encodedToken = encodeURIComponent(token);
  const baseUrl = Deno.env.get("PATIENT_INVITATION_BASE_URL")?.trim();

  // Sem baseUrl: deep link direto (funciona em apps de e-mail nativos).
  if (!baseUrl) return `esquemacore://app/accept-invitation?token=${encodedToken}`;

  // URL HTTPS (ex.: edge function invite-redirect): envia token como query param.
  if (baseUrl.startsWith("http")) {
    const url = new URL(baseUrl.replace(/\/$/, ""));
    url.searchParams.set("token", token);
    return url.toString();
  }

  // Custom scheme (ex.: esquemacore://app): monta deep link diretamente.
  return `${baseUrl.replace(/\/$/, "")}/accept-invitation?token=${encodedToken}`;
}
export function invalidInvitationError() {
  return new AppError("VALIDATION_ERROR", "Convite inválido ou expirado.", 400);
}
