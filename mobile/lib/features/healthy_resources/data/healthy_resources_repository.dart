import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/healthy_resources.dart';

class HealthyResourcesRepository {
  HealthyResourcesRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  Future<HealthyResources> fetch({required String patientId}) async {
    try {
      final psychologistId = _client.auth.currentUser?.id;
      if (psychologistId == null) {
        return HealthyResources.empty();
      }
      final rows = await _client
          .from('patient_healthy_resources')
          .select()
          .eq('patient_id', patientId)
          .eq('psychologist_id', psychologistId)
          .limit(1);
      if (rows.isEmpty) return HealthyResources.empty();
      return HealthyResources.fromJson(rows.first as Map<String, dynamic>);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> save({
    required String patientId,
    required HealthyResources data,
  }) async {
    try {
      final psychologistId = _client.auth.currentUser?.id;
      if (psychologistId == null) {
        throw AppException(
          code: AppExceptionCodes.unauthorized,
          message: 'Sessão não iniciada.',
        );
      }
      await _client.from('patient_healthy_resources').upsert(
        {
          'patient_id': patientId,
          'psychologist_id': psychologistId,
          'selected_predefined': data.selectedPredefined,
          'custom_resources': data.customResources,
          'observations': data.observations?.trim().isEmpty == true
              ? null
              : data.observations?.trim(),
        },
        onConflict: 'patient_id,psychologist_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
