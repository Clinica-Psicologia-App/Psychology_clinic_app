import 'mental_map_check_in_summary.dart';
import 'mental_map_goal_summary.dart';
import 'mental_map_problem_summary.dart';

/// Série temporal simples para sparkline de check-in (M4).
class MentalMapCheckInSparkline {
  const MentalMapCheckInSparkline({
    required this.moodPoints,
    required this.anxietyPoints,
    required this.energyPoints,
    required this.showChart,
  });

  static const empty = MentalMapCheckInSparkline(
    moodPoints: [],
    anxietyPoints: [],
    energyPoints: [],
    showChart: false,
  );

  final List<double?> moodPoints;
  final List<double?> anxietyPoints;
  final List<double?> energyPoints;
  final bool showChart;
}

/// Resumo de recursos terapêuticos liberados/concluídos (M4).
class MentalMapResourcesSummary {
  const MentalMapResourcesSummary({
    required this.releasedCount,
    required this.completedCount,
    required this.viewedCount,
  });

  static const empty = MentalMapResourcesSummary(
    releasedCount: 0,
    completedCount: 0,
    viewedCount: 0,
  );

  final int releasedCount;
  final int completedCount;
  final int viewedCount;

  bool get hasContent => releasedCount > 0;
}

/// Camada M4 - plano terapêutico.
class MentalMapTherapyPlan {
  const MentalMapTherapyPlan({
    required this.activeGoals,
    required this.activeProblems,
    required this.recentCheckIns,
    required this.sparkline,
    required this.resources,
    this.latestCheckIn,
  });

  static const empty = MentalMapTherapyPlan(
    activeGoals: [],
    activeProblems: [],
    recentCheckIns: [],
    sparkline: MentalMapCheckInSparkline.empty,
    resources: MentalMapResourcesSummary.empty,
  );

  final List<MentalMapGoalSummary> activeGoals;
  final List<MentalMapProblemSummary> activeProblems;
  final List<MentalMapCheckInSummary> recentCheckIns;
  final MentalMapCheckInSparkline sparkline;
  final MentalMapResourcesSummary resources;
  final MentalMapCheckInSummary? latestCheckIn;

  bool get hasGoals => activeGoals.isNotEmpty;

  bool get hasProblems => activeProblems.isNotEmpty;

  bool get hasCheckIns => recentCheckIns.isNotEmpty;

  bool get hasContent =>
      hasGoals || hasProblems || hasCheckIns || resources.hasContent;
}
