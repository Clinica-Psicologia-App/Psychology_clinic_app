import '../../patient_check_ins/domain/patient_check_in.dart';
import '../../patient_problems/domain/patient_problem.dart';
import '../../results/domain/patient_response_summary.dart';
import '../../therapy_goals/domain/therapy_goal.dart';
import '../../patient_timeline/domain/patient_timeline_event.dart';
import 'clinical_case_summary.dart';
import 'clinical_dashboard_score_row.dart';
import 'clinical_instrument_dashboard.dart';

const _defaultCaseListLimit = 3;
const _defaultEventLimit = 3;

ClinicalCaseSummary buildClinicalCaseSummary({
  required String patientName,
  required List<PatientResponseSummary> responses,
  required ClinicalInstrumentDashboard? ysq,
  required ClinicalInstrumentDashboard? yami,
  ClinicalInstrumentDashboard? attachment,
  ClinicalInstrumentDashboard? yci,
  ClinicalInstrumentDashboard? yrai,
  required List<PatientProblem> problems,
  required List<TherapyGoal> goals,
  required List<PatientCheckIn> checkIns,
  required List<PatientTimelineEvent> events,
}) {
  final structuredResultCount = responses.where((r) => r.hasResults).length;

  final latestQuestionnaireAt = _latestQuestionnaireAt(responses);
  final latestCheckIn = checkIns.isEmpty ? null : checkIns.first;

  final openProblems = problems.where((problem) => problem.isOpen).toList()
    ..sort((a, b) {
      final intensityA = a.intensity ?? -1;
      final intensityB = b.intensity ?? -1;
      final byIntensity = intensityB.compareTo(intensityA);
      if (byIntensity != 0) return byIntensity;
      return b.updatedAt.compareTo(a.updatedAt);
    });

  final activeGoals = goals.where((goal) => goal.isActive).toList()
    ..sort((a, b) {
      final aDate = a.targetDate;
      final bDate = b.targetDate;
      if (aDate != null && bDate != null) return aDate.compareTo(bDate);
      if (aDate != null) return -1;
      if (bDate != null) return 1;
      return b.updatedAt.compareTo(a.updatedAt);
    });

  final rankedEvents = [...events]..sort((a, b) {
      final impactA = a.emotionalImpact ?? -1;
      final impactB = b.emotionalImpact ?? -1;
      final byImpact = impactB.compareTo(impactA);
      if (byImpact != 0) return byImpact;

      final aDate = a.eventDate ?? a.createdAt;
      final bDate = b.eventDate ?? b.createdAt;
      return bDate.compareTo(aDate);
    });

  return ClinicalCaseSummary(
    patientName: patientName,
    structuredResultCount: structuredResultCount,
    latestQuestionnaireAt: latestQuestionnaireAt,
    latestClinicalUpdateAt: _latestClinicalUpdateAt(
      latestQuestionnaireAt: latestQuestionnaireAt,
      latestCheckIn: latestCheckIn,
      openProblems: openProblems,
      activeGoals: activeGoals,
      rankedEvents: rankedEvents,
    ),
    latestCheckIn: latestCheckIn,
    openProblemsCount: openProblems.length,
    activeGoalsCount: activeGoals.length,
    relevantEventsCount: rankedEvents.length,
    topSchemas: ysq?.topScores.take(_defaultCaseListLimit).toList() ?? const [],
    topModes: yami?.topScores.take(_defaultCaseListLimit).toList() ?? const [],
    topAttachment:
        attachment?.topScores.take(_defaultCaseListLimit).toList() ?? const [],
    topCoping:
        _topCopingScores(yci: yci, yrai: yrai, limit: _defaultCaseListLimit),
    highlightedProblems:
        openProblems.take(_defaultCaseListLimit).toList(growable: false),
    highlightedGoals:
        activeGoals.take(_defaultCaseListLimit).toList(growable: false),
    relevantEvents:
        rankedEvents.take(_defaultEventLimit).toList(growable: false),
  );
}

List<ClinicalDashboardScoreRow> _topCopingScores({
  ClinicalInstrumentDashboard? yci,
  ClinicalInstrumentDashboard? yrai,
  required int limit,
}) {
  final merged = <ClinicalDashboardScoreRow>[
    ...?yci?.topScores,
    ...?yrai?.topScores,
  ]..sort((a, b) => b.score.compareTo(a.score));
  return merged.take(limit).toList(growable: false);
}

DateTime? _latestQuestionnaireAt(List<PatientResponseSummary> responses) {
  DateTime? latest;
  for (final response in responses) {
    final candidate = response.completedAt ?? response.startedAt;
    if (candidate == null) continue;
    if (latest == null || candidate.isAfter(latest)) {
      latest = candidate;
    }
  }
  return latest;
}

DateTime? _latestClinicalUpdateAt({
  required DateTime? latestQuestionnaireAt,
  required PatientCheckIn? latestCheckIn,
  required List<PatientProblem> openProblems,
  required List<TherapyGoal> activeGoals,
  required List<PatientTimelineEvent> rankedEvents,
}) {
  DateTime? latest = latestQuestionnaireAt;

  void consider(DateTime? candidate) {
    if (candidate == null) return;
    final current = latest;
    if (current == null || candidate.isAfter(current)) {
      latest = candidate;
    }
  }

  consider(latestCheckIn?.checkedInAt);
  consider(latestCheckIn?.updatedAt);

  for (final problem in openProblems) {
    consider(problem.updatedAt);
  }
  for (final goal in activeGoals) {
    consider(goal.updatedAt);
  }
  for (final event in rankedEvents) {
    consider(event.eventDate ?? event.updatedAt);
  }

  return latest;
}
