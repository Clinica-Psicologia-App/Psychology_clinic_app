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
  isParentalStylesQuestionnaire,
  loadCanonicalParentalQuestions,
  loadResponseContexts,
  loadResponseForUpdate,
  type ResponseContextRow,
} from "../_shared/questionnaire.ts";
import { buildScoringPayload } from "../_shared/scoring/scorer.ts";
import {
  SNAPSHOT_VERSION,
  type AnswerMap,
  type DomainMeta,
  type LegacyCategorySnapshot,
  type MergedResultSnapshot,
  type QuestionnaireMeta,
  type QuestionnaireVersionRow,
  type SchemaMeta,
  type ScoringPayload,
  type ScoringRuleRow,
  type SeverityRangeRow,
} from "../_shared/scoring/types.ts";
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
  response_context_id?: string | null;
};

const FN = "finish-questionnaire";
const DEMO_NOTE =
  "Motor DEMO (scoring engine) — agregação estruturada; não é interpretação clínica validada.";

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
    const questionnaireCode =
      (response.questionnaire as { code?: string } | null)?.code ?? null;
    const isParental = isParentalStylesQuestionnaire(questionnaireCode);

    if (isParental) {
      const data = await finishParentalQuestionnaire({
        client,
        callerId: caller.id,
        responseId,
        response,
      });
      return jsonResponse({ ok: true, data });
    }

    const { data: answers, error: answersError } = await client
      .from("questionnaire_answers")
      .select("question_id, answer_value")
      .eq("response_id", responseId);

    if (answersError) {
      throw new AppError("INTERNAL_ERROR", "Failed to load answers", 500);
    }

    const answerMap: AnswerMap = new Map();
    for (const a of answers ?? []) {
      if (a.answer_value != null) {
        answerMap.set(a.question_id, Number(a.answer_value));
      }
    }

    const questionIds = [...answerMap.keys()];
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

    const scoringPayload = await loadAndComputeScoring(
      client,
      response.questionnaire_id,
      answerMap,
    );

    const categoryAggregates = buildLegacyCategoryAggregates(
      categories ?? [],
      categoryItems,
      answerMap,
    );

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

    const completedAt = completedResponse.completed_at ?? now;
    const resultsPayload = [];
    const serviceClient = createServiceClient();

    for (const cat of categories ?? []) {
      const agg = categoryAggregates.get(cat.id) ?? {
        total: 0,
        weightSum: 0,
        items: [] as LegacyCategorySnapshot["items"],
      };
      const average = agg.weightSum > 0 ? agg.total / agg.weightSum : null;

      const legacySnapshot: LegacyCategorySnapshot = {
        version: scoringPayload ? SNAPSHOT_VERSION : "mvp-1",
        category_code: cat.code,
        category_name: cat.name,
        answer_count: agg.items.length,
        total_weighted_score: agg.total,
        average_score: average,
        items: agg.items,
        note: scoringPayload ? DEMO_NOTE : (
          "Placeholder aggregation — clinical engine not applied"
        ),
      };

      const snapshot: MergedResultSnapshot = scoringPayload
        ? mergeSnapshot(legacySnapshot, scoringPayload, completedAt)
        : legacySnapshot;

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
      scoring_engine: scoringPayload != null,
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

async function finishParentalQuestionnaire(input: {
  client: ReturnType<typeof createUserClient>;
  callerId: string;
  responseId: string;
  response: Awaited<ReturnType<typeof loadResponseForUpdate>>;
}) {
  const { client, callerId, responseId, response } = input;
  const contexts = await loadResponseContexts(client, responseId);
  if (contexts.isEmpty) {
    throw new AppError(
      "INVALID_STATE",
      "Selecione ao menos uma figura parental antes de responder.",
      409,
    );
  }

  const canonicalQuestions = await loadCanonicalParentalQuestions(
    client,
    response.questionnaire_id,
  );
  if (canonicalQuestions.length == 0) {
    throw new AppError(
      "INVALID_STATE",
      "Questionário parental sem perguntas canônicas configuradas.",
      409,
    );
  }

  const canonicalQuestionIds = canonicalQuestions.map((q) => q.id as string);
  const { data: answers, error: answersError } = await client
    .from("questionnaire_answers")
    .select("question_id, answer_value, response_context_id")
    .eq("response_id", responseId)
    .in("question_id", canonicalQuestionIds);

  if (answersError) {
    throw new AppError("INTERNAL_ERROR", "Failed to load answers", 500);
  }

  const answersByContext = new Map<string, AnswerMap>();
  for (const context of contexts) {
    answersByContext.set(context.id, new Map());
  }

  for (const row of (answers ?? []) as AnswerRow[]) {
    if (!row.response_context_id || row.answer_value == null) continue;
    const map = answersByContext.get(row.response_context_id);
    if (map == null) continue;
    map.set(row.question_id, Number(row.answer_value));
  }

  for (const context of contexts) {
    const answered = answersByContext.get(context.id)?.size ?? 0;
    if (answered < canonicalQuestions.length) {
      throw new AppError(
        "INVALID_STATE",
        "Finalize todas as figuras parentais antes de concluir o questionário.",
        409,
        {
          context_label: context.context_label,
          answered_questions: answered,
          total_questions: canonicalQuestions.length,
        },
      );
    }
  }

  const templateCategories = await loadParentalTemplateCategories(
    client,
    response.questionnaire_id,
  );
  const templateCategoryItems = await loadParentalTemplateCategoryItems(
    client,
    canonicalQuestionIds,
  );

  const now = new Date().toISOString();
  const contextSnapshots = contexts.map((context) =>
    buildParentalContextSnapshot({
      context,
      totalQuestions: canonicalQuestions.length,
      answerMap: answersByContext.get(context.id) ?? new Map(),
      categories: templateCategories,
      categoryItems: templateCategoryItems,
    })
  );

  const totalAnswered = contextSnapshots.reduce(
    (sum, item) => sum + Number(item.answer_count ?? 0),
    0,
  );
  const note =
    "Resultado estruturado por figura parental para validação clínica. Não é interpretação clínica automática.";
  const snapshot = {
    version: "parental-context-v1",
    category_code: "PARENTAL_CONTEXTS",
    category_name: "Estilos Parentais por figura",
    answer_count: totalAnswered,
    total_weighted_score: null,
    average_score: null,
    items: [],
    note,
    contexts: contextSnapshots,
  };

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

  const { error: contextsUpdateError } = await client
    .from("questionnaire_response_contexts")
    .update({
      status: "completed",
      completed_at: now,
    })
    .eq("response_id", responseId);

  if (contextsUpdateError) {
    throw new AppError(
      "INTERNAL_ERROR",
      "Failed to complete parental contexts",
      500,
      { hint: contextsUpdateError.message },
    );
  }

  const anchorCategoryId = templateCategories[0]?.id;
  if (!anchorCategoryId) {
    throw new AppError(
      "INVALID_STATE",
      "Questionário parental sem categorias de referência configuradas.",
      409,
    );
  }

  const serviceClient = createServiceClient();
  const { data: result, error: resultError } = await serviceClient
    .from("questionnaire_results")
    .upsert(
      {
        response_id: responseId,
        questionnaire_id: response.questionnaire_id,
        category_id: anchorCategoryId,
        total_score: null,
        average_score: null,
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
      "Failed to save parental questionnaire result",
      500,
      { hint: resultError.message },
    );
  }

  logger.info(`${FN}.success.parental`, {
    caller_id: callerId,
    response_id: responseId,
    contexts_count: contexts.length,
  });

  return {
    response: completedResponse,
    results: [result],
  };
}

function buildLegacyCategoryAggregates(
  categories: Array<{ id: string; code: string; name: string }>,
  categoryItems: CategoryItem[],
  answerMap: AnswerMap,
): Map<
  string,
  { total: number; weightSum: number; items: LegacyCategorySnapshot["items"] }
> {
  const categoryAggregates = new Map<
    string,
    { total: number; weightSum: number; items: LegacyCategorySnapshot["items"] }
  >();

  for (const cat of categories) {
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

  return categoryAggregates;
}

function mergeSnapshot(
  legacy: LegacyCategorySnapshot,
  scoring: ScoringPayload,
  completedAt: string,
): MergedResultSnapshot {
  return {
    ...legacy,
    ...scoring,
    completed_at: completedAt,
    version: legacy.version,
  };
}

async function loadAndComputeScoring(
  client: ReturnType<typeof createUserClient>,
  questionnaireId: string,
  answers: AnswerMap,
): Promise<ScoringPayload | null> {
  const { data: questionnaire, error: qError } = await client
    .from("questionnaires")
    .select("id, code, name")
    .eq("id", questionnaireId)
    .maybeSingle();

  if (qError || !questionnaire) {
    return null;
  }

  const { data: versionRow, error: vError } = await client
    .from("questionnaire_versions")
    .select(
      "id, questionnaire_id, version, scoring_method, scale_min, scale_max, instructions",
    )
    .eq("questionnaire_id", questionnaireId)
    .eq("status", "active")
    .maybeSingle();

  if (vError || !versionRow) {
    return null;
  }

  const version = versionRow as QuestionnaireVersionRow;

  const { data: rules, error: rulesError } = await client
    .from("question_scoring_rules")
    .select(
      "id, question_id, schema_id, domain_id, weight, reverse_score, min_value, max_value, sort_order, metadata",
    )
    .eq("questionnaire_version_id", version.id)
    .order("sort_order");

  if (rulesError || !rules?.length) {
    return null;
  }

  const scoringRules = rules as ScoringRuleRow[];
  const schemaIds = [
    ...new Set(
      scoringRules.map((r) => r.schema_id).filter((id): id is string =>
        id != null
      ),
    ),
  ];
  const domainIds = [
    ...new Set(
      scoringRules.map((r) => r.domain_id).filter((id): id is string =>
        id != null
      ),
    ),
  ];

  let schemas: SchemaMeta[] = [];
  if (schemaIds.length > 0) {
    const { data, error } = await client
      .from("schemas")
      .select("id, domain_id, code, name")
      .in("id", schemaIds);
    if (error) {
      throw new AppError("INTERNAL_ERROR", "Failed to load schemas", 500);
    }
    schemas = (data ?? []) as SchemaMeta[];
    for (const s of schemas) {
      if (!domainIds.includes(s.domain_id)) domainIds.push(s.domain_id);
    }
  }

  let domains: DomainMeta[] = [];
  if (domainIds.length > 0) {
    const { data, error } = await client
      .from("schema_domains")
      .select("id, code, name")
      .in("id", domainIds);
    if (error) {
      throw new AppError("INTERNAL_ERROR", "Failed to load schema domains", 500);
    }
    domains = (data ?? []) as DomainMeta[];
  }

  const { data: severityRanges, error: sevError } = await client
    .from("severity_ranges")
    .select(
      "id, questionnaire_version_id, schema_id, domain_id, label, min_score, max_score, color_key, sort_order",
    )
    .eq("questionnaire_version_id", version.id);

  if (sevError) {
    throw new AppError("INTERNAL_ERROR", "Failed to load severity ranges", 500);
  }

  const questionnaireMeta: QuestionnaireMeta = {
    id: questionnaire.id,
    code: questionnaire.code,
    name: questionnaire.name,
  };

  return buildScoringPayload({
    questionnaire: questionnaireMeta,
    version,
    completedAt: new Date().toISOString(),
    rules: scoringRules,
    answers,
    domains,
    schemas,
    severityRanges: (severityRanges ?? []) as SeverityRangeRow[],
  });
}

type ParentalTemplateCategory = {
  id: string;
  code: string;
  name: string;
};

async function loadParentalTemplateCategories(
  client: ReturnType<typeof createUserClient>,
  questionnaireId: string,
): Promise<ParentalTemplateCategory[]> {
  const { data, error } = await client
    .from("question_categories")
    .select("id, code, name")
    .eq("questionnaire_id", questionnaireId)
    .like("code", "MOTHER_%")
    .order("name");

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load parental categories", 500);
  }

  return (data ?? []) as ParentalTemplateCategory[];
}

async function loadParentalTemplateCategoryItems(
  client: ReturnType<typeof createUserClient>,
  questionIds: string[],
): Promise<CategoryItem[]> {
  if (questionIds.isEmpty) return [];

  const { data, error } = await client
    .from("question_category_items")
    .select("category_id, question_id, weight")
    .in("question_id", questionIds);

  if (error) {
    throw new AppError(
      "INTERNAL_ERROR",
      "Failed to load parental category items",
      500,
    );
  }

  return (data ?? []) as CategoryItem[];
}

function buildParentalContextSnapshot(input: {
  context: ResponseContextRow;
  totalQuestions: number;
  answerMap: AnswerMap;
  categories: ParentalTemplateCategory[];
  categoryItems: CategoryItem[];
}) {
  const aggregates = buildLegacyCategoryAggregates(
    input.categories,
    input.categoryItems,
    input.answerMap,
  );

  const schemas = input.categories.map((category) {
    const agg = aggregates.get(category.id) ?? {
      total: 0,
      weightSum: 0,
      items: [] as LegacyCategorySnapshot["items"],
    };
    const average = agg.weightSum > 0 ? agg.total / agg.weightSum : null;
    return {
      code: normalizeParentalCategoryCode(category.code, input.context.context_key),
      name: normalizeParentalCategoryName(category.name, input.context.context_label),
      raw_score: agg.total,
      weighted_score: agg.total,
      average_score: average,
      answered_items: agg.items.length,
      max_possible_score: agg.weightSum * 6,
      severity: null,
    };
  });

  const total = schemas.reduce(
    (sum, item) => sum + Number(item.weighted_score ?? 0),
    0,
  );
  const answeredItems = input.answerMap.length;
  const averageScore = answeredItems > 0 ? total / answeredItems : null;

  return {
    id: input.context.id,
    key: input.context.context_key,
    label: input.context.context_label,
    status: "completed",
    completed_at: input.context.completed_at,
    answer_count: answeredItems,
    total_questions: input.totalQuestions,
    completion_ratio: input.totalQuestions > 0
      ? answeredItems / input.totalQuestions
      : 0,
    summary: {
      raw_score: total,
      weighted_score: total,
      average_score: averageScore,
      answered_items: answeredItems,
      max_possible_score: input.totalQuestions * 6,
    },
    schemas,
  };
}

function normalizeParentalCategoryCode(code: string, contextKey: string) {
  const stripped = code.replace(/^MOTHER_/, "");
  return `${contextKey.toUpperCase()}_${stripped}`;
}

function normalizeParentalCategoryName(name: string, contextLabel: string) {
  return name.replace(/—\s*Mãe$/i, `— ${contextLabel}`);
}
