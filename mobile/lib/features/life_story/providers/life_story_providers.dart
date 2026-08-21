import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/life_story_repository.dart';
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

/// Pessoas da família (Tela 3), com contagem de acontecimentos.
final myFamilyProvider = FutureProvider<List<FamilyPerson>>((ref) async {
  final patientId = await ref.watch(lifeStoryPatientIdProvider.future);
  return ref.read(lifeStoryRepositoryProvider).loadFamily(patientId);
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
