import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_data.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_person.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship_type.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_case_map.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_case_map_builder.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_aggregator.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_case_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_check_in_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_data.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_genogram_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_goal_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_hub_builder.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_clinical_core.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_clinical_core_builder.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_history_links.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_history_links_builder.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_therapy_plan.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_therapy_plan_builder.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_problem_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_questionnaire_block.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_score_highlight.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_validation_summary.dart';
import 'package:terapia_esquema/features/mental_map/presentation/mental_map_navigation_targets.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_availability.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_id.dart';
import 'package:terapia_esquema/features/patient_journey/domain/patient_journey_progress.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/results/domain/category_result.dart';
import 'package:terapia_esquema/features/results/domain/patient_response_summary.dart';
import 'package:terapia_esquema/features/results/domain/patient_result_detail.dart';
import 'package:terapia_esquema/features/results/domain/questionnaire_response_status.dart';
import 'package:terapia_esquema/features/results/domain/result_snapshot.dart';
import 'package:terapia_esquema/features/results/domain/scoring_schema_result.dart';
import 'package:terapia_esquema/features/results/domain/scoring_severity.dart';
import 'package:terapia_esquema/features/results/domain/scoring_snapshot.dart';
import 'package:terapia_esquema/features/results/domain/snapshot_context_result.dart';
import 'package:terapia_esquema/features/patient_timeline/domain/patient_timeline_event.dart';
import 'package:terapia_esquema/features/therapy_resources/domain/patient_resource_access.dart';
import 'package:terapia_esquema/features/therapy_resources/domain/resource_access_status.dart';
import 'package:terapia_esquema/features/therapy_resources/domain/therapy_resource.dart';
import 'package:terapia_esquema/features/therapy_resources/domain/therapy_resource_type.dart';

void main() {
  test('buildQuestionnaireBlocks picks latest responses for core instruments',
      () {
    final responses = [
      PatientResponseSummary(
        id: 'old-ysq',
        questionnaireId: 'q1',
        questionnaireCode: 'YSQ_FOUNDATION_V1',
        questionnaireName: 'YSQ',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2024, 1, 1),
        answerCount: 90,
        hasResults: true,
        resultsCount: 1,
      ),
      PatientResponseSummary(
        id: 'new-ysq',
        questionnaireId: 'q1',
        questionnaireCode: 'YSQ_FOUNDATION_V1',
        questionnaireName: 'YSQ',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 6, 1),
        answerCount: 90,
        hasResults: true,
        resultsCount: 1,
      ),
      PatientResponseSummary(
        id: 'yami-1',
        questionnaireId: 'q2',
        questionnaireCode: 'YAMI_MODES',
        questionnaireName: 'YAMI',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 5, 1),
        answerCount: 20,
        hasResults: true,
        resultsCount: 1,
      ),
      PatientResponseSummary(
        id: 'attachment-1',
        questionnaireId: 'q3',
        questionnaireCode: 'ATTACHMENT_STYLES_V1',
        questionnaireName: 'Apego',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 5, 2),
        answerCount: 42,
        hasResults: true,
        resultsCount: 3,
      ),
      PatientResponseSummary(
        id: 'parental-1',
        questionnaireId: 'q4',
        questionnaireCode: 'PARENTAL_STYLES_V1',
        questionnaireName: 'Parentais',
        status: QuestionnaireResponseStatus.completed,
        completedAt: DateTime(2025, 5, 3),
        answerCount: 36,
        hasResults: true,
        resultsCount: 2,
      ),
    ];

    final blocks = buildQuestionnaireBlocks(responses: responses);
    expect(blocks.length, 4);
    expect(blocks.any((b) => b.responseId == 'new-ysq'), isTrue);
    expect(blocks.any((b) => b.responseId == 'yami-1'), isTrue);
    expect(blocks.any((b) => b.responseId == 'attachment-1'), isTrue);
    expect(blocks.any((b) => b.responseId == 'parental-1'), isTrue);
  });

  test('extractScoreHighlights orders by score descending', () {
    final detail = _detailWithSchemas(
      const PatientResultDetail(
        id: 'r1',
        patientId: 'p1',
        questionnaireId: 'q1',
        questionnaireCode: 'YSQ',
        questionnaireName: 'YSQ',
        status: QuestionnaireResponseStatus.completed,
        answers: [],
        categoryResults: [],
      ),
    );

    final highlights = extractScoreHighlights(detail, limit: 3);
    expect(highlights.length, 2);
    expect(highlights.first.name, 'Alto');
    expect(highlights.last.name, 'Baixo');
  });

  test('extractParentalFigureSummaries reads snapshot contexts', () {
    final detail = const PatientResultDetail(
      id: 'parental-1',
      patientId: 'p1',
      questionnaireId: 'q4',
      questionnaireCode: 'PARENTAL_STYLES_V1',
      questionnaireName: 'Parentais',
      status: QuestionnaireResponseStatus.completed,
      answers: [],
      categoryResults: [
        CategoryResult(
          id: 'cat1',
          categoryName: 'Parentais',
          averageScore: 3,
          snapshot: ResultSnapshot(
            version: ScoringSnapshot.demoVersion,
            scoring: ScoringSnapshot.empty,
            contexts: [
              SnapshotContextResult(
                id: 'ctx1',
                key: 'mother',
                label: 'Mãe',
                status: 'completed',
                schemas: [
                  ScoringSchemaResult(
                    id: 's1',
                    code: 'OVERPROTECTIVE',
                    name: 'Superprotetora',
                    weightedScore: 4.2,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );

    final summaries = extractParentalFigureSummaries(detail);
    expect(summaries, contains('Mãe - Superprotetora'));
  });

  test('mentalMapHasRelevantData false when all sections empty', () {
    expect(mentalMapHasRelevantData(MentalMapData.empty), isFalse);
  });

  test('mentalMapHasRelevantData true with active problem', () {
    const data = MentalMapData(
      patientName: 'Paciente teste',
      caseMap: MentalCaseMap.empty,
      caseSummary: MentalMapCaseSummary.empty,
      validationSummary: MentalMapValidationSummary.empty,
      clinicalCore: MentalMapClinicalCore.empty,
      historyLinks: MentalMapHistoryLinks.empty,
      therapyPlan: MentalMapTherapyPlan.empty,
      questionnaires: [],
      activeProblems: [
        MentalMapProblemSummary(
          id: '1',
          title: 'Ansiedade',
          statusLabel: 'Ativo',
        ),
      ],
      activeGoals: [],
      recentMonitors: [],
      recentTimelineEvents: [],
      genogram: MentalMapGenogramSummary.empty,
    );
    expect(mentalMapHasRelevantData(data), isTrue);
  });

  test('buildValidationSummary flags pending therapist review', () {
    final caseSummary = buildCaseSummary(
      patient: const Patient(
        id: 'p1',
        fullName: 'Paciente',
        responsiblePsychologistId: 'psy-1',
        intakeSummary: 'Sintese inicial.',
      ),
      questionnaires: const [],
      activeProblems: const [],
      activeGoals: const [],
    );

    final summary = buildValidationSummary(
      patient: const Patient(
        id: 'p1',
        fullName: 'Paciente',
        responsiblePsychologistId: 'psy-1',
        intakeSummary: 'Sintese inicial.',
      ),
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'r1',
          questionnaireCode: 'YSQ_FOUNDATION_V1',
          questionnaireName: 'YSQ',
          requiresTherapistReview: true,
          highlights: [],
        ),
      ],
      activeProblems: const [],
      activeGoals: const [],
      caseSummary: caseSummary,
    );

    expect(summary.hasPendingReview, isTrue);
    expect(summary.title, 'Revisão clínica pendente');
  });

  test('buildCaseSummary merges intake, highlights, goals and problems', () {
    final summary = buildCaseSummary(
      patient: const Patient(
        id: 'p1',
        fullName: 'Paciente',
        responsiblePsychologistId: 'psy-1',
        intakeSummary: 'Histórico com ansiedade persistente.',
        currentLifeContext: 'Sobrecarga no trabalho e conflitos familiares.',
        therapyDemands: 'Regular ansiedade\nMelhorar limites',
      ),
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'r1',
          questionnaireCode: 'YSQ_FOUNDATION_V1',
          questionnaireName: 'YSQ',
          highlights: [
            MentalMapScoreHighlight(
              name: 'Abandono',
              code: 'ABANDONO',
              kind: 'schema',
              score: 5,
            ),
            MentalMapScoreHighlight(
              name: 'Privação emocional',
              code: 'PRIVACAO',
              kind: 'schema',
              score: 4,
            ),
          ],
        ),
      ],
      activeProblems: const [
        MentalMapProblemSummary(
          id: 'prob-1',
          title: 'Crises de ansiedade',
          statusLabel: 'Ativo',
        ),
      ],
      activeGoals: const [
        MentalMapGoalSummary(
          id: 'goal-1',
          title: 'Fortalecer autonomia emocional',
          statusLabel: 'Ativo',
        ),
      ],
    );

    expect(summary.hasContent, isTrue);
    expect(summary.centralHypotheses, contains('Abandono'));
    expect(summary.currentFocuses, contains('Regular ansiedade'));
    expect(
      summary.currentFocuses,
      contains('Fortalecer autonomia emocional'),
    );
  });

  test('buildMentalCaseMap includes attachment node with top styles', () {
    final map = buildMentalCaseMap(
      patientName: 'Maria',
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'att-1',
          questionnaireCode: 'ATTACHMENT_STYLES_V1',
          questionnaireName: 'Estilos de Apego',
          highlights: [
            MentalMapScoreHighlight(
              name: 'Ansioso',
              code: 'ATTACHMENT_STYLE_ANXIOUS',
              kind: 'schema',
              score: 0.82,
            ),
            MentalMapScoreHighlight(
              name: 'Seguro',
              code: 'ATTACHMENT_STYLE_SECURE',
              kind: 'schema',
              score: 0.64,
            ),
          ],
        ),
      ],
      activeProblems: const [],
      activeGoals: const [],
      recentCheckIn: null,
      timelineEvents: const [],
      genogramData: const GenogramData(people: [], relationships: []),
    );

    final attachmentNode = map.contextNodes.firstWhere(
      (node) => node.id == 'attachment',
    );

    expect(attachmentNode.title, 'Apego');
    expect(attachmentNode.isFilled, isTrue);
    expect(attachmentNode.items, contains('Ansioso 0.82'));
    expect(attachmentNode.items, contains('Seguro 0.64'));
  });

  test('buildMentalCaseMap includes coping node with YCI highlights', () {
    final map = buildMentalCaseMap(
      patientName: 'Maria',
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'yci-1',
          questionnaireCode: 'YCI_FOUNDATION_V1',
          questionnaireName: 'YCI',
          highlights: [
            MentalMapScoreHighlight(
              name: 'YCI Geral',
              code: 'YCI_TOTAL',
              kind: 'schema',
              score: 4.48,
            ),
          ],
        ),
      ],
      activeProblems: const [],
      activeGoals: const [],
      recentCheckIn: null,
      timelineEvents: const [],
      genogramData: const GenogramData(people: [], relationships: []),
    );

    final copingNode = map.contextNodes.firstWhere(
      (node) => node.id == 'coping',
    );

    expect(copingNode.title, 'Enfrentamento');
    expect(copingNode.items, contains('YCI Geral 4.48'));
  });

  test('buildMentalCaseMap includes coping node with YRAI highlights', () {
    final map = buildMentalCaseMap(
      patientName: 'Maria',
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'yrai-1',
          questionnaireCode: 'YRAI_FOUNDATION_V1',
          questionnaireName: 'YRAI',
          highlights: [
            MentalMapScoreHighlight(
              name: 'YRAI Geral',
              code: 'YRAI_TOTAL',
              kind: 'schema',
              score: 3.85,
            ),
          ],
        ),
      ],
      activeProblems: const [],
      activeGoals: const [],
      recentCheckIn: null,
      timelineEvents: const [],
      genogramData: const GenogramData(people: [], relationships: []),
    );

    final copingNode = map.contextNodes.firstWhere(
      (node) => node.id == 'coping',
    );

    expect(copingNode.title, 'Enfrentamento');
    expect(copingNode.items, contains('YRAI Geral 3.85'));
  });

  test('buildMentalCaseMap combines YCI and YRAI in coping node', () {
    final map = buildMentalCaseMap(
      patientName: 'Maria',
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'yci-1',
          questionnaireCode: 'YCI_FOUNDATION_V1',
          questionnaireName: 'YCI',
          highlights: [
            MentalMapScoreHighlight(
              name: 'YCI Geral',
              code: 'YCI_TOTAL',
              kind: 'schema',
              score: 4.48,
            ),
          ],
        ),
        MentalMapQuestionnaireBlock(
          responseId: 'yrai-1',
          questionnaireCode: 'YRAI_FOUNDATION_V1',
          questionnaireName: 'YRAI',
          highlights: [
            MentalMapScoreHighlight(
              name: 'YRAI Geral',
              code: 'YRAI_TOTAL',
              kind: 'schema',
              score: 3.85,
            ),
          ],
        ),
      ],
      activeProblems: const [],
      activeGoals: const [],
      recentCheckIn: null,
      timelineEvents: const [],
      genogramData: const GenogramData(people: [], relationships: []),
    );

    final copingNode = map.contextNodes.firstWhere(
      (node) => node.id == 'coping',
    );

    expect(copingNode.shortLabel, 'Preenchido');
    expect(copingNode.items, contains('YCI Geral 4.48'));
    expect(copingNode.items, contains('YRAI Geral 3.85'));
  });

  test('journey mental map available without clinical data', () {
    const progress = PatientJourneyProgress(
      activeQuestionnaireCount: 0,
      completedQuestionnaireCount: 0,
      hasMonitorToday: false,
      releasedResourceCount: 0,
      completedResourceCount: 0,
      activeTherapyGoalCount: 0,
      completedTherapyGoalCount: 0,
      totalProblemCount: 0,
      openProblemCount: 0,
      hasCheckInToday: false,
      timelineEventCount: 0,
      genogramPeopleCount: 0,
      genogramRelationshipCount: 0,
      checkInCount: 0,
      dailyMonitorCount: 0,
      hasYsqStructuredResult: false,
      hasYamiStructuredResult: false,
    );

    final steps = buildPatientJourneySteps(progress);
    final map = steps.firstWhere((s) => s.id == JourneyStepId.mentalMap);
    expect(map.availability, JourneyStepAvailability.available);
  });

  test('journey mental map inProgress with relevant data', () {
    const progress = PatientJourneyProgress(
      activeQuestionnaireCount: 0,
      completedQuestionnaireCount: 1,
      hasMonitorToday: false,
      releasedResourceCount: 0,
      completedResourceCount: 0,
      activeTherapyGoalCount: 0,
      completedTherapyGoalCount: 0,
      totalProblemCount: 0,
      openProblemCount: 0,
      hasCheckInToday: false,
      timelineEventCount: 0,
      genogramPeopleCount: 0,
      genogramRelationshipCount: 0,
      checkInCount: 0,
      dailyMonitorCount: 0,
      hasYsqStructuredResult: false,
      hasYamiStructuredResult: false,
    );

    final steps = buildPatientJourneySteps(progress);
    final map = steps.firstWhere((s) => s.id == JourneyStepId.mentalMap);
    expect(map.availability, JourneyStepAvailability.inProgress);
  });

  test('buildMentalCaseMap returns empty nodes for patient without data', () {
    final caseMap = buildMentalCaseMap(
      patientName: 'Paciente vazio',
      questionnaires: const [],
      activeProblems: const [],
      activeGoals: const [],
      recentCheckIn: null,
      timelineEvents: const [],
      genogramData: const GenogramData(people: [], relationships: []),
    );

    expect(caseMap.center.patientName, 'Paciente vazio');
    expect(caseMap.primaryNodes.length, 4);
    expect(caseMap.contextNodes.length, 4);
    expect(caseMap.primaryNodes.every((node) => node.isEmpty), isTrue);
    expect(caseMap.contextNodes.every((node) => node.isEmpty), isTrue);
  });

  test('buildMentalCaseMap orders top schemas and modes from YSQ/YAMI', () {
    final caseMap = buildMentalCaseMap(
      patientName: 'Paciente com instrumentos',
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'ysq-1',
          questionnaireCode: 'YSQ_FOUNDATION_V1',
          questionnaireName: 'YSQ',
          highlights: [
            MentalMapScoreHighlight(
              name: 'Abandono',
              code: 'ABN',
              kind: 'schema',
              score: 5.8,
            ),
            MentalMapScoreHighlight(
              name: 'Privação emocional',
              code: 'PRV',
              kind: 'schema',
              score: 4.9,
            ),
          ],
        ),
        MentalMapQuestionnaireBlock(
          responseId: 'yami-1',
          questionnaireCode: 'YAMI_MODES_FOUNDATION_V1',
          questionnaireName: 'YAMI',
          highlights: [
            MentalMapScoreHighlight(
              name: 'Criança vulnerável',
              code: 'CV',
              kind: 'schema',
              score: 5.4,
            ),
            MentalMapScoreHighlight(
              name: 'Pai punitivo',
              code: 'PP',
              kind: 'schema',
              score: 4.3,
            ),
          ],
        ),
      ],
      activeProblems: const [],
      activeGoals: const [],
      recentCheckIn: null,
      timelineEvents: const [],
      genogramData: const GenogramData(people: [], relationships: []),
    );

    expect(caseMap.primaryNodes[0].items.first, 'Abandono 5.80');
    expect(caseMap.primaryNodes[1].items.first, 'Criança vulnerável 5.40');
  });

  test('buildMentalCaseMap includes problems and goals in primary ring', () {
    final caseMap = buildMentalCaseMap(
      patientName: 'Paciente com foco clínico',
      questionnaires: const [],
      activeProblems: const [
        MentalMapProblemSummary(
          id: 'p1',
          title: 'Ansiedade social',
          statusLabel: 'Ativo',
        ),
      ],
      activeGoals: const [
        MentalMapGoalSummary(
          id: 'g1',
          title: 'Praticar exposição gradual',
          statusLabel: 'Ativo',
        ),
      ],
      recentCheckIn: MentalMapCheckInSummary(
        id: 'c1',
        moodScore: 4,
        anxietyScore: 8,
        checkedInAt: DateTime(2025, 1, 1),
      ),
      timelineEvents: const [],
      genogramData: const GenogramData(people: [], relationships: []),
    );

    expect(caseMap.center.activeProblemsLabel, '1 problema ativo');
    expect(caseMap.center.activeGoalsLabel, '1 objetivo ativo');
    expect(caseMap.center.lastCheckInLabel, 'Humor 4 · Ans. 8');
    expect(caseMap.primaryNodes[2].items.single, 'Ansiedade social');
    expect(caseMap.primaryNodes[3].items.single, 'Praticar exposição gradual');
  });

  test('buildMentalCaseMap includes history node with genogram highlights', () {
    final caseMap = buildMentalCaseMap(
      patientName: 'Paciente com genograma',
      questionnaires: const [],
      activeProblems: const [],
      activeGoals: const [],
      recentCheckIn: null,
      timelineEvents: const [],
      genogramData: GenogramData(
        people: [
          GenogramPerson(
            id: 'gp1',
            clinicId: 'c1',
            patientId: 'p1',
            fullName: 'Marta',
            isDeceased: false,
            isSensitive: false,
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
          ),
          GenogramPerson(
            id: 'gp2',
            clinicId: 'c1',
            patientId: 'p1',
            fullName: 'Carlos',
            isDeceased: false,
            isSensitive: false,
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
          ),
        ],
        relationships: [
          GenogramRelationship(
            id: 'gr1',
            clinicId: 'c1',
            patientId: 'p1',
            personAId: 'gp1',
            personBId: 'gp2',
            relationshipType: GenogramRelationshipType.parentChild,
            isSensitive: false,
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
          ),
        ],
      ),
    );

    final historyNode = caseMap.contextNodes.singleWhere(
      (node) => node.id == 'history',
    );
    expect(historyNode.isEmpty, isFalse);
    expect(historyNode.items, contains('2 pessoa(s) no genograma'));
  });

  test('buildMentalCaseMap uses parental figure summaries when provided', () {
    final map = buildMentalCaseMap(
      patientName: 'Maria',
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'parental-1',
          questionnaireCode: 'PARENTAL_STYLES_V1',
          questionnaireName: 'Parentais',
          highlights: [],
        ),
      ],
      activeProblems: const [],
      activeGoals: const [],
      recentCheckIn: null,
      timelineEvents: const [],
      genogramData: const GenogramData(people: [], relationships: []),
      questionnaireContexts: const [
        MentalMapQuestionnaireContext(
          responseId: 'parental-1',
          questionnaireCode: 'PARENTAL_STYLES_V1',
          figureSummaries: ['Mãe - Superprotetora'],
        ),
      ],
    );

    final parentalNode = map.contextNodes.singleWhere(
      (node) => node.id == 'parental',
    );
    expect(parentalNode.items, contains('Mãe - Superprotetora'));
  });

  test('buildMentalMapNodeDetail exposes data source and routes for staff', () {
    const node = MentalCaseMapNode(
      id: 'schemas',
      title: 'Esquemas',
      shortLabel: 'Preenchido',
      items: ['Abandono 5.80'],
      emptyLabel: 'Pendente',
      dataSource: 'YSQ - última resposta concluída',
      responseId: 'ysq-1',
    );

    final detail = buildMentalMapNodeDetail(
      node: node,
      role: ProfileRole.psychologist,
      patientId: 'p1',
    );

    expect(detail.dataSource, contains('YSQ'));
    expect(detail.isFilled, isTrue);
    expect(
      resolvePrimaryRoute(
        detail: detail,
        role: ProfileRole.psychologist,
        patientId: 'p1',
      ),
      MentalMapNavigationTargets.clinicalDashboard(
        role: ProfileRole.psychologist,
        patientId: 'p1',
      ),
    );
    expect(
      resolveSecondaryRoute(
        detail: detail,
        role: ProfileRole.psychologist,
        patientId: 'p1',
      ),
      MentalMapNavigationTargets.questionnaireResult(
        role: ProfileRole.psychologist,
        patientId: 'p1',
        responseId: 'ysq-1',
      ),
    );
  });

  test('history node routes to timeline and genogram', () {
    const node = MentalCaseMapNode(
      id: 'history',
      title: 'História / Vínculos',
      shortLabel: 'Preenchido',
      items: ['2 pessoa(s) no genograma'],
      emptyLabel: 'Pendente',
      dataSource: 'Linha do tempo + genograma',
    );

    final detail = buildMentalMapNodeDetail(
      node: node,
      role: ProfileRole.psychologist,
      patientId: 'p1',
    );

    expect(
      resolvePrimaryRoute(
        detail: detail,
        role: ProfileRole.psychologist,
        patientId: 'p1',
      ),
      MentalMapNavigationTargets.timeline(
        role: ProfileRole.psychologist,
        patientId: 'p1',
      ),
    );
    expect(
      resolveSecondaryRoute(
        detail: detail,
        role: ProfileRole.psychologist,
        patientId: 'p1',
      ),
      MentalMapNavigationTargets.genogram(
        role: ProfileRole.psychologist,
        patientId: 'p1',
      ),
    );
  });

  test('buildMentalMapClinicalCore empty when no data', () {
    final core = buildMentalMapClinicalCore(
      questionnaires: const [],
      activeProblems: const [],
    );
    expect(core.hasContent, isFalse);
    expect(core.topSchemas, isEmpty);
    expect(core.topModes, isEmpty);
  });

  test('buildMentalMapClinicalCore orders schemas modes and problems', () {
    final core = buildMentalMapClinicalCore(
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'ysq-1',
          questionnaireCode: 'YSQ_FOUNDATION_V1',
          questionnaireName: 'YSQ',
          highlights: [
            MentalMapScoreHighlight(
              name: 'Abandono',
              code: 'ABN',
              kind: 'schema',
              score: 5.8,
            ),
            MentalMapScoreHighlight(
              name: 'Privação',
              code: 'PRV',
              kind: 'schema',
              score: 4.2,
            ),
          ],
        ),
        MentalMapQuestionnaireBlock(
          responseId: 'yami-1',
          questionnaireCode: 'YAMI_MODES',
          questionnaireName: 'YAMI',
          highlights: [
            MentalMapScoreHighlight(
              name: 'Vulnerável',
              code: 'VUL',
              kind: 'schema',
              score: 4.9,
            ),
          ],
        ),
      ],
      activeProblems: const [
        MentalMapProblemSummary(
          id: 'p1',
          title: 'Ansiedade',
          intensity: 8,
          statusLabel: 'Ativo',
        ),
        MentalMapProblemSummary(
          id: 'p2',
          title: 'Insônia',
          intensity: 5,
          statusLabel: 'Ativo',
        ),
      ],
    );

    expect(core.topSchemas.first.name, 'Abandono');
    expect(core.topModes.single.name, 'Vulnerável');
    expect(core.topProblemsByIntensity.first.title, 'Ansiedade');
    expect(core.topProblemsByIntensity.first.intensity, 8);
  });

  test('buildMentalMapHistoryLinks masks sensitive timeline items', () {
    final history = buildMentalMapHistoryLinks(
      timelineEvents: [
        PatientTimelineEvent(
          id: 'e1',
          clinicId: 'c1',
          patientId: 'p1',
          title: 'Evento confidencial',
          emotionalImpact: 9,
          isSensitive: true,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
        ),
      ],
      genogramData: const GenogramData(people: [], relationships: []),
      questionnaires: const [],
    );

    expect(history.timelineEvents.single.displayTitle, 'Evento sensível');
    expect(history.timelineEvents.single.emotionalImpact, isNull);
    expect(history.sensitiveItemCount, 1);
  });

  test('buildMentalMapHistoryLinks includes parental figures and genogram', () {
    final history = buildMentalMapHistoryLinks(
      timelineEvents: const [],
      genogramData: GenogramData(
        people: [
          GenogramPerson(
            id: 'gp1',
            clinicId: 'c1',
            patientId: 'p1',
            fullName: 'Marta',
            isDeceased: false,
            isSensitive: false,
            createdAt: DateTime(2025, 1, 1),
            updatedAt: DateTime(2025, 1, 1),
          ),
        ],
        relationships: const [],
      ),
      questionnaires: const [],
      questionnaireContexts: const [
        MentalMapQuestionnaireContext(
          responseId: 'par-1',
          questionnaireCode: 'PARENTAL_STYLES_V1',
          figureSummaries: ['Mãe - Superprotetora'],
        ),
      ],
    );

    expect(history.hasGenogram, isTrue);
    expect(history.parentalFigures.single.figureLabel, 'Mãe');
    expect(history.genogramPeople.single.displayName, 'Marta');
  });

  test('buildMentalMapTherapyPlan builds sparkline with enough check-ins', () {
    final plan = buildMentalMapTherapyPlan(
      activeGoals: const [
        MentalMapGoalSummary(
          id: 'g1',
          title: 'Autocompaixão',
          statusLabel: 'Ativo',
        ),
      ],
      activeProblems: const [
        MentalMapProblemSummary(
          id: 'p1',
          title: 'Ansiedade',
          statusLabel: 'Ativo',
        ),
      ],
      checkIns: [
        MentalMapCheckInSummary(
          id: 'c1',
          moodScore: 4,
          anxietyScore: 7,
          energyScore: 3,
          checkedInAt: DateTime(2025, 6, 3),
        ),
        MentalMapCheckInSummary(
          id: 'c2',
          moodScore: 6,
          anxietyScore: 5,
          energyScore: 4,
          checkedInAt: DateTime(2025, 6, 2),
        ),
      ],
      resourceAccess: const [],
    );

    expect(plan.hasGoals, isTrue);
    expect(plan.hasProblems, isTrue);
    expect(plan.sparkline.showChart, isTrue);
    expect(plan.sparkline.moodPoints.length, 2);
  });

  test('buildCheckInSparkline hidden with single check-in', () {
    final sparkline = buildCheckInSparkline([
      MentalMapCheckInSummary(
        id: 'c1',
        moodScore: 4,
        checkedInAt: DateTime(2025, 6, 3),
      ),
    ]);
    expect(sparkline.showChart, isFalse);
  });

  test('buildResourcesSummary counts released and completed resources', () {
    final summary = buildResourcesSummary([
      PatientResourceAccess(
        id: 'a1',
        patientId: 'p1',
        resourceId: 'r1',
        isActive: true,
        completedAt: DateTime(2025, 1, 1),
        resource: const TherapyResource(
          id: 'r1',
          title: 'Recurso 1',
          type: TherapyResourceType.article,
          description: 'Desc',
          isActive: true,
        ),
      ),
      const PatientResourceAccess(
        id: 'a2',
        patientId: 'p1',
        resourceId: 'r2',
        isActive: true,
        resource: TherapyResource(
          id: 'r2',
          title: 'Recurso 2',
          type: TherapyResourceType.article,
          description: 'Desc',
          isActive: true,
        ),
      ),
    ]);

    expect(summary.releasedCount, 2);
    expect(summary.completedCount, 1);
    expect(ResourceAccessStatus.completed.label, 'Concluído');
  });

  // ---------------------------------------------------------------------------
  // Severity propagation tests
  // ---------------------------------------------------------------------------

  test('extractScoreHighlights preserves severityColorKey from schema', () {
    final detail = const PatientResultDetail(
      id: 'sev-1',
      patientId: 'p1',
      questionnaireId: 'q1',
      questionnaireCode: 'YSQ_FOUNDATION_V1',
      questionnaireName: 'YSQ',
      status: QuestionnaireResponseStatus.completed,
      answers: [],
      categoryResults: [
        CategoryResult(
          id: 'cat1',
          categoryName: 'Esquemas',
          averageScore: 8,
          snapshot: ResultSnapshot(
            version: ScoringSnapshot.demoVersion,
            scoring: ScoringSnapshot(
              schemas: [
                ScoringSchemaResult(
                  id: 's1',
                  code: 'ABANDONO',
                  name: 'Abandono',
                  weightedScore: 8,
                  severity: ScoringSeverity(label: 'Severo', colorKey: 'red'),
                ),
                ScoringSchemaResult(
                  id: 's2',
                  code: 'PRIVACAO',
                  name: 'Privação',
                  weightedScore: 4,
                  severity: ScoringSeverity(
                    label: 'Moderado',
                    colorKey: 'amber',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );

    final highlights = extractScoreHighlights(detail);
    expect(highlights.first.name, 'Abandono');
    expect(highlights.first.severityColorKey, 'red');
    expect(highlights[1].severityColorKey, 'amber');
  });

  test(
      'buildMentalCaseMap schema node carries worst aggregateSeverityColorKey',
      () {
    final map = buildMentalCaseMap(
      patientName: 'Teste',
      questionnaires: const [
        MentalMapQuestionnaireBlock(
          responseId: 'ysq-sev',
          questionnaireCode: 'YSQ_FOUNDATION_V1',
          questionnaireName: 'YSQ',
          highlights: [
            MentalMapScoreHighlight(
              name: 'Abandono',
              code: 'ABANDONO',
              kind: 'schema',
              score: 8,
              severityColorKey: 'red',
            ),
            MentalMapScoreHighlight(
              name: 'Privação',
              code: 'PRIVACAO',
              kind: 'schema',
              score: 4,
              severityColorKey: 'amber',
            ),
          ],
        ),
      ],
      activeProblems: const [],
      activeGoals: const [],
      recentCheckIn: null,
      timelineEvents: const [],
      genogramData: const GenogramData(people: [], relationships: []),
    );

    final schemaNode =
        map.primaryNodes.firstWhere((n) => n.id == 'schemas');
    // worst-of: red > amber → red
    expect(schemaNode.aggregateSeverityColorKey, 'red');
  });

  test(
      'buildMentalCaseMap problems node derives severity from intensity',
      () {
    final map = buildMentalCaseMap(
      patientName: 'Teste',
      questionnaires: const [],
      activeProblems: const [
        MentalMapProblemSummary(
          id: 'p1',
          title: 'Crise de pânico',
          intensity: 8,
          statusLabel: 'Ativo',
        ),
        MentalMapProblemSummary(
          id: 'p2',
          title: 'Insônia',
          intensity: 3,
          statusLabel: 'Ativo',
        ),
      ],
      activeGoals: const [],
      recentCheckIn: null,
      timelineEvents: const [],
      genogramData: const GenogramData(people: [], relationships: []),
    );

    final problemsNode =
        map.primaryNodes.firstWhere((n) => n.id == 'problems');
    // max intensity = 8 (≥ 7) → red
    expect(problemsNode.aggregateSeverityColorKey, 'red');
  });

  test('buildMentalCaseMap problems node severity green for low intensity',
      () {
    final map = buildMentalCaseMap(
      patientName: 'Teste',
      questionnaires: const [],
      activeProblems: const [
        MentalMapProblemSummary(
          id: 'p1',
          title: 'Insônia leve',
          intensity: 2,
          statusLabel: 'Ativo',
        ),
      ],
      activeGoals: const [],
      recentCheckIn: null,
      timelineEvents: const [],
      genogramData: const GenogramData(people: [], relationships: []),
    );

    final problemsNode =
        map.primaryNodes.firstWhere((n) => n.id == 'problems');
    expect(problemsNode.aggregateSeverityColorKey, 'green');
  });

  test('buildMentalCaseMap history node has null severity', () {
    final map = buildMentalCaseMap(
      patientName: 'Teste',
      questionnaires: const [],
      activeProblems: const [],
      activeGoals: const [],
      recentCheckIn: null,
      timelineEvents: const [],
      genogramData: const GenogramData(people: [], relationships: []),
    );

    final historyNode =
        map.contextNodes.firstWhere((n) => n.id == 'history');
    expect(historyNode.aggregateSeverityColorKey, isNull);
  });
}

PatientResultDetail _detailWithSchemas(PatientResultDetail base) {
  return PatientResultDetail(
    id: base.id,
    patientId: base.patientId,
    questionnaireId: base.questionnaireId,
    questionnaireCode: base.questionnaireCode,
    questionnaireName: base.questionnaireName,
    status: base.status,
    answers: base.answers,
    categoryResults: [
      const CategoryResult(
        id: 'cat1',
        categoryName: 'Legado',
        averageScore: 2,
        snapshot: ResultSnapshot(
          version: ScoringSnapshot.demoVersion,
          scoring: ScoringSnapshot(
            schemas: [
              ScoringSchemaResult(
                id: 's1',
                code: 'LOW',
                name: 'Baixo',
                weightedScore: 1,
              ),
              ScoringSchemaResult(
                id: 's2',
                code: 'HIGH',
                name: 'Alto',
                weightedScore: 9,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
