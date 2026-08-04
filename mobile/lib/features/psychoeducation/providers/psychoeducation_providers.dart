import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_psychoeducation_repository.dart';
import '../data/psychoeducation_repository.dart';
import '../domain/psychoeducation_module.dart';

// ── Paciente ─────────────────────────────────────────────────────────────────

final psychoeducationRepositoryProvider =
    Provider<PsychoeducationRepository>((ref) {
  return PsychoeducationRepository();
});

/// Jornada de psicoeducação do paciente (módulos publicados, sem texto do
/// terapeuta).
final psychoeducationJourneyProvider =
    FutureProvider<List<PsychoeducationModule>>((ref) {
  return ref.read(psychoeducationRepositoryProvider).getJourney();
});

// ── Admin ────────────────────────────────────────────────────────────────────

final adminPsychoeducationRepositoryProvider =
    Provider<AdminPsychoeducationRepository>((ref) {
  return AdminPsychoeducationRepository();
});

/// Lista de curadoria (todos os módulos, publicados ou não).
final adminPsychoListProvider =
    FutureProvider<List<AdminPsychoModule>>((ref) {
  return ref.read(adminPsychoeducationRepositoryProvider).listAll();
});

/// Módulo completo para edição.
final adminPsychoModuleProvider =
    FutureProvider.family<PsychoeducationModule?, String>((ref, id) {
  return ref.read(adminPsychoeducationRepositoryProvider).getModule(id);
});

/// Mutações da curadoria (publicar, salvar, remover).
final psychoMutationProvider =
    AsyncNotifierProvider<PsychoMutation, void>(PsychoMutation.new);

class PsychoMutation extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  AdminPsychoeducationRepository get _repo =>
      ref.read(adminPsychoeducationRepositoryProvider);

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

  Future<String> save({
    String? id,
    required Map<String, dynamic> values,
  }) async {
    state = const AsyncValue.loading();
    try {
      final String resultId;
      if (id == null) {
        resultId = await _repo.createModule(values);
      } else {
        await _repo.updateModule(id, values);
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
      await _repo.deleteModule(id);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
