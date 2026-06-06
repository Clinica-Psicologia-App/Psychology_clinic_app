import { AppError } from "./errors.ts";

const DEFAULT_EXPIRY_DAYS = 7;

function bytesToHex(bytes: Uint8Array): string {
  return Array.from(bytes)
    .map((byte) => byte.toString(16).padStart(2, "0"))
    .join("");
}

function toBase64Url(bytes: Uint8Array): string {
  return btoa(String.fromCharCode(...bytes))
    .replace(/\+/g, "-")
    .replace(/\//g, "_")
    .replace(/=+$/g, "");
}

export function generateInvitationToken(): string {
  const bytes = crypto.getRandomValues(new Uint8Array(32));
  return toBase64Url(bytes);
}

export async function hashInvitationToken(token: string): Promise<string> {
  const normalized = token.trim();
  if (!normalized) {
    throw new AppError("VALIDATION_ERROR", "Invitation token is required", 400);
  }

  const digest = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(normalized),
  );
  return bytesToHex(new Uint8Array(digest));
}

export function invitationExpiresAt(days = DEFAULT_EXPIRY_DAYS): string {
  const expiresAt = new Date();
  expiresAt.setUTCDate(expiresAt.getUTCDate() + days);
  return expiresAt.toISOString();
}

export function buildInviteUrl(token: string): string {
  const path = `/accept-invitation?token=${encodeURIComponent(token)}`;
  const baseUrl = Deno.env.get("PATIENT_INVITATION_BASE_URL")?.trim();

  if (!baseUrl) return path;
  return `${baseUrl.replace(/\/$/, "")}${path}`;
}

export function invalidInvitationError(): AppError {
  return new AppError(
    "VALIDATION_ERROR",
    "Convite inválido ou expirado.",
    400,
  );
}
