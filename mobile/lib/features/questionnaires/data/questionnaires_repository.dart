import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/questionnaires/supported_questionnaire_codes.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/edge_api_client.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/finish_questionnaire_result.dart';
import '../domain/questionnaire_access_item.dart';
import '../domain/questionnaire_access_management_data.dart';
import '../domain/questionnaire_catalog_visibility.dart';
import '../domain/questionnaire_professional_option.dart';
import '../domain/questionnaire.dart';
import '../domain/questionnaire_response_context.dart';
import '../domain/questionnaire_session.dart';

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
        case ProfileRole.admin:
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
          final professionalId = await _getResponsiblePsychologistId(patientId);
          final enabledIds = await _listEnabledQuestionnaireIdsForProfessional(
            professionalId,
          );
          return _filterCatalogByAccess(
            catalog,
            enabledIds: enabledIds,
            fallbackToAllWhenUnavailable: true,
          );
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
          .or('role.eq.admin,role.eq.psychologist')
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

  Future<QuestionnaireAccessManagementData> listQuestionnaireAccessForProfessional(
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
      final clinicId = await _getCurrentClinicId();

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
        .where((questionnaire) => isSupportedQuestionnaireCode(questionnaire.code))
        .toList();
  }

  Future<List<dynamic>> _fetchActiveQuestionnaireRowsWithFallback() async {
    try {
      return await _fetchActiveQuestionnaireRows(
        withReferencePeriod: true,
        withCatalogMetadata: true,
      );
    } on PostgrestException catch (e) {
      if (_isMissingCatalogMetadataError(e)) {
        try {
          return await _fetchActiveQuestionnaireRows(
            withReferencePeriod: true,
            withCatalogMetadata: false,
          );
        } on PostgrestException catch (inner) {
          if (_isMissingReferencePeriodColumn(inner)) {
            return await _fetchActiveQuestionnaireRows(
              withReferencePeriod: false,
              withCatalogMetadata: false,
            );
          }
          rethrow;
        }
      }

      if (_isMissingReferencePeriodColumn(e)) {
        return await _fetchActiveQuestionnaireRows(
          withReferencePeriod: false,
          withCatalogMetadata: false,
        );
      }
      rethrow;
    }
  }

  Future<List<dynamic>> _fetchActiveQuestionnaireRows({
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
      ],
    ];

    if (withReferencePeriod) {
      return await _client
          .from('questionnaires')
          .select(
            '${fields.join(', ')}, '
            'questionnaire_versions!inner(reference_period)',
          )
          .eq('is_active', true)
          .eq('questionnaire_versions.status', 'active')
          .order('name');
    }

    return await _client
        .from('questionnaires')
        .select(fields.join(', '))
        .eq('is_active', true)
        .order('name');
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
        message.contains('license_notes');
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

  Future<String> _getCurrentClinicId() async {
    final row = await _client
        .from('profiles')
        .select('clinic_id')
        .eq('id', _currentProfileId())
        .maybeSingle();

    final clinicId = row?['clinic_id'] as String?;
    if (clinicId == null) {
      throw AppException(
        code: AppExceptionCodes.unauthorized,
        message: 'Clínica do usuário não encontrada.',
      );
    }
    return clinicId;
  }

  Future<String> _getResponsiblePsychologistId(String patientId) async {
    final row = await _client
        .from('patients')
        .select('responsible_psychologist_id')
        .eq('id', patientId)
        .maybeSingle();

    final professionalId = row?['responsible_psychologist_id'] as String?;
    if (professionalId == null) {
      throw AppException(
        code: AppExceptionCodes.notFound,
        message: 'Psicólogo responsável não encontrado para este paciente.',
      );
    }
    return professionalId;
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
          if (responseContextId != null) 'response_context_id': responseContextId,
        },
      );
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
