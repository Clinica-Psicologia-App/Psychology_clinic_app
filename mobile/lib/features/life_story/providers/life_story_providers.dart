import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/life_story_repository.dart';
import '../domain/family_context.dart';
import '../domain/family_person.dart';
import '../domain/life_story_enums.dart';
import '../domain/life_timeline_event.dart';
import '../domain/timeline_person.dart';

final lifeStoryRepositoryProvider = Provider<LifeStoryRepository>((ref) {
  return LifeStoryRepository();
});

final lifeStoryPatientIdProvider = FutureProvider<String>((ref) async {
  return ref.read(lifeStoryRepositoryProvider).getPatientIdForCurrentProfile();
});

final myTimelineProvider =
    FutureProvider<List<LifeTimelineEvent>>((ref) async {
  final patientId = await ref.watch(lifeStoryPatientIdProvider.future);
  return ref.read(lifeStoryRepositoryProvider).loadTimeline(patientId);
});

final myTimelinePeopleProvider =
    FutureProvider<List<TimelinePerson>>((ref) async {
  final patientId = await ref.watch(lifeStoryPatientIdProvider.future);
  return ref.read(lifeStoryRepositoryProvider).loadPeople(patientId);
});

/// Clima e padrões da família (Tela 3, §32–33).
final myFamilyContextProvider = FutureProvider<FamilyContext>((ref) async {
  final patientId = await ref.watch(lifeStoryPatientIdProvider.future);
  return ref.read(lifeStoryRepositoryProvider).loadFamilyContext(patientId);
});

class SaveFamilyContextNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit(FamilyContext context) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final patientId = await ref.read(lifeStoryPatientIdProvider.future);
      await ref
          .read(lifeStoryRepositoryProvider)
          .saveFamilyContext(patientId: patientId, context: context);
      ref.invalidate(myFamilyContextProvider);
    });
  }
}

final saveFamilyContextProvider =
    AsyncNotifierProvider<SaveFamilyContextNotifier, void>(
  SaveFamilyContextNotifier.new,
);

/// Pessoas da família (Tela 3), com contagem de acontecimentos.
final myFamilyProvider = FutureProvider<List<FamilyPerson>>((ref) async {
  final patientId = await ref.watch(lifeStoryPatientIdProvider.future);
  return ref.read(lifeStoryRepositoryProvider).loadFamily(patientId);
});

/// Pessoas da família de um paciente específico — usado no contexto do
/// terapeuta (§41, painel do genograma). RLS libera a leitura via
/// `user_can_access_patient`.
final familyForPatientProvider =
    FutureProvider.family<List<FamilyPerson>, String>((ref, patientId) async {
  return ref.read(lifeStoryRepositoryProvider).loadFamily(patientId);
});

/// Clima e padrões da família de um paciente específico (contexto do terapeuta).
final familyContextForPatientProvider =
    FutureProvider.family<FamilyContext, String>((ref, patientId) async {
  return ref.read(lifeStoryRepositoryProvider).loadFamilyContext(patientId);
});

/// Acontecimentos da Linha do Tempo de um paciente específico — contexto do
/// terapeuta (§42, síntese). RLS libera a leitura via `user_can_access_patient`.
final timelineForPatientProvider =
    FutureProvider.family<List<LifeTimelineEvent>, String>(
        (ref, patientId) async {
  return ref.read(lifeStoryRepositoryProvider).loadTimeline(patientId);
});

/// Cria/atualiza uma pessoa da família e invalida os caches.
class SaveFamilyPersonNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> create(FamilyPerson person) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final patientId = await ref.read(lifeStoryPatientIdProvider.future);
      await ref
          .read(lifeStoryRepositoryProvider)
          .createFamilyPerson(patientId: patientId, person: person);
      ref.invalidate(myFamilyProvider);
      ref.invalidate(myTimelinePeopleProvider);
    });
  }

  Future<void> updatePerson(String personId, FamilyPerson person) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(lifeStoryRepositoryProvider)
          .updateFamilyPerson(personId: personId, person: person);
      ref.invalidate(myFamilyProvider);
    });
  }
}

final saveFamilyPersonProvider =
    AsyncNotifierProvider<SaveFamilyPersonNotifier, void>(
  SaveFamilyPersonNotifier.new,
);

/// Salva um novo acontecimento (+ pessoas) e invalida os caches de leitura.
class CreateTimelineEventNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required LifeTimelineEvent event,
    required List<String> personIds,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final patientId =
          await ref.read(lifeStoryPatientIdProvider.future);
      await ref.read(lifeStoryRepositoryProvider).createEvent(
            patientId: patientId,
            event: event,
            personIds: personIds,
          );
      ref.invalidate(myTimelineProvider);
      ref.invalidate(myTimelinePeopleProvider);
    });
  }
}

final createTimelineEventProvider =
    AsyncNotifierProvider<CreateTimelineEventNotifier, void>(
  CreateTimelineEventNotifier.new,
);

/// Salva os campos de "aprofundar" sobre um acontecimento existente.
class UpdateTimelineEventNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required String eventId,
    required LifeTimelineEvent event,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref
          .read(lifeStoryRepositoryProvider)
          .updateEvent(eventId: eventId, event: event);
      ref.invalidate(myTimelineProvider);
    });
  }
}

final updateTimelineEventProvider =
    AsyncNotifierProvider<UpdateTimelineEventNotifier, void>(
  UpdateTimelineEventNotifier.new,
);

/// Comentário clínico do terapeuta sobre uma pessoa (§40), por `personId`.
/// Staff-only: leitura devolve `null` quando não há nota (ou sem acesso).
final personClinicalCommentProvider =
    FutureProvider.family<String?, String>((ref, personId) async {
  return ref.read(lifeStoryRepositoryProvider).loadClinicalComment(personId);
});

/// Salva/atualiza o comentário clínico de uma pessoa e invalida o cache.
class SaveClinicalCommentNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit({
    required String patientId,
    required String personId,
    required String comment,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(lifeStoryRepositoryProvider).saveClinicalComment(
            patientId: patientId,
            personId: personId,
            comment: comment,
          );
      ref.invalidate(personClinicalCommentProvider(personId));
    });
  }
}

final saveClinicalCommentProvider =
    AsyncNotifierProvider<SaveClinicalCommentNotifier, void>(
  SaveClinicalCommentNotifier.new,
);

/// Cria uma pessoa nova durante o fluxo e devolve o registro criado.
class CreatePersonNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<TimelinePerson> submit({
    required String fullName,
    RelationshipRole? role,
  }) async {
    final patientId = await ref.read(lifeStoryPatientIdProvider.future);
    final person = await ref.read(lifeStoryRepositoryProvider).createPerson(
          patientId: patientId,
          fullName: fullName,
          role: role,
        );
    ref.invalidate(myTimelinePeopleProvider);
    return person;
  }
}

final createPersonProvider =
    AsyncNotifierProvider<CreatePersonNotifier, void>(
  CreatePersonNotifier.new,
);
