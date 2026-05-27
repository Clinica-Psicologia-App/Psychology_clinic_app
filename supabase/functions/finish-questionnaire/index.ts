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
import { loadResponseForUpdate } from "../_shared/questionnaire.ts";
import {
  createServiceClient,
  createUserClient,
  getBearerToken,
} from "../_shared/supabase.ts";

type FinishQuestionnaireBody = {
  response_id: string;
};

type CategoryItem = {
  category_id: string;
  question_id: string;
  weight: number;
};

type AnswerRow = {
  question_id: string;
  answer_value: number | null;
};

const FN = "finish-questionnaire";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const client = createUserClient(authHeader);
    const caller = await getCallerProfile(client);

    const body = await parseJsonBody<FinishQuestionnaireBody>(req);
    const responseId = assertUuid(body.response_id, "response_id");
    const response = await loadResponseForUpdate(client, responseId);

    const { data: answers, error: answersError } = await client
      .from("questionnaire_answers")
      .select("question_id, answer_value")
      .eq("response_id", responseId);

    if (answersError) {
      throw new AppError("INTERNAL_ERROR", "Failed to load answers", 500);
    }

    const questionIds = (answers ?? []).map((a: AnswerRow) => a.question_id);
    let categoryItems: CategoryItem[] = [];

    if (questionIds.length > 0) {
      const { data, error: itemsError } = await client
        .from("question_category_items")
        .select("category_id, question_id, weight")
        .in("question_id", questionIds);

      if (itemsError) {
        throw new AppError(
          "INTERNAL_ERROR",
          "Failed to load category items",
          500,
        );
      }
      categoryItems = (data ?? []) as CategoryItem[];
    }

    const { data: categories, error: catError } = await client
      .from("question_categories")
      .select("id, code, name")
      .eq("questionnaire_id", response.questionnaire_id);

    if (catError) {
      throw new AppError("INTERNAL_ERROR", "Failed to load categories", 500);
    }

    const answerMap = new Map<string, number>();
    for (const a of answers ?? []) {
      if (a.answer_value != null) {
        answerMap.set(a.question_id, Number(a.answer_value));
      }
    }

    const categoryAggregates = new Map<
      string,
      { total: number; weightSum: number; items: unknown[] }
    >();

    for (const cat of categories ?? []) {
      categoryAggregates.set(cat.id, { total: 0, weightSum: 0, items: [] });
    }

    for (const item of categoryItems) {
      const value = answerMap.get(item.question_id);
      if (value == null) continue;

      const agg = categoryAggregates.get(item.category_id) ?? {
        total: 0,
        weightSum: 0,
        items: [],
      };
      const weighted = value * Number(item.weight);
      agg.total += weighted;
      agg.weightSum += Number(item.weight);
      agg.items.push({
        question_id: item.question_id,
        answer_value: value,
        weight: Number(item.weight),
        weighted_score: weighted,
      });
      categoryAggregates.set(item.category_id, agg);
    }

    const now = new Date().toISOString();
    const { data: completedResponse, error: updateError } = await client
      .from("questionnaire_responses")
      .update({
        status: "completed",
        completed_at: now,
      })
      .eq("id", responseId)
      .select("id, status, completed_at, patient_id, questionnaire_id")
      .single();

    if (updateError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to complete questionnaire response",
        500,
        { hint: updateError.message },
      );
    }

    const resultsPayload = [];
    const serviceClient = createServiceClient();

    for (const cat of categories ?? []) {
      const agg = categoryAggregates.get(cat.id) ?? {
        total: 0,
        weightSum: 0,
        items: [],
      };
      const average = agg.weightSum > 0 ? agg.total / agg.weightSum : null;

      const snapshot = {
        version: "mvp-1",
        category_code: cat.code,
        category_name: cat.name,
        answer_count: agg.items.length,
        total_weighted_score: agg.total,
        average_score: average,
        items: agg.items,
        note: "Placeholder aggregation — clinical engine not applied",
      };

      // Service role: pacientes não têm policy INSERT em results; autorização já validada acima.
      const { data: result, error: resultError } = await serviceClient
        .from("questionnaire_results")
        .upsert(
          {
            response_id: responseId,
            questionnaire_id: response.questionnaire_id,
            category_id: cat.id,
            total_score: agg.total,
            average_score: average,
            snapshot,
            classification: "pending_review",
          },
          { onConflict: "response_id,category_id" },
        )
        .select(
          "id, response_id, category_id, total_score, average_score, snapshot, classification",
        )
        .single();

      if (resultError) {
        throw new AppError(
          "INTERNAL_ERROR",
          "Failed to save questionnaire result",
          500,
          { hint: resultError.message },
        );
      }

      resultsPayload.push(result);
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      response_id: responseId,
      results_count: resultsPayload.length,
    });

    return jsonResponse({
      ok: true,
      data: {
        response: completedResponse,
        results: resultsPayload,
      },
    });
  } catch (error) {
    return handleError(error, FN);
  }
});
