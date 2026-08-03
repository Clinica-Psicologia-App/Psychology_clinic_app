import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../patients/providers/patients_providers.dart';
import '../data/patient_journey_repository.dart';
import '../domain/journey_step.dart';
import '../domain/patient_journey_progress.dart';

final patientJourneyRepositoryProvider =
    Provider<PatientJourneyRepository>((ref) {
  return PatientJourneyRepository();
});

final patientJourneyPatientIdProvider = FutureProvider<String>((ref) async {
  return ref
      .read(patientJourneyRepositoryProvider)
      .getPatientIdForCurrentProfile();
});

final patientJourneyProgressProvider =
    FutureProvider<PatientJourneyProgress>((ref) async {
  final patientId = await ref.watch(patientJourneyPatientIdProvider.future);
  return ref.read(patientJourneyRepositoryProvider).loadProgress(patientId);
});

final patientJourneyStepsProvider =
    FutureProvider<List<JourneyStep>>((ref) async {
  final progress = await ref.watch(patientJourneyProgressProvider.future);
  final myPatient = await ref.watch(myPatientProvider.future);
  return buildPatientJourneySteps(
    progress,
    // Sem registro/liberação → bloqueado (não expõe resultados antes da hora).
    resultsReleased: myPatient?.resultsReleased ?? false,
  );
});
