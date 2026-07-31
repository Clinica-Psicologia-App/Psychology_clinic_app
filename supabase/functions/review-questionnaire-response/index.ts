import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import {
  assertUuid,
  getCallerProfile,
  requireStaff,
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
  loadCanonicalParentalQuestions,
  loadResponseContexts,
} from "../_shared/questionnaire.ts";
import {
  buildLegacyCategoryAggregates,
  loadAndComputeScoring,
  type CategoryItem,
} from "../_shared/scoring/compute.ts";
import {
  buildParentalContextSnapshot,
  loadParentalTemplateCategories,
  loadParentalTemplateCategoryItems,
} from "../_shared/scoring/parental.ts";
import type { AnswerMap } from "../_shared/scoring/types.ts";
import {
  createServiceClient,
  createUserClient,
  getBearerToken,
} from "../_shared/supabase.ts";

/// "Passar a régua": o psicólogo valida o resultado consolidado do questionário
/// ajustando diretamente as pontuações por esquema/categoria (modo consolidado)
/// ou, em modo legado, ajustando itens individuais (professional_value).
///
/// Modo consolidado (novo, recomendado):
///   - schema_adjustments: ajuste direto em snapshot.schemas[].professional_average_score
///   - result_adjustments: ajuste em questionnaire_results.professional_average_score
///
/// Modo legado (item a item):
///   - adjustments: altera questionnaire_answers.professional_value e
///     recalcula os resultados a partir dos valores validados.
type AnswerAdjustment = {
  answer_id: string;
  professional_value?: number | null;
  professional_note?: string | null;
};

type SchemaAdjustment = {
  schema_id: string;
  professional_score?: number | null;
  professional_note?: string | null;
};

type ResultAdjustment = {
  result_id: string;
  professional_score?: number | null;
  professional_note?: string | null;
};

type ReviewQuestionnaireResponseBody = {
  response_id: string;
  reviewed: boolean;
  review_notes?: string | null;
  // Legado (item a item)
  adjustments?: AnswerAdjustment[];
  // Consolidado (por esquema / categoria)
  schema_adjustments?: SchemaAdjustment[];
  result_adjustments?: ResultAdjustment[];
};

const FN = "review-questionnaire-response";

serve(async (req) => {
  const options = handleOptions(req);
  if (options) return options;

  try {
    requirePost(req);
    const authHeader = getBearerToken(req);
    const client = createUserClient(authHeader);
    const caller = await getCallerProfile(client);
    requireStaff(caller);

    const body = await parseJsonBody<ReviewQuestionnaireResponseBody>(req);
    const responseId = assertUuid(body.response_id, "response_id");
    const reviewed = body.reviewed === true;
    const notes = normalizeNotes(body.review_notes);
    const adjustments = body.adjustments ?? [];
    const schemaAdjustments = body.schema_adjustments ?? [];
    const resultAdjustments = body.result_adjustments ?? [];

    const { data: response, error: loadError } = await client
      .from("questionnaire_responses")
      .select(
        "id, questionnaire_id, questionnaire_version_id, status, questionnaire:questionnaires(code)",
      )
      .eq("id", responseId)
      .eq("clinic_id", caller.clinic_id)
      .maybeSingle();

    if (loadError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to load questionnaire response",
        500,
        { hint: loadError.message },
      );
    }

    if (!response) {
      throw new AppError(
        "FORBIDDEN",
        "Questionnaire response not found or access denied",
        403,
        { response_id: responseId },
      );
    }

    const serviceClient = createServiceClient();

    // ── 1. Aplica ajustes de itens (modo legado) ─────────────────────────────
    if (adjustments.length > 0) {
      await applyAdjustments(serviceClient, responseId, adjustments);
    }

    // ── 2. Ao concluir, recalcula / aplica ajustes consolidados ──────────────
    const questionnaireCode =
      (response.questionnaire as { code?: string } | null)?.code ?? null;
    const isParental = isParentalStylesQuestionnaire(questionnaireCode);
    const hasConsolidatedAdjs =
      schemaAdjustments.length > 0 || resultAdjustments.length > 0;
    let adjustedCount = 0;

    if (reviewed) {
      if (hasConsolidatedAdjs) {
        // Modo consolidado: aplica overrides diretos nos resultados.
        adjustedCount = await applyConsolidatedAdjustments(
          serviceClient,
          responseId,
          schemaAdjustments,
          resultAdjustments,
          caller.id,
        );
      } else {
        // Modo legado: recalcula a partir dos valores dos itens.
        adjustedCount = isParental
          ? await recomputeParentalValidatedResults(
            client,
            serviceClient,
            responseId,
            response.questionnaire_id as string,
            response.questionnaire_version_id as string | null,
            caller.id,
          )
          : await recomputeValidatedResults(
            client,
            serviceClient,
            responseId,
            response.questionnaire_id as string,
            response.questionnaire_version_id as string | null,
            caller.id,
          );
      }
    }

    // ── 3. Atualiza o carimbo de revisão ─────────────────────────────────────
    const now = new Date().toISOString();
    const payload = reviewed
      ? {
        reviewed_at: now,
        reviewed_by_profile_id: caller.id,
        review_notes: notes,
      }
      : {
        reviewed_at: null,
        reviewed_by_profile_id: null,
        review_notes: null,
      };

    const { data: updated, error: updateError } = await client
      .from("questionnaire_responses")
      .update(payload)
      .eq("id", responseId)
      .select("id, reviewed_at, review_notes")
      .single();

    if (updateError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to update questionnaire review state",
        500,
        { hint: updateError.message },
      );
    }

    logger.info(`${FN}.success`, {
      caller_id: caller.id,
      response_id: responseId,
      reviewed,
      adjustments_saved: adjustments.length,
      schema_adjustments_saved: schemaAdjustments.length,
      result_adjustments_saved: resultAdjustments.length,
      adjusted_items_total: adjustedCount,
    });

    return jsonResponse({
      ok: true,
      data: { response: updated, adjusted_items: adjustedCount },
    });
  } catch (error) {
    return handleError(error, FN);
  }
});

/// Aplica ajustes no modo consolidado: patcha snapshot.schemas[] e/ou
/// questionnaire_results.professional_average_score diretamente, sem recalcular
/// a partir dos itens individuais.
async function applyConsolidatedAdjustments(
  serviceClient: ReturnType<typeof createServiceClient>,
  responseId: string,
  schemaAdjustments: SchemaAdjustment[],
  resultAdjustments: ResultAdjustment[],
  reviewerProfileId: string,
): Promise<number> {
  const { data: results, error: resultsError } = await serviceClient
    .from("questionnaire_results")
    .select("id, snapshot")
    .eq("response_id", responseId);

  if (resultsError) {
    throw new AppError("INTERNAL_ERROR", "Failed to load results", 500, {
      hint: resultsError.message,
    });
  }

  // Mapas para lookup rápido
  const schemaAdjBySchemaId = new Map(
    schemaAdjustments.map((a) => [a.schema_id, a]),
  );
  const resultAdjByResultId = new Map(
    resultAdjustments.map((a) => [a.result_id, a]),
  );

  const schemaCount = schemaAdjustments.filter((a) =>
    a.professional_score != null
  ).length;
  const resultCount = resultAdjustments.filter((a) =>
    a.professional_score != null
  ).length;
  const totalAdjusted = schemaCount + resultCount;

  const now = new Date().toISOString();

  for (const result of results ?? []) {
    const previous = (result.snapshot ?? {}) as Record<string, unknown>;
    const patientOriginal = previous.patient_original ??
      stripReguaFields(previous);

    // Patcha schemas no snapshot com professional_average_score do psicólogo.
    let updatedSchemas = previous.schemas as unknown[] | undefined;
    if (schemaAdjustments.length > 0 && Array.isArray(updatedSchemas)) {
      updatedSchemas = updatedSchemas.map((raw) => {
        const schema = raw as Record<string, unknown>;
        const adj = schemaAdjBySchemaId.get(schema.id as string);
        if (!adj) return schema;
        return {
          ...schema,
          professional_average_score: adj.professional_score ?? null,
          professional_note: adj.professional_note?.trim() ?? null,
        };
      });
    }

    const snapshot: Record<string, unknown> = {
      ...previous,
      ...(updatedSchemas ? { schemas: updatedSchemas } : {}),
      patient_original: patientOriginal,
      regua: {
        version: 2,
        mode: "consolidated",
        schema_overrides: schemaCount,
        result_overrides: resultCount,
        concluded_at: now,
        concluded_by_profile_id: reviewerProfileId,
      },
    };

    const updatePayload: Record<string, unknown> = {
      snapshot,
      classification: "reviewed",
    };

    const resultAdj = resultAdjByResultId.get(result.id as string);
    if (resultAdj) {
      updatePayload.professional_average_score = resultAdj.professional_score ??
        null;
      updatePayload.professional_note =
        resultAdj.professional_note?.trim() ?? null;
    }

    const { error: upError } = await serviceClient
      .from("questionnaire_results")
      .update(updatePayload)
      .eq("id", result.id as string);

    if (upError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to save consolidated adjustment",
        500,
        { hint: upError.message },
      );
    }
  }

  return totalAdjusted;
}

async function applyAdjustments(
  serviceClient: ReturnType<typeof createServiceClient>,
  responseId: string,
  adjustments: AnswerAdjustment[],
): Promise<void> {
  const { data: answers, error } = await serviceClient
    .from("questionnaire_answers")
    .select("id, question_id, question:questions(scale_min, scale_max)")
    .eq("response_id", responseId);

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load answers", 500, {
      hint: error.message,
    });
  }

  const byId = new Map((answers ?? []).map((a) => [a.id as string, a]));

  for (const adj of adjustments) {
    const answerId = assertUuid(adj.answer_id, "adjustments.answer_id");
    const row = byId.get(answerId);
    if (!row) {
      throw new AppError(
        "VALIDATION_ERROR",
        "Adjustment refers to an answer that does not belong to this response",
        422,
        { answer_id: answerId },
      );
    }

    const value = adj.professional_value ?? null;
    if (value != null) {
      const q = row.question as
        | { scale_min?: number | null; scale_max?: number | null }
        | null;
      const min = Number(q?.scale_min ?? 0);
      const max = Number(q?.scale_max ?? 10);
      if (!Number.isInteger(value) || value < min || value > max) {
        throw new AppError(
          "VALIDATION_ERROR",
          `professional_value must be an integer between ${min} and ${max}`,
          422,
          { answer_id: answerId, professional_value: value },
        );
      }
    }

    const note = adj.professional_note?.trim();
    const { error: upError } = await serviceClient
      .from("questionnaire_answers")
      .update({
        professional_value: value,
        professional_note: note ? note.slice(0, 500) : null,
      })
      .eq("id", row.id as string);

    if (upError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to save answer adjustment",
        500,
        { hint: upError.message },
      );
    }
  }
}

async function recomputeValidatedResults(
  client: ReturnType<typeof createUserClient>,
  serviceClient: ReturnType<typeof createServiceClient>,
  responseId: string,
  questionnaireId: string,
  responseVersionId: string | null,
  reviewerProfileId: string,
): Promise<number> {
  const { data: answers, error: answersError } = await serviceClient
    .from("questionnaire_answers")
    .select("question_id, answer_value, professional_value")
    .eq("response_id", responseId);

  if (answersError) {
    throw new AppError("INTERNAL_ERROR", "Failed to load answers", 500, {
      hint: answersError.message,
    });
  }

  const effectiveMap: AnswerMap = new Map();
  let adjustedCount = 0;
  for (const a of answers ?? []) {
    const patientValue = a.answer_value == null ? null : Number(a.answer_value);
    const professionalValue =
      a.professional_value == null ? null : Number(a.professional_value);
    const effective = professionalValue ?? patientValue;
    if (effective != null) {
      effectiveMap.set(a.question_id as string, effective);
    }
    if (professionalValue != null && professionalValue !== patientValue) {
      adjustedCount++;
    }
  }

  const validatedScoring = await loadAndComputeScoring(
    client,
    questionnaireId,
    effectiveMap,
    responseVersionId,
  );

  const questionIds = [...effectiveMap.keys()];
  let categoryItems: CategoryItem[] = [];
  if (questionIds.length > 0) {
    const { data, error } = await serviceClient
      .from("question_category_items")
      .select("category_id, question_id, weight")
      .in("question_id", questionIds);
    if (error) {
      throw new AppError("INTERNAL_ERROR", "Failed to load category items", 500);
    }
    categoryItems = (data ?? []) as CategoryItem[];
  }

  const { data: categories, error: catError } = await serviceClient
    .from("question_categories")
    .select("id, code, name")
    .eq("questionnaire_id", questionnaireId);

  if (catError) {
    throw new AppError("INTERNAL_ERROR", "Failed to load categories", 500);
  }

  const aggregates = buildLegacyCategoryAggregates(
    categories ?? [],
    categoryItems,
    effectiveMap,
  );

  const { data: results, error: resultsError } = await serviceClient
    .from("questionnaire_results")
    .select("id, category_id, snapshot")
    .eq("response_id", responseId);

  if (resultsError) {
    throw new AppError("INTERNAL_ERROR", "Failed to load results", 500, {
      hint: resultsError.message,
    });
  }

  const now = new Date().toISOString();

  for (const result of results ?? []) {
    const previous = (result.snapshot ?? {}) as Record<string, unknown>;
    const patientOriginal = previous.patient_original ??
      stripReguaFields(previous);

    const agg = aggregates.get(result.category_id as string) ?? {
      total: 0,
      weightSum: 0,
      items: [],
    };
    const average = agg.weightSum > 0 ? agg.total / agg.weightSum : null;

    const snapshot: Record<string, unknown> = {
      ...previous,
      answer_count: agg.items.length,
      total_weighted_score: agg.total,
      average_score: average,
      items: agg.items,
      ...(validatedScoring ?? {}),
      patient_original: patientOriginal,
      regua: {
        version: 1,
        mode: "item_level",
        adjusted_items: adjustedCount,
        concluded_at: now,
        concluded_by_profile_id: reviewerProfileId,
      },
    };

    const { error: upError } = await serviceClient
      .from("questionnaire_results")
      .update({
        total_score: agg.total,
        average_score: average,
        snapshot,
        classification: "reviewed",
      })
      .eq("id", result.id as string);

    if (upError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to save validated result",
        500,
        { hint: upError.message },
      );
    }
  }

  return adjustedCount;
}

async function recomputeParentalValidatedResults(
  client: ReturnType<typeof createUserClient>,
  serviceClient: ReturnType<typeof createServiceClient>,
  responseId: string,
  questionnaireId: string,
  responseVersionId: string | null,
  reviewerProfileId: string,
): Promise<number> {
  const contexts = await loadResponseContexts(client, responseId);
  if (contexts.length === 0) return 0;

  const canonicalQuestions = await loadCanonicalParentalQuestions(
    client,
    questionnaireId,
    responseVersionId,
  );
  const canonicalIds = canonicalQuestions.map((q) => q.id as string);

  const { data: answers, error: answersError } = await serviceClient
    .from("questionnaire_answers")
    .select("question_id, answer_value, professional_value, response_context_id")
    .eq("response_id", responseId)
    .in("question_id", canonicalIds);

  if (answersError) {
    throw new AppError("INTERNAL_ERROR", "Failed to load answers", 500, {
      hint: answersError.message,
    });
  }

  const answersByContext = new Map<string, AnswerMap>();
  for (const context of contexts) {
    answersByContext.set(context.id, new Map());
  }

  let adjustedCount = 0;
  for (const row of answers ?? []) {
    const contextId = row.response_context_id as string | null;
    if (!contextId) continue;
    const map = answersByContext.get(contextId);
    if (!map) continue;

    const patientValue = row.answer_value == null
      ? null
      : Number(row.answer_value);
    const professionalValue = row.professional_value == null
      ? null
      : Number(row.professional_value);
    const effective = professionalValue ?? patientValue;
    if (effective != null) {
      map.set(row.question_id as string, effective);
    }
    if (professionalValue != null && professionalValue !== patientValue) {
      adjustedCount++;
    }
  }

  const templateCategories = await loadParentalTemplateCategories(
    client,
    questionnaireId,
  );
  const templateCategoryItems = await loadParentalTemplateCategoryItems(
    client,
    canonicalIds,
  );

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

  const { data: results, error: resultsError } = await serviceClient
    .from("questionnaire_results")
    .select("id, snapshot")
    .eq("response_id", responseId);

  if (resultsError) {
    throw new AppError("INTERNAL_ERROR", "Failed to load results", 500, {
      hint: resultsError.message,
    });
  }

  const now = new Date().toISOString();

  for (const result of results ?? []) {
    const previous = (result.snapshot ?? {}) as Record<string, unknown>;
    const patientOriginal = previous.patient_original ??
      stripReguaFields(previous);

    const snapshot: Record<string, unknown> = {
      ...previous,
      answer_count: totalAnswered,
      contexts: contextSnapshots,
      patient_original: patientOriginal,
      regua: {
        version: 1,
        mode: "item_level",
        adjusted_items: adjustedCount,
        concluded_at: now,
        concluded_by_profile_id: reviewerProfileId,
      },
    };

    const { error: upError } = await serviceClient
      .from("questionnaire_results")
      .update({ snapshot, classification: "reviewed" })
      .eq("id", result.id as string);

    if (upError) {
      throw new AppError(
        "INTERNAL_ERROR",
        "Failed to save validated parental result",
        500,
        { hint: upError.message },
      );
    }
  }

  return adjustedCount;
}

function stripReguaFields(
  snapshot: Record<string, unknown>,
): Record<string, unknown> {
  const clone = { ...snapshot };
  delete clone.patient_original;
  delete clone.regua;
  return clone;
}

function normalizeNotes(value?: string | null): string | null {
  const trimmed = value?.trim();
  if (!trimmed) return null;
  return trimmed.slice(0, 1000);
}
