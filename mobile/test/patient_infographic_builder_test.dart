import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_case_summary.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_data.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_score_row.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/consolidated_schema_row.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_data.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_person.dart';
import 'package:terapia_esquema/features/healthy_resources/domain/healthy_resources.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/clinical_impressions.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/initial_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area_assessment.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/patient_infographic/domain/patient_infographic_builder.dart';
import 'package:terapia_esquema/features/patient_infographic/domain/patient_infographic_data.dart';
import 'package:terapia_esquema/features/patient_problems/domain/patient_problem.dart';
import 'package:terapia_esquema/features/patient_problems/domain/patient_problem_status.dart';
import 'package:terapia_esquema/features/patient_timeline/domain/patient_timeline_event.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/therapy_goals/domain/therapy_goal.dart';
import 'package:terapia_esquema/features/therapy_goals/domain/therapy_goal_status.dart';

ClinicalDashboardData _dashboardWith(
  List<ConsolidatedSchemaRow> rows, {
  List<ClinicalDashboardScoreRow> coping = const [],
  List<TherapyGoal> goals = const [],
}) {
  return ClinicalDashboardData(
    patientName: 'Roberto',
    caseSummary: ClinicalCaseSummary(
      patientName: 'Roberto',
      structuredResultCount: 0,
      openProblemsCount: 0,
      activeGoalsCount: goals.length,
      relevantEventsCount: 0,
      topSchemas: const [],
      topModes: const [],
      topAttachment: const [],
      topCoping: coping,
      highlightedProblems: const [],
      highlightedGoals: goals,
      relevantEvents: const [],
    ),
    callouts: const [],
    history: const [],
    consolidatedSchemas: rows,
  );
}

ConsolidatedSchemaRow _schema(String name, double score, {bool on = true}) =>
    ConsolidatedSchemaRow(
      name: name,
      code: name.toUpperCase(),
      score: score,
      responseId: 'r1',
      isAutoActivated: on,
    );

ConsolidatedSchemaRow _mode(String name, double score, {bool on = true}) =>
    ConsolidatedSchemaRow(
      name: name,
      code: 'YAMI_PM2_MODE_X',
      instrumentCode: 'YAMI_MODES_FOUNDATION_V1',
      score: score,
      responseId: 'r2',
      isAutoActivated: on,
    );

PatientTimelineEvent _event(
  String title, {
  DateTime? date,
  String? period,
  String? chapter,
  int? age,
  bool sensitive = false,
}) =>
    PatientTimelineEvent(
      id: title,
      clinicId: 'c',
      patientId: 'p1',
      title: title,
      eventDate: date,
      periodLabel: period,
      lifeChapter: chapter,
      ageAtEvent: age,
      isSensitive: sensitive,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

TherapyGoal _goal(String title,
        {TherapyGoalStatus status = TherapyGoalStatus.active,
        int progress = 0,
        String? description}) =>
    TherapyGoal(
      id: title,
      clinicId: 'c',
      patientId: 'p1',
      title: title,
      description: description,
      status: status,
      progress: progress,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

GenogramPerson _person(String id, String name, {bool sensitive = false}) =>
    GenogramPerson(
      id: id,
      clinicId: 'c',
      patientId: 'p1',
      fullName: name,
      isDeceased: false,
      isSensitive: sensitive,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

void main() {
  final patient = Patient(
    id: 'p1',
    fullName: 'Roberto Silva',
    birthDate: DateTime(1986, 1, 1),
    occupation: 'Engenheiro',
  );

  PatientInfographicData build({
    ClinicalDashboardData? dashboard,
    InitialAssessment? assessment,
    List<PatientTimelineEvent> timeline = const [],
    CaseConceptualization? concept,
    List<PatientProblem> problems = const [],
    String? attachment,
    GenogramData? genogram,
    HealthyResources? resources,
  }) =>
      buildPatientInfographic(
        patient: patient,
        dashboard: dashboard ?? _dashboardWith(const []),
        assessment: assessment,
        timelineEvents: timeline,
        concept: concept,
        problems: problems,
        attachmentStyle: attachment,
        genogramData: genogram,
        healthyResources: resources,
      );

  group('esquemas, modos e enfrentamento', () {
    test('esquemas vêm dos ativados; modos do YAMI não entram aqui', () {
      final data = build(
        dashboard: _dashboardWith([
          _schema('Abandono', 5.2),
          _schema('Autossacrifício', 2.0, on: false),
          _mode('Criança Vulnerável', 4.6),
        ]),
      );
      expect(data.schemas.map((s) => s.title), ['Abandono']);
      expect(data.schemas.single.description, isNotNull);
    });

    test('modos vêm do resultado do YAMI, ativados, do maior para o menor', () {
      final data = build(
        dashboard: _dashboardWith([
          _mode('Adulto Feliz', 3.5, on: false),
          _mode('Pai Punitivo', 4.2),
          _mode('Criança Vulnerável', 4.8),
        ]),
      );
      expect(data.modes.map((m) => m.title),
          ['Criança Vulnerável', 'Pai Punitivo']);
      expect(data.modes.first.description, 'Média 4,8 no YAMI');
    });

    test('sem YAMI ativado, modos caem para as hipóteses em texto', () {
      final data = build(
        dashboard: _dashboardWith([_mode('Adulto Feliz', 3.5, on: false)]),
        assessment: const InitialAssessment(
          patientId: 'p1',
          clinicalImpressions: ClinicalImpressions(
              modeHypothesesText: 'Protetor distanciado — evita conflito'),
        ),
      );
      expect(data.modes.single.title, 'Protetor distanciado');
      expect(data.modes.single.description, 'evita conflito');
    });

    test('enfrentamento vem dos questionários YCI/YRAI', () {
      final data = build(
        dashboard: _dashboardWith(const [], coping: const [
          ClinicalDashboardScoreRow(
              name: 'Resignação', code: 'YCI_X', score: 4.1, averageScore: 4.1),
          ClinicalDashboardScoreRow(
              name: 'Evitação',
              code: 'YCI_Y',
              score: 3.0,
              severityLabel: 'Moderado'),
        ]),
      );
      expect(data.coping.map((c) => c.title), ['Resignação', 'Evitação']);
      expect(data.coping.first.description, 'Média 4,1');
      expect(data.coping.last.description, 'Moderado');
    });
  });

  group('demandas e contexto de vida', () {
    test('motivos inicial/atual vêm de Demandas Terapêuticas', () {
      final data = build(
        concept: const CaseConceptualization(
          unmetNeeds: [],
          modeSequences: [],
          relationship: TherapeuticRelationship(),
          motivoInitial: ' Ansiedade e depressão ',
          motivoCurrent: 'Dificuldade de relacionamento',
        ),
      );
      expect(data.reasonsInitial, 'Ansiedade e depressão');
      expect(data.reasonsCurrent, 'Dificuldade de relacionamento');
      expect(data.hasDemands, isTrue);
    });

    test('só demandas abertas entram na lista', () {
      final data = build(problems: [
        PatientProblem(
          id: '1',
          clinicId: 'c',
          patientId: 'p1',
          title: 'Insônia',
          status: PatientProblemStatus.active,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
        PatientProblem(
          id: '2',
          clinicId: 'c',
          patientId: 'p1',
          title: 'Resolvida',
          status: PatientProblemStatus.resolved,
          createdAt: DateTime(2026, 1, 1),
          updatedAt: DateTime(2026, 1, 1),
        ),
      ]);
      expect(data.demands.map((d) => d.title), ['Insônia']);
    });

    test('roda da vida usa a satisfação do paciente (1–10) por área', () {
      final data = build(
        assessment: const InitialAssessment(patientId: 'p1', lifeAreas: [
          LifeAreaAssessment(area: LifeArea.workCareer, score: 7),
          LifeAreaAssessment(area: LifeArea.friends, score: 10),
          LifeAreaAssessment(area: LifeArea.family),
        ]),
      );
      expect(data.lifeWheel, {LifeArea.workCareer: 7, LifeArea.friends: 10});
      expect(data.lifeWheelAverage, 8.5);
      expect(data.hasLifeWheel, isTrue);
    });
  });

  group('linha do tempo', () {
    test('rótulo usa idade ou fase da vida em vez de "data não informada"', () {
      expect(_event('a', age: 8).dateLabel, '8 anos');
      expect(_event('a', age: 1).dateLabel, '1 ano');
      expect(_event('a', chapter: 'adolescence').dateLabel, 'Adolescência');
      expect(_event('a', period: 'Verão de 95').dateLabel, 'Verão de 95');
      expect(_event('a', date: DateTime(2020, 3, 5)).dateLabel, '05/03/2020');
      expect(_event('a').dateLabel, 'Data não informada');
    });

    test('ordem cronológica mistura data, idade e fase', () {
      final data = build(timeline: [
        _event('adulto', chapter: 'adulthood'),
        _event('aos 8', age: 8),
        _event('hoje', chapter: 'today'),
        _event('em 2000', date: DateTime(2000, 6, 1)), // 14 anos
      ]);
      expect(data.timeline.map((t) => t.description),
          ['aos 8', 'em 2000', 'adulto', 'hoje']);
      expect(data.timeline.first.periodLabel, '8 anos');
    });
  });

  group('apego, recursos, plano e genograma', () {
    test('apego traz o estilo principal com breve explicação', () {
      final a = build(attachment: 'Ansioso').attachment!;
      expect(a.title, 'Apego ansioso');
      expect(a.description, contains('rejeição'));
      expect(build().attachment, isNull);
      expect(build(attachment: '  ').attachment, isNull);
    });

    test('recursos saudáveis vêm do módulo (catálogo + personalizados)', () {
      final data = build(
        resources: const HealthyResources(
          selectedPredefined: ['pc_creativity', 'id_inexistente'],
          customResources: ['Cantar no coral', '  '],
        ),
      );
      expect(data.resources.map((r) => r.title),
          ['Criatividade', 'Cantar no coral']);
    });

    test('plano terapêutico lista só metas ativas, com progresso', () {
      final data = build(
        dashboard: _dashboardWith(const [], goals: [
          _goal('Pedir ajuda', progress: 40, description: 'Aos poucos'),
          _goal('Antiga', status: TherapyGoalStatus.completed),
          _goal('Sem progresso'),
        ]),
      );
      expect(data.plan.map((g) => g.title), ['Pedir ajuda', 'Sem progresso']);
      expect(data.plan.first.bullets, ['Progresso: 40%']);
      expect(data.plan.last.bullets, isEmpty);
    });

    test('genograma não leva pessoas sensíveis', () {
      final data = build(
        genogram: GenogramData(
          people: [
            _person('1', 'Mãe'),
            _person('2', 'Pessoa sensível', sensitive: true),
          ],
          relationships: const [],
        ),
      );
      expect(data.genogramMembers.map((m) => m.name), ['Mãe']);
      expect(data.genogram!.people.map((p) => p.id), ['1']);
    });
  });

  test('cabeçalho traz idade e avatar do paciente, sem citação', () {
    final data = build();
    expect(data.header.name, 'Roberto Silva');
    expect(data.header.avatarInitials, 'RS');
    expect(data.header.avatarType, patient.avatarType);
    expect(data.header.facts.any((f) => f.text.contains('anos')), isTrue);
  });

  test('hasAnyContent e isSparse refletem o preenchimento', () {
    final empty = build();
    expect(empty.hasAnyContent, isFalse);
    expect(empty.isSparse, isTrue);
    expect(empty.generatedOn, isNotNull);

    final rich = build(
      dashboard: _dashboardWith([_schema('Abandono', 5)], goals: [_goal('A')]),
      attachment: 'Seguro',
      resources: const HealthyResources(
          selectedPredefined: ['pc_humor'], customResources: []),
    );
    expect(rich.hasAnyContent, isTrue);
    expect(rich.contentSectionCount, 4);
    expect(rich.isSparse, isFalse);
  });

  test('seções respeitam o limite máximo de itens', () {
    final data = build(
      dashboard: _dashboardWith(
        [for (var i = 0; i < 20; i++) _schema('Esquema $i', 5)],
        goals: [for (var i = 0; i < 20; i++) _goal('Meta $i')],
      ),
      timeline: [for (var i = 0; i < 20; i++) _event('e$i', age: i)],
    );
    expect(data.schemas.length, 6);
    expect(data.plan.length, 6);
    expect(data.timeline.length, 8);
  });
}
