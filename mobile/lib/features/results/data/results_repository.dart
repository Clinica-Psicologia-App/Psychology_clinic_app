import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/questionnaires/supported_questionnaire_codes.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/patient_response_summary.dart';
import '../domain/patient_result_detail.dart';
import '../domain/schema_activation.dart';

class ResultsRepository {
  ResultsRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  /// Respostas do paciente (RLS: staff com acesso ao paciente).
  Future<List<PatientResponseSummary>> listPatientResponses(
    String patientId, {
    bool onlyReviewed = false,
  }) async {
    try {
      final payload = await _client.rpc(
        'list_questionnaire_response_summaries',
        params: {'p_patient_id': patientId},
      );
      final rows = (payload as List)
          .where(
            (row) => !onlyReviewed || row['reviewed_at'] != null,
          )
          .toList();
      return rows
          .map(
            (row) => PatientResponseSummary.fromJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .where(
            (summary) =>
                isSupportedQuestionnaireCode(summary.questionnaireCode),
          )
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Detalhe de uma resposta (RLS via `user_can_access_response`).
  Future<PatientResultDetail?> getResponseDetail(
    String responseId, {
    bool requireReviewed = false,
  }) async {
    try {
      final payload = await _client.rpc(
        'get_questionnaire_response_detail',
        params: {'p_response_id': responseId},
      );
      final row = payload as Map?;
      if (requireReviewed && row?['reviewed_at'] == null) return null;
      if (row == null) return null;
      final detail =
          PatientResultDetail.fromJson(Map<String, dynamic>.from(row));
      if (!isSupportedQuestionnaireCode(detail.questionnaireCode)) {
        return null;
      }
      return detail;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  // ── Schema activations (régua manual) ──────────────────────────────────

  static const _activationSelectStaff = '''
id,
questionnaire_response_id,
schema_code,
schema_name,
psi_observation,
activated_by_profile_id,
created_at
''';

  Future<List<SchemaActivation>> listSchemaActivations(
    String responseId, {
    bool includeObservation = false,
  }) async {
    try {
      final rows = includeObservation
          ? await _client
              .from('questionnaire_schema_activations')
              .select(_activationSelectStaff)
              .eq('questionnaire_response_id', responseId)
          : await _client.rpc('get_patient_schema_activations',
              params: {'p_response_id': responseId});
      return (rows as List)
          .map(
            (r) =>
                SchemaActivation.fromJson(Map<String, dynamic>.from(r as Map)),
          )
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> saveSchemaActivation({
    required String responseId,
    required String schemaCode,
    required String schemaName,
    String? psiObservation,
  }) async {
    try {
      await _client.from('questionnaire_schema_activations').upsert(
        {
          'questionnaire_response_id': responseId,
          'schema_code': schemaCode,
          'schema_name': schemaName,
          if (psiObservation != null && psiObservation.trim().isNotEmpty)
            'psi_observation': psiObservation.trim()
          else
            'psi_observation': null,
        },
        onConflict: 'questionnaire_response_id,schema_code',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> deleteSchemaActivation({
    required String responseId,
    required String schemaCode,
  }) async {
    try {
      await _client
          .from('questionnaire_schema_activations')
          .delete()
          .eq('questionnaire_response_id', responseId)
          .eq('schema_code', schemaCode);
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
