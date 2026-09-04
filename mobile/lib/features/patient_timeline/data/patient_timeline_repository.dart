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

  static const _columns =
      'id, clinic_id, patient_id, created_by, title, description, event_date, period_label, category, emotional_impact, emotional_need_keys, emotional_need_other, emotions_felt, self_meaning, others_meaning, world_meaning, coping_keys, coping_other, present_influence, present_area_keys, present_reaction, is_sensitive, created_at, updated_at';

  // Embed padrão da junção pessoa↔evento (leitura). listForPerson usa a
  // variante `!inner` para filtrar pelo person_id embutido.
  static const _select = '$_columns, timeline_event_people(person_id)';

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

  /// Eventos vinculados a uma pessoa específica do genograma (via junção
  /// `timeline_event_people`) — usado para navegar do genograma direto
  /// para a linha do tempo daquela pessoa.
  Future<List<PatientTimelineEvent>> listForPerson({
    required String patientId,
    required String personId,
  }) async {
    try {
      final rows = await _client
          .from('patient_timeline_events')
          .select('$_columns, timeline_event_people!inner(person_id)')
          .eq('patient_id', patientId)
          .eq('timeline_event_people.person_id', personId)
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
          .select(_columns)
          .single();

      final eventId = row['id'] as String;
      await _syncRelatedPeople(
        eventId: eventId,
        clinicId: clinicId,
        patientId: patientId,
        personIds: input.relatedPersonIds,
        createdBy: userId,
      );

      return PatientTimelineEvent.fromJson({
        ...Map<String, dynamic>.from(row),
        'timeline_event_people': [
          for (final personId in input.relatedPersonIds) {'person_id': personId},
        ],
      });
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
          .select(_columns)
          .single();

      final clinicId = row['clinic_id'] as String;
      final patientId = row['patient_id'] as String;
      await _syncRelatedPeople(
        eventId: id,
        clinicId: clinicId,
        patientId: patientId,
        personIds: input.relatedPersonIds,
        createdBy: _client.auth.currentUser?.id,
      );

      return PatientTimelineEvent.fromJson({
        ...Map<String, dynamic>.from(row),
        'timeline_event_people': [
          for (final personId in input.relatedPersonIds) {'person_id': personId},
        ],
      });
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Substitui (remove e recria) as pessoas ligadas a um evento na junção
  /// `timeline_event_people`. A UI atual liga no máximo uma pessoa por
  /// evento, mas a junção já suporta várias.
  Future<void> _syncRelatedPeople({
    required String eventId,
    required String clinicId,
    required String patientId,
    required List<String> personIds,
    String? createdBy,
  }) async {
    await _client
        .from('timeline_event_people')
        .delete()
        .eq('event_id', eventId);
    if (personIds.isEmpty) return;
    await _client.from('timeline_event_people').insert([
      for (final personId in personIds)
        {
          'clinic_id': clinicId,
          'patient_id': patientId,
          'event_id': eventId,
          'person_id': personId,
          if (createdBy != null) 'created_by': createdBy,
        },
    ]);
  }
}
