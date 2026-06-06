import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile_role.dart';
import '../data/patient_timeline_repository.dart';
import '../domain/patient_timeline_event.dart';

final patientTimelineRepositoryProvider =
    Provider<PatientTimelineRepository>((ref) {
  return PatientTimelineRepository();
});

final myPatientTimelineProvider =
    AsyncNotifierProvider<MyPatientTimelineNotifier, List<PatientTimelineEvent>>(
  MyPatientTimelineNotifier.new,
);

class MyPatientTimelineNotifier extends AsyncNotifier<List<PatientTimelineEvent>> {
  @override
  Future<List<PatientTimelineEvent>> build() async {
    return ref.read(patientTimelineRepositoryProvider).listMyEvents();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(patientTimelineRepositoryProvider).listMyEvents(),
    );
  }
}

class StaffPatientTimelineContext {
  const StaffPatientTimelineContext({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffPatientTimelineContext &&
          role == other.role &&
          patientId == other.patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

final staffPatientTimelineProvider =
    FutureProvider.family<List<PatientTimelineEvent>, StaffPatientTimelineContext>(
  (ref, ctx) {
    return ref
        .read(patientTimelineRepositoryProvider)
        .listForPatient(ctx.patientId);
  },
);

final patientTimelineEventDetailProvider =
    FutureProvider.family<PatientTimelineEvent?, String>((ref, id) {
  return ref.read(patientTimelineRepositoryProvider).getById(id);
});
