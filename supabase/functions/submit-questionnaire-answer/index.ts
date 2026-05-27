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
  assertQuestionInQuestionnaire,
  loadResponseForUpdate,
  validateAnswerValue,
} from "../_shared/questionnaire.ts";
import { createUserClient, getBearerToken } from "../_shared/supabase.ts";

type SubmitAnswerBody = {
  response_id: string;
  question_id: string;
  answer_value: number;
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

    validateAnswerValue(
      body.answer_value,
      question.scale_min,
      question.scale_max,
    );

    const { data: answer, error: upsertError } = await client
      .from("questionnaire_answers")
      .upsert(
        {
          response_id: responseId,
          question_id: questionId,
          answer_value: body.answer_value,
        },
        { onConflict: "response_id,question_id" },
      )
      .select("id, response_id, question_id, answer_value, created_at, updated_at")
      .single();

    if (upsertError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to save answer",
        500,
        { hint: upsertError.message },
      );
    }

    logger.info(`${FN}.success`, {
      response_id: responseId,
      question_id: questionId,
      answer_id: answer.id,
    });

    return jsonResponse({ ok: true, data: { answer } });
  } catch (error) {
    return handleError(error, FN);
  }
});
