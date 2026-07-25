import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/life_chapter.dart';
import '../domain/patient_history.dart';
import '../domain/timeline_belief.dart';
import '../domain/timeline_entry.dart';

/// Tela 2 (Minha História) — lê/escreve `patient_timeline_events` com os campos
/// da visão Conhecer (capítulo, idade, crenças) e mescla o comentário clínico
/// staff-only de `patient_timeline_event_notes`.
class PatientHistoryRepository {
  PatientHistoryRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _select =
      'id, clinic_id, patient_id, created_by, title, description, event_date, '
      'life_chapter, age_at_event, emotional_impact, belief_keys, belief_other, '
      'is_sensitive, filled_by_role, created_at, updated_at';

  String? get _currentProfileId => _client.auth.currentUser?.id;

  Future<String> getPatientIdForCurrentProfile() async {
    try {
      final userId = _currentProfileId;
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

  Future<({String patientId, String clinicId})> _resolveContext(
    String patientId,
  ) async {
    final row = await _client
        .from('patients')
        .select('id, clinic_id')
        .eq('id', patientId)
        .maybeSingle();
    if (row == null) {
      throw AppException(
        code: AppExceptionCodes.notFound,
        message: 'Paciente não encontrado.',
      );
    }
    return (patientId: row['id'] as String, clinicId: row['clinic_id'] as String);
  }

  // ---------------------------------------------------------------------------
  // Leitura
  // ---------------------------------------------------------------------------

  Future<PatientHistory> load(String patientId) async {
    try {
      final eventRows = await _client
          .from('patient_timeline_events')
          .select(_select)
          .eq('patient_id', patientId);

      // Staff-only — vazio para o paciente (RLS).
      final noteRows = await _client
          .from('patient_timeline_event_notes')
          .select('event_id, clinical_comment')
          .eq('patient_id', patientId);

      final notesByEvent = <String, String?>{
        for (final row in noteRows)
          row['event_id'] as String: row['clinical_comment'] as String?,
      };

      final entries = [
        for (final row in eventRows)
          TimelineEntry.fromJson(Map<String, dynamic>.from(row))
              .copyWith(clinicalComment: notesByEvent[row['id'] as String]),
      ];

      return PatientHistory(patientId: patientId, entries: entries);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Escrita — evento (paciente ou terapeuta)
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _eventPayload({
    required LifeChapter? lifeChapter,
    required String title,
    String? description,
    int? ageAtEvent,
    int? emotionalImpact,
    List<TimelineBelief> beliefs = const [],
    String? beliefOther,
    required String filledByRole,
  }) {
    return {
      'title': title.trim(),
      'description': description,
      'life_chapter': lifeChapter?.key,
      'age_at_event': ageAtEvent,
      'emotional_impact': emotionalImpact,
      'belief_keys':
          beliefs.isEmpty ? null : [for (final b in beliefs) b.key],
      'belief_other': beliefOther,
      'filled_by_profile_id': _currentProfileId,
      'filled_by_role': filledByRole,
    };
  }

  Future<TimelineEntry> createEntry({
    required String patientId,
    required String filledByRole,
    required String title,
    LifeChapter? lifeChapter,
    String? description,
    int? ageAtEvent,
    int? emotionalImpact,
    List<TimelineBelief> beliefs = const [],
    String? beliefOther,
  }) async {
    if (title.trim().isEmpty) {
      throw AppException(
        code: AppExceptionCodes.validation,
        message: 'Descreva o acontecimento.',
      );
    }
    try {
      final ctx = await _resolveContext(patientId);
      final row = await _client
          .from('patient_timeline_events')
          .insert({
            'clinic_id': ctx.clinicId,
            'patient_id': ctx.patientId,
            'created_by': _currentProfileId,
            ..._eventPayload(
              lifeChapter: lifeChapter,
              title: title,
              description: description,
              ageAtEvent: ageAtEvent,
              emotionalImpact: emotionalImpact,
              beliefs: beliefs,
              beliefOther: beliefOther,
              filledByRole: filledByRole,
            ),
          })
          .select(_select)
          .single();
      return TimelineEntry.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<TimelineEntry> updateEntry({
    required String eventId,
    required String filledByRole,
    required String title,
    LifeChapter? lifeChapter,
    String? description,
    int? ageAtEvent,
    int? emotionalImpact,
    List<TimelineBelief> beliefs = const [],
    String? beliefOther,
  }) async {
    if (title.trim().isEmpty) {
      throw AppException(
        code: AppExceptionCodes.validation,
        message: 'Descreva o acontecimento.',
      );
    }
    try {
      final row = await _client
          .from('patient_timeline_events')
          .update(_eventPayload(
            lifeChapter: lifeChapter,
            title: title,
            description: description,
            ageAtEvent: ageAtEvent,
            emotionalImpact: emotionalImpact,
            beliefs: beliefs,
            beliefOther: beliefOther,
            filledByRole: filledByRole,
          ))
          .eq('id', eventId)
          .select(_select)
          .single();
      return TimelineEntry.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> deleteEntry(String eventId) async {
    try {
      await _client.from('patient_timeline_events').delete().eq('id', eventId);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Escrita — comentário clínico por evento (staff-only)
  // ---------------------------------------------------------------------------

  Future<void> saveEntryNote({
    required String patientId,
    required String eventId,
    String? clinicalComment,
  }) async {
    try {
      await _client.from('patient_timeline_event_notes').upsert(
        {
          'patient_id': patientId,
          'event_id': eventId,
          'clinical_comment': (clinicalComment ?? '').trim().isEmpty
              ? null
              : clinicalComment!.trim(),
          'updated_by_profile_id': _currentProfileId,
        },
        onConflict: 'event_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
