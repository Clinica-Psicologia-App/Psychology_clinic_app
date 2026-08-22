import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../clinical_dashboard/providers/clinical_dashboard_providers.dart';
import '../../mental_map/providers/mental_map_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../../results/providers/results_providers.dart';
import '../data/questionnaires_repository.dart';
import '../domain/finish_questionnaire_result.dart';
import '../domain/questionnaire_access_management_data.dart';
import '../domain/questionnaire_patient_status.dart';
import '../domain/questionnaire_professional_option.dart';
import '../domain/questionnaire.dart';
import '../domain/questionnaire_question.dart';
import '../domain/questionnaire_response_context.dart';
import '../domain/questionnaire_session.dart';

final questionnairesRepositoryProvider =
    Provider<QuestionnairesRepository>((ref) {
  return QuestionnairesRepository();
});

/// Resolve `patients.id` para a tela de listagem.
final questionnairePatientIdProvider =
    FutureProvider.family<String, QuestionnaireListContext>((ref, ctx) async {
  final repo = ref.read(questionnairesRepositoryProvider);
  if (ctx.patientId != null) return ctx.patientId!;
  return repo.getPatientIdForCurrentProfile();
});

final questionnairesListProvider =
    FutureProvider.family<List<Questionnaire>, QuestionnaireListContext>(
  (ref, ctx) async {
    final patientId =
        await ref.watch(questionnairePatientIdProvider(ctx).future);
    return ref.read(questionnairesRepositoryProvider).listVisibleQuestionnaires(
          role: ctx.role,
          patientId: patientId,
        );
  },
);

final questionnaireStaffOptionsProvider =
    FutureProvider<List<QuestionnaireProfessionalOption>>((ref) {
  return ref.read(questionnairesRepositoryProvider).listStaffOptions();
});

final questionnaireAdminCatalogProvider =
    FutureProvider<List<Questionnaire>>((ref) {
  return ref
      .read(questionnairesRepositoryProvider)
      .listQuestionnaireCatalogForAdmin();
});

final psychologistQuestionnairesProvider =
    FutureProvider<List<Questionnaire>>((ref) {
  return ref.read(questionnairesRepositoryProvider).listVisibleQuestionnaires(
        role: ProfileRole.psychologist,
        patientId: '',
      );
});

final questionnaireAdminQuestionsProvider =
    FutureProvider.family<List<QuestionnaireQuestion>, String>(
        (ref, questionnaireId) {
  return ref
      .read(questionnairesRepositoryProvider)
      .listQuestionsForAdmin(questionnaireId);
});

final questionnaireAccessManagementProvider =
    FutureProvider.family<QuestionnaireAccessManagementData, String>(
        (ref, professionalId) {
  return ref
      .read(questionnairesRepositoryProvider)
      .listQuestionnaireAccessForProfessional(professionalId);
});

class QuestionnaireListContext {
  const QuestionnaireListContext({
    required this.role,
    this.patientId,
  });

  final ProfileRole role;
  final String? patientId;

  @override
  bool operator ==(Object other) =>
      other is QuestionnaireListContext &&
      other.role == role &&
      other.patientId == patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

/// Status de resposta por `questionnaire_id` para um paciente específico.
final questionnairePatientStatusProvider =
    FutureProvider.family<Map<String, QuestionnairePatientStatus>, String>(
        (ref, patientId) {
  return ref
      .read(questionnairesRepositoryProvider)
      .getPatientResponseStatuses(patientId);
});

/// IDs dos questionários liberados (atribuição ativa) para um paciente.
final patientAssignmentIdsProvider =
    FutureProvider.family<Set<String>, String>((ref, patientId) {
  return ref
      .read(questionnairesRepositoryProvider)
      .listActiveAssignmentQuestionnaireIds(patientId);
});

/// Libera/revoga um questionário para um paciente e atualiza os caches.
class AssignQuestionnaireNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> setReleased({
    required String patientId,
    required String questionnaireId,
    required bool released,
    String? message,
  }) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(questionnairesRepositoryProvider);
      if (released) {
        await repo.assignQuestionnaire(
          patientId: patientId,
          questionnaireId: questionnaireId,
          message: message,
        );
      } else {
        await repo.cancelPatientAssignment(
          patientId: patientId,
          questionnaireId: questionnaireId,
        );
      }
      ref.invalidate(patientAssignmentIdsProvider(patientId));
      ref.invalidate(questionnairePatientStatusProvider(patientId));
    });
  }
}

final assignQuestionnaireProvider =
    AsyncNotifierProvider<AssignQuestionnaireNotifier, void>(
  AssignQuestionnaireNotifier.new,
);

final startQuestionnaireProvider = AsyncNotifierProvider.family<
    StartQuestionnaireNotifier, void, StartQuestionnaireArgs>(
  StartQuestionnaireNotifier.new,
);

class StartQuestionnaireArgs {
  const StartQuestionnaireArgs({
    required this.patientId,
    required this.questionnaireId,
    this.contexts = const [],
  });

  final String patientId;
  final String questionnaireId;
  final List<QuestionnaireContextInput> contexts;

  @override
  bool operator ==(Object other) =>
      other is StartQuestionnaireArgs &&
      other.patientId == patientId &&
      other.questionnaireId == questionnaireId &&
      _sameContexts(other.contexts, contexts);

  @override
  int get hashCode => Object.hash(
        patientId,
        questionnaireId,
        Object.hashAll(
          contexts.map((item) => Object.hash(item.key, item.label)),
        ),
      );
}

bool _sameContexts(
  List<QuestionnaireContextInput> a,
  List<QuestionnaireContextInput> b,
) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].key != b[i].key || a[i].label != b[i].label) {
      return false;
    }
  }
  return true;
}

class StartQuestionnaireNotifier
    extends FamilyAsyncNotifier<void, StartQuestionnaireArgs> {
  @override
  Future<void> build(StartQuestionnaireArgs arg) async {}

  Future<QuestionnaireSession> start() async {
    state = const AsyncValue.loading();
    try {
      final session =
          await ref.read(questionnairesRepositoryProvider).startQuestionnaire(
                patientId: arg.patientId,
                questionnaireId: arg.questionnaireId,
                contexts: arg.contexts,
              );
      state = const AsyncValue.data(null);
      return session;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final finishQuestionnaireProvider = AsyncNotifierProvider.family<
    FinishQuestionnaireNotifier,
    FinishQuestionnaireResult?,
    FinishQuestionnaireArgs>(FinishQuestionnaireNotifier.new);

class FinishQuestionnaireArgs {
  const FinishQuestionnaireArgs({
    required this.responseId,
    required this.questionnaireName,
  });

  final String responseId;
  final String questionnaireName;

  @override
  bool operator ==(Object other) =>
      other is FinishQuestionnaireArgs &&
      other.responseId == responseId &&
      other.questionnaireName == questionnaireName;

  @override
  int get hashCode => Object.hash(responseId, questionnaireName);
}

class FinishQuestionnaireNotifier extends FamilyAsyncNotifier<
    FinishQuestionnaireResult?, FinishQuestionnaireArgs> {
  @override
  Future<FinishQuestionnaireResult?> build(FinishQuestionnaireArgs arg) async =>
      null;

  Future<FinishQuestionnaireResult> submit() async {
    state = const AsyncValue.loading();
    try {
      final result =
          await ref.read(questionnairesRepositoryProvider).finishQuestionnaire(
                responseId: arg.responseId,
                questionnaireName: arg.questionnaireName,
              );
      state = AsyncValue.data(result);
      _invalidateDependentProviders();
      return result;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Todas as telas que leem `questionnaire_responses`/`questionnaire_results`
  /// ficam com cache desatualizado até isto rodar — sem ele, o status só
  /// atualiza se o usuário atualizar a tela manualmente. `ref.invalidate` num
  /// provider `.family` sem argumento invalida todas as instâncias em cache
  /// (qualquer paciente, qualquer role), sem precisar saber qual delas está
  /// ativa nesta sessão.
  void _invalidateDependentProviders() {
    ref.invalidate(questionnairePatientStatusProvider);
    ref.invalidate(myClinicalDashboardProvider);
    ref.invalidate(staffClinicalDashboardProvider);
    ref.invalidate(myMentalMapProvider);
    ref.invalidate(staffMentalMapProvider);
    ref.invalidate(patientResultsListProvider);
    ref.invalidate(patientResultDetailProvider);
  }
}
