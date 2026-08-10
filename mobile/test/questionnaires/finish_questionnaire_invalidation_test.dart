import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_data.dart';
import 'package:terapia_esquema/features/clinical_dashboard/providers/clinical_dashboard_providers.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_data.dart';
import 'package:terapia_esquema/features/mental_map/providers/mental_map_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/questionnaires/data/questionnaires_repository.dart';
import 'package:terapia_esquema/features/questionnaires/domain/finish_questionnaire_result.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_patient_status.dart';
import 'package:terapia_esquema/features/questionnaires/providers/questionnaires_providers.dart';
import 'package:terapia_esquema/features/results/domain/patient_response_summary.dart';
import 'package:terapia_esquema/features/results/providers/results_providers.dart';

/// Sem isto o bug volta: até este teste existir, finalizar um questionário
/// deixava a lista de questionários, o dashboard clínico, o mapa mental e a
/// tela de resultados com cache velho — só atualizavam com pull-to-refresh
/// ou navegação manual.
class _FakeQuestionnairesRepository extends QuestionnairesRepository {
  _FakeQuestionnairesRepository()
      : super(client: SupabaseClient('https://example.com', 'anon-key'));

  @override
  Future<FinishQuestionnaireResult> finishQuestionnaire({
    required String responseId,
    required String questionnaireName,
  }) async {
    return FinishQuestionnaireResult(
      responseId: responseId,
      questionnaireName: questionnaireName,
      completedAt: DateTime.utc(2026, 8, 14),
      resultsCount: 1,
    );
  }
}

void main() {
  const patientId = 'patient-1';
  const staffCtx =
      StaffClinicalDashboardContext(role: ProfileRole.psychologist, patientId: patientId);
  const staffMapCtx =
      StaffMentalMapContext(role: ProfileRole.psychologist, patientId: patientId);
  const resultsCtx =
      PatientResultsContext(role: ProfileRole.psychologist, patientId: patientId);
  const detailCtx = PatientResultDetailContext(
    role: ProfileRole.psychologist,
    responseId: 'resp-1',
  );

  test(
    'finalizar um questionário invalida todas as telas que dependem dele',
    () async {
      final rebuildCounts = <String, int>{
        'status': 0,
        'myDashboard': 0,
        'staffDashboard': 0,
        'myMap': 0,
        'staffMap': 0,
        'resultsList': 0,
        'resultDetail': 0,
      };

      final container = ProviderContainer(
        overrides: [
          questionnairesRepositoryProvider
              .overrideWithValue(_FakeQuestionnairesRepository()),
          questionnairePatientStatusProvider.overrideWith((ref, id) {
            rebuildCounts['status'] = rebuildCounts['status']! + 1;
            return <String, QuestionnairePatientStatus>{};
          }),
          myClinicalDashboardProvider.overrideWith(
            () => _CountingClinicalDashboardNotifier(rebuildCounts, 'myDashboard'),
          ),
          staffClinicalDashboardProvider.overrideWith((ref, ctx) {
            rebuildCounts['staffDashboard'] = rebuildCounts['staffDashboard']! + 1;
            return ClinicalDashboardData.empty;
          }),
          myMentalMapProvider.overrideWith(
            () => _CountingMentalMapNotifier(rebuildCounts, 'myMap'),
          ),
          staffMentalMapProvider.overrideWith((ref, ctx) {
            rebuildCounts['staffMap'] = rebuildCounts['staffMap']! + 1;
            return MentalMapData.empty;
          }),
          patientResultsListProvider.overrideWith(
            () => _CountingResultsListNotifier(rebuildCounts),
          ),
          patientResultDetailProvider.overrideWith((ref, ctx) {
            rebuildCounts['resultDetail'] = rebuildCounts['resultDetail']! + 1;
            return null;
          }),
        ],
      );
      addTearDown(container.dispose);

      // Popula o cache de todas as instâncias family relevantes — igual ao
      // que aconteceria com as telas abertas antes de finalizar.
      await container.read(questionnairePatientStatusProvider(patientId).future);
      await container.read(myClinicalDashboardProvider.future);
      await container.read(staffClinicalDashboardProvider(staffCtx).future);
      await container.read(myMentalMapProvider.future);
      await container.read(staffMentalMapProvider(staffMapCtx).future);
      await container.read(patientResultsListProvider(resultsCtx).future);
      await container.read(patientResultDetailProvider(detailCtx).future);

      expect(rebuildCounts.values, everyElement(1));

      await container
          .read(
            finishQuestionnaireProvider(
              const FinishQuestionnaireArgs(
                responseId: 'resp-1',
                questionnaireName: 'YSQ',
              ),
            ).notifier,
          )
          .submit();

      // Força a resolução das instâncias marcadas como inválidas.
      await container.read(questionnairePatientStatusProvider(patientId).future);
      await container.read(myClinicalDashboardProvider.future);
      await container.read(staffClinicalDashboardProvider(staffCtx).future);
      await container.read(myMentalMapProvider.future);
      await container.read(staffMentalMapProvider(staffMapCtx).future);
      await container.read(patientResultsListProvider(resultsCtx).future);
      await container.read(patientResultDetailProvider(detailCtx).future);

      expect(
        rebuildCounts.values,
        everyElement(2),
        reason: 'todo provider dependente deve reconstruir uma vez após o '
            'finish — se algum ficar em 1, o cache dele não foi invalidado',
      );
    },
  );
}

class _CountingClinicalDashboardNotifier extends MyClinicalDashboardNotifier {
  _CountingClinicalDashboardNotifier(this._counts, this._key);

  final Map<String, int> _counts;
  final String _key;

  @override
  Future<ClinicalDashboardData> build() async {
    _counts[_key] = _counts[_key]! + 1;
    return ClinicalDashboardData.empty;
  }
}

class _CountingMentalMapNotifier extends MyMentalMapNotifier {
  _CountingMentalMapNotifier(this._counts, this._key);

  final Map<String, int> _counts;
  final String _key;

  @override
  Future<MentalMapData> build() async {
    _counts[_key] = _counts[_key]! + 1;
    return MentalMapData.empty;
  }
}

class _CountingResultsListNotifier extends PatientResultsListNotifier {
  _CountingResultsListNotifier(this._counts);

  final Map<String, int> _counts;

  @override
  Future<List<PatientResponseSummary>> build(PatientResultsContext arg) async {
    _counts['resultsList'] = _counts['resultsList']! + 1;
    return const [];
  }
}
