import { classifySeverity } from "./severity.ts";
import type {
  AnswerMap,
  DomainMeta,
  GroupScores,
  QuestionnaireMeta,
  QuestionnaireVersionRow,
  SchemaMeta,
  ScoredItem,
  ScoringPayload,
  ScoringRuleRow,
  ScoringSummary,
  SeverityRangeRow,
} from "./types.ts";

export function applyReverseScore(
  value: number,
  scaleMin: number,
  scaleMax: number,
  reverse: boolean,
): number {
  if (!reverse) return value;
  return scaleMin + scaleMax - value;
}

export function clampToScale(value: number, min: number, max: number): number {
  return Math.min(max, Math.max(min, value));
}

export function resolveScaleBounds(
  rule: ScoringRuleRow,
  version: QuestionnaireVersionRow,
): { min: number; max: number } {
  const min = rule.min_value ?? version.scale_min ?? 1;
  const max = rule.max_value ?? version.scale_max ?? min;
  return { min: Number(min), max: Number(max) };
}

export function scoreAnswerValue(
  raw: number,
  rule: ScoringRuleRow,
  version: QuestionnaireVersionRow,
): {
  raw: number;
  adjusted: number;
  weight: number;
  weighted: number;
  scaleMin: number;
  scaleMax: number;
} {
  const { min: scaleMin, max: scaleMax } = resolveScaleBounds(rule, version);
  let adjusted = applyReverseScore(
    raw,
    scaleMin,
    scaleMax,
    rule.reverse_score,
  );
  adjusted = clampToScale(adjusted, scaleMin, scaleMax);
  const weight = Number(rule.weight);
  return {
    raw,
    adjusted,
    weight,
    weighted: adjusted * weight,
    scaleMin,
    scaleMax,
  };
}

export function computeGroupAggregate(
  items: ScoredItem[],
  maxPossible: number,
): Omit<GroupScores, "id" | "code" | "name" | "severity"> {
  let rawScore = 0;
  let weightedScore = 0;
  let weightSum = 0;
  let answered = 0;

  for (const item of items) {
    rawScore += item.adjusted_score;
    weightedScore += item.weighted_score;
    weightSum += item.weight;
    answered += 1;
  }

  const averageScore = weightSum > 0 ? weightedScore / weightSum : null;

  return {
    raw_score: round4(rawScore),
    weighted_score: round4(weightedScore),
    average_score: averageScore != null ? round4(averageScore) : null,
    answered_items: answered,
    max_possible_score: round4(maxPossible),
  };
}

export function maxPossibleForRules(
  rules: ScoringRuleRow[],
  version: QuestionnaireVersionRow,
): number {
  let total = 0;
  for (const rule of rules) {
    const { max } = resolveScaleBounds(rule, version);
    total += max * Number(rule.weight);
  }
  return total;
}

export function groupItemsBySchema(
  items: ScoredItem[],
): Map<string, ScoredItem[]> {
  const map = new Map<string, ScoredItem[]>();
  for (const item of items) {
    if (!item.schema_id) continue;
    const list = map.get(item.schema_id) ?? [];
    list.push(item);
    map.set(item.schema_id, list);
  }
  return map;
}

export function groupItemsByDomain(
  items: ScoredItem[],
): Map<string, ScoredItem[]> {
  const map = new Map<string, ScoredItem[]>();
  for (const item of items) {
    if (!item.domain_id) continue;
    const list = map.get(item.domain_id) ?? [];
    list.push(item);
    map.set(item.domain_id, list);
  }
  return map;
}

export function buildScoringPayload(input: {
  questionnaire: QuestionnaireMeta;
  version: QuestionnaireVersionRow;
  completedAt: string;
  rules: ScoringRuleRow[];
  answers: AnswerMap;
  domains: DomainMeta[];
  schemas: SchemaMeta[];
  severityRanges: SeverityRangeRow[];
}): ScoringPayload {
  const domainById = new Map(input.domains.map((d) => [d.id, d]));
  const schemaById = new Map(input.schemas.map((s) => [s.id, s]));

  const scoredItems: ScoredItem[] = [];

  for (const rule of input.rules) {
    const raw = input.answers.get(rule.question_id);
    if (raw == null) continue;

    const scored = scoreAnswerValue(raw, rule, input.version);
    const schema = rule.schema_id ? schemaById.get(rule.schema_id) : undefined;
    const domain = rule.domain_id
      ? domainById.get(rule.domain_id)
      : schema
      ? domainById.get(schema.domain_id)
      : undefined;

    scoredItems.push({
      question_id: rule.question_id,
      answer_value: raw,
      raw_score: scored.raw,
      adjusted_score: round4(scored.adjusted),
      weight: scored.weight,
      weighted_score: round4(scored.weighted),
      reverse_score: rule.reverse_score,
      scale_min: scored.scaleMin,
      scale_max: scored.scaleMax,
      schema_id: rule.schema_id,
      domain_id: rule.domain_id ?? schema?.domain_id ?? null,
      schema_code: schema?.code ?? null,
      schema_name: schema?.name ?? null,
      domain_code: domain?.code ?? null,
      domain_name: domain?.name ?? null,
    });
  }

  const rulesBySchema = groupRulesByKey(input.rules, "schema_id");
  const rulesByDomain = groupRulesByKey(input.rules, "domain_id");

  const schemaGroups = buildSchemaGroups(
    scoredItems,
    input.schemas,
    rulesBySchema,
    input.version,
    input.severityRanges,
  );

  const domainGroups = buildDomainGroups(
    scoredItems,
    input.domains,
    rulesByDomain,
    input.version,
    input.severityRanges,
  );

  const summary = buildSummary(scoredItems, input.rules, input.version);

  return {
    questionnaire: input.questionnaire,
    questionnaire_version: input.version,
    completed_at: input.completedAt,
    summary,
    domains: domainGroups,
    schemas: schemaGroups,
    items: scoredItems,
  };
}

function buildSummary(
  scoredItems: ScoredItem[],
  rules: ScoringRuleRow[],
  version: QuestionnaireVersionRow,
): ScoringSummary {
  const agg = computeGroupAggregate(
    scoredItems,
    maxPossibleForRules(rules, version),
  );
  return {
    raw_score: agg.raw_score,
    weighted_score: agg.weighted_score,
    average_score: agg.average_score,
    answered_items: agg.answered_items,
    max_possible_score: agg.max_possible_score,
  };
}

function buildSchemaGroups(
  scoredItems: ScoredItem[],
  schemas: SchemaMeta[],
  rulesBySchema: Map<string, ScoringRuleRow[]>,
  version: QuestionnaireVersionRow,
  severityRanges: SeverityRangeRow[],
): GroupScores[] {
  const bySchema = groupItemsBySchema(scoredItems);
  const result: GroupScores[] = [];

  for (const schema of schemas) {
    const items = bySchema.get(schema.id) ?? [];
    const rules = rulesBySchema.get(schema.id) ?? [];
    const agg = computeGroupAggregate(
      items,
      maxPossibleForRules(rules, version),
    );
    const severity = agg.average_score != null
      ? classifySeverity(agg.average_score, severityRanges, {
        schemaId: schema.id,
        domainId: schema.domain_id,
      })
      : null;

    result.push({
      id: schema.id,
      code: schema.code,
      name: schema.name,
      ...agg,
      severity,
    });
  }

  return result.sort((a, b) => a.code.localeCompare(b.code));
}

function buildDomainGroups(
  scoredItems: ScoredItem[],
  domains: DomainMeta[],
  rulesByDomain: Map<string, ScoringRuleRow[]>,
  version: QuestionnaireVersionRow,
  severityRanges: SeverityRangeRow[],
): GroupScores[] {
  const byDomain = groupItemsByDomain(scoredItems);
  const result: GroupScores[] = [];

  for (const domain of domains) {
    const items = byDomain.get(domain.id) ?? [];
    const rules = rulesByDomain.get(domain.id) ?? [];
    const agg = computeGroupAggregate(
      items,
      maxPossibleForRules(rules, version),
    );
    const severity = agg.average_score != null
      ? classifySeverity(agg.average_score, severityRanges, {
        domainId: domain.id,
      })
      : null;

    result.push({
      id: domain.id,
      code: domain.code,
      name: domain.name,
      ...agg,
      severity,
    });
  }

  return result.sort((a, b) => a.code.localeCompare(b.code));
}

function groupRulesByKey(
  rules: ScoringRuleRow[],
  key: "schema_id" | "domain_id",
): Map<string, ScoringRuleRow[]> {
  const map = new Map<string, ScoringRuleRow[]>();
  for (const rule of rules) {
    const id = rule[key];
    if (!id) continue;
    const list = map.get(id) ?? [];
    list.push(rule);
    map.set(id, list);
  }
  return map;
}

function round4(n: number): number {
  return Math.round(n * 10000) / 10000;
}
