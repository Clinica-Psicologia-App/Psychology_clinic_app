import '../../therapy_resources/domain/patient_resource_access.dart';
import '../../therapy_resources/domain/resource_access_status.dart';
import 'mental_map_check_in_summary.dart';
import 'mental_map_goal_summary.dart';
import 'mental_map_problem_summary.dart';
import 'mental_map_therapy_plan.dart';

const _checkInLimit = 7;
const _minSparklineCheckIns = 2;

MentalMapTherapyPlan buildMentalMapTherapyPlan({
  required List<MentalMapGoalSummary> activeGoals,
  required List<MentalMapProblemSummary> activeProblems,
  required List<MentalMapCheckInSummary> checkIns,
  required List<PatientResourceAccess> resourceAccess,
}) {
  final recentCheckIns = checkIns.take(_checkInLimit).toList(growable: false);

  return MentalMapTherapyPlan(
    activeGoals: activeGoals,
    activeProblems: activeProblems,
    recentCheckIns: recentCheckIns,
    sparkline: buildCheckInSparkline(recentCheckIns),
    resources: buildResourcesSummary(resourceAccess),
    latestCheckIn: recentCheckIns.isEmpty ? null : recentCheckIns.first,
  );
}

MentalMapCheckInSparkline buildCheckInSparkline(
  List<MentalMapCheckInSummary> checkIns,
) {
  if (checkIns.length < _minSparklineCheckIns) {
    return const MentalMapCheckInSparkline(
      moodPoints: [],
      anxietyPoints: [],
      energyPoints: [],
      showChart: false,
    );
  }

  final chronological = checkIns.reversed.toList(growable: false);

  return MentalMapCheckInSparkline(
    moodPoints: chronological.map((c) => c.moodScore?.toDouble()).toList(),
    anxietyPoints:
        chronological.map((c) => c.anxietyScore?.toDouble()).toList(),
    energyPoints:
        chronological.map((c) => c.energyScore?.toDouble()).toList(),
    showChart: true,
  );
}

MentalMapResourcesSummary buildResourcesSummary(
  List<PatientResourceAccess> resourceAccess,
) {
  if (resourceAccess.isEmpty) {
    return MentalMapResourcesSummary.empty;
  }

  var released = 0;
  var viewed = 0;
  var completed = 0;

  for (final access in resourceAccess) {
    if (!access.isActive) continue;
    released++;
    switch (access.progressStatus) {
      case ResourceAccessStatus.completed:
        completed++;
      case ResourceAccessStatus.viewed:
        viewed++;
      case ResourceAccessStatus.released:
        break;
    }
  }

  return MentalMapResourcesSummary(
    releasedCount: released,
    completedCount: completed,
    viewedCount: viewed,
  );
}
