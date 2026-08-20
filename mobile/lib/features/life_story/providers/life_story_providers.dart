import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/life_story_repository.dart';
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
