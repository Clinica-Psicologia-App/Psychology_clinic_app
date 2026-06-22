import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/network/edge_api_client.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/clinic_summary.dart';

class ClinicsRepository {
  ClinicsRepository({
    SupabaseClient? client,
    EdgeApiClient? edgeApi,
  })  : _client = client ?? SupabaseBootstrap.client,
        _edgeApi = edgeApi ?? EdgeApiClient(client: client);

  final SupabaseClient _client;
  final EdgeApiClient _edgeApi;

  Future<List<ClinicSummary>> listClinics() async {
    try {
      final clinicsRows = await _client
          .from('clinics')
          .select(
            'id, name, document, email, phone, clinic_type, is_active, created_at',
          )
          .order('name');

      final profileRows = await _client
          .from('profiles')
          .select('clinic_id, role')
          .or('role.eq.psychologist,role.eq.platform_admin');

      final patientRows = await _client.from('patients').select('clinic_id');

      final usersByClinic = <String, int>{};
      for (final row in profileRows as List) {
        final clinicId = (row as Map)['clinic_id'] as String?;
        if (clinicId == null) continue;
        usersByClinic[clinicId] = (usersByClinic[clinicId] ?? 0) + 1;
      }

      final patientsByClinic = <String, int>{};
      for (final row in patientRows as List) {
        final clinicId = (row as Map)['clinic_id'] as String?;
        if (clinicId == null) continue;
        patientsByClinic[clinicId] = (patientsByClinic[clinicId] ?? 0) + 1;
      }

      return (clinicsRows as List).map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        final id = json['id'] as String;
        return ClinicSummary.fromJson(
          json,
          userCount: usersByClinic[id] ?? 0,
          patientCount: patientsByClinic[id] ?? 0,
        );
      }).toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> setClinicActive({
    required String clinicId,
    required bool isActive,
  }) async {
    try {
      await _client
          .from('clinics')
          .update({'is_active': isActive}).eq('id', clinicId);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<String> createClinic({
    required String name,
    required String clinicType,
    String? document,
    String? email,
    String? phone,
  }) async {
    try {
      final row = await _client
          .from('clinics')
          .insert({
            'name': name.trim(),
            'clinic_type': clinicType,
            if (document != null && document.trim().isNotEmpty)
              'document': document.trim(),
            if (email != null && email.trim().isNotEmpty) 'email': email.trim(),
            if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          })
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> deleteClinic({
    required String clinicId,
    required String confirmationName,
  }) async {
    try {
      await _edgeApi.invoke(
        'delete-clinic',
        body: {
          'clinic_id': clinicId,
          'confirmation_name': confirmationName,
        },
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
