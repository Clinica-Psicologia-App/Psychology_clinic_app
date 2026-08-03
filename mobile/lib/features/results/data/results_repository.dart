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

  static const _listSelect = '''
id,
status,
started_at,
completed_at,
created_at,
questionnaire_id,
reviewed_at,
review_notes,
reviewed_by:profiles!questionnaire_responses_reviewed_by_profile_id_fkey(full_name),
questionnaire:questionnaires(id, code, name),
questionnaire_answers(count),
questionnaire_results(count)
''';

  static const _detailSelect = '''
id,
patient_id,
questionnaire_id,
status,
started_at,
completed_at,
reviewed_at,
review_notes,
reviewed_by:profiles!questionnaire_responses_reviewed_by_profile_id_fkey(full_name),
questionnaire:questionnaires(id, code, name, description),
questionnaire_answers(
  id,
  question_id,
  response_context:questionnaire_response_contexts(context_label),
  answer_value,
  professional_value,
  professional_note,
  question:questions(id, code, text, order_index, answer_type, scale_min, scale_max)
),
questionnaire_results(
  id,
  category_id,
  total_score,
  average_score,
  classification,
  professional_average_score,
  professional_note,
  snapshot,
  category:question_categories(id, code, name)
)
''';

  /// Respostas do paciente (RLS: staff com acesso ao paciente).
  Future<List<PatientResponseSummary>> listPatientResponses(
    String patientId, {
    bool onlyReviewed = false,
  }) async {
    try {
      var query = _client
          .from('questionnaire_responses')
          .select(_listSelect)
          .eq('patient_id', patientId);

      if (onlyReviewed) {
        query = query.not('reviewed_at', 'is', null);
      }

      final rows = await query.order('created_at', ascending: false);

      return (rows as List)
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
      var query = _client
          .from('questionnaire_responses')
          .select(_detailSelect)
          .eq('id', responseId);

      if (requireReviewed) {
        query = query.not('reviewed_at', 'is', null);
      }

      final row = await query.maybeSingle();

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

  static const _activationSelectBase = '''
id,
questionnaire_response_id,
schema_code,
schema_name,
activated_by_profile_id,
created_at
''';

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
      final rows = await _client
          .from('questionnaire_schema_activations')
          .select(
            includeObservation ? _activationSelectStaff : _activationSelectBase,
          )
          .eq('questionnaire_response_id', responseId);
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
