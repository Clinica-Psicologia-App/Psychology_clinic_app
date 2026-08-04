import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/patient_library_repository.dart';
import '../domain/library_content.dart';
import '../domain/library_content_builder.dart';
import '../domain/library_indication.dart';

final patientLibraryRepositoryProvider =
    Provider<PatientLibraryRepository>((ref) {
  return PatientLibraryRepository();
});

/// Indicações do paciente logado.
final myLibraryIndicationsProvider =
    FutureProvider<List<LibraryIndication>>((ref) {
  return ref.read(patientLibraryRepositoryProvider).getMyLibrary();
});

/// Conteúdo da tela (hero + prateleiras). Null quando não há indicações.
final myLibraryContentProvider = FutureProvider<LibraryContent?>((ref) async {
  final indications = await ref.watch(myLibraryIndicationsProvider.future);
  return buildLibraryContent(indications);
});
