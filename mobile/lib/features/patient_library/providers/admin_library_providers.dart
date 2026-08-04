import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_library_repository.dart';
import '../domain/library_work_full.dart';

final adminLibraryRepositoryProvider = Provider<AdminLibraryRepository>((ref) {
  return AdminLibraryRepository();
});

/// Lista de curadoria (todas as obras, publicadas ou não), filtrada por busca.
final adminLibraryListProvider =
    FutureProvider.family<List<AdminLibraryWork>, String?>((ref, query) {
  return ref.read(adminLibraryRepositoryProvider).listAll(query: query);
});

/// Detalhe completo de uma obra para edição.
final adminLibraryWorkProvider =
    FutureProvider.family<LibraryWorkFull?, String>((ref, id) {
  return ref.read(adminLibraryRepositoryProvider).getWork(id);
});

/// Mutações do catálogo (publicar, salvar, remover).
final libraryCatalogMutationProvider =
    AsyncNotifierProvider<LibraryCatalogMutation, void>(
        LibraryCatalogMutation.new);

class LibraryCatalogMutation extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AdminLibraryRepository get _repo => ref.read(adminLibraryRepositoryProvider);

  Future<void> setPublished(String id, bool published) async {
    state = const AsyncValue.loading();
    try {
      await _repo.setPublished(id, published);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Cria (id nulo) ou atualiza uma obra; retorna o id.
  Future<String> save({
    String? id,
    required Map<String, dynamic> values,
  }) async {
    state = const AsyncValue.loading();
    try {
      final String resultId;
      if (id == null) {
        resultId = await _repo.createWork(values);
      } else {
        await _repo.updateWork(id, values);
        resultId = id;
      }
      state = const AsyncValue.data(null);
      return resultId;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> delete(String id) async {
    state = const AsyncValue.loading();
    try {
      await _repo.deleteWork(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
