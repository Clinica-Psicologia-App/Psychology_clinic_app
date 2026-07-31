import { AppError } from "../errors.ts";
import { createUserClient } from "../supabase.ts";
import { buildScoringPayload } from "./scorer.ts";
import type {
  AnswerMap,
  DomainMeta,
  LegacyCategorySnapshot,
  QuestionnaireMeta,
  QuestionnaireVersionRow,
  SchemaMeta,
  ScoringPayload,
  ScoringRuleRow,
  SeverityRangeRow,
} from "./types.ts";

type Client = ReturnType<typeof createUserClient>;

export type CategoryItem = {
  category_id: string;
  question_id: string;
  weight: number;
};

export type CategoryAggregate = {
  total: number;
  weightSum: number;
  items: LegacyCategorySnapshot["items"];
};

/// Agrega respostas por categoria legada (question_categories).
export function buildLegacyCategoryAggregates(
  categories: Array<{ id: string; code: string; name: string }>,
  categoryItems: CategoryItem[],
  answerMap: AnswerMap,
): Map<string, CategoryAggregate> {
  const categoryAggregates = new Map<string, CategoryAggregate>();

  for (const cat of categories) {
    categoryAggregates.set(cat.id, { total: 0, weightSum: 0, items: [] });
  }

  for (const item of categoryItems) {
    const value = answerMap.get(item.question_id);
    if (value == null) continue;

    const agg = categoryAggregates.get(item.category_id) ?? {
      total: 0,
      weightSum: 0,
      items: [] as LegacyCategorySnapshot["items"],
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

/// Carrega versão, regras, schemas, domínios e faixas de severidade e computa
/// o payload estruturado de pontuação para o mapa de respostas informado.
/// Retorna null quando o instrumento não tem camada estruturada configurada.
export async function loadAndComputeScoring(
  client: Client,
  questionnaireId: string,
  answers: AnswerMap,
  responseVersionId?: string | null,
): Promise<ScoringPayload | null> {
  const { data: questionnaire, error: qError } = await client
    .from("questionnaires")
    .select("id, code, name")
    .eq("id", questionnaireId)
    .maybeSingle();

  if (qError || !questionnaire) {
    return null;
  }

  // Pontua contra a versão FIXADA na resposta (a que o paciente realmente
  // respondeu). Fallback para a ativa apenas em respostas antigas sem versão.
  let versionQuery = client
    .from("questionnaire_versions")
    .select(
      "id, questionnaire_id, version, scoring_method, scale_min, scale_max, instructions",
    );
  versionQuery = responseVersionId
    ? versionQuery.eq("id", responseVersionId)
    : versionQuery.eq("questionnaire_id", questionnaireId).eq(
        "status",
        "active",
      );
  const { data: versionRow, error: vError } = await versionQuery.maybeSingle();

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
