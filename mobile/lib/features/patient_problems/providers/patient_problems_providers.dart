import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile_role.dart';
import '../data/patient_problems_repository.dart';
import '../domain/patient_problem.dart';

final patientProblemsRepositoryProvider =
    Provider<PatientProblemsRepository>((ref) {
  return PatientProblemsRepository();
});

final myPatientProblemsProvider =
    AsyncNotifierProvider<MyPatientProblemsNotifier, List<PatientProblem>>(
  MyPatientProblemsNotifier.new,
);

class MyPatientProblemsNotifier extends AsyncNotifier<List<PatientProblem>> {
  @override
  Future<List<PatientProblem>> build() async {
    return ref.read(patientProblemsRepositoryProvider).listMyProblems();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(patientProblemsRepositoryProvider).listMyProblems(),
    );
  }
}

class StaffPatientProblemsContext {
  const StaffPatientProblemsContext({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffPatientProblemsContext &&
          role == other.role &&
          patientId == other.patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

final staffPatientProblemsProvider =
    FutureProvider.family<List<PatientProblem>, StaffPatientProblemsContext>(
  (ref, ctx) {
    return ref
        .read(patientProblemsRepositoryProvider)
        .listForPatient(ctx.patientId);
  },
);

final patientProblemDetailProvider =
    FutureProvider.family<PatientProblem?, String>((ref, id) {
  return ref.read(patientProblemsRepositoryProvider).getById(id);
});
