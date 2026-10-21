import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/exercise_definition.dart';

class ExerciseRepository {
  ExerciseRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _table = 'psychoeducation_exercise_responses';

  /// Receives patients.id; exercise responses instead reference profiles.id.
  /// Both queries retain the signed-in user's RLS restrictions.
  Future<List<ExerciseResponse>> listPatientResponses(String patientId) async {
    try {
      final patient = await _client
          .from('patients')
          .select('profile_id')
          .eq('id', patientId)
          .maybeSingle();
      if (patient == null) {
        throw AppException(
            code: AppExceptionCodes.notFound,
            message: 'Paciente não encontrado ou sem acesso.');
      }
      final profileId = patient['profile_id'] as String?;
      if (profileId == null) return [];
      final rows = await _client
          .from(_table)
          .select()
          .eq('patient_id', profileId)
          .order('updated_at', ascending: false);
      return rows.map((row) => ExerciseResponse.fromJson(row)).toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<ExerciseResponse?> getResponse(String moduleId) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      final rows = await _client
          .from(_table)
          .select()
          .eq('patient_id', userId)
          .eq('module_id', moduleId)
          .limit(1);
      if (rows.isEmpty) return null;
      return ExerciseResponse.fromJson(Map<String, dynamic>.from(rows.first));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<ExerciseResponse> saveResponse({
    required String moduleId,
    required Map<String, dynamic> responses,
    String? difficultyScale,
    bool? wantsToTalk,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado');
      final payload = {
        'patient_id': userId,
        'module_id': moduleId,
        'responses': responses,
        if (difficultyScale != null) 'difficulty_scale': difficultyScale,
        if (wantsToTalk != null) 'wants_to_talk': wantsToTalk,
        'updated_at': DateTime.now().toIso8601String(),
      };
      final rows = await _client
          .from(_table)
          .upsert(payload, onConflict: 'patient_id,module_id')
          .select();
      return ExerciseResponse.fromJson(Map<String, dynamic>.from(rows.first));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Reads one response using profiles.id (not patients.id).
  Future<ExerciseResponse?> getPatientResponse({
    required String patientId,
    required String moduleId,
  }) async {
    try {
      final rows = await _client
          .from(_table)
          .select()
          .eq('patient_id', patientId)
          .eq('module_id', moduleId)
          .limit(1);
      if (rows.isEmpty) return null;
      return ExerciseResponse.fromJson(Map<String, dynamic>.from(rows.first));
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
