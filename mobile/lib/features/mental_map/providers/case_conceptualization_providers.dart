import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/case_conceptualization_repository.dart';
import '../domain/case_conceptualization.dart';

final caseConceptualizationRepositoryProvider =
    Provider<CaseConceptualizationRepository>((ref) {
  return CaseConceptualizationRepository();
});

/// Documento da Conceitualização de caso (campos do terapeuta) por paciente.
final caseConceptualizationProvider =
    FutureProvider.family<CaseConceptualization, String>((ref, patientId) {
  return ref.read(caseConceptualizationRepositoryProvider).load(patientId);
});
