import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/staff_library_repository.dart';
import '../domain/library_work_full.dart';

final staffLibraryRepositoryProvider = Provider<StaffLibraryRepository>((ref) {
  return StaffLibraryRepository();
});

/// Esquemas do catálogo (para os chips de filtro).
final librarySchemasProvider = FutureProvider<List<String>>((ref) {
  return ref.read(staffLibraryRepositoryProvider).listSchemas();
});

class LibraryCatalogFilter {
  const LibraryCatalogFilter({this.schema, this.query});

  final String? schema;
  final String? query;

  @override
  bool operator ==(Object other) =>
      other is LibraryCatalogFilter &&
      other.schema == schema &&
      other.query == query;

  @override
  int get hashCode => Object.hash(schema, query);
}

final libraryCatalogProvider =
    FutureProvider.family<List<LibraryWorkFull>, LibraryCatalogFilter>(
        (ref, filter) {
  return ref
      .read(staffLibraryRepositoryProvider)
      .listWorks(schema: filter.schema, query: filter.query);
});

final libraryWorkProvider =
    FutureProvider.family<LibraryWorkFull?, String>((ref, id) {
  return ref.read(staffLibraryRepositoryProvider).getWork(id);
});

/// Ação de indicar uma obra ao paciente.
final indicateWorkProvider =
    AsyncNotifierProvider<IndicateWorkNotifier, void>(IndicateWorkNotifier.new);

class IndicateWorkNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required String patientId,
    required String workId,
    String? objective,
    String? scope,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(staffLibraryRepositoryProvider).indicateWork(
            patientId: patientId,
            workId: workId,
            objective: objective,
            scope: scope,
          );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
