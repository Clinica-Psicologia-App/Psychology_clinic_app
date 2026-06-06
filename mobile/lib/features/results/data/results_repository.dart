import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/questionnaires/supported_questionnaire_codes.dart';
import '../../../core/network/edge_api_client.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/patient_response_summary.dart';
import '../domain/patient_result_detail.dart';

class ResultsRepository {
  ResultsRepository({
    SupabaseClient? client,
    EdgeApiClient? edgeApi,
  })  : _client = client ?? SupabaseBootstrap.client,
        _edgeApi = edgeApi ?? EdgeApiClient(client: client);

  final SupabaseClient _client;
  final EdgeApiClient _edgeApi;

  static const _listSelect = '''
id,
status,
started_at,
completed_at,
created_at,
questionnaire_id,
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
questionnaire:questionnaires(id, code, name, description),
questionnaire_answers(
  id,
  question_id,
  response_context:questionnaire_response_contexts(context_label),
  answer_value,
  question:questions(id, code, text, order_index, answer_type, scale_min, scale_max)
),
questionnaire_results(
  id,
  category_id,
  total_score,
  average_score,
  classification,
  snapshot,
  category:question_categories(id, code, name)
)
''';

  /// Respostas do paciente (RLS: staff com acesso ao paciente).
  Future<List<PatientResponseSummary>> listPatientResponses(
    String patientId,
  ) async {
    try {
      final rows = await _client
          .from('questionnaire_responses')
          .select(_listSelect)
          .eq('patient_id', patientId)
          .order('created_at', ascending: false);

      return (rows as List)
          .map(
            (row) => PatientResponseSummary.fromJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .where(
            (summary) => isSupportedQuestionnaireCode(summary.questionnaireCode),
          )
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Detalhe de uma resposta (RLS via `user_can_access_response`).
  Future<PatientResultDetail?> getResponseDetail(String responseId) async {
    try {
      final row = await _client
          .from('questionnaire_responses')
          .select(_detailSelect)
          .eq('id', responseId)
          .maybeSingle();

      if (row == null) return null;
      final detail = PatientResultDetail.fromJson(Map<String, dynamic>.from(row));
      if (!isSupportedQuestionnaireCode(detail.questionnaireCode)) {
        return null;
      }
      return detail;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> setResponseReviewed({
    required String responseId,
    required bool reviewed,
    String? reviewNotes,
  }) async {
    try {
      await _edgeApi.invoke(
        'review-questionnaire-response',
        body: {
          'response_id': responseId,
          'reviewed': reviewed,
          'review_notes': reviewNotes,
        },
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
