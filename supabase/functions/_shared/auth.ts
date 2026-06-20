import { AppError } from "./errors.ts";
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;
export function assertUuid(value, field) {
  if (!UUID_RE.test(value)) {
    throw new AppError("VALIDATION_ERROR", `Invalid UUID: ${field}`, 400, {
      field
    });
  }
  return value;
}
export async function requireAuthUser(client) {
  const { data, error } = await client.auth.getUser();
  if (error || !data.user) {
    throw new AppError("UNAUTHORIZED", "Invalid or expired token", 401);
  }
  return data.user;
}
export async function getCallerProfile(client) {
  const user = await requireAuthUser(client);
  const { data, error } = await client.from("profiles").select("id, clinic_id, role, full_name, email, is_active").eq("id", user.id).maybeSingle();
  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load profile", 500, {
      hint: error.message
    });
  }
  if (!data || !data.is_active) {
    throw new AppError("FORBIDDEN", "Profile not found or inactive", 403);
  }
  return data;
}
export function requireStaff(profile) {
  if (profile.role !== "psychologist") {
    throw new AppError("FORBIDDEN", "Only psychologists can perform this clinical action", 403);
  }
}
export async function assertPatientAccess(client, patientId) {
  const { data, error } = await client.from("patients").select("id").eq("id", patientId).maybeSingle();
  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to verify patient access", 500);
  }
  if (!data) {
    throw new AppError("FORBIDDEN", "Patient not found or access denied", 403, {
      patient_id: patientId
    });
  }
}
export async function assertPsychologistInClinic(client, psychologistId, clinicId) {
  await assertProfileInClinic(client, psychologistId, clinicId, "responsible_psychologist_id", [
    "psychologist"
  ]);
}
export async function assertProfileInClinic(client, profileId, clinicId, fieldName, allowedRoles) {
  const { data, error } = await client.from("profiles").select("id, role, clinic_id").eq("id", profileId).maybeSingle();
  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to validate profile", 500);
  }
  if (!data || !allowedRoles.includes(data.role) || data.clinic_id !== clinicId) {
    throw new AppError("VALIDATION_ERROR", `${fieldName} must belong to an allowed staff profile in your clinic`, 400, {
      [fieldName]: profileId
    });
  }
}
export async function assertPsychologistCanReceivePatient(client, psychologistId, clinicId) {
  const { data: profile, error: profileError } = await client.from("profiles").select("id, role, clinic_id, is_active, can_receive_patients, patient_assignment_limit").eq("id", psychologistId).maybeSingle();
  if (profileError) {
    throw new AppError("INTERNAL_ERROR", "Failed to validate psychologist access limits", 500, {
      hint: profileError.message
    });
  }
  if (!profile || profile.role !== "psychologist" || profile.clinic_id !== clinicId) {
    throw new AppError("VALIDATION_ERROR", "responsible_psychologist_id must be an active psychologist in your clinic", 400, {
      responsible_psychologist_id: psychologistId
    });
  }
  if (!profile.is_active || profile.can_receive_patients === false) {
    throw new AppError("INVALID_STATE", "Este psicólogo não está liberado para receber novos pacientes.", 400, {
      responsible_psychologist_id: psychologistId
    });
  }
  const limit = profile.patient_assignment_limit;
  if (limit == null) return;
  const [patientsResult, invitationsResult] = await Promise.all([
    client.from("patients").select("id", {
      count: "exact",
      head: true
    }).eq("clinic_id", clinicId).eq("responsible_psychologist_id", psychologistId).eq("is_active", true),
    client.from("patient_invitations").select("id", {
      count: "exact",
      head: true
    }).eq("clinic_id", clinicId).eq("responsible_psychologist_id", psychologistId).eq("status", "pending")
  ]);
  if (patientsResult.error || invitationsResult.error) {
    throw new AppError("INTERNAL_ERROR", "Failed to validate psychologist patient quota", 500, {
      patients_hint: patientsResult.error?.message,
      invitations_hint: invitationsResult.error?.message
    });
  }
  const usedSlots = (patientsResult.count ?? 0) + (invitationsResult.count ?? 0);
  if (usedSlots >= limit) {
    throw new AppError("INVALID_STATE", "Este psicólogo atingiu o limite de pacientes definido pelo administrador.", 400, {
      responsible_psychologist_id: psychologistId,
      patient_assignment_limit: limit,
      used_slots: usedSlots
    });
  }
}
export async function assertEmailAvailableInClinic(client, clinicId, email) {
  const normalized = email.trim().toLowerCase();
  const { data, error } = await client.from("profiles").select("id").eq("clinic_id", clinicId).ilike("email", normalized).limit(1);
  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to check email", 500);
  }
  if (data && data.length > 0) {
    throw new AppError("CONFLICT", "Email already registered in this clinic", 409, {
      email: normalized
    });
  }
}
