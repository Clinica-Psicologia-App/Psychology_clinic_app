import type { SeverityMatch, SeverityRangeRow } from "./types.ts";

/**
 * Classifica um score usando faixas da versão do questionário.
 * Prioridade: faixas com schema_id → fallback faixas só com domain_id.
 */
export function classifySeverity(
  score: number,
  ranges: SeverityRangeRow[],
  opts: { schemaId?: string | null; domainId?: string | null },
): SeverityMatch | null {
  if (opts.schemaId) {
    const schemaRanges = ranges.filter((r) => r.schema_id === opts.schemaId);
    const match = pickMatchingRange(score, schemaRanges);
    if (match) return toSeverityMatch(match);
  }

  if (opts.domainId) {
    const domainRanges = ranges.filter(
      (r) => r.domain_id === opts.domainId && r.schema_id == null,
    );
    const match = pickMatchingRange(score, domainRanges);
    if (match) return toSeverityMatch(match);
  }

  return null;
}

export function pickMatchingRange(
  score: number,
  ranges: SeverityRangeRow[],
): SeverityRangeRow | null {
  if (ranges.length === 0) return null;

  const sorted = [...ranges].sort((a, b) => a.sort_order - b.sort_order);
  for (const range of sorted) {
    const min = range.min_score ?? Number.NEGATIVE_INFINITY;
    const max = range.max_score ?? Number.POSITIVE_INFINITY;
    if (score >= min && score <= max) {
      return range;
    }
  }
  return null;
}

function toSeverityMatch(range: SeverityRangeRow): SeverityMatch {
  return {
    label: range.label,
    color_key: range.color_key,
    min_score: range.min_score,
    max_score: range.max_score,
  };
}
