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
import { sendPushToUser } from "../_shared/push.ts";
import {
  createServiceClient,
  createUserClient,
  getBearerToken,
} from "../_shared/supabase.ts";

type SetQuestionnaireAccessBody = {
  professional_id: string;
  questionnaire_id: string;
  is_enabled: boolean;
};

const FN = "set-questionnaire-access";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const userClient = createUserClient(authHeader);
    const caller = await getCallerProfile(userClient);

    if (caller.role !== "platform_admin") {
      throw new AppError(
        "FORBIDDEN",
        "Apenas administradores podem configurar acesso aos questionários.",
        403,
      );
    }

    const body = await parseJsonBody<SetQuestionnaireAccessBody>(req);
    const professionalId = assertUuid(body.professional_id, "professional_id");
    const questionnaireId = assertUuid(body.questionnaire_id, "questionnaire_id");

    if (typeof body.is_enabled !== "boolean") {
      throw new AppError("VALIDATION_ERROR", "is_enabled deve ser booleano.", 400);
    }

    const serviceClient = createServiceClient();

    const { data: professional, error: profError } = await serviceClient
      .from("profiles")
      .select("id, clinic_id, full_name")
      .eq("id", professionalId)
      .eq("role", "psychologist")
      .maybeSingle();

    if (profError || !professional) {
      throw new AppError("NOT_FOUND", "Psicólogo não encontrado.", 404);
    }

    const { data: questionnaire, error: qError } = await serviceClient
      .from("questionnaires")
      .select("id, name")
      .eq("id", questionnaireId)
      .maybeSingle();

    if (qError || !questionnaire) {
      throw new AppError("NOT_FOUND", "Questionário não encontrado.", 404);
    }

    const { error: upsertError } = await serviceClient
      .from("questionnaire_professional_access")
      .upsert(
        {
          clinic_id: professional.clinic_id,
          questionnaire_id: questionnaireId,
          professional_id: professionalId,
          granted_by: caller.id,
          is_enabled: body.is_enabled,
        },
        { onConflict: "questionnaire_id,professional_id" },
      );

    if (upsertError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Falha ao atualizar acesso ao questionário.",
        500,
        { hint: upsertError.message },
      );
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      professional_id: professionalId,
      questionnaire_id: questionnaireId,
      is_enabled: body.is_enabled,
    });

    // Notifica o psicólogo quando um questionário é habilitado.
    if (body.is_enabled) {
      try {
        await sendPushToUser(serviceClient, professionalId, {
          title: "Novo instrumento disponível",
          body: `O questionário "${questionnaire.name}" foi liberado para você.`,
          data: {
            type: "questionnaire_access_granted",
            questionnaire_id: questionnaireId,
          },
        });
      } catch (e) {
        console.error("[set-questionnaire-access] push failed", e);
      }
    }

    return jsonResponse({ ok: true, data: { is_enabled: body.is_enabled } });
  } catch (error) {
    return handleError(error, FN);
  }
});
