import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_psychoeducation_repository.dart';
import '../data/exercise_repository.dart';
import '../data/psychoeducation_repository.dart';
import '../domain/exercise_definition.dart';
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

// ── Exercícios (paciente) ─────────────────────────────────────────────────────

final exerciseRepositoryProvider = Provider<ExerciseRepository>((ref) {
  return ExerciseRepository();
});

/// Carrega a resposta salva para um módulo específico.
final exerciseResponseProvider =
    FutureProvider.family<ExerciseResponse?, String>((ref, moduleId) {
  return ref.read(exerciseRepositoryProvider).getResponse(moduleId);
});

class ExerciseSaveNotifier
    extends FamilyAsyncNotifier<ExerciseResponse?, String> {
  @override
  Future<ExerciseResponse?> build(String arg) async {
    return ref.read(exerciseRepositoryProvider).getResponse(arg);
  }

  Future<void> save({
    required Map<String, dynamic> responses,
    String? difficultyScale,
    bool? wantsToTalk,
  }) async {
    state = const AsyncValue.loading();
    try {
      final result = await ref.read(exerciseRepositoryProvider).saveResponse(
            moduleId: arg,
            responses: responses,
            difficultyScale: difficultyScale,
            wantsToTalk: wantsToTalk,
          );
      state = AsyncValue.data(result);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final exerciseSaveProvider =
    AsyncNotifierProvider.family<ExerciseSaveNotifier, ExerciseResponse?, String>(
  ExerciseSaveNotifier.new,
);

// ── Admin ────────────────────────────────────────────────────────────────────

final adminPsychoeducationRepositoryProvider =
    Provider<AdminPsychoeducationRepository>((ref) {
  return AdminPsychoeducationRepository();
});

/// Lista de curadoria (todos os módulos, publicados ou não).
final adminPsychoListProvider = FutureProvider<List<AdminPsychoModule>>((ref) {
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
