import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/patient_check_in.dart';
import '../domain/patient_check_in_input.dart';

class PatientCheckInsRepository {
  PatientCheckInsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _select =
      'id, clinic_id, patient_id, created_by, mood_score, anxiety_score, energy_score, problem_intensity_score, notes, checked_in_at, created_at, updated_at';

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

  Future<List<PatientCheckIn>> listForPatient(String patientId) async {
    try {
      final rows = await _client
          .from('patient_check_ins')
          .select(_select)
          .eq('patient_id', patientId)
          .order('checked_in_at', ascending: false);

      return (rows as List)
          .map((r) => PatientCheckIn.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<PatientCheckIn>> listMyCheckIns() async {
    final patientId = await getPatientIdForCurrentProfile();
    return listForPatient(patientId);
  }

  Future<PatientCheckIn?> findTodayForCurrentPatient() async {
    final items = await listMyCheckIns();
    for (final item in items) {
      if (item.isToday) return item;
    }
    return null;
  }

  Future<PatientCheckIn?> getById(String id) async {
    try {
      final row = await _client
          .from('patient_check_ins')
          .select(_select)
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return PatientCheckIn.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<PatientCheckIn> create({
    required String clinicId,
    required String patientId,
    required PatientCheckInInput input,
  }) async {
    final validation = input.validate();
    if (validation != null) {
      throw AppException(
        code: AppExceptionCodes.validation,
        message: validation,
      );
    }

    try {
      final userId = _client.auth.currentUser?.id;
      final row = await _client
          .from('patient_check_ins')
          .insert({
            'clinic_id': clinicId,
            'patient_id': patientId,
            if (userId != null) 'created_by': userId,
            ...input.toRowJson(),
          })
          .select(_select)
          .single();

      return PatientCheckIn.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<PatientCheckIn> update({
    required String id,
    required PatientCheckInInput input,
    required PatientCheckIn existing,
  }) async {
    if (!existing.isEditableToday) {
      throw AppException(
        code: AppExceptionCodes.validation,
        message: 'Só é possível editar o check-in de hoje.',
      );
    }

    final validation = input.validate();
    if (validation != null) {
      throw AppException(
        code: AppExceptionCodes.validation,
        message: validation,
      );
    }

    try {
      final row = await _client
          .from('patient_check_ins')
          .update(input.toRowJson())
          .eq('id', id)
          .select(_select)
          .single();

      return PatientCheckIn.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
