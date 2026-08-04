import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/admin_entitlements_repository.dart';

final adminEntitlementsRepositoryProvider =
    Provider<AdminEntitlementsRepository>((ref) {
  return AdminEntitlementsRepository();
});

/// Permissões atuais de uma clínica (feature_key → is_enabled).
final clinicEntitlementsAdminProvider =
    FutureProvider.family<Map<String, bool>, String>((ref, clinicId) {
  return ref.read(adminEntitlementsRepositoryProvider).listForClinic(clinicId);
});

/// Mutação: liga/desliga um módulo de uma clínica.
final entitlementMutationProvider =
    AsyncNotifierProvider<EntitlementMutation, void>(EntitlementMutation.new);

class EntitlementMutation extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setEnabled({
    required String clinicId,
    required AdminFeatureDef feature,
    required bool enabled,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(adminEntitlementsRepositoryProvider).setEnabled(
            clinicId: clinicId,
            featureKey: feature.key,
            featureName: feature.name,
            enabled: enabled,
          );
      ref.invalidate(clinicEntitlementsAdminProvider(clinicId));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
