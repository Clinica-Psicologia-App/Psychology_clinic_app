import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/genogram_data.dart';
import '../domain/genogram_family_patterns.dart';
import '../domain/genogram_person.dart';
import '../domain/genogram_person_input.dart';
import '../domain/genogram_relationship.dart';
import '../domain/genogram_relationship_input.dart';

class GenogramRepository {
  GenogramRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _personSelect =
      'id, clinic_id, patient_id, created_by, full_name, nickname, relationship_to_patient, gender, birth_year, death_year, is_deceased, notes, is_sensitive, created_at, updated_at';

  static const _relationshipSelect =
      'id, clinic_id, patient_id, created_by, person_a_id, person_b_id, relationship_type, notes, is_adoptive, is_sensitive, created_at, updated_at';

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

  Future<GenogramData> loadForPatient(String patientId) async {
    try {
      await _ensurePatientPerson(patientId);

      final peopleRows = await _client
          .from('genogram_people')
          .select(_personSelect)
          .eq('patient_id', patientId)
          .order('full_name');

      final relationshipRows = await _client
          .from('genogram_relationships')
          .select(_relationshipSelect)
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      final people = (peopleRows as List)
          .map((r) => GenogramPerson.fromJson(Map<String, dynamic>.from(r)))
          .toList();

      final relationships = (relationshipRows as List)
          .map(
            (r) => GenogramRelationship.fromJson(Map<String, dynamic>.from(r)),
          )
          .toList();

      return GenogramData(people: people, relationships: relationships);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<GenogramData> loadMyGenogram() async {
    final patientId = await getPatientIdForCurrentProfile();
    return loadForPatient(patientId);
  }

  Future<void> _ensurePatientPerson(String patientId) async {
    final existing = await _client
        .from('genogram_people')
        .select('id')
        .eq('patient_id', patientId)
        .eq('relationship_to_patient', 'Paciente')
        .limit(1);

    if ((existing as List).isNotEmpty) return;

    final patient = await _client
        .from('patients')
        .select('id, clinic_id, full_name')
        .eq('id', patientId)
        .maybeSingle();

    if (patient == null) return;

    final userId = _client.auth.currentUser?.id;
    await _client.from('genogram_people').insert({
      'clinic_id': patient['clinic_id'],
      'patient_id': patient['id'],
      if (userId != null) 'created_by': userId,
      'full_name': patient['full_name'],
      'nickname': null,
      'relationship_to_patient': 'Paciente',
      'is_deceased': false,
      'is_sensitive': false,
    });
  }

  Future<GenogramPerson?> getPersonById(String id) async {
    try {
      final row = await _client
          .from('genogram_people')
          .select(_personSelect)
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return GenogramPerson.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<GenogramRelationship?> getRelationshipById(String id) async {
    try {
      final row = await _client
          .from('genogram_relationships')
          .select(_relationshipSelect)
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return GenogramRelationship.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<GenogramFamilyPatterns> getFamilyPatterns(String patientId) async {
    try {
      final row = await _client
          .from('genogram_family_patterns')
          .select('patient_id, pattern_keys, other_text')
          .eq('patient_id', patientId)
          .maybeSingle();

      if (row == null) return GenogramFamilyPatterns.empty(patientId);
      return GenogramFamilyPatterns.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> saveFamilyPatterns({
    required String patientId,
    required Set<String> selectedKeys,
    String? otherText,
  }) async {
    final hasOther =
        selectedKeys.contains(GenogramFamilyPatternOption.other.key);
    final trimmedOther = otherText?.trim() ?? '';
    if (hasOther && trimmedOther.isEmpty) {
      throw AppException(
        code: AppExceptionCodes.validation,
        message: 'Descreva o outro padrão familiar percebido.',
      );
    }

    try {
      final ctx = await resolvePatientContext(patientId: patientId);
      await _client.from('genogram_family_patterns').upsert(
        {
          'clinic_id': ctx.clinicId,
          'patient_id': ctx.patientId,
          'pattern_keys': selectedKeys.toList()..sort(),
          'other_text': hasOther ? trimmedOther : null,
        },
        onConflict: 'patient_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<GenogramPerson> createPerson({
    required String clinicId,
    required String patientId,
    required GenogramPersonInput input,
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
          .from('genogram_people')
          .insert({
            'clinic_id': clinicId,
            'patient_id': patientId,
            if (userId != null) 'created_by': userId,
            ...input.toInsertJson(),
          })
          .select(_personSelect)
          .single();

      return GenogramPerson.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<GenogramPerson> updatePerson({
    required String id,
    required GenogramPersonInput input,
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
          .from('genogram_people')
          .update(input.toUpdateJson())
          .eq('id', id)
          .select(_personSelect)
          .single();

      return GenogramPerson.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<GenogramRelationship> createRelationship({
    required String clinicId,
    required String patientId,
    required GenogramRelationshipInput input,
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
          .from('genogram_relationships')
          .insert({
            'clinic_id': clinicId,
            'patient_id': patientId,
            if (userId != null) 'created_by': userId,
            ...input.toInsertJson(),
          })
          .select(_relationshipSelect)
          .single();

      return GenogramRelationship.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<GenogramRelationship> updateRelationship({
    required String id,
    required GenogramRelationshipInput input,
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
          .from('genogram_relationships')
          .update(input.toUpdateJson())
          .eq('id', id)
          .select(_relationshipSelect)
          .single();

      return GenogramRelationship.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
