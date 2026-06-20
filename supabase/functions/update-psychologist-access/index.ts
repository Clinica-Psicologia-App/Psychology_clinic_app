import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { assertUuid, getCallerProfile } from "../_shared/auth.ts";
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

type UpdatePsychologistAccessBody = {
  profile_id: string;
  can_receive_patients: boolean;
  patient_assignment_limit?: number | null;
};

const FN = "update-psychologist-access";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const userClient = createUserClient(authHeader);
    const serviceClient = createServiceClient();
    const caller = await getCallerProfile(userClient);

    if (caller.role !== "platform_admin") {
      throw new AppError(
        "FORBIDDEN",
        "Apenas administradores podem configurar acessos de psicólogos",
        403,
      );
    }

    const body = await parseJsonBody<UpdatePsychologistAccessBody>(req);
    const profileId = assertUuid(body.profile_id, "profile_id");
    const limit = normalizeLimit(body.patient_assignment_limit);

    if (typeof body.can_receive_patients !== "boolean") {
      throw new AppError(
        "VALIDATION_ERROR",
        "can_receive_patients deve ser booleano",
        400,
      );
    }

    const { data: profile, error: profileError } = await userClient
      .from("profiles")
      .select("id, clinic_id, role")
      .eq("id", profileId)
      .maybeSingle();

    if (profileError) {
      throw new AppError("INTERNAL_ERROR", "Falha ao carregar psicólogo", 500, {
        hint: profileError.message,
      });
    }

    if (!profile || profile.role !== "psychologist") {
      throw new AppError(
        "NOT_FOUND",
        "Psicólogo não encontrado",
        404,
      );
    }

    const { data: updated, error: updateError } = await serviceClient
      .from("profiles")
      .update({
        can_receive_patients: body.can_receive_patients,
        patient_assignment_limit: limit,
      })
      .eq("id", profileId)
      .select(
        "id, clinic_id, full_name, email, role, is_active, can_receive_patients, patient_assignment_limit",
      )
      .single();

    if (updateError) {
      logger.error(`${FN}.update_failed`, {
        profile_id: profileId,
        message: updateError.message,
      });
      throw new AppError(
        "INTERNAL_ERROR",
        "Falha ao atualizar acessos do psicólogo",
        500,
        { hint: updateError.message },
      );
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      profile_id: profileId,
      can_receive_patients: body.can_receive_patients,
      patient_assignment_limit: limit,
    });

    return jsonResponse({
      ok: true,
      data: {
        profile: updated,
      },
    });
  } catch (error) {
    return handleError(error, FN);
  }
});

function normalizeLimit(value: number | null | undefined): number | null {
  if (value == null) return null;
  if (!Number.isInteger(value) || value < 0) {
    throw new AppError(
      "VALIDATION_ERROR",
      "patient_assignment_limit deve ser um inteiro maior ou igual a zero",
      400,
    );
  }
  return value;
}
