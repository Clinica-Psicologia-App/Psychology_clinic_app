import type { SupabaseClient } from "@supabase/supabase-js";
import { AppError } from "../errors.ts";
import type { CallerProfile } from "../auth.ts";
import {
  latestCompletedResponse,
  markerFromCode,
  topScoresFromSnapshots,
} from "./snapshot_parse.ts";
import type {
  MentalMapSummary,
  PatientReportContext,
  QuestionnaireReportBlock,
  ReportData,
  ReportInclude,
} from "./types.ts";
import { REPORT_VERSION } from "./types.ts";

type PatientRow = {
  id: string;
  clinic_id: string;
  full_name: string;
  email: string | null;
  phone: string | null;
  birth_date: string | null;
  intake_summary: string | null;
  current_life_context: string | null;
  therapy_demands: string | null;
  responsible_psychologist_id: string;
  clinic: { name: string } | null;
  responsible_psychologist: { full_name: string } | null;
};

export async function loadPatientForReport(
  service: SupabaseClient,
  patientId: string,
  caller: CallerProfile,
): Promise<PatientRow> {
  const { data, error } = await service
    .from("patients")
    .select(
      `
      id,
      clinic_id,
      full_name,
      email,
      phone,
      birth_date,
      intake_summary,
      current_life_context,
      therapy_demands,
      responsible_psychologist_id,
      clinic:clinics!inner(name),
      responsible_psychologist:profiles!patients_responsible_psychologist_id_fkey(full_name)
    `,
    )
    .eq("id", patientId)
    .eq("clinic_id", caller.clinic_id)
    .maybeSingle();

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load patient", 500, {
      hint: error.message,
    });
  }

  if (!data) {
    throw new AppError(
      "FORBIDDEN",
      "Patient not found or access denied",
      403,
      { patient_id: patientId },
    );
  }

  return data as PatientRow;
}

export async function fetchReportData(
  service: SupabaseClient,
  patient: PatientRow,
  include: ReportInclude,
): Promise<ReportData> {
  const generatedAt = new Date().toISOString();
  const context: PatientReportContext = {
    patientId: patient.id,
    clinicId: patient.clinic_id,
    clinicName: patient.clinic?.name ?? "Clínica",
    patientName: patient.full_name,
    patientEmail: patient.email,
    patientPhone: patient.phone,
    birthDate: patient.birth_date,
    psychologistName: patient.responsible_psychologist?.full_name ?? null,
    generatedAt,
  };

  const [
    questionnaires,
    goals,
    problems,
    checkIns,
    dailyMonitors,
    timelineEvents,
    therapyResources,
    genogramPeople,
    genogramRelationships,
  ] = await Promise.all([
    include.questionnaires || include.mental_map
      ? fetchQuestionnaireBlocks(service, patient.id, patient.clinic_id)
      : Promise.resolve([]),
    include.goals || include.mental_map
      ? fetchGoals(service, patient.id, patient.clinic_id)
      : Promise.resolve([]),
    include.problems || include.mental_map
      ? fetchProblems(service, patient.id, patient.clinic_id)
      : Promise.resolve([]),
    include.check_ins || include.mental_map
      ? fetchCheckIns(service, patient.id, patient.clinic_id)
      : Promise.resolve([]),
    include.daily_monitors || include.mental_map
      ? fetchDailyMonitors(service, patient.id, patient.clinic_id)
      : Promise.resolve([]),
    include.timeline || include.mental_map
      ? fetchTimeline(service, patient.id, patient.clinic_id)
      : Promise.resolve([]),
    include.mental_map
      ? fetchTherapyResources(service, patient.clinic_id)
      : Promise.resolve([]),
    include.genogram || include.mental_map
      ? fetchGenogramPeople(service, patient.id, patient.clinic_id)
      : Promise.resolve([]),
    include.genogram || include.mental_map
      ? fetchGenogramRelationships(service, patient.id, patient.clinic_id)
      : Promise.resolve([]),
  ]);

  const mentalMap = include.mental_map
    ? buildMentalMapSummary({
      patient,
      questionnaires,
      problems,
      goals,
      checkIns,
      dailyMonitors,
      timelineEvents,
      therapyResources,
      genogramPeople,
      genogramRelationships,
    })
    : null;

  const peopleForReport = include.genogram
    ? genogramPeople.map((p) => ({
      displayName: p.displayName,
      gender: p.gender,
      birthYear: p.birthYear,
    }))
    : [];

  const nameById = new Map(
    genogramPeople.map((p) => [p.id, p.displayName]),
  );
  const relationshipsForReport = include.genogram
    ? genogramRelationships.map((r) => ({
      personA: nameById.get(r.personAId) ?? "Pessoa A",
      personB: nameById.get(r.personBId) ?? "Pessoa B",
      type: r.type,
    }))
    : [];

  return {
    context,
    questionnaires: include.questionnaires ? questionnaires : [],
    mentalMap,
    goals: include.goals ? goals : [],
    problems: include.problems ? problems : [],
    checkIns: include.check_ins ? checkIns : [],
    dailyMonitors: include.daily_monitors ? dailyMonitors : [],
    timelineEvents: include.timeline ? timelineEvents : [],
    genogramPeople: peopleForReport,
    genogramRelationships: relationshipsForReport,
  };
}

async function fetchQuestionnaireBlocks(
  service: SupabaseClient,
  patientId: string,
  clinicId: string,
): Promise<QuestionnaireReportBlock[]> {
  const { data, error } = await service
    .from("questionnaire_responses")
    .select(
      `
      id,
      status,
      completed_at,
      started_at,
      reviewed_at,
      review_notes,
      questionnaire:questionnaires(code, name),
      reviewed_by:profiles!questionnaire_responses_reviewed_by_profile_id_fkey(full_name),
      results:questionnaire_results(snapshot)
    `,
    )
    .eq("patient_id", patientId)
    .eq("clinic_id", clinicId)
    .eq("status", "completed")
    .order("completed_at", { ascending: false });

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load questionnaires", 500);
  }

  const rows = (data ?? []) as Array<{
    id: string;
    completed_at: string | null;
    started_at: string | null;
    reviewed_at: string | null;
    review_notes: string | null;
    questionnaire: { code: string; name: string } | null;
    reviewed_by: { full_name: string | null } | null;
    results: Array<{ snapshot: unknown }> | null;
  }>;

  const byMarker = new Map<string, typeof rows>();
  for (const row of rows) {
    const code = row.questionnaire?.code ?? "";
    const marker = markerFromCode(code);
    if (!marker) continue;
    const list = byMarker.get(marker) ?? [];
    list.push(row);
    byMarker.set(marker, list);
  }

  const blocks: QuestionnaireReportBlock[] = [];
  for (const [marker, list] of byMarker) {
    const latest = latestCompletedResponse(list);
    if (!latest) continue;
    const snapshots = (latest.results ?? []).map((r) => r.snapshot);
    const topScores = topScoresFromSnapshots(snapshots);
    const q = latest.questionnaire;
    blocks.push({
      responseId: latest.id,
      questionnaireCode: q?.code ?? marker,
      questionnaireName: q?.name ?? marker,
      completedAt: latest.completed_at,
      reviewedAt: latest.reviewed_at,
      reviewedByName: latest.reviewed_by?.full_name ?? null,
      reviewNotes: latest.review_notes,
      requiresTherapistReview: latest.reviewed_at == null,
      topScores,
    });
  }

  return blocks.sort((a, b) =>
    a.questionnaireCode.localeCompare(b.questionnaireCode)
  );
}

async function fetchGoals(
  service: SupabaseClient,
  patientId: string,
  clinicId: string,
) {
  const { data, error } = await service
    .from("therapy_goals")
    .select("title, status, description")
    .eq("patient_id", patientId)
    .eq("clinic_id", clinicId)
    .order("created_at", { ascending: false })
    .limit(50);

  if (error) throw new AppError("INTERNAL_ERROR", "Failed to load goals", 500);

  return (data ?? []).map((g) => ({
    title: String(g.title ?? ""),
    status: String(g.status ?? ""),
    description: g.description ? String(g.description) : null,
  }));
}

async function fetchProblems(
  service: SupabaseClient,
  patientId: string,
  clinicId: string,
) {
  const { data, error } = await service
    .from("patient_problems")
    .select("title, status, intensity")
    .eq("patient_id", patientId)
    .eq("clinic_id", clinicId)
    .order("created_at", { ascending: false })
    .limit(50);

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load problems", 500);
  }

  return (data ?? []).map((p) => ({
    title: String(p.title ?? ""),
    status: String(p.status ?? ""),
    intensity: typeof p.intensity === "number" ? p.intensity : null,
  }));
}

async function fetchCheckIns(
  service: SupabaseClient,
  patientId: string,
  clinicId: string,
) {
  const { data, error } = await service
    .from("patient_check_ins")
    .select(
      "checked_in_at, mood_score, anxiety_score, energy_score, notes",
    )
    .eq("patient_id", patientId)
    .eq("clinic_id", clinicId)
    .order("checked_in_at", { ascending: false })
    .limit(10);

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load check-ins", 500);
  }

  return (data ?? []).map((c) => ({
    checkedInAt: String(c.checked_in_at),
    mood: c.mood_score as number | null,
    anxiety: c.anxiety_score as number | null,
    energy: c.energy_score as number | null,
    notes: c.notes ? String(c.notes) : null,
  }));
}

async function fetchDailyMonitors(
  service: SupabaseClient,
  patientId: string,
  clinicId: string,
) {
  const { data, error } = await service
    .from("daily_monitors")
    .select("created_at, mood_notes, sleep_notes, activity_notes")
    .eq("patient_id", patientId)
    .eq("clinic_id", clinicId)
    .order("created_at", { ascending: false })
    .limit(10);

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load daily monitors", 500);
  }

  return (data ?? []).map((m) => ({
    createdAt: String(m.created_at),
    moodNotes: m.mood_notes ? String(m.mood_notes) : null,
    sleepNotes: m.sleep_notes ? String(m.sleep_notes) : null,
    activityNotes: m.activity_notes ? String(m.activity_notes) : null,
  }));
}

async function fetchTimeline(
  service: SupabaseClient,
  patientId: string,
  clinicId: string,
) {
  const { data, error } = await service
    .from("patient_timeline_events")
    .select("title, event_date, period_label, category")
    .eq("patient_id", patientId)
    .eq("clinic_id", clinicId)
    .order("event_date", { ascending: false, nullsFirst: false })
    .limit(15);

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load timeline", 500);
  }

  return (data ?? []).map((e) => ({
    title: String(e.title ?? ""),
    eventDate: e.event_date ? String(e.event_date) : null,
    periodLabel: e.period_label ? String(e.period_label) : null,
    category: e.category ? String(e.category) : null,
  }));
}

async function fetchGenogramPeople(
  service: SupabaseClient,
  patientId: string,
  clinicId: string,
) {
  const { data, error } = await service
    .from("genogram_people")
    .select("id, full_name, nickname, gender, birth_year")
    .eq("patient_id", patientId)
    .eq("clinic_id", clinicId)
    .order("full_name");

  if (error) {
    throw new AppError("INTERNAL_ERROR", "Failed to load genogram people", 500);
  }

  return (data ?? []).map((p) => {
    const fullName = String(p.full_name ?? "");
    const nick = p.nickname ? String(p.nickname).trim() : "";
    const displayName = nick
      ? `${fullName} (${nick})`
      : fullName;
    return {
      id: String(p.id),
      displayName,
      gender: p.gender ? String(p.gender) : null,
      birthYear: typeof p.birth_year === "number" ? p.birth_year : null,
    };
  });
}

async function fetchGenogramRelationships(
  service: SupabaseClient,
  patientId: string,
  clinicId: string,
) {
  const { data, error } = await service
    .from("genogram_relationships")
    .select("person_a_id, person_b_id, relationship_type")
    .eq("patient_id", patientId)
    .eq("clinic_id", clinicId);

  if (error) {
    throw new AppError(
      "INTERNAL_ERROR",
      "Failed to load genogram relationships",
      500,
    );
  }

  return (data ?? []).map((r) => ({
    personAId: String(r.person_a_id),
    personBId: String(r.person_b_id),
    type: String(r.relationship_type ?? ""),
  }));
}

async function fetchTherapyResources(
  service: SupabaseClient,
  clinicId: string,
) {
  const { data, error } = await service
    .from("therapy_resources")
    .select("title, description, type")
    .eq("clinic_id", clinicId)
    .eq("is_active", true)
    .order("title");

  if (error) {
    throw new AppError(
      "INTERNAL_ERROR",
      "Failed to load therapy resources",
      500,
    );
  }

  return (data ?? []).map((r) => ({
    title: String(r.title ?? ""),
    description: r.description ? String(r.description) : null,
    type: r.type ? String(r.type) : null,
  }));
}

function buildMentalMapSummary(input: {
  patient: Pick<
    PatientRow,
    "intake_summary" | "current_life_context" | "therapy_demands"
  >;
  questionnaires: QuestionnaireReportBlock[];
  problems: Array<{ status: string }>;
  goals: Array<{ status: string }>;
  checkIns: Array<{ checkedInAt: string; mood: number | null }>;
  dailyMonitors: Array<{ createdAt: string }>;
  timelineEvents: Array<{ title: string }>;
  therapyResources: Array<{ title: string; description: string | null }>;
  genogramPeople: Array<unknown>;
  genogramRelationships: Array<unknown>;
}): MentalMapSummary {
  const activeProblems = input.problems.filter((p) =>
    p.status === "active" || p.status === "improved"
  );
  const activeGoals = input.goals.filter((g) => g.status === "active");
  const latestCheckIn = input.checkIns[0] ?? null;
  const latestMonitor = input.dailyMonitors[0] ?? null;
  const centralHypotheses = input.questionnaires
    .flatMap((q) => q.topScores.map((row) => row.name))
    .filter((name, index, list) => name && list.indexOf(name) === index)
    .slice(0, 4);
  const currentFocuses = [
    ...splitFocusLines(input.patient.therapy_demands),
    ...activeGoals.map((g) => g.title),
    ...input.problems.map((p) => p.title),
  ].filter((name, index, list) => name && list.indexOf(name) === index).slice(0, 4);
  const suggestedResources = buildSuggestedResources({
    intakeSummary: input.patient.intake_summary,
    currentLifeContext: input.patient.current_life_context,
    therapyDemands: input.patient.therapy_demands,
    centralHypotheses,
    currentFocuses,
    questionnaireBlocks: input.questionnaires,
    problems: input.problems,
    goals: input.goals,
    checkIns: input.checkIns,
    dailyMonitors: input.dailyMonitors,
    library: input.therapyResources,
  });

  return {
    intakeSummary: input.patient.intake_summary,
    currentLifeContext: input.patient.current_life_context,
    therapyDemands: input.patient.therapy_demands,
    centralHypotheses,
    currentFocuses,
    suggestedResources,
    pendingQuestionnaireReviewCount: input.questionnaires
      .filter((q) => q.requiresTherapistReview)
      .length,
    reviewedQuestionnaireCount: input.questionnaires
      .filter((q) => !q.requiresTherapistReview)
      .length,
    activeProblemCount: activeProblems.length,
    activeGoalCount: activeGoals.length,
    latestCheckInAt: latestCheckIn?.checkedInAt ?? null,
    latestCheckInMood: latestCheckIn?.mood ?? null,
    latestMonitorAt: latestMonitor?.createdAt ?? null,
    genogramPeopleCount: input.genogramPeople.length,
    genogramRelationshipCount: input.genogramRelationships.length,
    recentTimelineTitles: input.timelineEvents.slice(0, 5).map((e) => e.title),
  };
}

function splitFocusLines(value: string | null): string[] {
  if (!value) return [];
  return value
    .split(/\r?\n/)
    .map((line) => line.replace(/^[-•\s]+/, "").trim())
    .filter(Boolean);
}

function buildSuggestedResources(input: {
  intakeSummary: string | null;
  currentLifeContext: string | null;
  therapyDemands: string | null;
  centralHypotheses: string[];
  currentFocuses: string[];
  questionnaireBlocks: QuestionnaireReportBlock[];
  problems: Array<{ title: string }>;
  goals: Array<{ title: string }>;
  checkIns: Array<{ mood: number | null; anxiety: number | null }>;
  dailyMonitors: Array<{ createdAt: string }>;
  library: Array<{ title: string; description: string | null }>;
}) {
  const questionnaireCodes = new Set(
    input.questionnaireBlocks.map((block) => block.questionnaireCode.trim().toUpperCase()),
  );
  const attachmentHints = highlightTextFor(input.questionnaireBlocks, "ATTACHMENT_STYLES_V1");
  const parentalHints = highlightTextFor(input.questionnaireBlocks, "PARENTAL_STYLES_V1");
  const yciHints = highlightTextFor(input.questionnaireBlocks, "YCI_FOUNDATION_V1");
  const yraiHints = highlightTextFor(input.questionnaireBlocks, "YRAI_FOUNDATION_V1");

  const signals = normalize([
    input.intakeSummary,
    input.currentLifeContext,
    input.therapyDemands,
    ...input.centralHypotheses,
    ...input.currentFocuses,
    ...input.problems.map((item) => item.title),
    ...input.goals.map((item) => item.title),
  ].filter(Boolean).join(" "));

  return input.library
    .map((resource) => {
      const text = normalize(`${resource.title} ${resource.description ?? ""}`);
      const reasons: string[] = [];

      if (text.includes("esquema") &&
        (input.centralHypotheses.length > 0 || input.questionnaireBlocks.length > 0)) {
        reasons.push("Ajuda a psicoeducar os esquemas e sustentar a formulacao do caso.");
      }

      if ((text.includes("registro emocional") || text.includes("emocional")) &&
        containsAny(signals, ["ansied", "emoc", "humor", "crise", "gatilh"])) {
        reasons.push("Apoia o rastreio de emocoes, gatilhos e padroes recorrentes.");
      }

      if ((text.includes("grounding") || text.includes("ancoragem")) &&
        (containsAny(signals, ["ansied", "crise", "sobrecarg", "gatilh"]) ||
          hasElevatedDistress(input.checkIns))) {
        reasons.push("Pode ajudar na regulacao imediata diante de ativacao emocional.");
      }

      if ((text.includes("emocional") || text.includes("grounding")) &&
        questionnaireCodes.has("ATTACHMENT_STYLES_V1") &&
        containsAny(attachmentHints, ["ansioso", "evitante"])) {
        reasons.push("Dialoga com sinais de apego inseguro identificados na avaliacao.");
      }

      if ((text.includes("esquema") || text.includes("emocional")) &&
        questionnaireCodes.has("PARENTAL_STYLES_V1") &&
        containsAny(parentalHints, ["abandono", "privacao", "punitiva", "desconfianca"])) {
        reasons.push("Conversa com padroes parentais percebidos e com a historia de desenvolvimento.");
      }

      if ((text.includes("registro emocional") || text.includes("emocional")) &&
        questionnaireCodes.has("YCI_FOUNDATION_V1") &&
        containsAny(yciHints, ["evit", "submiss", "hipercompens"])) {
        reasons.push("Ajuda a observar estilos de enfrentamento e respostas automaticas.");
      }

      if ((text.includes("grounding") || text.includes("esquema")) &&
        questionnaireCodes.has("YRAI_FOUNDATION_V1") &&
        containsAny(yraiHints, ["evit", "vulner", "crit", "control"])) {
        reasons.push("Pode apoiar o manejo de reacoes interpessoais ativadas no vinculo.");
      }

      return {
        title: resource.title,
        reasons,
        score: reasons.length,
      };
    })
    .filter((item) => item.reasons.length > 0)
    .sort((a, b) => b.score - a.score || a.title.localeCompare(b.title))
    .slice(0, 3)
    .map(({ title, reasons }) => ({ title, reasons }));
}

function highlightTextFor(
  blocks: QuestionnaireReportBlock[],
  questionnaireCode: string,
): string {
  const block = blocks.find((item) =>
    item.questionnaireCode.trim().toUpperCase() === questionnaireCode
  );
  if (!block) return "";
  return normalize(
    block.topScores.map((row) => `${row.name} ${row.code}`).join(" "),
  );
}

function hasElevatedDistress(
  checkIns: Array<{ mood: number | null; anxiety: number | null }>,
): boolean {
  const latest = checkIns[0];
  if (!latest) return false;
  return (latest.anxiety ?? 0) >= 6 || (latest.mood != null && latest.mood <= 4);
}

function containsAny(haystack: string, needles: string[]): boolean {
  return needles.some((needle) => haystack.includes(needle));
}

function normalize(value: string): string {
  return value
    .toLowerCase()
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "");
}

export function reportFilename(patientName: string): string {
  const safe = patientName
    .normalize("NFD")
    .replace(/[\u0300-\u036f]/g, "")
    .replace(/[^a-zA-Z0-9]+/g, "-")
    .replace(/^-|-$/g, "")
    .slice(0, 40) || "paciente";
  const date = new Date().toISOString().slice(0, 10);
  return `relatorio-clinico-${safe}-${date}.pdf`;
}

export { REPORT_VERSION };
