import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/healthy_resources_repository.dart';
import '../domain/healthy_resources.dart';

final healthyResourcesRepositoryProvider =
    Provider<HealthyResourcesRepository>((_) => HealthyResourcesRepository());

// ── Fetch ─────────────────────────────────────────────────────────────────────

final healthyResourcesProvider =
    FutureProvider.family<HealthyResources, String>(
  (ref, patientId) =>
      ref.read(healthyResourcesRepositoryProvider).fetch(patientId: patientId),
);

// ── Save ──────────────────────────────────────────────────────────────────────

final saveHealthyResourcesProvider =
    AsyncNotifierProviderFamily<SaveHealthyResourcesNotifier, void, String>(
  SaveHealthyResourcesNotifier.new,
);

class SaveHealthyResourcesNotifier
    extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  Future<void> save(HealthyResources data) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(healthyResourcesRepositoryProvider).save(
            patientId: arg,
            data: data,
          );
      ref.invalidate(healthyResourcesProvider(arg));
    });
  }
}
