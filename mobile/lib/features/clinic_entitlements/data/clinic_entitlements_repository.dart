import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/clinic_feature_entitlement.dart';

class ClinicEntitlementsRepository {
  ClinicEntitlementsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  Future<ClinicFeatureEntitlements> fetchCurrentClinicEntitlements() async {
    try {
      final response = await _client.rpc('get_current_clinic_entitlements');
      final rows = response is List ? response : const [];
      final entitlements = <String, ClinicFeatureEntitlement>{};

      for (final row in rows) {
        if (row is Map) {
          final entitlement = ClinicFeatureEntitlement.fromJson(
            Map<String, dynamic>.from(row),
          );
          entitlements[entitlement.featureKey] = entitlement;
        }
      }

      return ClinicFeatureEntitlements(entitlements);
    } catch (error) {
      throw mapToAppException(error);
    }
  }
}
