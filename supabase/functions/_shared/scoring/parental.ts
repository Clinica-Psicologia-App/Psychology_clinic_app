import { AppError } from "../errors.ts";
import { createUserClient } from "../supabase.ts";
import type { ResponseContextRow } from "../questionnaire.ts";
import {
  buildLegacyCategoryAggregates,
  type CategoryItem,
} from "./compute.ts";
import type { AnswerMap, LegacyCategorySnapshot } from "./types.ts";

type Client = ReturnType<typeof createUserClient>;

export type ParentalTemplateCategory = {
  id: string;
  code: string;
  name: string;
};

export async function loadParentalTemplateCategories(
  client: Client,
  questionnaireId: string,
): Promise<ParentalTemplateCategory[]> {
  const { data, error } = await client
    .from("question_categories")
    .select("id, code, name")
    .eq("questionnaire_id", questionnaireId)
    .like("code", "MOTHER_%")
    .order("name");

  if (error) {
    throw new AppError(
      "INTERNAL_ERROR",
      "Failed to load parental categories",
      500,
    );
  }

  return (data ?? []) as ParentalTemplateCategory[];
}

export async function loadParentalTemplateCategoryItems(
  client: Client,
  questionIds: string[],
): Promise<CategoryItem[]> {
  if (questionIds.length === 0) return [];

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

export function buildParentalContextSnapshot(input: {
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

  const schemas = input.categories.map((category) => {
    const agg = aggregates.get(category.id) ?? {
      total: 0,
      weightSum: 0,
      items: [] as LegacyCategorySnapshot["items"],
    };
    const average = agg.weightSum > 0 ? agg.total / agg.weightSum : null;
    return {
      code: normalizeParentalCategoryCode(
        category.code,
        input.context.context_key,
      ),
      name: normalizeParentalCategoryName(
        category.name,
        input.context.context_label,
      ),
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
  const answeredItems = input.answerMap.size;
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

export function normalizeParentalCategoryCode(code: string, contextKey: string) {
  const stripped = code.replace(/^MOTHER_/, "");
  return `${contextKey.toUpperCase()}_${stripped}`;
}

export function normalizeParentalCategoryName(
  name: string,
  contextLabel: string,
) {
  return name.replace(/—\s*Mãe$/i, `— ${contextLabel}`);
}
