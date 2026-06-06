/** Catálogo e apuração DEMO — não é interpretação clínica validada. */

export const SNAPSHOT_VERSION = "scoring-demo-1";

export type ScoringRuleRow = {
  id: string;
  question_id: string;
  schema_id: string | null;
  domain_id: string | null;
  weight: number;
  reverse_score: boolean;
  min_value: number | null;
  max_value: number | null;
  sort_order: number;
  metadata?: Record<string, unknown>;
};

export type QuestionnaireVersionRow = {
  id: string;
  questionnaire_id: string;
  version: string;
  scoring_method: string | null;
  scale_min: number | null;
  scale_max: number | null;
  instructions: string | null;
};

export type QuestionnaireMeta = {
  id: string;
  code: string;
  name: string;
};

export type DomainMeta = {
  id: string;
  code: string;
  name: string;
};

export type SchemaMeta = {
  id: string;
  domain_id: string;
  code: string;
  name: string;
};

export type SeverityRangeRow = {
  id: string;
  questionnaire_version_id: string;
  schema_id: string | null;
  domain_id: string | null;
  label: string;
  min_score: number | null;
  max_score: number | null;
  color_key: string | null;
  sort_order: number;
};

export type AnswerMap = Map<string, number>;

export type ScoredItem = {
  question_id: string;
  answer_value: number;
  raw_score: number;
  adjusted_score: number;
  weight: number;
  weighted_score: number;
  reverse_score: boolean;
  scale_min: number;
  scale_max: number;
  schema_id: string | null;
  domain_id: string | null;
  schema_code: string | null;
  schema_name: string | null;
  domain_code: string | null;
  domain_name: string | null;
};

export type GroupScores = {
  id: string;
  code: string;
  name: string;
  raw_score: number;
  weighted_score: number;
  average_score: number | null;
  answered_items: number;
  max_possible_score: number;
  severity: SeverityMatch | null;
};

export type SeverityMatch = {
  label: string;
  color_key: string | null;
  min_score: number | null;
  max_score: number | null;
};

export type ScoringSummary = {
  raw_score: number;
  weighted_score: number;
  average_score: number | null;
  answered_items: number;
  max_possible_score: number;
};

export type ScoringPayload = {
  questionnaire: QuestionnaireMeta;
  questionnaire_version: QuestionnaireVersionRow;
  completed_at: string;
  summary: ScoringSummary;
  domains: GroupScores[];
  schemas: GroupScores[];
  items: ScoredItem[];
};

/** Campos legados lidos pelo app Flutter (`ResultSnapshot`). */
export type LegacyCategorySnapshot = {
  version: string;
  category_code: string;
  category_name: string;
  answer_count: number;
  total_weighted_score: number;
  average_score: number | null;
  items: Array<{
    question_id: string;
    answer_value: number;
    weight: number;
    weighted_score: number;
  }>;
  note: string;
};

export type MergedResultSnapshot = LegacyCategorySnapshot & ScoringPayload;
