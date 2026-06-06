import {
  applyReverseScore,
  buildScoringPayload,
  clampToScale,
  computeGroupAggregate,
  groupItemsByDomain,
  groupItemsBySchema,
  maxPossibleForRules,
  scoreAnswerValue,
} from "./scorer.ts";
import type {
  DomainMeta,
  QuestionnaireMeta,
  QuestionnaireVersionRow,
  SchemaMeta,
  ScoredItem,
  ScoringRuleRow,
  SeverityRangeRow,
} from "./types.ts";

import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";

const VERSION: QuestionnaireVersionRow = {
  id: "v1",
  questionnaire_id: "q1",
  version: "v1-demo",
  scoring_method: "weighted_sum_demo",
  scale_min: 1,
  scale_max: 6,
  instructions: null,
};

Deno.test("applyReverseScore inverts on 1-6 scale", () => {
  assertEquals(applyReverseScore(1, 1, 6, true), 6);
  assertEquals(applyReverseScore(6, 1, 6, true), 1);
  assertEquals(applyReverseScore(4, 1, 6, true), 3);
  assertEquals(applyReverseScore(4, 1, 6, false), 4);
});

Deno.test("clampToScale enforces bounds", () => {
  assertEquals(clampToScale(0, 1, 6), 1);
  assertEquals(clampToScale(9, 1, 6), 6);
});

Deno.test("scoreAnswerValue applies weight and reverse", () => {
  const rule: ScoringRuleRow = {
    id: "r1",
    question_id: "q1",
    schema_id: "s1",
    domain_id: "d1",
    weight: 2,
    reverse_score: true,
    min_value: null,
    max_value: null,
    sort_order: 0,
  };
  const scored = scoreAnswerValue(1, rule, VERSION);
  assertEquals(scored.adjusted, 6);
  assertEquals(scored.weighted, 12);
});

Deno.test("computeGroupAggregate sums weighted scores and average", () => {
  const items: ScoredItem[] = [
    makeItem("q1", 4, 4, 1, 4),
    makeItem("q2", 3, 3, 1, 3),
  ];
  const agg = computeGroupAggregate(items, 12);
  assertEquals(agg.raw_score, 7);
  assertEquals(agg.weighted_score, 7);
  assertEquals(agg.average_score, 3.5);
  assertEquals(agg.answered_items, 2);
  assertEquals(agg.max_possible_score, 12);
});

Deno.test("maxPossibleForRules uses scale max and weight", () => {
  const rules: ScoringRuleRow[] = [
    {
      id: "r1",
      question_id: "q1",
      schema_id: "s1",
      domain_id: "d1",
      weight: 1,
      reverse_score: false,
      min_value: null,
      max_value: null,
      sort_order: 0,
    },
    {
      id: "r2",
      question_id: "q2",
      schema_id: "s1",
      domain_id: "d1",
      weight: 2,
      reverse_score: false,
      min_value: null,
      max_value: null,
      sort_order: 1,
    },
  ];
  assertEquals(maxPossibleForRules(rules, VERSION), 18);
});

Deno.test("groupItemsBySchema and groupItemsByDomain", () => {
  const items: ScoredItem[] = [
    makeItem("q1", 4, 4, 1, 4, "s1", "d1"),
    makeItem("q2", 3, 3, 1, 3, "s2", "d1"),
    makeItem("q3", 5, 5, 1, 5, "s2", "d2"),
  ];
  assertEquals(groupItemsBySchema(items).get("s1")?.length, 1);
  assertEquals(groupItemsBySchema(items).get("s2")?.length, 2);
  assertEquals(groupItemsByDomain(items).get("d1")?.length, 2);
  assertEquals(groupItemsByDomain(items).get("d2")?.length, 1);
});

Deno.test("buildScoringPayload aggregates schemas and domains", () => {
  const questionnaire: QuestionnaireMeta = {
    id: "q1",
    code: "MVP_DEMO",
    name: "Demo",
  };
  const domains: DomainMeta[] = [
    { id: "d1", code: "D1", name: "Domain 1" },
    { id: "d2", code: "D2", name: "Domain 2" },
  ];
  const schemas: SchemaMeta[] = [
    { id: "s1", domain_id: "d1", code: "S1", name: "Schema 1" },
    { id: "s2", domain_id: "d2", code: "S2", name: "Schema 2" },
  ];
  const rules: ScoringRuleRow[] = [
    {
      id: "r1",
      question_id: "q1",
      schema_id: "s1",
      domain_id: "d1",
      weight: 1,
      reverse_score: false,
      min_value: null,
      max_value: null,
      sort_order: 0,
    },
    {
      id: "r2",
      question_id: "q2",
      schema_id: "s2",
      domain_id: "d2",
      weight: 1,
      reverse_score: false,
      min_value: null,
      max_value: null,
      sort_order: 1,
    },
  ];
  const answers = new Map([
    ["q1", 4],
    ["q2", 2],
  ]);
  const severityRanges: SeverityRangeRow[] = [
    {
      id: "sr1",
      questionnaire_version_id: "v1",
      schema_id: "s1",
      domain_id: null,
      label: "Demo — Moderado",
      min_score: 2.51,
      max_score: 4,
      color_key: "severity_moderate",
      sort_order: 1,
    },
  ];

  const payload = buildScoringPayload({
    questionnaire,
    version: VERSION,
    completedAt: "2025-05-31T12:00:00.000Z",
    rules,
    answers,
    domains,
    schemas,
    severityRanges,
  });

  assertEquals(payload.items.length, 2);
  assertEquals(payload.summary.answered_items, 2);
  assertEquals(payload.summary.weighted_score, 6);
  assertEquals(payload.schemas.length, 2);
  assertEquals(payload.domains.length, 2);

  const s1 = payload.schemas.find((s) => s.id === "s1");
  assertEquals(s1?.average_score, 4);
  assertEquals(s1?.severity?.label, "Demo — Moderado");
});

function makeItem(
  questionId: string,
  answerValue: number,
  adjusted: number,
  weight: number,
  weighted: number,
  schemaId: string | null = null,
  domainId: string | null = null,
): ScoredItem {
  return {
    question_id: questionId,
    answer_value: answerValue,
    raw_score: answerValue,
    adjusted_score: adjusted,
    weight,
    weighted_score: weighted,
    reverse_score: false,
    scale_min: 1,
    scale_max: 6,
    schema_id: schemaId,
    domain_id: domainId,
    schema_code: null,
    schema_name: null,
    domain_code: null,
    domain_name: null,
  };
}
