import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  assertPatientAccess,
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
  isParentalStylesQuestionnaire,
  loadActiveQuestionnaire,
  loadCanonicalParentalQuestions,
  normalizeParentalContexts,
} from "../_shared/questionnaire.ts";
import { createServiceClient, createUserClient, getBearerToken } from "../_shared/supabase.ts";

type StartQuestionnaireBody = {
  patient_id: string;
  questionnaire_id: string;
  contexts?: Array<{ key?: string; label?: string }>;
  assignment_id?: string;
};

const FN = "start-questionnaire";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const client = createUserClient(authHeader);
    const caller = await getCallerProfile(client);

    const body = await parseJsonBody<StartQuestionnaireBody>(req);
    const patientId = assertUuid(body.patient_id, "patient_id");
    const questionnaireId = assertUuid(
      body.questionnaire_id,
      "questionnaire_id",
    );
    const assignmentId = body.assignment_id ?? null;

    if (caller.role === "patient") {
      const { data: ownPatient } = await client
        .from("patients")
        .select("id")
        .eq("profile_id", caller.id)
        .maybeSingle();

      if (!ownPatient || ownPatient.id !== patientId) {
        throw new AppError(
          "FORBIDDEN",
          "Patient can only start questionnaires for themselves",
          403,
        );
      }

      // O paciente só pode iniciar questionários LIBERADOS para ele pelo
      // psicólogo (atribuição ativa, não cancelada). Sem liberação → 403.
      // Uma atribuição ativa é única por (paciente, questionário).
      const { data: activeAssignment } = await client
        .from("patient_questionnaire_assignments")
        .select("id, patient_id")
        .eq("patient_id", ownPatient.id)
        .eq("questionnaire_id", questionnaireId)
        .is("cancelled_at", null)
        .maybeSingle();

      if (!activeAssignment) {
        throw new AppError(
          "FORBIDDEN",
          "Questionnaire not released for this patient",
          403,
          { questionnaire_id: questionnaireId },
        );
      }

      // Se um assignment_id específico foi enviado, precisa ser o deste paciente.
      if (assignmentId && activeAssignment.id !== assignmentId) {
        throw new AppError(
          "FORBIDDEN",
          "Assignment not found or does not belong to this patient",
          403,
        );
      }
    }

    await assertPatientAccess(client, patientId);
    const questionnaire = await loadActiveQuestionnaire(client, questionnaireId);

    // Versão ativa é fixada na resposta: edições futuras do instrumento
    // (novas versões) não afetam respostas já iniciadas/concluídas.
    const { data: activeVersion, error: versionError } = await client
      .from("questionnaire_versions")
      .select("id, version")
      .eq("questionnaire_id", questionnaireId)
      .eq("status", "active")
      .maybeSingle();

    if (versionError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to resolve questionnaire version",
        500,
        { hint: versionError.message },
      );
    }
    if (!activeVersion) {
      throw new AppError(
        "INVALID_STATE",
        "Questionnaire has no active version",
        409,
        { questionnaire_id: questionnaireId },
      );
    }

    const isParental = isParentalStylesQuestionnaire(questionnaire.code);
    const normalizedContexts = isParental
      ? normalizeParentalContexts(body.contexts)
      : [];

    const now = new Date().toISOString();
    const { data: response, error: responseError } = await client
      .from("questionnaire_responses")
      .insert({
        clinic_id: caller.clinic_id,
        patient_id: patientId,
        questionnaire_id: questionnaireId,
        questionnaire_version_id: activeVersion.id,
        status: "draft",
        started_at: now,
      })
      .select(
        "id, clinic_id, patient_id, questionnaire_id, questionnaire_version_id, status, started_at, created_at",
      )
      .single();

    if (responseError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to create questionnaire response",
        500,
        { hint: responseError.message },
      );
    }

    // Link the response to the assignment if one was provided.
    // Staff branch: verify the assignment belongs to the target patient before updating.
    if (assignmentId) {
      if (caller.role !== "patient") {
        const { data: assignment } = await client
          .from("patient_questionnaire_assignments")
          .select("id, patient_id")
          .eq("id", assignmentId)
          .maybeSingle();

        if (!assignment || assignment.patient_id !== patientId) {
          throw new AppError(
            "FORBIDDEN",
            "Assignment not found or does not belong to this patient",
            403,
          );
        }
      }

      const serviceClient = createServiceClient();
      await serviceClient
        .from("patient_questionnaire_assignments")
        .update({ response_id: response.id })
        .eq("id", assignmentId);
    }

    if (isParental && normalizedContexts.length > 0) {
      const { error: contextsError } = await client
        .from("questionnaire_response_contexts")
        .insert(
          normalizedContexts.map((context) => ({
            clinic_id: caller.clinic_id,
            response_id: response.id,
            patient_id: patientId,
            questionnaire_id: questionnaireId,
            ...context,
          })),
        );

      if (contextsError) {
        throw new AppError(
          "INTERNAL_ERROR",
          "Failed to create questionnaire contexts",
          500,
          { hint: contextsError.message },
        );
      }
    }

    const questions = isParental
      ? await loadCanonicalParentalQuestions(
          client,
          questionnaireId,
          activeVersion.id,
        )
      : await loadStandardQuestions(client, activeVersion.id);

    const contexts = isParental
      ? await client
        .from("questionnaire_response_contexts")
        .select(
          "id, clinic_id, response_id, patient_id, questionnaire_id, context_type, context_key, context_label, sort_order, status, completed_at",
        )
        .eq("response_id", response.id)
        .order("sort_order", { ascending: true })
      : { data: [], error: null };

    if (contexts.error) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to load questionnaire contexts",
        500,
        { hint: contexts.error.message },
      );
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      response_id: response.id,
      patient_id: patientId,
      questionnaire_id: questionnaireId,
    });

    return jsonResponse({
      ok: true,
      data: {
        response,
        questionnaire,
        questions,
        contexts: contexts.data ?? [],
      },
    });
  } catch (error) {
    return handleError(error, FN);
  }
});

async function loadStandardQuestions(
  client: ReturnType<typeof createUserClient>,
  questionnaireVersionId: string,
) {
  const { data, error } = await client
    .from("questions")
    .select(
      "id, code, text, order_index, answer_type, scale_min, scale_max",
    )
    .eq("questionnaire_version_id", questionnaireVersionId)
    .eq("is_active", true)
    .order("order_index", { ascending: true });

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load questions", 500);
  }

  return data ?? [];
}
