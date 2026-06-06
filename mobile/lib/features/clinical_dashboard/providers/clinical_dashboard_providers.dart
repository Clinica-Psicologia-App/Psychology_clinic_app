import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile_role.dart';
import '../data/clinical_dashboard_repository.dart';
import '../domain/clinical_dashboard_data.dart';

final clinicalDashboardRepositoryProvider =
    Provider<ClinicalDashboardRepository>((ref) {
  return ClinicalDashboardRepository();
});

final myClinicalDashboardProvider =
    AsyncNotifierProvider<MyClinicalDashboardNotifier, ClinicalDashboardData>(
  MyClinicalDashboardNotifier.new,
);

class MyClinicalDashboardNotifier extends AsyncNotifier<ClinicalDashboardData> {
  @override
  Future<ClinicalDashboardData> build() async {
    return ref.read(clinicalDashboardRepositoryProvider).loadMyDashboard();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(clinicalDashboardRepositoryProvider).loadMyDashboard(),
    );
  }
}

class StaffClinicalDashboardContext {
  const StaffClinicalDashboardContext({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffClinicalDashboardContext &&
          role == other.role &&
          patientId == other.patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

final staffClinicalDashboardProvider =
    FutureProvider.family<ClinicalDashboardData, StaffClinicalDashboardContext>(
  (ref, ctx) {
    return ref
        .read(clinicalDashboardRepositoryProvider)
        .loadForPatient(ctx.patientId);
  },
);
