import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile_role.dart';
import '../data/patient_check_ins_repository.dart';
import '../domain/patient_check_in.dart';

final patientCheckInsRepositoryProvider =
    Provider<PatientCheckInsRepository>((ref) {
  return PatientCheckInsRepository();
});

final myPatientCheckInsProvider =
    AsyncNotifierProvider<MyPatientCheckInsNotifier, List<PatientCheckIn>>(
  MyPatientCheckInsNotifier.new,
);

class MyPatientCheckInsNotifier extends AsyncNotifier<List<PatientCheckIn>> {
  @override
  Future<List<PatientCheckIn>> build() async {
    return ref.read(patientCheckInsRepositoryProvider).listMyCheckIns();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(patientCheckInsRepositoryProvider).listMyCheckIns(),
    );
  }
}

final todayCheckInProvider = FutureProvider<PatientCheckIn?>((ref) async {
  ref.watch(myPatientCheckInsProvider);
  return ref.read(patientCheckInsRepositoryProvider).findTodayForCurrentPatient();
});

class StaffCheckInsContext {
  const StaffCheckInsContext({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffCheckInsContext &&
          role == other.role &&
          patientId == other.patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

final staffPatientCheckInsProvider =
    FutureProvider.family<List<PatientCheckIn>, StaffCheckInsContext>(
  (ref, ctx) {
    return ref
        .read(patientCheckInsRepositoryProvider)
        .listForPatient(ctx.patientId);
  },
);

final patientCheckInDetailProvider =
    FutureProvider.family<PatientCheckIn?, String>((ref, id) {
  return ref.read(patientCheckInsRepositoryProvider).getById(id);
});
