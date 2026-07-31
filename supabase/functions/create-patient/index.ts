import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  assertEmailAvailableInClinic,
  assertPsychologistCanReceivePatient,
  assertUuid,
  getCallerProfile,
} from "../_shared/auth.ts";
import { AppError } from "../_shared/errors.ts";
import {
  handleError,
  handleOptions,
  jsonResponse,
  parseJsonBody,
  requirePost,
} from "../_shared/http.ts";
import { logger } from "../_shared/logger.ts";
import {
  createServiceClient,
  createUserClient,
  getBearerToken,
} from "../_shared/supabase.ts";

type CreatePatientBody = {
  email: string;
  password: string;
  full_name: string;
  phone?: string;
  responsible_psychologist_id: string;
  cpf?: string;
  birth_date?: string;
  gender?: string;
  relationship_status?: string;
  education_level?: string;
  occupation?: string;
  country_birth?: string;
  state_birth?: string;
  religious_orientation?: string;
  ethnic_group?: string;
  sexual_orientation?: string;
  has_children?: boolean;
  email_patient?: string;
  phone_patient?: string;
};

const FN = "create-patient";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const userClient = createUserClient(authHeader);
    const serviceClient = createServiceClient();
    const caller = await getCallerProfile(userClient);
    if (!["platform_admin", "admin", "psychologist"].includes(caller.role)) {
      throw new AppError(
        "FORBIDDEN",
        "Only clinic staff can create patients",
        403,
      );
    }

    const body = await parseJsonBody<CreatePatientBody>(req);

    if (!body.email?.trim() || !body.password || body.password.length < 8) {
      throw new AppError(
        "VALIDATION_ERROR",
        "email and password (min 8 chars) are required",
        400,
      );
    }

    if (!body.full_name?.trim()) {
      throw new AppError("VALIDATION_ERROR", "full_name is required", 400);
    }

    const psychologistId = assertUuid(
      body.responsible_psychologist_id,
      "responsible_psychologist_id",
    );

    if (caller.role === "psychologist" && psychologistId !== caller.id) {
      throw new AppError(
        "FORBIDDEN",
        "Psychologist can only assign themselves as responsible",
        403,
      );
    }

    const { data: responsibleProfile, error: responsibleError } =
      await serviceClient
        .from("profiles")
        .select("id, clinic_id, role, is_active")
        .eq("id", psychologistId)
        .maybeSingle();

    if (responsibleError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to validate responsible psychologist",
        500,
        { hint: responsibleError.message },
      );
    }

    if (
      !responsibleProfile ||
      responsibleProfile.role !== "psychologist" ||
      !responsibleProfile.is_active ||
      !responsibleProfile.clinic_id
    ) {
      throw new AppError(
        "VALIDATION_ERROR",
        "responsible_psychologist_id must be an active psychologist",
        400,
        { responsible_psychologist_id: psychologistId },
      );
    }

    const targetClinicId = responsibleProfile.clinic_id as string;

    if (
      caller.role !== "platform_admin" &&
      caller.clinic_id !== targetClinicId
    ) {
      throw new AppError(
        "VALIDATION_ERROR",
        "responsible_psychologist_id must belong to your clinic",
        400,
        { responsible_psychologist_id: psychologistId },
      );
    }

    await assertPsychologistCanReceivePatient(
      userClient,
      psychologistId,
      targetClinicId,
    );
    await assertEmailAvailableInClinic(
      userClient,
      targetClinicId,
      body.email,
    );

    const { data: authData, error: authError } = await serviceClient.auth.admin
      .createUser({
        email: body.email.trim().toLowerCase(),
        password: body.password,
        email_confirm: true,
        user_metadata: {
          full_name: body.full_name.trim(),
          clinic_id: targetClinicId,
          role: "patient",
          phone: body.phone ?? null,
        },
      });

    if (authError || !authData.user) {
      logger.warn(`${FN}.auth_create_failed`, { message: authError?.message });
      if (authError?.message?.toLowerCase().includes("already")) {
        throw new AppError("CONFLICT", "Email already registered", 409);
      }
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to create auth user",
        500,
        { hint: authError?.message },
      );
    }

    const profileId = authData.user.id;

    // Insert com service role após validações (evita race/trigger com RLS no mesmo request).
    const { data: patient, error: patientError } = await serviceClient
      .from("patients")
      .insert({
        clinic_id: targetClinicId,
        profile_id: profileId,
        responsible_psychologist_id: psychologistId,
        full_name: body.full_name.trim(),
        email: body.email_patient?.trim() ?? body.email.trim().toLowerCase(),
        phone: body.phone_patient ?? body.phone ?? null,
        cpf: body.cpf ?? null,
        birth_date: body.birth_date ?? null,
        gender: body.gender ?? null,
        relationship_status: body.relationship_status ?? null,
        education_level: body.education_level ?? null,
        occupation: body.occupation ?? null,
        country_birth: body.country_birth ?? null,
        state_birth: body.state_birth ?? null,
        religious_orientation: body.religious_orientation ?? null,
        ethnic_group: body.ethnic_group ?? null,
        sexual_orientation: body.sexual_orientation ?? null,
        has_children: body.has_children ?? null,
      })
      .select(
        "id, clinic_id, profile_id, responsible_psychologist_id, full_name, email, created_at",
      )
      .single();

    if (patientError) {
      logger.error(`${FN}.patient_insert_failed`, {
        message: patientError.message,
        profile_id: profileId,
      });
      await serviceClient.auth.admin.deleteUser(profileId);
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to create patient record",
        500,
        { hint: patientError.message },
      );
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      patient_id: patient.id,
      profile_id: profileId,
      clinic_id: targetClinicId,
    });

    return jsonResponse({
      ok: true,
      data: {
        patient,
        profile_id: profileId,
      },
    });
  } catch (error) {
    return handleError(error, FN);
  }
});
