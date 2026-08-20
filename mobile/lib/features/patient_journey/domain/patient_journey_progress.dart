/// Indicadores leves para status dos passos da trilha (somente leitura).
class PatientJourneyProgress {
  const PatientJourneyProgress({
    required this.activeQuestionnaireCount,
    required this.completedQuestionnaireCount,
    required this.hasMonitorToday,
    required this.releasedResourceCount,
    required this.completedResourceCount,
    required this.activeTherapyGoalCount,
    required this.completedTherapyGoalCount,
    required this.totalProblemCount,
    required this.openProblemCount,
    required this.hasCheckInToday,
    required this.timelineEventCount,
    required this.genogramPeopleCount,
    required this.genogramRelationshipCount,
    required this.checkInCount,
    required this.dailyMonitorCount,
    required this.hasYsqStructuredResult,
    required this.hasYamiStructuredResult,
    this.initialAssessmentFraction = 0.0,
  });

  final int activeQuestionnaireCount;
  final int completedQuestionnaireCount;
  final bool hasMonitorToday;
  final int releasedResourceCount;
  final int completedResourceCount;
  final int activeTherapyGoalCount;
  final int completedTherapyGoalCount;
  final int totalProblemCount;
  final int openProblemCount;
  final bool hasCheckInToday;
  final int timelineEventCount;
  final int genogramPeopleCount;
  final int genogramRelationshipCount;
  final int checkInCount;
  final int dailyMonitorCount;
  final bool hasYsqStructuredResult;
  final bool hasYamiStructuredResult;

  /// Fração [0.0, 1.0] de campos preenchidos em "Conhecendo você" (Blocos
  /// 1–3 da avaliação inicial). Ver [InitialAssessment.completionFraction].
  final double initialAssessmentFraction;

  bool get hasClinicalDashboardData =>
      hasYsqStructuredResult || hasYamiStructuredResult;

  bool get hasMentalMapRelevantData =>
      completedQuestionnaireCount > 0 ||
      openProblemCount > 0 ||
      activeTherapyGoalCount > 0 ||
      checkInCount > 0 ||
      dailyMonitorCount > 0 ||
      timelineEventCount > 0 ||
      genogramPeopleCount > 0 ||
      genogramRelationshipCount > 0;

  bool get hasGenogramContent =>
      genogramPeopleCount > 0 || genogramRelationshipCount > 0;

  bool get allActiveQuestionnairesCompleted =>
      activeQuestionnaireCount > 0 &&
      completedQuestionnaireCount >= activeQuestionnaireCount;
}
