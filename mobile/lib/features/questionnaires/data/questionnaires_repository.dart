import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/questionnaires/supported_questionnaire_codes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/edge_api_client.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/finish_questionnaire_result.dart';
import '../domain/questionnaire_access_item.dart';
import '../domain/questionnaire_patient_status.dart';
import '../domain/questionnaire_access_management_data.dart';
import '../domain/questionnaire_catalog_visibility.dart';
import '../domain/questionnaire_professional_option.dart';
import '../domain/questionnaire.dart';
import '../domain/questionnaire_question.dart';
import '../domain/questionnaire_response_context.dart';
import '../domain/questionnaire_session.dart';
import '../domain/question_answer_type.dart';

class QuestionnairesRepository {
  QuestionnairesRepository({
    SupabaseClient? client,
    EdgeApiClient? edgeApi,
  })  : _client = client ?? SupabaseBootstrap.client,
        _edgeApi = edgeApi ?? EdgeApiClient(client: client);

  final SupabaseClient _client;
  final EdgeApiClient _edgeApi;

  static const _accessSelect = 'questionnaire_id, is_enabled';

  /// Questionários ativos (RLS: `questionnaires_select_active`).
  Future<List<Questionnaire>> listVisibleQuestionnaires({
    required ProfileRole role,
    required String patientId,
  }) async {
    try {
      final catalog = await _listCatalogQuestionnaires();
      switch (role) {
        case ProfileRole.platformAdmin:
          return catalog;
        case ProfileRole.psychologist:
          final professionalId = _currentProfileId();
          final enabledIds = await _listEnabledQuestionnaireIdsForProfessional(
            professionalId,
          );
          return _filterCatalogByAccess(
            catalog,
            enabledIds: enabledIds,
            fallbackToAllWhenUnavailable: true,
          );
        case ProfileRole.patient:
          // O paciente só vê o que o psicólogo liberou PARA ELE (atribuições
          // ativas). Sem liberação, a lista fica vazia — nada "vaza" dos
          // grants admin→psicólogo direto para o paciente.
          final assignedIds =
              await listActiveAssignmentQuestionnaireIds(patientId);
          return catalog.where((q) => assignedIds.contains(q.id)).toList();
      }
    } on PostgrestException catch (e) {
      throw mapToAppException(e);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<QuestionnaireProfessionalOption>> listStaffOptions() async {
    try {
      final rows = await _client
          .from('profiles')
          .select('id, full_name, email, role')
          .eq('role', 'psychologist')
          .eq('is_active', true)
          .order('full_name');

      return (rows as List)
          .map(
            (row) => QuestionnaireProfessionalOption.fromJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<Questionnaire>> listQuestionnaireCatalogForAdmin() async {
    try {
      final rows = await _fetchQuestionnaireCatalogRows(
        onlyActive: false,
        withReferencePeriod: true,
        withCatalogMetadata: true,
      );
      return rows
          .map((row) => Questionnaire.fromJson(Map<String, dynamic>.from(row)))
          .toList();
    } on PostgrestException catch (e) {
      if (_isMissingCatalogMetadataError(e) ||
          _isMissingReferencePeriodColumn(e)) {
        final rows = await _fetchQuestionnaireCatalogRows(
          onlyActive: false,
          withReferencePeriod: false,
          withCatalogMetadata: false,
        );
        return rows
            .map(
              (row) => Questionnaire.fromJson(Map<String, dynamic>.from(row)),
            )
            .toList();
      }
      throw mapToAppException(e);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> createQuestionnaire({
    required String code,
    required String name,
    String? description,
    String? authorName,
    String? instrumentVersion,
    String? citation,
    String? licenseNotes,
    required QuestionnaireClinicalStatus clinicalStatus,
    required bool isActive,
  }) async {
    try {
      await _client.from('questionnaires').insert(
            _questionnairePayload(
              code: code,
              name: name,
              description: description,
              authorName: authorName,
              instrumentVersion: instrumentVersion,
              citation: citation,
              licenseNotes: licenseNotes,
              clinicalStatus: clinicalStatus,
              isActive: isActive,
            ),
          );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> updateQuestionnaire({
    required String questionnaireId,
    required String code,
    required String name,
    String? description,
    String? authorName,
    String? instrumentVersion,
    String? citation,
    String? licenseNotes,
    required QuestionnaireClinicalStatus clinicalStatus,
    required bool isActive,
  }) async {
    try {
      await _client
          .from('questionnaires')
          .update(
            _questionnairePayload(
              code: code,
              name: name,
              description: description,
              authorName: authorName,
              instrumentVersion: instrumentVersion,
              citation: citation,
              licenseNotes: licenseNotes,
              clinicalStatus: clinicalStatus,
              isActive: isActive,
            ),
          )
          .eq('id', questionnaireId);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> deleteQuestionnaire(String questionnaireId) async {
    try {
      final responseCount = await _countQuestionnaireResponses(questionnaireId);
      if (responseCount > 0) {
        throw AppException(
          code: AppExceptionCodes.validation,
          message: 'Este questionário já possui respostas clínicas. '
              'Para preservar histórico e resultados, inative o questionário '
              'em vez de excluir definitivamente.',
        );
      }

      await _client.from('questionnaires').delete().eq('id', questionnaireId);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<int> _countQuestionnaireResponses(String questionnaireId) async {
    final rows = await _client
        .from('questionnaire_responses')
        .select('id')
        .eq('questionnaire_id', questionnaireId)
        .limit(1);
    return (rows as List).length;
  }

  Future<List<QuestionnaireQuestion>> listQuestionsForAdmin(
    String questionnaireId,
  ) async {
    try {
      final rows = await _client
          .from('questions')
          .select(
            'id, code, text, order_index, answer_type, scale_min, scale_max',
          )
          .eq('questionnaire_id', questionnaireId)
          .order('order_index');

      return (rows as List)
          .map(
            (row) => QuestionnaireQuestion.fromJson(
              Map<String, dynamic>.from(row),
            ),
          )
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> createQuestion({
    required String questionnaireId,
    required String code,
    required String text,
    required int orderIndex,
    required QuestionAnswerType answerType,
    int? scaleMin,
    int? scaleMax,
  }) async {
    try {
      await _client.from('questions').insert(
            _questionPayload(
              questionnaireId: questionnaireId,
              code: code,
              text: text,
              orderIndex: orderIndex,
              answerType: answerType,
              scaleMin: scaleMin,
              scaleMax: scaleMax,
            ),
          );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> updateQuestion({
    required String questionId,
    required String questionnaireId,
    required String code,
    required String text,
    required int orderIndex,
    required QuestionAnswerType answerType,
    int? scaleMin,
    int? scaleMax,
  }) async {
    try {
      await _client
          .from('questions')
          .update(
            _questionPayload(
              questionnaireId: questionnaireId,
              code: code,
              text: text,
              orderIndex: orderIndex,
              answerType: answerType,
              scaleMin: scaleMin,
              scaleMax: scaleMax,
            ),
          )
          .eq('id', questionId);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<QuestionnaireAccessManagementData>
      listQuestionnaireAccessForProfessional(
    String professionalId,
  ) async {
    try {
      final catalog = await _listCatalogQuestionnaires();
      final enabledIds = await _listEnabledQuestionnaireIdsForProfessional(
        professionalId,
      );
      return QuestionnaireAccessManagementData(
        items: catalog
            .map(
              (questionnaire) => QuestionnaireAccessItem(
                questionnaire: questionnaire,
                isEnabled: enabledIds?.contains(questionnaire.id) ?? true,
              ),
            )
            .toList(),
        supportsAccessControl: enabledIds != null,
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> setQuestionnaireAccess({
    required String professionalId,
    required String questionnaireId,
    required bool isEnabled,
  }) async {
    try {
      final currentUserId = _currentProfileId();
      final clinicId = await _getProfessionalClinicId(professionalId);

      await _client.from('questionnaire_professional_access').upsert(
        {
          'clinic_id': clinicId,
          'questionnaire_id': questionnaireId,
          'professional_id': professionalId,
          'granted_by': currentUserId,
          'is_enabled': isEnabled,
        },
        onConflict: 'questionnaire_id,professional_id',
      );
    } on PostgrestException catch (e) {
      if (_isMissingQuestionnaireAccessSchemaError(e)) {
        throw AppException(
          code: AppExceptionCodes.validation,
          message: 'Controle de acesso dos questionários disponível após '
              'atualização do banco.',
          cause: e,
        );
      }
      throw mapToAppException(e);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<Questionnaire>> _listCatalogQuestionnaires() async {
    final rows = await _fetchActiveQuestionnaireRowsWithFallback();
    return rows
        .map((row) => Questionnaire.fromJson(Map<String, dynamic>.from(row)))
        .where(
            (questionnaire) => isSupportedQuestionnaireCode(questionnaire.code))
        .toList();
  }

  Future<List<dynamic>> _fetchActiveQuestionnaireRowsWithFallback() async {
    try {
      return await _fetchQuestionnaireCatalogRows(
        onlyActive: true,
        withReferencePeriod: true,
        withCatalogMetadata: true,
      );
    } on PostgrestException catch (e) {
      if (_isMissingCatalogMetadataError(e)) {
        try {
          return await _fetchQuestionnaireCatalogRows(
            onlyActive: true,
            withReferencePeriod: true,
            withCatalogMetadata: false,
          );
        } on PostgrestException catch (inner) {
          if (_isMissingReferencePeriodColumn(inner)) {
            return await _fetchQuestionnaireCatalogRows(
              onlyActive: true,
              withReferencePeriod: false,
              withCatalogMetadata: false,
            );
          }
          rethrow;
        }
      }

      if (_isMissingReferencePeriodColumn(e)) {
        return await _fetchQuestionnaireCatalogRows(
          onlyActive: true,
          withReferencePeriod: false,
          withCatalogMetadata: false,
        );
      }
      rethrow;
    }
  }

  Future<List<dynamic>> _fetchQuestionnaireCatalogRows({
    required bool onlyActive,
    required bool withReferencePeriod,
    required bool withCatalogMetadata,
  }) async {
    final fields = <String>[
      'id',
      'code',
      'name',
      'description',
      'is_active',
      if (withCatalogMetadata) ...[
        'author_name',
        'instrument_version',
        'citation',
        'license_notes',
        'clinical_status',
      ],
    ];

    if (withReferencePeriod) {
      var query = _client.from('questionnaires').select(
            '${fields.join(', ')}, '
            'questionnaire_versions!inner(reference_period)',
          );
      if (onlyActive) {
        query = query.eq('is_active', true);
      }
      return await query
          .eq('questionnaire_versions.status', 'active')
          .order('name');
    }

    var query = _client.from('questionnaires').select(fields.join(', '));
    if (onlyActive) {
      query = query.eq('is_active', true);
    }
    return await query.order('name');
  }

  Map<String, dynamic> _questionnairePayload({
    required String code,
    required String name,
    String? description,
    String? authorName,
    String? instrumentVersion,
    String? citation,
    String? licenseNotes,
    required QuestionnaireClinicalStatus clinicalStatus,
    required bool isActive,
  }) {
    String? nullableText(String? value) {
      final trimmed = value?.trim();
      return trimmed == null || trimmed.isEmpty ? null : trimmed;
    }

    return {
      'code': code.trim().toUpperCase(),
      'name': name.trim(),
      'description': nullableText(description),
      'author_name': nullableText(authorName),
      'instrument_version': nullableText(instrumentVersion),
      'citation': nullableText(citation),
      'license_notes': nullableText(licenseNotes),
      'clinical_status': clinicalStatus.storageValue,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> _questionPayload({
    required String questionnaireId,
    required String code,
    required String text,
    required int orderIndex,
    required QuestionAnswerType answerType,
    int? scaleMin,
    int? scaleMax,
  }) {
    return {
      'questionnaire_id': questionnaireId,
      'code': code.trim(),
      'text': text.trim(),
      'order_index': orderIndex,
      'answer_type': answerType.value,
      'scale_min': scaleMin,
      'scale_max': scaleMax,
      'is_active': true,
    };
  }

  bool _isMissingReferencePeriodColumn(PostgrestException e) {
    final message = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    return message.contains('reference_period');
  }

  bool _isMissingCatalogMetadataError(PostgrestException e) {
    final message = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    return message.contains('author_name') ||
        message.contains('instrument_version') ||
        message.contains('citation') ||
        message.contains('license_notes') ||
        message.contains('clinical_status');
  }

  bool _isMissingQuestionnaireAccessSchemaError(PostgrestException e) {
    final message = '${e.message} ${e.details} ${e.hint}'.toLowerCase();
    return message.contains('questionnaire_professional_access') ||
        message.contains('granted_by') ||
        message.contains('professional_id') ||
        message.contains('questionnaire_id');
  }

  /// `patients.id` do usuário logado (role patient).
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

  String _currentProfileId() {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw AppException(
        code: AppExceptionCodes.unauthorized,
        message: 'Sessão não encontrada.',
      );
    }
    return userId;
  }

  Future<String> _getProfessionalClinicId(String professionalId) async {
    final row = await _client
        .from('profiles')
        .select('clinic_id')
        .eq('id', professionalId)
        .eq('role', 'psychologist')
        .maybeSingle();

    final clinicId = row?['clinic_id'] as String?;
    if (clinicId == null) {
      throw AppException(
        code: AppExceptionCodes.unauthorized,
        message: 'Clínica do psicólogo não encontrada.',
      );
    }
    return clinicId;
  }

  Future<Set<String>?> _listEnabledQuestionnaireIdsForProfessional(
    String professionalId,
  ) async {
    try {
      final rows = await _client
          .from('questionnaire_professional_access')
          .select(_accessSelect)
          .eq('professional_id', professionalId)
          .eq('is_enabled', true);

      return (rows as List)
          .map((row) => row['questionnaire_id'] as String)
          .toSet();
    } on PostgrestException catch (e) {
      if (_isMissingQuestionnaireAccessSchemaError(e)) {
        return null;
      }
      rethrow;
    }
  }

  List<Questionnaire> _filterCatalogByAccess(
    List<Questionnaire> catalog, {
    required Set<String>? enabledIds,
    required bool fallbackToAllWhenUnavailable,
  }) {
    return visibleQuestionnairesFromEnabledIds(
      catalog,
      enabledIds: enabledIds,
      fallbackToAllWhenUnavailable: fallbackToAllWhenUnavailable,
    );
  }

  Future<QuestionnaireSession> startQuestionnaire({
    required String patientId,
    required String questionnaireId,
    List<QuestionnaireContextInput> contexts = const [],
  }) async {
    try {
      final data = await _edgeApi.invoke(
        'start-questionnaire',
        body: {
          'patient_id': patientId,
          'questionnaire_id': questionnaireId,
          if (contexts.isNotEmpty)
            'contexts': contexts.map((context) => context.toJson()).toList(),
        },
      );

      return QuestionnaireSession.fromStartResponse(data, patientId);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  // ── Liberação de questionários por paciente (atribuições) ─────────────────

  /// IDs dos questionários com atribuição ATIVA (não cancelada) para o paciente.
  /// RLS: staff lê dos pacientes que acessa; paciente lê as próprias.
  Future<Set<String>> listActiveAssignmentQuestionnaireIds(
      String patientId) async {
    try {
      final rows = await _client
          .from('patient_questionnaire_assignments')
          .select('questionnaire_id')
          .eq('patient_id', patientId)
          .isFilter('cancelled_at', null);
      return {
        for (final row in rows as List) row['questionnaire_id'] as String,
      };
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Libera (atribui) um questionário para um paciente. Valida acesso do
  /// psicólogo na edge (`assign-questionnaire`).
  Future<void> assignQuestionnaire({
    required String patientId,
    required String questionnaireId,
    String? message,
  }) async {
    try {
      await _edgeApi.invoke(
        'assign-questionnaire',
        body: {
          'patient_id': patientId,
          'questionnaire_id': questionnaireId,
          if (message != null && message.trim().isNotEmpty)
            'message': message.trim(),
        },
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Revoga a liberação: marca a(s) atribuição(ões) ativa(s) como cancelada(s).
  /// RLS restringe a staff dos pacientes que acessa.
  Future<void> cancelPatientAssignment({
    required String patientId,
    required String questionnaireId,
  }) async {
    try {
      await _client
          .from('patient_questionnaire_assignments')
          .update({'cancelled_at': DateTime.now().toUtc().toIso8601String()})
          .eq('patient_id', patientId)
          .eq('questionnaire_id', questionnaireId)
          .isFilter('cancelled_at', null);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> submitAnswer({
    required String responseId,
    required String questionId,
    required int answerValue,
    String? responseContextId,
  }) async {
    try {
      await _edgeApi.invoke(
        'submit-questionnaire-answer',
        body: {
          'response_id': responseId,
          'question_id': questionId,
          'answer_value': answerValue,
          if (responseContextId != null)
            'response_context_id': responseContextId,
        },
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Retorna o melhor status de resposta por questionário para o paciente.
  /// Prioridade: completed > draft.
  Future<Map<String, QuestionnairePatientStatus>> getPatientResponseStatuses(
    String patientId,
  ) async {
    try {
      final rows = await _client
          .from('questionnaire_responses')
          .select('questionnaire_id, status')
          .eq('patient_id', patientId)
          .inFilter('status', ['draft', 'completed']);

      final result = <String, QuestionnairePatientStatus>{};
      for (final row in rows as List) {
        final qId = row['questionnaire_id'] as String?;
        final statusStr = row['status'] as String?;
        if (qId == null || statusStr == null) continue;

        final status = statusStr == 'completed'
            ? QuestionnairePatientStatus.completed
            : QuestionnairePatientStatus.draft;

        if (status == QuestionnairePatientStatus.completed ||
            !result.containsKey(qId)) {
          result[qId] = status;
        }
      }
      return result;
    } on PostgrestException catch (e) {
      throw mapToAppException(e);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<FinishQuestionnaireResult> finishQuestionnaire({
    required String responseId,
    required String questionnaireName,
  }) async {
    try {
      final data = await _edgeApi.invoke(
        'finish-questionnaire',
        body: {'response_id': responseId},
      );

      return FinishQuestionnaireResult.fromApi(data, questionnaireName);
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
