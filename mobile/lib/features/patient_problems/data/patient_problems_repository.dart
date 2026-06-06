import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/patient_problem.dart';
import '../domain/patient_problem_input.dart';
import '../domain/patient_problem_status.dart';

class PatientProblemsRepository {
  PatientProblemsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _select =
      'id, clinic_id, patient_id, created_by, title, description, category, intensity, status, identified_at, resolved_at, created_at, updated_at';

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

  Future<List<PatientProblem>> listForPatient(String patientId) async {
    try {
      final rows = await _client
          .from('patient_problems')
          .select(_select)
          .eq('patient_id', patientId)
          .order('updated_at', ascending: false);

      return (rows as List)
          .map((r) => PatientProblem.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<PatientProblem>> listMyProblems() async {
    final patientId = await getPatientIdForCurrentProfile();
    return listForPatient(patientId);
  }

  Future<PatientProblem?> getById(String id) async {
    try {
      final row = await _client
          .from('patient_problems')
          .select(_select)
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return PatientProblem.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<PatientProblem> create({
    required String clinicId,
    required String patientId,
    required PatientProblemInput input,
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
          .from('patient_problems')
          .insert({
            'clinic_id': clinicId,
            'patient_id': patientId,
            if (userId != null) 'created_by': userId,
            ...input.toInsertJson(),
          })
          .select(_select)
          .single();

      return PatientProblem.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<PatientProblem> updateAsPatient({
    required String id,
    required PatientProblemInput input,
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
          .from('patient_problems')
          .update(input.toPatientUpdateJson())
          .eq('id', id)
          .select(_select)
          .single();

      return PatientProblem.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<PatientProblem> updateAsStaff({
    required String id,
    required PatientProblemInput input,
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
          .from('patient_problems')
          .update(input.toStaffUpdateJson())
          .eq('id', id)
          .select(_select)
          .single();

      return PatientProblem.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<PatientProblem> updateStatus({
    required String id,
    required PatientProblemStatus status,
  }) async {
    try {
      final row = await _client
          .from('patient_problems')
          .update({'status': status.storageValue})
          .eq('id', id)
          .select(_select)
          .single();

      return PatientProblem.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
