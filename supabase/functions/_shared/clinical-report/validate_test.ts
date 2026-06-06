import { assertEquals } from "https://deno.land/std@0.224.0/assert/mod.ts";
import { AppError } from "../errors.ts";
import {
  DEFAULT_INCLUDE,
  normalizeInclude,
  parseGenerateReportBody,
} from "./validate.ts";

Deno.test("normalizeInclude defaults all sections to true", () => {
  assertEquals(normalizeInclude(undefined), DEFAULT_INCLUDE);
  assertEquals(normalizeInclude({}), DEFAULT_INCLUDE);
});

Deno.test("normalizeInclude respects explicit false", () => {
  const inc = normalizeInclude({ questionnaires: false, genogram: false });
  assertEquals(inc.questionnaires, false);
  assertEquals(inc.genogram, false);
  assertEquals(inc.goals, true);
});

Deno.test("parseGenerateReportBody rejects missing patient_id", () => {
  let thrown = false;
  try {
    parseGenerateReportBody({ patient_id: "" });
  } catch (e) {
    thrown = e instanceof AppError && e.code === "VALIDATION_ERROR";
  }
  assertEquals(thrown, true);
});

Deno.test("parseGenerateReportBody rejects all sections disabled", () => {
  let thrown = false;
  try {
    parseGenerateReportBody({
      patient_id: "11111111-1111-1111-1111-111111111201",
      include: {
        questionnaires: false,
        mental_map: false,
        goals: false,
        problems: false,
        check_ins: false,
        daily_monitors: false,
        timeline: false,
        genogram: false,
      },
    });
  } catch (e) {
    thrown = e instanceof AppError && e.code === "VALIDATION_ERROR";
  }
  assertEquals(thrown, true);
});
