import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { classifySeverity, pickMatchingRange } from "./severity.ts";
import type { SeverityRangeRow } from "./types.ts";

const ranges: SeverityRangeRow[] = [
  {
    id: "1",
    questionnaire_version_id: "v1",
    schema_id: "schema-a",
    domain_id: null,
    label: "Schema Baixo",
    min_score: 1,
    max_score: 2.5,
    color_key: "low",
    sort_order: 0,
  },
  {
    id: "2",
    questionnaire_version_id: "v1",
    schema_id: "schema-a",
    domain_id: null,
    label: "Schema Alto",
    min_score: 4.01,
    max_score: 6,
    color_key: "high",
    sort_order: 2,
  },
  {
    id: "3",
    questionnaire_version_id: "v1",
    schema_id: null,
    domain_id: "domain-b",
    label: "Domain Moderado",
    min_score: 2.51,
    max_score: 4,
    color_key: "moderate",
    sort_order: 1,
  },
];

Deno.test("pickMatchingRange is inclusive on bounds", () => {
  assertEquals(pickMatchingRange(2.5, ranges.slice(0, 1))?.label, "Schema Baixo");
  assertEquals(pickMatchingRange(4.01, ranges.slice(1, 2))?.label, "Schema Alto");
  assertEquals(pickMatchingRange(3, ranges.slice(2, 3))?.label, "Domain Moderado");
});

Deno.test("classifySeverity prefers schema ranges over domain", () => {
  const match = classifySeverity(3, ranges, {
    schemaId: "schema-a",
    domainId: "domain-b",
  });
  assertEquals(match, null);
});

Deno.test("classifySeverity falls back to domain when schema has no band", () => {
  const match = classifySeverity(3, ranges, {
    schemaId: "schema-unknown",
    domainId: "domain-b",
  });
  assertEquals(match?.label, "Domain Moderado");
});

Deno.test("classifySeverity uses schema bands when present", () => {
  const match = classifySeverity(5, ranges, { schemaId: "schema-a" });
  assertEquals(match?.label, "Schema Alto");
});
