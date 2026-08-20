import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../initial_assessment/data/initial_assessment_repository.dart';
import '../../profile/domain/profile_role.dart';
import '../../questionnaires/data/questionnaires_repository.dart';
import '../domain/patient_journey_progress.dart';

/// Leituras agregadas para a trilha do paciente (sem alterar outros módulos).
class PatientJourneyRepository {
  PatientJourneyRepository({
    SupabaseClient? client,
    QuestionnairesRepository? questionnairesRepository,
    InitialAssessmentRepository? initialAssessmentRepository,
  })  : _client = client ?? SupabaseBootstrap.client,
        _questionnairesRepository = questionnairesRepository ??
            QuestionnairesRepository(client: client),
        _initialAssessmentRepository =
            initialAssessmentRepository ?? InitialAssessmentRepository(client: client);

  final SupabaseClient _client;
  final QuestionnairesRepository _questionnairesRepository;
  final InitialAssessmentRepository _initialAssessmentRepository;

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

  Future<PatientJourneyProgress> loadProgress(String patientId) async {
    try {
      final visibleQuestionnaires =
          await _questionnairesRepository.listVisibleQuestionnaires(
        role: ProfileRole.patient,
        patientId: patientId,
      );
      final activeIds = visibleQuestionnaires.map((item) => item.id).toSet();

      final completedRows = await _client
          .from('questionnaire_responses')
          .select(
            'questionnaire_id, questionnaire:questionnaires(code), questionnaire_results(count)',
          )
          .eq('patient_id', patientId)
          .eq('status', 'completed');

      var hasYsqStructuredResult = false;
      var hasYamiStructuredResult = false;

      final completedQuestionnaireIds = <String>{};
      for (final row in completedRows as List) {
        final qId = row['questionnaire_id'] as String?;
        if (qId != null && activeIds.contains(qId)) {
          completedQuestionnaireIds.add(qId);
        }

        final hasResults = _embeddedCount(row['questionnaire_results']) > 0;
        if (!hasResults) continue;

        final questionnaire = row['questionnaire'];
        String? code;
        if (questionnaire is Map) {
          code = questionnaire['code'] as String?;
        }
        final upper = code?.toUpperCase() ?? '';
        if (upper.contains('YSQ')) hasYsqStructuredResult = true;
        if (upper.contains('YAMI')) hasYamiStructuredResult = true;
      }

      final monitorRows = await _client
          .from('daily_monitors')
          .select('created_at')
          .eq('patient_id', patientId)
          .order('created_at', ascending: false)
          .limit(30);

      final hasMonitorToday =
          _hasRecordToday(monitorRows as List, 'created_at');

      final accessRows = await _client
          .from('patient_resource_access')
          .select('completed_at')
          .eq('patient_id', patientId)
          .eq('is_active', true);

      var released = 0;
      var completedResources = 0;
      for (final row in accessRows as List) {
        released++;
        if (row['completed_at'] != null) completedResources++;
      }

      final goalRows = await _client
          .from('therapy_goals')
          .select('status')
          .eq('patient_id', patientId);

      var activeGoals = 0;
      var completedGoals = 0;
      for (final row in goalRows as List) {
        switch (row['status'] as String?) {
          case 'active':
            activeGoals++;
          case 'completed':
            completedGoals++;
          default:
            break;
        }
      }

      final problemRows = await _client
          .from('patient_problems')
          .select('status')
          .eq('patient_id', patientId);

      var openProblems = 0;
      for (final row in problemRows as List) {
        final status = row['status'] as String?;
        if (status == 'active' || status == 'improved') {
          openProblems++;
        }
      }

      final checkInRows = await _client
          .from('patient_check_ins')
          .select('checked_in_at')
          .eq('patient_id', patientId)
          .order('checked_in_at', ascending: false)
          .limit(30);

      final checkInCount = (checkInRows as List).length;
      final hasCheckInToday = _hasRecordToday(checkInRows, 'checked_in_at');

      final monitorCountRows = await _client
          .from('daily_monitors')
          .select('id')
          .eq('patient_id', patientId);

      final dailyMonitorCount = (monitorCountRows as List).length;

      final timelineRows = await _client
          .from('patient_timeline_events')
          .select('id')
          .eq('patient_id', patientId);

      final genogramPeopleRows = await _client
          .from('genogram_people')
          .select('id')
          .eq('patient_id', patientId);

      final genogramRelRows = await _client
          .from('genogram_relationships')
          .select('id')
          .eq('patient_id', patientId);

      final initialAssessment =
          await _initialAssessmentRepository.load(patientId);

      return PatientJourneyProgress(
        activeQuestionnaireCount: activeIds.length,
        completedQuestionnaireCount: completedQuestionnaireIds.length,
        hasMonitorToday: hasMonitorToday,
        releasedResourceCount: released,
        completedResourceCount: completedResources,
        activeTherapyGoalCount: activeGoals,
        completedTherapyGoalCount: completedGoals,
        totalProblemCount: (problemRows as List).length,
        openProblemCount: openProblems,
        hasCheckInToday: hasCheckInToday,
        timelineEventCount: (timelineRows as List).length,
        genogramPeopleCount: (genogramPeopleRows as List).length,
        genogramRelationshipCount: (genogramRelRows as List).length,
        checkInCount: checkInCount,
        dailyMonitorCount: dailyMonitorCount,
        hasYsqStructuredResult: hasYsqStructuredResult,
        hasYamiStructuredResult: hasYamiStructuredResult,
        initialAssessmentFraction: initialAssessment.completionFraction,
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  int _embeddedCount(dynamic embedded) {
    if (embedded is List) {
      if (embedded.isEmpty) return 0;
      final first = embedded.first;
      if (first is Map && first.containsKey('count')) {
        final c = first['count'];
        if (c is int) return c;
        if (c is num) return c.toInt();
      }
      return embedded.length;
    }
    if (embedded is Map && embedded.containsKey('count')) {
      final c = embedded['count'];
      if (c is int) return c;
      if (c is num) return c.toInt();
    }
    return 0;
  }

  bool _hasRecordToday(List<dynamic> rows, String timestampField) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (final row in rows) {
      final raw = row[timestampField];
      if (raw is! String) continue;
      final created = DateTime.parse(raw).toLocal();
      final day = DateTime(created.year, created.month, created.day);
      if (day == today) return true;
    }
    return false;
  }
}
