import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile_role.dart';
import '../data/therapy_goals_repository.dart';
import '../domain/therapy_goal.dart';

final therapyGoalsRepositoryProvider =
    Provider<TherapyGoalsRepository>((ref) => TherapyGoalsRepository());

final myTherapyGoalsProvider =
    AsyncNotifierProvider<MyTherapyGoalsNotifier, List<TherapyGoal>>(
  MyTherapyGoalsNotifier.new,
);

class MyTherapyGoalsNotifier extends AsyncNotifier<List<TherapyGoal>> {
  @override
  Future<List<TherapyGoal>> build() async {
    return ref.read(therapyGoalsRepositoryProvider).listMyGoals();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(therapyGoalsRepositoryProvider).listMyGoals(),
    );
  }
}

class StaffTherapyGoalsContext {
  const StaffTherapyGoalsContext({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffTherapyGoalsContext &&
          role == other.role &&
          patientId == other.patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

final staffPatientTherapyGoalsProvider =
    FutureProvider.family<List<TherapyGoal>, StaffTherapyGoalsContext>(
  (ref, ctx) {
    return ref
        .read(therapyGoalsRepositoryProvider)
        .listForPatient(ctx.patientId);
  },
);

final therapyGoalDetailProvider =
    FutureProvider.family<TherapyGoal?, String>((ref, id) {
  return ref.read(therapyGoalsRepositoryProvider).getById(id);
});
