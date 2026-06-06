import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/therapy_goal.dart';
import '../domain/therapy_goal_input.dart';
import '../domain/therapy_goal_status.dart';

class TherapyGoalsRepository {
  TherapyGoalsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _select =
      'id, clinic_id, patient_id, created_by, title, description, status, target_date, completed_at, created_at, updated_at';

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

  Future<List<TherapyGoal>> listForPatient(String patientId) async {
    try {
      final rows = await _client
          .from('therapy_goals')
          .select(_select)
          .eq('patient_id', patientId)
          .order('updated_at', ascending: false);

      return (rows as List)
          .map((r) => TherapyGoal.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<TherapyGoal>> listMyGoals() async {
    final patientId = await getPatientIdForCurrentProfile();
    return listForPatient(patientId);
  }

  Future<TherapyGoal?> getById(String id) async {
    try {
      final row = await _client
          .from('therapy_goals')
          .select(_select)
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return TherapyGoal.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<TherapyGoal> create({
    required String clinicId,
    required String patientId,
    required TherapyGoalInput input,
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
          .from('therapy_goals')
          .insert({
            'clinic_id': clinicId,
            'patient_id': patientId,
            if (userId != null) 'created_by': userId,
            ...input.toInsertJson(),
          })
          .select(_select)
          .single();

      return TherapyGoal.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<TherapyGoal> updateAsPatient({
    required String id,
    required TherapyGoalInput input,
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
          .from('therapy_goals')
          .update(input.toPatientUpdateJson())
          .eq('id', id)
          .select(_select)
          .single();

      return TherapyGoal.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<TherapyGoal> updateAsStaff({
    required String id,
    required TherapyGoalInput input,
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
          .from('therapy_goals')
          .update(input.toStaffUpdateJson())
          .eq('id', id)
          .select(_select)
          .single();

      return TherapyGoal.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<TherapyGoal> updateStatus({
    required String id,
    required TherapyGoalStatus status,
  }) async {
    try {
      final row = await _client
          .from('therapy_goals')
          .update({'status': status.storageValue})
          .eq('id', id)
          .select(_select)
          .single();

      return TherapyGoal.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
