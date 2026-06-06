import { AppError } from "../errors.ts";
import { assertUuid } from "../auth.ts";
import type {
  GenerateReportBody,
  ReportInclude,
  ReportIncludeInput,
} from "./types.ts";

export const DEFAULT_INCLUDE: ReportInclude = {
  questionnaires: true,
  mental_map: true,
  goals: true,
  problems: true,
  check_ins: true,
  daily_monitors: true,
  timeline: true,
  genogram: true,
};

export function normalizeInclude(
  raw?: ReportIncludeInput,
): ReportInclude {
  if (!raw) return { ...DEFAULT_INCLUDE };
  return {
    questionnaires: raw.questionnaires !== false,
    mental_map: raw.mental_map !== false,
    goals: raw.goals !== false,
    problems: raw.problems !== false,
    check_ins: raw.check_ins !== false,
    daily_monitors: raw.daily_monitors !== false,
    timeline: raw.timeline !== false,
    genogram: raw.genogram !== false,
  };
}

export function parseGenerateReportBody(
  body: GenerateReportBody,
): { patientId: string; include: ReportInclude } {
  if (!body?.patient_id) {
    throw new AppError("VALIDATION_ERROR", "patient_id is required", 400);
  }

  const patientId = assertUuid(body.patient_id, "patient_id");
  const include = normalizeInclude(body.include);

  const hasSection = Object.values(include).some(Boolean);
  if (!hasSection) {
    throw new AppError(
      "VALIDATION_ERROR",
      "At least one report section must be included",
      400,
    );
  }

  return { patientId, include };
}
