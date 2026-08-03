import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/patients_repository.dart';
import '../domain/create_patient_request.dart';
import '../domain/patient.dart';
import '../domain/psychologist_option.dart';
import '../domain/update_patient_request.dart';

final patientsRepositoryProvider = Provider<PatientsRepository>((ref) {
  return PatientsRepository();
});

final patientsListProvider =
    AsyncNotifierProvider<PatientsListNotifier, List<Patient>>(
  PatientsListNotifier.new,
);

class PatientsListNotifier extends AsyncNotifier<List<Patient>> {
  @override
  Future<List<Patient>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<Patient>> _load() {
    return ref.read(patientsRepositoryProvider).listPatients();
  }
}

final patientDetailProvider =
    FutureProvider.family<Patient?, String>((ref, patientId) {
  return ref.read(patientsRepositoryProvider).getPatientById(patientId);
});

final psychologistsOptionsProvider =
    FutureProvider<List<PsychologistOption>>((ref) {
  return ref.read(patientsRepositoryProvider).listPsychologistsInClinic();
});

/// Registro do próprio paciente logado (para gatear seus módulos por liberação).
final myPatientProvider = FutureProvider<Patient?>((ref) {
  return ref.read(patientsRepositoryProvider).getMyPatient();
});

/// Libera/revoga o acesso do paciente aos resultados clínicos (psicólogo).
final releaseResultsProvider =
    AsyncNotifierProvider<ReleaseResultsNotifier, void>(
  ReleaseResultsNotifier.new,
);

class ReleaseResultsNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Patient> submit({
    required String patientId,
    required bool released,
  }) async {
    state = const AsyncValue.loading();
    try {
      final patient = await ref
          .read(patientsRepositoryProvider)
          .setResultsReleased(patientId: patientId, released: released);
      state = const AsyncValue.data(null);
      ref.invalidate(patientDetailProvider(patientId));
      ref.invalidate(patientsListProvider);
      return patient;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final createPatientProvider =
    AsyncNotifierProvider<CreatePatientNotifier, void>(
  CreatePatientNotifier.new,
);

class CreatePatientNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Patient> submit(CreatePatientRequest request) async {
    state = const AsyncValue.loading();
    try {
      final patient =
          await ref.read(patientsRepositoryProvider).createPatient(request);
      state = const AsyncValue.data(null);
      ref.invalidate(patientsListProvider);
      return patient;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final updatePatientProvider =
    AsyncNotifierProvider<UpdatePatientNotifier, void>(
  UpdatePatientNotifier.new,
);

class UpdatePatientNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Patient> submit(UpdatePatientRequest request) async {
    state = const AsyncValue.loading();
    try {
      final patient =
          await ref.read(patientsRepositoryProvider).updatePatient(request);
      state = const AsyncValue.data(null);
      ref.invalidate(patientDetailProvider(request.patientId));
      ref.invalidate(patientsListProvider);
      return patient;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
