import 'mental_case_map.dart';
import 'mental_map_aggregator.dart';
import 'mental_map_case_summary.dart';
import 'mental_map_check_in_summary.dart';
import 'mental_map_clinical_core.dart';
import 'mental_map_genogram_summary.dart';
import 'mental_map_goal_summary.dart';
import 'mental_map_history_links.dart';
import 'mental_map_monitor_summary.dart';
import 'mental_map_problem_summary.dart';
import 'mental_map_questionnaire_block.dart';
import 'mental_map_therapy_plan.dart';
import 'mental_map_timeline_summary.dart';
import 'mental_map_validation_summary.dart';

class MentalMapData {
  const MentalMapData({
    required this.patientName,
    required this.caseMap,
    required this.caseSummary,
    required this.validationSummary,
    required this.clinicalCore,
    required this.historyLinks,
    required this.therapyPlan,
    required this.questionnaires,
    required this.activeProblems,
    required this.activeGoals,
    this.recentCheckIn,
    required this.recentMonitors,
    required this.recentTimelineEvents,
    required this.genogram,
  });

  static const empty = MentalMapData(
    patientName: 'Paciente',
    caseMap: MentalCaseMap.empty,
    caseSummary: MentalMapCaseSummary.empty,
    validationSummary: MentalMapValidationSummary.empty,
    clinicalCore: MentalMapClinicalCore.empty,
    historyLinks: MentalMapHistoryLinks.empty,
    therapyPlan: MentalMapTherapyPlan.empty,
    questionnaires: [],
    activeProblems: [],
    activeGoals: [],
    recentMonitors: [],
    recentTimelineEvents: [],
    genogram: MentalMapGenogramSummary.empty,
  );

  final String patientName;
  final MentalCaseMap caseMap;
  final MentalMapCaseSummary caseSummary;
  final MentalMapValidationSummary validationSummary;
  final MentalMapClinicalCore clinicalCore;
  final MentalMapHistoryLinks historyLinks;
  final MentalMapTherapyPlan therapyPlan;
  final List<MentalMapQuestionnaireBlock> questionnaires;
  final List<MentalMapProblemSummary> activeProblems;
  final List<MentalMapGoalSummary> activeGoals;
  final MentalMapCheckInSummary? recentCheckIn;
  final List<MentalMapMonitorSummary> recentMonitors;
  final List<MentalMapTimelineSummary> recentTimelineEvents;
  final MentalMapGenogramSummary genogram;

  bool get hasRelevantData => mentalMapHasRelevantData(this);
}
