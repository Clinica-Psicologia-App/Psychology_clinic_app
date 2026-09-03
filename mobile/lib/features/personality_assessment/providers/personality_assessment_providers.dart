import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/personality_assessment_repository.dart';
import '../domain/personality_assessment.dart';

final personalityAssessmentRepositoryProvider =
    Provider<PersonalityAssessmentRepository>(
  (ref) => PersonalityAssessmentRepository(),
);

/// Lista de avaliações registradas de um paciente.
final personalityAssessmentsProvider = FutureProvider.family<
    List<PersonalityAssessment>, String>((ref, patientId) {
  return ref
      .read(personalityAssessmentRepositoryProvider)
      .listForPatient(patientId);
});

/// Uma avaliação por id (para dashboard/edição).
final personalityAssessmentByIdProvider =
    FutureProvider.family<PersonalityAssessment?, String>((ref, id) {
  return ref.read(personalityAssessmentRepositoryProvider).getById(id);
});

/// Perfis compartilhados com o paciente logado (view isolada).
final patientSharedPersonalityProvider =
    FutureProvider<List<PersonalityAssessment>>((ref) {
  return ref
      .read(personalityAssessmentRepositoryProvider)
      .listSharedForCurrentPatient();
});
