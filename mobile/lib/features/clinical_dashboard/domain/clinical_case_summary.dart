import '../../patient_check_ins/domain/patient_check_in.dart';
import '../../patient_problems/domain/patient_problem.dart';
import '../../therapy_goals/domain/therapy_goal.dart';
import '../../patient_timeline/domain/patient_timeline_event.dart';
import 'clinical_dashboard_score_row.dart';

class ClinicalCaseSummary {
  const ClinicalCaseSummary({
    required this.patientName,
    required this.structuredResultCount,
    this.latestQuestionnaireAt,
    this.latestClinicalUpdateAt,
    this.latestCheckIn,
    required this.openProblemsCount,
    required this.activeGoalsCount,
    required this.relevantEventsCount,
    required this.topSchemas,
    required this.topModes,
    required this.topAttachment,
    required this.topCoping,
    required this.highlightedProblems,
    required this.highlightedGoals,
    required this.relevantEvents,
  });

  static const empty = ClinicalCaseSummary(
    patientName: 'Paciente',
    structuredResultCount: 0,
    openProblemsCount: 0,
    activeGoalsCount: 0,
    relevantEventsCount: 0,
    topSchemas: [],
    topModes: [],
    topAttachment: [],
    topCoping: [],
    highlightedProblems: [],
    highlightedGoals: [],
    relevantEvents: [],
  );

  final String patientName;
  final int structuredResultCount;
  final DateTime? latestQuestionnaireAt;
  final DateTime? latestClinicalUpdateAt;
  final PatientCheckIn? latestCheckIn;
  final int openProblemsCount;
  final int activeGoalsCount;
  final int relevantEventsCount;
  final List<ClinicalDashboardScoreRow> topSchemas;
  final List<ClinicalDashboardScoreRow> topModes;
  final List<ClinicalDashboardScoreRow> topAttachment;
  final List<ClinicalDashboardScoreRow> topCoping;
  final List<PatientProblem> highlightedProblems;
  final List<TherapyGoal> highlightedGoals;
  final List<PatientTimelineEvent> relevantEvents;

  bool get hasSummary =>
      structuredResultCount > 0 ||
      latestQuestionnaireAt != null ||
      latestCheckIn != null ||
      openProblemsCount > 0 ||
      activeGoalsCount > 0 ||
      relevantEventsCount > 0;

  bool get hasTopSchemas => topSchemas.isNotEmpty;

  bool get hasTopModes => topModes.isNotEmpty;

  bool get hasTopAttachment => topAttachment.isNotEmpty;

  bool get hasTopCoping => topCoping.isNotEmpty;

  bool get hasProblemsAndGoals =>
      highlightedProblems.isNotEmpty || highlightedGoals.isNotEmpty;

  bool get hasRelevantEvents => relevantEvents.isNotEmpty;

  bool get isEmpty =>
      !hasSummary &&
      !hasTopSchemas &&
      !hasTopModes &&
      !hasTopAttachment &&
      !hasTopCoping &&
      !hasProblemsAndGoals &&
      !hasRelevantEvents;
}
