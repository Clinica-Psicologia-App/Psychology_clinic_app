import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/patient_timeline_event.dart';
import '../domain/patient_timeline_event_input.dart';

class PatientTimelineRepository {
  PatientTimelineRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _select =
      'id, clinic_id, patient_id, created_by, title, description, event_date, period_label, category, emotional_impact, emotional_need_keys, emotional_need_other, emotions_felt, self_meaning, others_meaning, world_meaning, coping_keys, coping_other, present_influence, present_area_keys, present_reaction, is_sensitive, created_at, updated_at';

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
          message: 'Cadastro de paciente não encontrado para este login.',
        );
      }

      return row['id'] as String;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<({String patientId, String clinicId})> resolvePatientContext({
    String? patientId,
  }) async {
    try {
      final id = patientId ?? await getPatientIdForCurrentProfile();
      final row = await _client
          .from('patients')
          .select('id, clinic_id')
          .eq('id', id)
          .maybeSingle();

      if (row == null) {
        throw AppException(
          code: AppExceptionCodes.notFound,
          message: 'Paciente não encontrado.',
        );
      }

      return (
        patientId: row['id'] as String,
        clinicId: row['clinic_id'] as String,
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<PatientTimelineEvent>> listForPatient(String patientId) async {
    try {
      final rows = await _client
          .from('patient_timeline_events')
          .select(_select)
          .eq('patient_id', patientId)
          .order('event_date', ascending: false)
          .order('created_at', ascending: false);

      final events = (rows as List)
          .map((r) =>
              PatientTimelineEvent.fromJson(Map<String, dynamic>.from(r)))
          .toList();

      return sortTimelineEventsChronologically(events);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<PatientTimelineEvent>> listMyEvents() async {
    final patientId = await getPatientIdForCurrentProfile();
    return listForPatient(patientId);
  }

  Future<int> countForPatient(String patientId) async {
    try {
      final rows = await _client
          .from('patient_timeline_events')
          .select('id')
          .eq('patient_id', patientId);

      return (rows as List).length;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<PatientTimelineEvent?> getById(String id) async {
    try {
      final row = await _client
          .from('patient_timeline_events')
          .select(_select)
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return PatientTimelineEvent.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<PatientTimelineEvent> create({
    required String clinicId,
    required String patientId,
    required PatientTimelineEventInput input,
    String? createdBy,
  }) async {
    final validation = input.validate();
    if (validation != null) {
      throw AppException(
        code: AppExceptionCodes.validation,
        message: validation,
      );
    }

    try {
      final userId = createdBy ?? _client.auth.currentUser?.id;
      final row = await _client
          .from('patient_timeline_events')
          .insert({
            'clinic_id': clinicId,
            'patient_id': patientId,
            if (userId != null) 'created_by': userId,
            ...input.toInsertJson(),
          })
          .select(_select)
          .single();

      return PatientTimelineEvent.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<PatientTimelineEvent> update({
    required String id,
    required PatientTimelineEventInput input,
  }) async {
    final validation = input.validate();
    if (validation != null) {
      throw AppException(
        code: AppExceptionCodes.validation,
        message: validation,
      );
    }

    try {
      final row = await _client
          .from('patient_timeline_events')
          .update(input.toUpdateJson())
          .eq('id', id)
          .select(_select)
          .single();

      return PatientTimelineEvent.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
