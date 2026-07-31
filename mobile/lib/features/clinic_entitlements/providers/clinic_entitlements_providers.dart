import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/clinic_entitlements_repository.dart';
import '../domain/clinic_feature_entitlement.dart';

final clinicEntitlementsRepositoryProvider =
    Provider<ClinicEntitlementsRepository>((ref) {
  return ClinicEntitlementsRepository();
});

final currentClinicEntitlementsProvider =
    FutureProvider<ClinicFeatureEntitlements>((ref) async {
  final profile = ref.watch(authControllerProvider).valueOrNull;
  if (profile == null) {
    return ClinicFeatureEntitlements.empty;
  }

  return ref
      .read(clinicEntitlementsRepositoryProvider)
      .fetchCurrentClinicEntitlements();
});
