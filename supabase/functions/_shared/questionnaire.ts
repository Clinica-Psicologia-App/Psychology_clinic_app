import type { SupabaseClient } from "@supabase/supabase-js";
import { AppError } from "./errors.ts";
import { assertUuid } from "./auth.ts";

export async function loadActiveQuestionnaire(
  client: SupabaseClient,
  questionnaireId: string,
) {
  const id = assertUuid(questionnaireId, "questionnaire_id");
  const { data, error } = await client
    .from("questionnaires")
    .select("id, code, name, description, is_active")
    .eq("id", id)
    .maybeSingle();

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load questionnaire", 500);
  }

  if (!data || !data.is_active) {
    throw new AppError("NOT_FOUND", "Questionnaire not found or inactive", 404);
  }

  return data;
}

export async function loadResponseForUpdate(
  client: SupabaseClient,
  responseId: string,
) {
  const id = assertUuid(responseId, "response_id");
  const { data, error } = await client
    .from("questionnaire_responses")
    .select("id, clinic_id, patient_id, questionnaire_id, status")
    .eq("id", id)
    .maybeSingle();

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load response", 500);
  }

  if (!data) {
    throw new AppError("NOT_FOUND", "Questionnaire response not found", 404);
  }

  if (data.status === "completed") {
    throw new AppError(
      "INVALID_STATE",
      "Questionnaire response is already completed",
      409,
      { response_id: id, status: data.status },
    );
  }

  if (data.status === "cancelled") {
    throw new AppError(
      "INVALID_STATE",
      "Questionnaire response is cancelled",
      409,
      { response_id: id, status: data.status },
    );
  }

  return data;
}

export async function assertQuestionInQuestionnaire(
  client: SupabaseClient,
  questionId: string,
  questionnaireId: string,
) {
  const qid = assertUuid(questionId, "question_id");
  const { data, error } = await client
    .from("questions")
    .select("id, questionnaire_id, answer_type, scale_min, scale_max, is_active")
    .eq("id", qid)
    .maybeSingle();

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load question", 500);
  }

  if (!data || !data.is_active || data.questionnaire_id !== questionnaireId) {
    throw new AppError(
      "VALIDATION_ERROR",
      "Question does not belong to this questionnaire",
      400,
      { question_id: qid, questionnaire_id: questionnaireId },
    );
  }

  return data;
}

export function validateAnswerValue(
  answerValue: number,
  scaleMin: number | null,
  scaleMax: number | null,
): void {
  if (!Number.isFinite(answerValue)) {
    throw new AppError("VALIDATION_ERROR", "answer_value must be a number", 400);
  }

  if (scaleMin != null && answerValue < scaleMin) {
    throw new AppError(
      "VALIDATION_ERROR",
      `answer_value must be >= ${scaleMin}`,
      400,
    );
  }

  if (scaleMax != null && answerValue > scaleMax) {
    throw new AppError(
      "VALIDATION_ERROR",
      `answer_value must be <= ${scaleMax}`,
      400,
    );
  }
}
