import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/personality_assessment_repository.dart';
import '../domain/personality_assessment.dart';

final personalityAssessmentRepositoryProvider =
    Provider<PersonalityAssessmentRepository>(
  (ref) => PersonalityAssessmentRepository(),
);

/// Lista de avaliações registradas de um paciente. `autoDispose` para
/// re-buscar sempre que a tela é reaberta (evita lista defasada após salvar).
final personalityAssessmentsProvider = FutureProvider.autoDispose
    .family<List<PersonalityAssessment>, String>((ref, patientId) {
  return ref
      .read(personalityAssessmentRepositoryProvider)
      .listForPatient(patientId);
});

/// Uma avaliação por id (para dashboard/edição).
final personalityAssessmentByIdProvider = FutureProvider.autoDispose
    .family<PersonalityAssessment?, String>((ref, id) {
  return ref.read(personalityAssessmentRepositoryProvider).getById(id);
});

/// Perfis compartilhados com o paciente logado (view isolada).
final patientSharedPersonalityProvider =
    FutureProvider.autoDispose<List<PersonalityAssessment>>((ref) {
  return ref
      .read(personalityAssessmentRepositoryProvider)
      .listSharedForCurrentPatient();
});

/// Avaliações do paciente que o terapeuta marcou como relevantes para a
/// conceitualização (integração preenchida) — usado para cruzar na Síntese.
final personalityIntegrationsProvider = FutureProvider.autoDispose
    .family<List<PersonalityAssessment>, String>((ref, patientId) async {
  final all = await ref
      .read(personalityAssessmentRepositoryProvider)
      .listForPatient(patientId);
  return [for (final a in all) if (a.hasIntegration) a];
});
