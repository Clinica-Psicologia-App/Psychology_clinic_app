import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/life_story_enums.dart';
import '../domain/life_timeline_event.dart';
import '../domain/timeline_person.dart';

/// Acesso a dados do fluxo "Minha História / Linha do Tempo" unificado.
///
/// Escreve na mesma `patient_timeline_events` e `genogram_people` das telas
/// antigas, mais a junção `timeline_event_people`. Substitui, no fluxo novo,
/// as duas implementações paralelas — que ficam intactas até serem
/// aposentadas.
class LifeStoryRepository {
  LifeStoryRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

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

  Future<String> _clinicIdFor(String patientId) async {
    final row = await _client
        .from('patients')
        .select('clinic_id')
        .eq('id', patientId)
        .maybeSingle();
    if (row == null) {
      throw AppException(
        code: AppExceptionCodes.notFound,
        message: 'Paciente não encontrado.',
      );
    }
    return row['clinic_id'] as String;
  }

  // ── Leitura ────────────────────────────────────────────────────────────────

  /// Acontecimentos do paciente, com as pessoas de cada um (via junção),
  /// ordenados por idade (quando houver) e depois por criação.
  Future<List<LifeTimelineEvent>> loadTimeline(String patientId) async {
    try {
      final rows = await _client
          .from('patient_timeline_events')
          .select('*, timeline_event_people(person_id)')
          .eq('patient_id', patientId)
          .order('age_at_event', nullsFirst: false)
          .order('created_at');

      return [
        for (final row in rows as List)
          LifeTimelineEvent.fromJson(
            Map<String, dynamic>.from(row),
            peopleIds: [
              for (final j in (row['timeline_event_people'] as List? ?? []))
                (j as Map)['person_id'] as String,
            ],
          ),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Pessoas já citadas, com a contagem de acontecimentos em que aparecem
  /// (Etapa 5 mostra estas primeiro; Genograma usa "aparece em N momentos").
  Future<List<TimelinePerson>> loadPeople(String patientId) async {
    try {
      final rows = await _client
          .from('genogram_people')
          .select(
            'id, full_name, relationship_to_patient, timeline_event_people(count)',
          )
          .eq('patient_id', patientId)
          .order('created_at');

      return [
        for (final row in rows as List)
          TimelinePerson.fromJson({
            ...Map<String, dynamic>.from(row),
            'event_count': _embeddedCount(row['timeline_event_people']),
          }),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  // ── Escrita ──────────────────────────────────────────────────────────────

  /// Cria um acontecimento e liga as pessoas que participaram (junção).
  Future<String> createEvent({
    required String patientId,
    required LifeTimelineEvent event,
    required List<String> personIds,
  }) async {
    try {
      final clinicId = await _clinicIdFor(patientId);
      final profileId = _client.auth.currentUser?.id;

      final inserted = await _client
          .from('patient_timeline_events')
          .insert({
            'clinic_id': clinicId,
            'patient_id': patientId,
            'created_by': profileId,
            'filled_by_profile_id': profileId,
            'filled_by_role': 'patient',
            ...event.toRow(),
          })
          .select('id')
          .single();

      final eventId = inserted['id'] as String;

      if (personIds.isNotEmpty) {
        await _client.from('timeline_event_people').insert([
          for (final personId in personIds)
            {
              'clinic_id': clinicId,
              'patient_id': patientId,
              'event_id': eventId,
              'person_id': personId,
              'created_by': profileId,
            },
        ]);
      }

      return eventId;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Cria uma pessoa nova (identificação mínima) em `genogram_people`.
  /// O mesmo registro é reaproveitado pelo Genograma.
  Future<TimelinePerson> createPerson({
    required String patientId,
    required String fullName,
    RelationshipRole? role,
  }) async {
    try {
      final clinicId = await _clinicIdFor(patientId);
      final profileId = _client.auth.currentUser?.id;

      final row = await _client
          .from('genogram_people')
          .insert({
            'clinic_id': clinicId,
            'patient_id': patientId,
            'created_by': profileId,
            'filled_by_profile_id': profileId,
            'filled_by_role': 'patient',
            'full_name': fullName.trim(),
            'relationship_to_patient': role?.key,
          })
          .select('id, full_name, relationship_to_patient')
          .single();

      return TimelinePerson.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  int _embeddedCount(dynamic embedded) {
    if (embedded is List && embedded.isNotEmpty) {
      final first = embedded.first;
      if (first is Map && first['count'] is num) {
        return (first['count'] as num).toInt();
      }
      return embedded.length;
    }
    return 0;
  }
}
