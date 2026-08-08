import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/family_context.dart';
import '../domain/genogram_enums.dart';
import '../domain/genogram_person_entry.dart';
import '../domain/patient_family.dart';

/// Tela 3 (Minha Família) — lê/escreve `genogram_people` com a camada
/// emocional, o `patient_family_context` (clima + padrões) e mescla os
/// comentários clínicos staff-only de `genogram_person_notes`.
class PatientFamilyRepository {
  PatientFamilyRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _peopleSelect =
      'id, clinic_id, patient_id, full_name, relationship_to_patient, gender, '
      'birth_year, death_year, is_deceased, is_sensitive, is_caregiver, '
      'bond_quality, emotional_presence, caregiver_traits, caregiver_traits_other, '
      'felt_needs, wished_needs, linked_events, linked_events_other, '
      'filled_by_role, created_at, updated_at';

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

  // ---------------------------------------------------------------------------
  // Leitura
  // ---------------------------------------------------------------------------

  Future<PatientFamily> load(String patientId) async {
    try {
      final peopleRows = await _client
          .from('genogram_people')
          .select(_peopleSelect)
          .eq('patient_id', patientId)
          .order('created_at');

      final contextRow = await _client
          .from('patient_family_context')
          .select()
          .eq('patient_id', patientId)
          .maybeSingle();

      // Staff-only — vazio para o paciente (RLS).
      final noteRows = await _client
          .from('genogram_person_notes')
          .select('person_id, clinical_comment')
          .eq('patient_id', patientId);

      final notesByPerson = <String, String?>{
        for (final row in noteRows)
          row['person_id'] as String: row['clinical_comment'] as String?,
      };

      final people = [
        for (final row in peopleRows)
          GenogramPersonEntry.fromJson(Map<String, dynamic>.from(row))
              .copyWith(clinicalComment: notesByPerson[row['id'] as String]),
      ];

      return PatientFamily(
        patientId: patientId,
        people: people,
        context: contextRow == null
            ? const FamilyContext()
            : FamilyContext.fromJson(Map<String, dynamic>.from(contextRow)),
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Escrita — pessoa
  // ---------------------------------------------------------------------------

  Map<String, dynamic> _personPayload({
    required String fullName,
    String? relationshipToPatient,
    String? gender,
    int? birthYear,
    int? deathYear,
    bool isDeceased = false,
    bool isSensitive = false,
    bool? isCaregiver,
    BondQuality? bondQuality,
    int? emotionalPresence,
    List<CaregiverTrait> caregiverTraits = const [],
    String? caregiverTraitsOther,
    List<CaregiverNeed> feltNeeds = const [],
    List<CaregiverNeed> wishedNeeds = const [],
    List<LinkedEvent> linkedEvents = const [],
    String? linkedEventsOther,
    required String filledByRole,
  }) {
    List<String>? keys<E>(List<E> items, String Function(E) keyOf) =>
        items.isEmpty ? null : [for (final e in items) keyOf(e)];

    return {
      'full_name': fullName.trim(),
      'relationship_to_patient': relationshipToPatient,
      'gender': gender,
      'birth_year': birthYear,
      'death_year': deathYear,
      'is_deceased': isDeceased,
      'is_sensitive': isSensitive,
      'is_caregiver': isCaregiver,
      'bond_quality': bondQuality?.key,
      'emotional_presence': emotionalPresence,
      'caregiver_traits': keys(caregiverTraits, (e) => e.key),
      'caregiver_traits_other': caregiverTraitsOther,
      'felt_needs': keys(feltNeeds, (e) => e.key),
      'wished_needs': keys(wishedNeeds, (e) => e.key),
      'linked_events': keys(linkedEvents, (e) => e.key),
      'linked_events_other': linkedEventsOther,
      'filled_by_profile_id': _currentProfileId,
      'filled_by_role': filledByRole,
    };
  }

  Future<GenogramPersonEntry> createPerson({
    required String patientId,
    required String filledByRole,
    required String fullName,
    String? relationshipToPatient,
    String? gender,
    int? birthYear,
    int? deathYear,
    bool isDeceased = false,
    bool isSensitive = false,
    bool? isCaregiver,
    BondQuality? bondQuality,
    int? emotionalPresence,
    List<CaregiverTrait> caregiverTraits = const [],
    String? caregiverTraitsOther,
    List<CaregiverNeed> feltNeeds = const [],
    List<CaregiverNeed> wishedNeeds = const [],
    List<LinkedEvent> linkedEvents = const [],
    String? linkedEventsOther,
  }) async {
    if (fullName.trim().isEmpty) {
      throw AppException(
        code: AppExceptionCodes.validation,
        message: 'Informe o nome da pessoa.',
      );
    }
    try {
      final clinicId = await _clinicIdFor(patientId);
      final row = await _client
          .from('genogram_people')
          .insert({
            'clinic_id': clinicId,
            'patient_id': patientId,
            'created_by': _currentProfileId,
            ..._personPayload(
              fullName: fullName,
              relationshipToPatient: relationshipToPatient,
              gender: gender,
              birthYear: birthYear,
              deathYear: deathYear,
              isDeceased: isDeceased,
              isSensitive: isSensitive,
              isCaregiver: isCaregiver,
              bondQuality: bondQuality,
              emotionalPresence: emotionalPresence,
              caregiverTraits: caregiverTraits,
              caregiverTraitsOther: caregiverTraitsOther,
              feltNeeds: feltNeeds,
              wishedNeeds: wishedNeeds,
              linkedEvents: linkedEvents,
              linkedEventsOther: linkedEventsOther,
              filledByRole: filledByRole,
            ),
          })
          .select(_peopleSelect)
          .single();
      return GenogramPersonEntry.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<GenogramPersonEntry> updatePerson({
    required String personId,
    required String filledByRole,
    required String fullName,
    String? relationshipToPatient,
    String? gender,
    int? birthYear,
    int? deathYear,
    bool isDeceased = false,
    bool isSensitive = false,
    bool? isCaregiver,
    BondQuality? bondQuality,
    int? emotionalPresence,
    List<CaregiverTrait> caregiverTraits = const [],
    String? caregiverTraitsOther,
    List<CaregiverNeed> feltNeeds = const [],
    List<CaregiverNeed> wishedNeeds = const [],
    List<LinkedEvent> linkedEvents = const [],
    String? linkedEventsOther,
  }) async {
    if (fullName.trim().isEmpty) {
      throw AppException(
        code: AppExceptionCodes.validation,
        message: 'Informe o nome da pessoa.',
      );
    }
    try {
      final row = await _client
          .from('genogram_people')
          .update(_personPayload(
            fullName: fullName,
            relationshipToPatient: relationshipToPatient,
            gender: gender,
            birthYear: birthYear,
            deathYear: deathYear,
            isDeceased: isDeceased,
            isSensitive: isSensitive,
            isCaregiver: isCaregiver,
            bondQuality: bondQuality,
            emotionalPresence: emotionalPresence,
            caregiverTraits: caregiverTraits,
            caregiverTraitsOther: caregiverTraitsOther,
            feltNeeds: feltNeeds,
            wishedNeeds: wishedNeeds,
            linkedEvents: linkedEvents,
            linkedEventsOther: linkedEventsOther,
            filledByRole: filledByRole,
          ))
          .eq('id', personId)
          .select(_peopleSelect)
          .single();
      return GenogramPersonEntry.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> deletePerson(String personId) async {
    try {
      await _client.from('genogram_people').delete().eq('id', personId);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Escrita — contexto familiar (clima + padrões)
  // ---------------------------------------------------------------------------

  Future<void> saveFamilyContext({
    required String patientId,
    required String filledByRole,
    List<FamilyClimateTrait> familyClimate = const [],
    String? familyClimateOther,
    List<TransgenerationalPattern> patterns = const [],
    String? patternsOther,
  }) async {
    try {
      await _client.from('patient_family_context').upsert(
        {
          'patient_id': patientId,
          'family_climate': familyClimate.isEmpty
              ? null
              : [for (final e in familyClimate) e.key],
          'family_climate_other': familyClimateOther,
          'transgenerational_patterns':
              patterns.isEmpty ? null : [for (final e in patterns) e.key],
          'transgenerational_patterns_other': patternsOther,
          'filled_by_profile_id': _currentProfileId,
          'filled_by_role': filledByRole,
        },
        onConflict: 'patient_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Escrita — comentário clínico por pessoa (staff-only)
  // ---------------------------------------------------------------------------

  Future<void> savePersonNote({
    required String patientId,
    required String personId,
    String? clinicalComment,
  }) async {
    try {
      await _client.from('genogram_person_notes').upsert(
        {
          'patient_id': patientId,
          'person_id': personId,
          'clinical_comment': (clinicalComment ?? '').trim().isEmpty
              ? null
              : clinicalComment!.trim(),
          'updated_by_profile_id': _currentProfileId,
        },
        onConflict: 'person_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
