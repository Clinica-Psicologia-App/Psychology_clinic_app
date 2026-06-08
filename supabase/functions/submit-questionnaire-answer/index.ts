import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { assertUuid } from "../_shared/auth.ts";
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
  assertResponseContextForAnswer,
  assertQuestionInQuestionnaire,
  loadResponseForUpdate,
  validateAnswerValue,
} from "../_shared/questionnaire.ts";
import { createUserClient, getBearerToken } from "../_shared/supabase.ts";

type SubmitAnswerBody = {
  response_id: string;
  question_id: string;
  answer_value: number;
  response_context_id?: string;
};

const FN = "submit-questionnaire-answer";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const client = createUserClient(authHeader);
    await client.auth.getUser();

    const body = await parseJsonBody<SubmitAnswerBody>(req);
    const responseId = assertUuid(body.response_id, "response_id");
    const questionId = assertUuid(body.question_id, "question_id");

    const response = await loadResponseForUpdate(client, responseId);
    const question = await assertQuestionInQuestionnaire(
      client,
      questionId,
      response.questionnaire_id,
    );
    const responseContext = await assertResponseContextForAnswer(
      client,
      responseId,
      body.response_context_id,
      typeof response.questionnaire?.code === "string"
        ? response.questionnaire.code
        : null,
    );

    validateAnswerValue(
      body.answer_value,
      question.scale_min,
      question.scale_max,
    );

    const existing = responseContext == null
      ? await client
        .from("questionnaire_answers")
        .select("id")
        .eq("response_id", responseId)
        .eq("question_id", questionId)
        .is("response_context_id", null)
        .maybeSingle()
      : await client
        .from("questionnaire_answers")
        .select("id")
        .eq("response_id", responseId)
        .eq("question_id", questionId)
        .eq("response_context_id", responseContext.id)
        .maybeSingle();

    if (existing.error) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to load existing answer",
        500,
        { hint: existing.error.message },
      );
    }

    const payload = {
      response_id: responseId,
      question_id: questionId,
      answer_value: body.answer_value,
      response_context_id: responseContext?.id ?? null,
    };

    const saveResult = existing.data?.id
      ? await client
        .from("questionnaire_answers")
        .update(payload)
        .eq("id", existing.data.id)
        .select(
          "id, response_id, question_id, response_context_id, answer_value, created_at, updated_at",
        )
        .single()
      : await client
        .from("questionnaire_answers")
        .insert(payload)
        .select(
          "id, response_id, question_id, response_context_id, answer_value, created_at, updated_at",
        )
        .single();

    if (saveResult.error) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to save answer",
        500,
        { hint: saveResult.error.message },
      );
    }

    const answer = saveResult.data;

    logger.info(`${FN}.success`, {
      response_id: responseId,
      question_id: questionId,
      response_context_id: responseContext?.id ?? null,
      answer_id: answer.id,
    });

    return jsonResponse({ ok: true, data: { answer } });
  } catch (error) {
    return handleError(error, FN);
  }
});
