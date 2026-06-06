import type { TopScoreRow } from "./types.ts";

const YSQ_MARKER = "YSQ";
const YAMI_MARKER = "YAMI";
const ATTACHMENT_CODE = "ATTACHMENT_STYLES_V1";
const PARENTAL_CODE = "PARENTAL_STYLES_V1";
const YCI_CODE = "YCI_FOUNDATION_V1";
const YRAI_CODE = "YRAI_FOUNDATION_V1";
const TOP_LIMIT = 8;

type SchemaLike = {
  code?: string;
  name?: string;
  weighted_score?: number;
  average_score?: number;
  raw_score?: number;
  severity?: { label?: string };
};

function scoreOf(schema: SchemaLike): number {
  const w = schema.weighted_score;
  if (typeof w === "number" && !Number.isNaN(w)) return w;
  const a = schema.average_score;
  if (typeof a === "number" && !Number.isNaN(a)) return a;
  const r = schema.raw_score;
  if (typeof r === "number" && !Number.isNaN(r)) return r;
  return 0;
}

function schemasFromSnapshot(snapshot: unknown): SchemaLike[] {
  if (!snapshot || typeof snapshot !== "object") return [];
  const map = snapshot as Record<string, unknown>;
  const direct = map["schemas"];
  if (Array.isArray(direct)) {
    return direct.filter((s) => s && typeof s === "object") as SchemaLike[];
  }
  return [];
}

export function topScoresFromSnapshots(
  snapshots: unknown[],
  limit = TOP_LIMIT,
): TopScoreRow[] {
  const rows: TopScoreRow[] = [];

  for (const snap of snapshots) {
    for (const schema of schemasFromSnapshot(snap)) {
      rows.push({
        name: String(schema.name ?? "—"),
        code: String(schema.code ?? "—"),
        score: scoreOf(schema),
        severityLabel: schema.severity?.label
          ? String(schema.severity.label)
          : null,
      });
    }
  }

  rows.sort((a, b) => b.score - a.score);
  const seen = new Set<string>();
  const unique: TopScoreRow[] = [];
  for (const row of rows) {
    const key = `${row.code}:${row.name}`;
    if (seen.has(key)) continue;
    seen.add(key);
    unique.push(row);
    if (unique.length >= limit) break;
  }
  return unique;
}

export function markerFromCode(code: string): string | null {
  const upper = code.toUpperCase();
  if (upper.includes(YSQ_MARKER)) return YSQ_MARKER;
  if (upper.includes(YAMI_MARKER)) return YAMI_MARKER;
  if (upper === ATTACHMENT_CODE) return ATTACHMENT_CODE;
  if (upper === PARENTAL_CODE) return PARENTAL_CODE;
  if (upper === YCI_CODE) return YCI_CODE;
  if (upper === YRAI_CODE) return YRAI_CODE;
  return null;
}

export function latestCompletedResponse<
  T extends { completed_at?: string | null; started_at?: string | null },
>(rows: T[]): T | null {
  let latest: T | null = null;
  for (const row of rows) {
    if (!latest) {
      latest = row;
      continue;
    }
    const a = row.completed_at ?? row.started_at;
    const b = latest.completed_at ?? latest.started_at;
    if (a && (!b || a > b)) latest = row;
  }
  return latest;
}
