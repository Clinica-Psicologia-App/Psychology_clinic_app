import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/clinics_repository.dart';
import '../domain/clinic_summary.dart';

final clinicsRepositoryProvider = Provider<ClinicsRepository>((ref) {
  return ClinicsRepository();
});

final clinicsProvider =
    AsyncNotifierProvider<ClinicsNotifier, List<ClinicSummary>>(
  ClinicsNotifier.new,
);

class ClinicsNotifier extends AsyncNotifier<List<ClinicSummary>> {
  @override
  Future<List<ClinicSummary>> build() {
    return ref.read(clinicsRepositoryProvider).listClinics();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(clinicsRepositoryProvider).listClinics(),
    );
  }

  Future<void> setActive({
    required String clinicId,
    required bool isActive,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(clinicsRepositoryProvider).setClinicActive(
            clinicId: clinicId,
            isActive: isActive,
          );
      return ref.read(clinicsRepositoryProvider).listClinics();
    });
  }

  Future<void> createClinic({
    required String name,
    required String clinicType,
    String? document,
    String? email,
    String? phone,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(clinicsRepositoryProvider).createClinic(
            name: name,
            clinicType: clinicType,
            document: document,
            email: email,
            phone: phone,
          );
      return ref.read(clinicsRepositoryProvider).listClinics();
    });
  }

  Future<void> deleteClinic({
    required String clinicId,
    required String confirmationName,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(clinicsRepositoryProvider).deleteClinic(
            clinicId: clinicId,
            confirmationName: confirmationName,
          );
      return ref.read(clinicsRepositoryProvider).listClinics();
    });
  }
}
