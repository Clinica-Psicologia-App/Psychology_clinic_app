import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/daily_monitor.dart';
import '../domain/daily_monitor_input.dart';

class DailyMonitorsRepository {
  DailyMonitorsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _select =
      'id, clinic_id, patient_id, mood_notes, sleep_notes, activity_notes, emotion_notes, created_at, updated_at';

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

  Future<List<DailyMonitor>> listForPatient(String patientId) async {
    try {
      final rows = await _client
          .from('daily_monitors')
          .select(_select)
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (rows as List)
          .map((r) => DailyMonitor.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<DailyMonitor>> listMyMonitors() async {
    final patientId = await getPatientIdForCurrentProfile();
    return listForPatient(patientId);
  }

  Future<DailyMonitor?> getById(String id) async {
    try {
      final row = await _client
          .from('daily_monitors')
          .select(_select)
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return DailyMonitor.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<DailyMonitor> create({
    required String clinicId,
    required String patientId,
    required DailyMonitorInput input,
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
          .from('daily_monitors')
          .insert({
            'clinic_id': clinicId,
            'patient_id': patientId,
            ...input.toRowJson(),
          })
          .select(_select)
          .single();

      return DailyMonitor.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<DailyMonitor> update({
    required String id,
    required DailyMonitorInput input,
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
          .from('daily_monitors')
          .update(input.toRowJson())
          .eq('id', id)
          .select(_select)
          .single();

      return DailyMonitor.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
