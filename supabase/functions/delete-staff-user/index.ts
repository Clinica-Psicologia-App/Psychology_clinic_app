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

type DeleteStaffUserBody = {
  profile_id: string;
};

const FN = "delete-staff-user";

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
        "Apenas administradores da plataforma podem excluir usuários",
        403,
      );
    }

    const body = await parseJsonBody<DeleteStaffUserBody>(req);
    const profileId = assertUuid(body.profile_id, "profile_id");

    if (profileId === caller.id) {
      throw new AppError(
        "INVALID_STATE",
        "Você não pode excluir o próprio usuário administrador",
        400,
      );
    }

    const { data: profile, error: profileError } = await userClient
      .from("profiles")
      .select("id, clinic_id, role, full_name, email, is_active")
      .eq("id", profileId)
      .maybeSingle();

    if (profileError) {
      throw new AppError("INTERNAL_ERROR", "Failed to load profile", 500, {
        hint: profileError.message,
      });
    }

    if (!profile) {
      throw new AppError("NOT_FOUND", "Usuário não encontrado", 404);
    }

    if (!["platform_admin", "psychologist"].includes(profile.role)) {
      throw new AppError(
        "VALIDATION_ERROR",
        "Somente administradores e psicólogos podem ser excluídos neste módulo",
        400,
      );
    }

    if (profile.is_active) {
      throw new AppError(
        "INVALID_STATE",
        "Inative o usuário antes de excluí-lo definitivamente",
        409,
      );
    }

    if (profile.role === "psychologist") {
      const [patientsResult, invitationsResult] = await Promise.all([
        userClient
          .from("patients")
          .select("id", { count: "exact", head: true })
          .eq("responsible_psychologist_id", profileId),
        userClient
          .from("patient_invitations")
          .select("id", { count: "exact", head: true })
          .eq("responsible_psychologist_id", profileId)
          .eq("status", "pending"),
      ]);

      if (patientsResult.error || invitationsResult.error) {
        throw new AppError(
          "INTERNAL_ERROR",
          "Failed to validate psychologist assignments",
          500,
          {
            patients_hint: patientsResult.error?.message,
            invitations_hint: invitationsResult.error?.message,
          },
        );
      }

      const assignedPatients = patientsResult.count ?? 0;
      const pendingInvitations = invitationsResult.count ?? 0;
      if (assignedPatients > 0 || pendingInvitations > 0) {
        throw new AppError(
          "INVALID_STATE",
          "Reatribua os pacientes e cancele os convites pendentes antes de excluir este psicólogo.",
          409,
          {
            assigned_patients: assignedPatients,
            pending_invitations: pendingInvitations,
          },
        );
      }
    }

    const { error: deleteError } = await serviceClient.auth.admin.deleteUser(
      profileId,
    );

    if (deleteError) {
      logger.error(`${FN}.auth_delete_failed`, {
        message: deleteError.message,
        profile_id: profileId,
      });
      throw new AppError(
        "INTERNAL_ERROR",
        "Não foi possível excluir o usuário do Supabase Auth",
        500,
        { hint: deleteError.message },
      );
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      profile_id: profileId,
      clinic_id: profile.clinic_id,
      role: profile.role,
    });

    return jsonResponse({
      ok: true,
      data: {
        deleted_profile_id: profileId,
      },
    });
  } catch (error) {
    return handleError(error, FN);
  }
});
