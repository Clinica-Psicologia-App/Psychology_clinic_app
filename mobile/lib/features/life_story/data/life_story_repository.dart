import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/clinical_hypothesis.dart';
import '../domain/family_context.dart';
import '../domain/family_person.dart';
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

  /// Pessoas da família (Tela 3) — dados estruturais completos + contagem de
  /// acontecimentos em que aparecem (§19 "aparece em N momentos").
  Future<List<FamilyPerson>> loadFamily(String patientId) async {
    try {
      final rows = await _client
          .from('genogram_people')
          .select('*, timeline_event_people(count)')
          .eq('patient_id', patientId)
          .order('created_at');

      return [
        for (final row in rows as List)
          FamilyPerson.fromJson({
            ...Map<String, dynamic>.from(row),
            'event_count': _embeddedCount(row['timeline_event_people']),
          }),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Clima e padrões familiares (Tela 3, §32–33) — colunas novas em
  /// patient_family_context.
  Future<FamilyContext> loadFamilyContext(String patientId) async {
    try {
      final row = await _client
          .from('patient_family_context')
          .select(
            'climate_traits, climate_note, has_patterns, pattern_traits, '
            'pattern_generations, patterns_note',
          )
          .eq('patient_id', patientId)
          .maybeSingle();
      return row == null
          ? const FamilyContext()
          : FamilyContext.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> saveFamilyContext({
    required String patientId,
    required FamilyContext context,
  }) async {
    try {
      final profileId = _client.auth.currentUser?.id;
      await _client.from('patient_family_context').upsert(
        {
          'patient_id': patientId,
          'filled_by_profile_id': profileId,
          'filled_by_role': 'patient',
          ...context.toRow(),
        },
        onConflict: 'patient_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Comentário clínico do terapeuta sobre uma pessoa (§40). Tabela
  /// `genogram_person_notes` — staff-only por RLS; o paciente nunca a lê.
  Future<String?> loadClinicalComment(String personId) async {
    try {
      final row = await _client
          .from('genogram_person_notes')
          .select('clinical_comment')
          .eq('person_id', personId)
          .maybeSingle();
      return row?['clinical_comment'] as String?;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> saveClinicalComment({
    required String patientId,
    required String personId,
    required String comment,
  }) async {
    try {
      final profileId = _client.auth.currentUser?.id;
      await _client.from('genogram_person_notes').upsert(
        {
          'patient_id': patientId,
          'person_id': personId,
          'clinical_comment': comment.trim(),
          'updated_by_profile_id': profileId,
        },
        onConflict: 'person_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Hipóteses de conceitualização do terapeuta (§43). Tabela
  /// `clinical_hypotheses` — staff-only por RLS.
  Future<List<ClinicalHypothesis>> loadHypotheses(String patientId) async {
    try {
      final rows = await _client
          .from('clinical_hypotheses')
          .select('id, kind, body')
          .eq('patient_id', patientId)
          .order('created_at');
      return [
        for (final row in rows as List)
          ClinicalHypothesis.fromJson(Map<String, dynamic>.from(row)),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> addHypothesis({
    required String patientId,
    required HypothesisKind kind,
    required String body,
  }) async {
    try {
      final clinicId = await _clinicIdFor(patientId);
      final profileId = _client.auth.currentUser?.id;
      await _client.from('clinical_hypotheses').insert({
        'clinic_id': clinicId,
        'patient_id': patientId,
        'author_id': profileId,
        'kind': kind.key,
        'body': body.trim(),
      });
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> updateHypothesis({
    required String id,
    required String body,
  }) async {
    try {
      await _client
          .from('clinical_hypotheses')
          .update({'body': body.trim()}).eq('id', id);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> deleteHypothesis(String id) async {
    try {
      await _client.from('clinical_hypotheses').delete().eq('id', id);
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

  /// Atualiza os campos de um acontecimento já existente (usado pelo
  /// "Aprofundar este momento"). Não mexe nas pessoas ligadas.
  Future<void> updateEvent({
    required String eventId,
    required LifeTimelineEvent event,
  }) async {
    try {
      await _client
          .from('patient_timeline_events')
          .update(event.toRow())
          .eq('id', eventId);
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

  /// Cria uma pessoa da família com os dados estruturais completos (§20).
  Future<FamilyPerson> createFamilyPerson({
    required String patientId,
    required FamilyPerson person,
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
            ...person.toRow(),
          })
          .select('*')
          .single();
      return FamilyPerson.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Atualiza os dados estruturais de uma pessoa da família.
  Future<void> updateFamilyPerson({
    required String personId,
    required FamilyPerson person,
  }) async {
    try {
      await _client
          .from('genogram_people')
          .update(person.toRow())
          .eq('id', personId);
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
