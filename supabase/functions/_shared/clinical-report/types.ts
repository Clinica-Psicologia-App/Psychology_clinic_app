export const REPORT_VERSION = "CLINICAL_REPORT_V1";

export type ReportIncludeInput = {
  questionnaires?: boolean;
  mental_map?: boolean;
  goals?: boolean;
  problems?: boolean;
  check_ins?: boolean;
  daily_monitors?: boolean;
  timeline?: boolean;
  genogram?: boolean;
};

export type ReportInclude = {
  questionnaires: boolean;
  mental_map: boolean;
  goals: boolean;
  problems: boolean;
  check_ins: boolean;
  daily_monitors: boolean;
  timeline: boolean;
  genogram: boolean;
};

export type GenerateReportBody = {
  patient_id: string;
  include?: ReportIncludeInput;
};

export type TopScoreRow = {
  name: string;
  code: string;
  score: number;
  severityLabel: string | null;
};

export type QuestionnaireReportBlock = {
  responseId: string;
  questionnaireCode: string;
  questionnaireName: string;
  completedAt: string | null;
  reviewedAt: string | null;
  reviewedByName: string | null;
  reviewNotes: string | null;
  requiresTherapistReview: boolean;
  topScores: TopScoreRow[];
};

export type PatientReportContext = {
  patientId: string;
  clinicId: string;
  clinicName: string;
  patientName: string;
  patientEmail: string | null;
  patientPhone: string | null;
  birthDate: string | null;
  psychologistName: string | null;
  generatedAt: string;
};

export type MentalMapSummary = {
  intakeSummary: string | null;
  currentLifeContext: string | null;
  therapyDemands: string | null;
  centralHypotheses: string[];
  currentFocuses: string[];
  suggestedResources: Array<{
    title: string;
    reasons: string[];
  }>;
  pendingQuestionnaireReviewCount: number;
  reviewedQuestionnaireCount: number;
  activeProblemCount: number;
  activeGoalCount: number;
  latestCheckInAt: string | null;
  latestCheckInMood: number | null;
  latestMonitorAt: string | null;
  genogramPeopleCount: number;
  genogramRelationshipCount: number;
  recentTimelineTitles: string[];
};

export type ReportData = {
  context: PatientReportContext;
  questionnaires: QuestionnaireReportBlock[];
  mentalMap: MentalMapSummary | null;
  goals: Array<{ title: string; status: string; description: string | null }>;
  problems: Array<{ title: string; status: string; intensity: number | null }>;
  checkIns: Array<{
    checkedInAt: string;
    mood: number | null;
    anxiety: number | null;
    energy: number | null;
    notes: string | null;
  }>;
  dailyMonitors: Array<{
    createdAt: string;
    moodNotes: string | null;
    sleepNotes: string | null;
    activityNotes: string | null;
  }>;
  timelineEvents: Array<{
    title: string;
    eventDate: string | null;
    periodLabel: string | null;
    category: string | null;
  }>;
  genogramPeople: Array<{ displayName: string; gender: string | null; birthYear: number | null }>;
  genogramRelationships: Array<{
    personA: string;
    personB: string;
    type: string;
  }>;
};
