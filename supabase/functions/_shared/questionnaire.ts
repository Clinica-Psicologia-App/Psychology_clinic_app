import type { SupabaseClient } from "@supabase/supabase-js";
import { AppError } from "./errors.ts";
import { assertUuid } from "./auth.ts";

export const PARENTAL_STYLES_CODE = "PARENTAL_STYLES_V1";

export type ResponseContextRow = {
  id: string;
  clinic_id: string;
  response_id: string;
  patient_id: string;
  questionnaire_id: string;
  context_type: string;
  context_key: string;
  context_label: string;
  sort_order: number;
  status: string;
  completed_at: string | null;
};

export async function loadActiveQuestionnaire(
  client: SupabaseClient,
  questionnaireId: string,
) {
  const id = assertUuid(questionnaireId, "questionnaire_id");
  const { data, error } = await client
    .from("questionnaires")
    .select("id, code, name, description, is_active, clinical_status")
    .eq("id", id)
    .maybeSingle();

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load questionnaire", 500);
  }

  if (!data || !data.is_active) {
    throw new AppError("NOT_FOUND", "Questionnaire not found or inactive", 404);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL") ?? "";
  const isLocal = supabaseUrl.includes("127.0.0.1") ||
    supabaseUrl.includes("localhost") ||
    supabaseUrl.includes("kong:8000");
  const allowUnvalidated =
    Deno.env.get("ALLOW_UNVALIDATED_INSTRUMENTS") === "true" || isLocal;
  if (data.clinical_status !== "approved" && !allowUnvalidated) {
    throw new AppError(
      "FORBIDDEN",
      "Instrumento indisponível até concluir homologação clínica e licenciamento.",
      403,
    );
  }

  return data;
}

export function isParentalStylesQuestionnaire(
  questionnaireCode: string | null | undefined,
): boolean {
  return questionnaireCode?.trim().toUpperCase() === PARENTAL_STYLES_CODE;
}

export function normalizeParentalContexts(
  raw: Array<{ key?: string; label?: string }> | null | undefined,
) {
  const contexts = (raw ?? []).map((entry, index) => {
    const key = entry.key?.trim().toLowerCase() ?? "";
    const label = entry.label?.trim() ?? "";

    if (!["mother", "father", "other"].includes(key)) {
      throw new AppError(
        "VALIDATION_ERROR",
        "Contexto parental inválido.",
        400,
      );
    }

    if (!label) {
      throw new AppError(
        "VALIDATION_ERROR",
        "Cada figura parental deve ter um rótulo.",
        400,
      );
    }

    if (key === "other" && label.toLowerCase() === "outro") {
      throw new AppError(
        "VALIDATION_ERROR",
        "Informe quem é a figura parental em \"Outro\".",
        400,
      );
    }

    return {
      context_type: "parental_figure",
      context_key: key,
      context_label: label,
      sort_order: index,
    };
  });

  if (contexts.length === 0) {
    throw new AppError(
      "VALIDATION_ERROR",
      "Selecione pelo menos uma figura parental.",
      400,
    );
  }

  const uniqueKeys = new Set<string>();
  const uniqueLabels = new Set<string>();
  for (const item of contexts) {
    const duplicateKey = uniqueKeys.has(item.context_key) &&
      item.context_key !== "other";
    const duplicateLabel = uniqueLabels.has(item.context_label.toLowerCase());
    if (duplicateKey || duplicateLabel) {
      throw new AppError(
        "VALIDATION_ERROR",
        "As figuras parentais selecionadas devem ser únicas.",
        400,
      );
    }
    uniqueKeys.add(item.context_key);
    uniqueLabels.add(item.context_label.toLowerCase());
  }

  return contexts;
}

export async function loadResponseForUpdate(
  client: SupabaseClient,
  responseId: string,
) {
  const id = assertUuid(responseId, "response_id");
  const { data, error } = await client
    .from("questionnaire_responses")
    .select("id, clinic_id, patient_id, questionnaire_id, status, questionnaire:questionnaires(code)")
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

export async function loadResponseContexts(
  client: SupabaseClient,
  responseId: string,
): Promise<ResponseContextRow[]> {
  const { data, error } = await client
    .from("questionnaire_response_contexts")
    .select(
      "id, clinic_id, response_id, patient_id, questionnaire_id, context_type, context_key, context_label, sort_order, status, completed_at",
    )
    .eq("response_id", responseId)
    .order("sort_order");

  if (error) {
    throw new AppError(
      "INTERNAL_ERROR",
      "Failed to load questionnaire response contexts",
      500,
      { hint: error.message },
    );
  }

  return (data ?? []) as ResponseContextRow[];
}

export async function loadCanonicalParentalQuestions(
  client: SupabaseClient,
  questionnaireId: string,
) {
  const { data, error } = await client
    .from("questions")
    .select(
      "id, code, text, order_index, answer_type, scale_min, scale_max",
    )
    .eq("questionnaire_id", questionnaireId)
    .eq("is_active", true)
    .like("code", "M_%")
    .order("order_index", { ascending: true });

  if (error) {
    throw new AppError(
      "INTERNAL_ERROR",
      "Failed to load parental questions",
      500,
      { hint: error.message },
    );
  }

  return data ?? [];
}

export async function assertResponseContextForAnswer(
  client: SupabaseClient,
  responseId: string,
  responseContextId: string | null | undefined,
  responseQuestionnaireCode: string | null | undefined,
) {
  const requiresContext = isParentalStylesQuestionnaire(responseQuestionnaireCode);
  if (!responseContextId) {
    if (requiresContext) {
      throw new AppError(
        "VALIDATION_ERROR",
        "response_context_id é obrigatório para Estilos Parentais.",
        400,
      );
    }
    return null;
  }

  const contextId = assertUuid(responseContextId, "response_context_id");
  const { data, error } = await client
    .from("questionnaire_response_contexts")
    .select(
      "id, response_id, patient_id, questionnaire_id, clinic_id, context_type, context_key, context_label",
    )
    .eq("id", contextId)
    .maybeSingle();

  if (error) {
    throw new AppError(
      "INTERNAL_ERROR",
      "Failed to load response context",
      500,
      { hint: error.message },
    );
  }

  if (!data || data.response_id !== responseId) {
    throw new AppError(
      "VALIDATION_ERROR",
      "response_context_id inválido para esta resposta.",
      400,
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
