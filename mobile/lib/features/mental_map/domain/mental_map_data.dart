import 'mental_map_aggregator.dart';
import 'mental_map_case_summary.dart';
import 'mental_map_check_in_summary.dart';
import 'mental_map_genogram_summary.dart';
import 'mental_map_goal_summary.dart';
import 'mental_map_monitor_summary.dart';
import 'mental_map_problem_summary.dart';
import 'mental_map_questionnaire_block.dart';
import 'mental_map_timeline_summary.dart';
import 'mental_map_validation_summary.dart';

class MentalMapData {
  const MentalMapData({
    required this.patientName,
    required this.caseSummary,
    required this.validationSummary,
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
    caseSummary: MentalMapCaseSummary.empty,
    validationSummary: MentalMapValidationSummary.empty,
    questionnaires: [],
    activeProblems: [],
    activeGoals: [],
    recentMonitors: [],
    recentTimelineEvents: [],
    genogram: MentalMapGenogramSummary.empty,
  );

  final String patientName;
  final MentalMapCaseSummary caseSummary;
  final MentalMapValidationSummary validationSummary;
  final List<MentalMapQuestionnaireBlock> questionnaires;
  final List<MentalMapProblemSummary> activeProblems;
  final List<MentalMapGoalSummary> activeGoals;
  final MentalMapCheckInSummary? recentCheckIn;
  final List<MentalMapMonitorSummary> recentMonitors;
  final List<MentalMapTimelineSummary> recentTimelineEvents;
  final MentalMapGenogramSummary genogram;

  bool get hasRelevantData => mentalMapHasRelevantData(this);
}
