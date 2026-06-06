import type { SupabaseClient } from "@supabase/supabase-js";
import { AppError } from "./errors.ts";

export type ProfileRole = "admin" | "psychologist" | "patient";

export type CallerProfile = {
  id: string;
  clinic_id: string;
  role: ProfileRole;
  full_name: string;
  email: string;
  is_active: boolean;
};

const UUID_RE =
  /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

export function assertUuid(value: string, field: string): string {
  if (!UUID_RE.test(value)) {
    throw new AppError("VALIDATION_ERROR", `Invalid UUID: ${field}`, 400, {
      field,
    });
  }
  return value;
}

export async function requireAuthUser(client: SupabaseClient) {
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) {
    throw new AppError("UNAUTHORIZED", "Invalid or expired token", 401);
  }
  return data.user;
}

export async function getCallerProfile(
  client: SupabaseClient,
): Promise<CallerProfile> {
  const user = await requireAuthUser(client);

  const { data, error } = await client
    .from("profiles")
    .select("id, clinic_id, role, full_name, email, is_active")
    .eq("id", user.id)
    .maybeSingle();

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load profile", 500, {
      hint: error.message,
    });
  }

  if (!data || !data.is_active) {
    throw new AppError("FORBIDDEN", "Profile not found or inactive", 403);
  }

  return data as CallerProfile;
}

export function requireStaff(profile: CallerProfile): void {
  if (profile.role !== "admin" && profile.role !== "psychologist") {
    throw new AppError(
      "FORBIDDEN",
      "Only admin or psychologist can perform this action",
      403,
    );
  }
}

export async function assertPatientAccess(
  client: SupabaseClient,
  patientId: string,
): Promise<void> {
  const { data, error } = await client
    .from("patients")
    .select("id")
    .eq("id", patientId)
    .maybeSingle();

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to verify patient access", 500);
  }

  if (!data) {
    throw new AppError(
      "FORBIDDEN",
      "Patient not found or access denied",
      403,
      { patient_id: patientId },
    );
  }
}

export async function assertPsychologistInClinic(
  client: SupabaseClient,
  psychologistId: string,
  clinicId: string,
): Promise<void> {
  await assertProfileInClinic(
    client,
    psychologistId,
    clinicId,
    "responsible_psychologist_id",
    ["psychologist"],
  );
}

export async function assertProfileInClinic(
  client: SupabaseClient,
  profileId: string,
  clinicId: string,
  fieldName: string,
  allowedRoles: ProfileRole[],
): Promise<void> {
  const { data, error } = await client
    .from("profiles")
    .select("id, role, clinic_id")
    .eq("id", profileId)
    .maybeSingle();

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to validate profile", 500);
  }

  if (
    !data ||
    !allowedRoles.includes(data.role as ProfileRole) ||
    data.clinic_id !== clinicId
  ) {
    throw new AppError(
      "VALIDATION_ERROR",
      `${fieldName} must belong to an allowed staff profile in your clinic`,
      400,
      { [fieldName]: profileId },
    );
  }
}

export async function assertEmailAvailableInClinic(
  client: SupabaseClient,
  clinicId: string,
  email: string,
): Promise<void> {
  const normalized = email.trim().toLowerCase();
  const { data, error } = await client
    .from("profiles")
    .select("id")
    .eq("clinic_id", clinicId)
    .ilike("email", normalized)
    .limit(1);

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to check email", 500);
  }

  if (data && data.length > 0) {
    throw new AppError(
      "CONFLICT",
      "Email already registered in this clinic",
      409,
      { email: normalized },
    );
  }
}
