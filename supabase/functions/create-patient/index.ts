import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  assertEmailAvailableInClinic,
  assertPsychologistInClinic,
  assertUuid,
  getCallerProfile,
  requireStaff,
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
    requireStaff(caller);

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

    await assertPsychologistInClinic(
      userClient,
      psychologistId,
      caller.clinic_id,
    );
    await assertEmailAvailableInClinic(
      userClient,
      caller.clinic_id,
      body.email,
    );

    const { data: authData, error: authError } = await serviceClient.auth.admin
      .createUser({
        email: body.email.trim().toLowerCase(),
        password: body.password,
        email_confirm: true,
        user_metadata: {
          full_name: body.full_name.trim(),
          clinic_id: caller.clinic_id,
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
        clinic_id: caller.clinic_id,
        profile_id: profileId,
        responsible_psychologist_id: psychologistId,
        full_name: body.full_name.trim(),
        email: body.email_patient?.trim() ?? body.email.trim().toLowerCase(),
        phone: body.phone_patient ?? body.phone ?? null,
        cpf: body.cpf ?? null,
        birth_date: body.birth_date ?? null,
        gender: body.gender ?? null,
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
      clinic_id: caller.clinic_id,
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
