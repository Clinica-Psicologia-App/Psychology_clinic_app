import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/questionnaire_catalog_admin.dart';

class QuestionnaireCatalogAdminRepository {
  QuestionnaireCatalogAdminRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  Future<List<QuestionnaireCatalogAdminItem>> list() async {
    try {
      final rows = await _client.rpc('admin_list_questionnaires');
      return (rows as List)
          .map((row) => QuestionnaireCatalogAdminItem.fromJson(
              Map<String, dynamic>.from(row as Map)))
          .toList();
    } catch (error) {
      throw mapToAppException(error);
    }
  }

  Future<QuestionnaireCatalogDetail> get(String id) async {
    try {
      final data = await _client
          .rpc('admin_get_questionnaire', params: {'p_questionnaire_id': id});
      return QuestionnaireCatalogDetail.fromJson(
          Map<String, dynamic>.from(data as Map));
    } catch (error) {
      throw mapToAppException(error);
    }
  }

  Future<String> saveDraft(QuestionnaireDraftInput input) async {
    try {
      return await _client.rpc('admin_save_questionnaire_draft', params: {
        'p_id': input.id,
        'p_code': input.code,
        'p_name': input.name,
        'p_description': input.description,
        'p_author_name': input.authorName,
        'p_instrument_version': input.version,
        'p_citation': input.citation,
        'p_license_notes': input.licenseNotes,
        'p_reference_period': input.referencePeriod,
        'p_scale_min': input.scaleMin,
        'p_scale_max': input.scaleMax,
      }) as String;
    } catch (error) {
      throw mapToAppException(error);
    }
  }

  Future<void> saveQuestion({
    required String questionnaireId,
    String? questionId,
    required String code,
    required String text,
    required int orderIndex,
    required String answerType,
    required int scaleMin,
    required int scaleMax,
    required double weight,
    required bool reverseScore,
  }) async {
    try {
      await _client.rpc('admin_save_question', params: {
        'p_questionnaire_id': questionnaireId,
        'p_question_id': questionId,
        'p_code': code,
        'p_text': text,
        'p_order_index': orderIndex,
        'p_answer_type': answerType,
        'p_scale_min': scaleMin,
        'p_scale_max': scaleMax,
        'p_weight': weight,
        'p_reverse_score': reverseScore,
      });
    } catch (error) {
      throw mapToAppException(error);
    }
  }

  Future<void> deleteQuestion(String questionnaireId, String questionId) =>
      _call('admin_delete_question', {
        'p_questionnaire_id': questionnaireId,
        'p_question_id': questionId,
      });

  Future<void> publish(String id) =>
      _call('admin_publish_questionnaire', {'p_questionnaire_id': id});

  Future<void> archive(String id) =>
      _call('admin_archive_questionnaire', {'p_questionnaire_id': id});

  Future<void> deleteDraft(String id) =>
      _call('admin_delete_questionnaire_draft', {'p_questionnaire_id': id});

  /// Cria uma versão rascunho editável de um instrumento publicado.
  /// As respostas existentes permanecem fixadas na versão anterior.
  Future<void> createDraftVersion(String id) =>
      _call('admin_create_draft_version', {'p_questionnaire_id': id});

  /// Descarta a versão rascunho de um publicado (a ativa segue intocada).
  Future<void> discardDraftVersion(String id) =>
      _call('admin_discard_draft_version', {'p_questionnaire_id': id});

  Future<String> duplicate({
    required String id,
    required String code,
    required String version,
  }) async {
    try {
      return await _client
          .rpc('admin_duplicate_questionnaire_as_draft', params: {
        'p_questionnaire_id': id,
        'p_new_code': code,
        'p_new_version': version,
      }) as String;
    } catch (error) {
      throw mapToAppException(error);
    }
  }

  Future<void> _call(String function, Map<String, dynamic> params) async {
    try {
      await _client.rpc(function, params: params);
    } catch (error) {
      throw mapToAppException(error);
    }
  }
}
