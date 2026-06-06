import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/patient_resource_access.dart';
import '../domain/therapy_resource.dart';

class TherapyResourcesRepository {
  TherapyResourcesRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _resourceSelect =
      'id, title, type, description, url, is_active';

  static const _accessSelect = '''
id,
patient_id,
resource_id,
is_active,
released_at,
viewed_at,
completed_at,
resource:therapy_resources($_resourceSelect),
released_by:profiles!patient_resource_access_released_by_profile_id_fkey(full_name)
''';

  Future<List<TherapyResource>> listClinicResources({bool activeOnly = true}) async {
    try {
      var query = _client.from('therapy_resources').select(_resourceSelect);
      if (activeOnly) {
        query = query.eq('is_active', true);
      }
      final rows = await query.order('title');

      return (rows as List)
          .map((r) => TherapyResource.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<TherapyResource?> getResourceById(String resourceId) async {
    try {
      final row = await _client
          .from('therapy_resources')
          .select(_resourceSelect)
          .eq('id', resourceId)
          .maybeSingle();

      if (row == null) return null;
      return TherapyResource.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<PatientResourceAccess>> listAccessForPatient(
    String patientId, {
    bool activeOnly = false,
  }) async {
    try {
      var query = _client
          .from('patient_resource_access')
          .select(_accessSelect)
          .eq('patient_id', patientId);

      if (activeOnly) {
        query = query.eq('is_active', true);
      }

      final rows = await query.order('released_at', ascending: false);

      return (rows as List)
          .map(
            (r) => PatientResourceAccess.fromJson(
              Map<String, dynamic>.from(r),
            ),
          )
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<String> getPatientIdForCurrentProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw AppException(
          code: AppExceptionCodes.unauthorized,
          message: 'Sessão não encontrada.',
        );
      }

      final row = await _client
          .from('patients')
          .select('id')
          .eq('profile_id', userId)
          .maybeSingle();

      if (row == null) {
        throw AppException(
          code: AppExceptionCodes.notFound,
          message: 'Cadastro de paciente não encontrado.',
        );
      }

      return row['id'] as String;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<PatientResourceAccess>> listMyReleasedResources() async {
    final patientId = await getPatientIdForCurrentProfile();
    return listAccessForPatient(patientId, activeOnly: true);
  }

  /// Libera ou reativa recurso (RLS: staff + released_by = auth.uid()).
  Future<PatientResourceAccess> assignResource({
    required String patientId,
    required String resourceId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw AppException(
          code: AppExceptionCodes.unauthorized,
          message: 'Sessão não encontrada.',
        );
      }

      final now = DateTime.now().toUtc().toIso8601String();

      await _client.from('patient_resource_access').upsert(
        {
          'patient_id': patientId,
          'resource_id': resourceId,
          'released_by_profile_id': userId,
          'is_active': true,
          'released_at': now,
        },
        onConflict: 'patient_id,resource_id',
      );

      final list = await listAccessForPatient(patientId);
      final match = list.where((a) => a.resourceId == resourceId).firstOrNull;
      if (match != null) return match;

      throw AppException(
        code: AppExceptionCodes.unknown,
        message: 'Recurso liberado, mas não foi possível recarregar o acesso.',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> revokeAccess(String accessId) async {
    try {
      await _client
          .from('patient_resource_access')
          .update({'is_active': false})
          .eq('id', accessId);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<PatientResourceAccess?> getAccessById(String accessId) async {
    try {
      final row = await _client
          .from('patient_resource_access')
          .select(_accessSelect)
          .eq('id', accessId)
          .maybeSingle();

      if (row == null) return null;
      return PatientResourceAccess.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<PatientResourceAccess> markViewed(String accessId) async {
    return _updateProgress(
      accessId,
      viewedAt: DateTime.now().toUtc(),
    );
  }

  Future<PatientResourceAccess> markCompleted(String accessId) async {
    final existing = await getAccessById(accessId);
    return _updateProgress(
      accessId,
      viewedAt: existing?.viewedAt ?? DateTime.now().toUtc(),
      completedAt: DateTime.now().toUtc(),
    );
  }

  Future<PatientResourceAccess> _updateProgress(
    String accessId, {
    DateTime? viewedAt,
    DateTime? completedAt,
  }) async {
    try {
      final payload = <String, dynamic>{};
      if (viewedAt != null) {
        payload['viewed_at'] = viewedAt.toIso8601String();
      }
      if (completedAt != null) {
        payload['completed_at'] = completedAt.toIso8601String();
      }

      await _client
          .from('patient_resource_access')
          .update(payload)
          .eq('id', accessId);

      final updated = await getAccessById(accessId);
      if (updated == null) {
        throw AppException(
          code: AppExceptionCodes.notFound,
          message: 'Acesso ao recurso não encontrado.',
        );
      }
      return updated;
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
