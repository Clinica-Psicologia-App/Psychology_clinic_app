import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_availability.dart';
import 'package:terapia_esquema/features/patient_journey/domain/journey_step_id.dart';
import 'package:terapia_esquema/features/patient_journey/domain/patient_journey_progress.dart';

void main() {
  test('buildPatientJourneySteps marks modules with correct base availability',
      () {
    final steps = buildPatientJourneySteps(null);
    expect(steps.length, 12);

    final byId = {for (final s in steps) s.id: s};

    // Psicoeducação é sempre disponível (conteúdo educativo, gated no servidor).
    expect(
      byId[JourneyStepId.psychoeducation]!.availability,
      JourneyStepAvailability.available,
    );

    expect(
      byId[JourneyStepId.questionnaires]!.availability,
      JourneyStepAvailability.available,
    );
    expect(
      byId[JourneyStepId.results]!.availability,
      JourneyStepAvailability.available,
    );
    expect(
      byId[JourneyStepId.therapyGoals]!.availability,
      JourneyStepAvailability.available,
    );
    expect(
      byId[JourneyStepId.genogram]!.availability,
      JourneyStepAvailability.available,
    );
    expect(steps.map((step) => step.order),
        orderedEquals([0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11]));
    expect(byId[JourneyStepId.initialAssessment]!.order, 0);
    expect(byId[JourneyStepId.psychoeducation]!.order, 1);
    // Linha da vida antes do Genograma: contexto biográfico primeiro, mapa
    // familiar em seguida.
    expect(byId[JourneyStepId.timeline]!.order, 2);
    expect(byId[JourneyStepId.genogram]!.order, 3);
    expect(byId[JourneyStepId.problems]!.order, 5);
    // O check-in virou nó de apoio pendurado no monitor diário, então o
    // monitor passou a vir antes dele na ordenação do fio principal.
    expect(byId[JourneyStepId.dailyMonitor]!.order, 9);
    expect(byId[JourneyStepId.checkIn]!.order, 10);
    expect(
      byId[JourneyStepId.checkIn]!.parentStepId,
      JourneyStepId.dailyMonitor,
    );
  });

  test('progress marks questionnaires completed when all active done', () {
    const progress = PatientJourneyProgress(
      activeQuestionnaireCount: 3,
      completedQuestionnaireCount: 3,
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
    final q = steps.firstWhere((s) => s.id == JourneyStepId.questionnaires);
    expect(q.availability, JourneyStepAvailability.completed);
  });

  test('questionnaires are blocked when none are available to patient', () {
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

    final step = buildPatientJourneySteps(progress)
        .firstWhere((item) => item.id == JourneyStepId.questionnaires);

    expect(step.availability, JourneyStepAvailability.blocked);
    expect(step.progressHint, contains('Nenhum instrumento'));
  });

  test('progress marks monitor completed when has record today', () {
    const progress = PatientJourneyProgress(
      activeQuestionnaireCount: 1,
      completedQuestionnaireCount: 0,
      hasMonitorToday: true,
      releasedResourceCount: 1,
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
    final monitor = steps.firstWhere((s) => s.id == JourneyStepId.dailyMonitor);
    expect(monitor.availability, JourneyStepAvailability.completed);
    expect(monitor.progressHint, contains('hoje'));
  });

  test('availability labels in Portuguese', () {
    expect(
      JourneyStepAvailability.available.label,
      'Disponível',
    );
    expect(
      JourneyStepAvailability.inDevelopment.label,
      'Em desenvolvimento',
    );
    expect(
      JourneyStepAvailability.completed.label,
      'Concluído',
    );
    expect(
      JourneyStepAvailability.blocked.label,
      'Bloqueado',
    );
  });

  test('JourneyStepId round-trips route key', () {
    expect(
      journeyStepIdFromRouteKey(JourneyStepId.mentalMap.routeKey),
      JourneyStepId.mentalMap,
    );
    expect(journeyStepIdFromRouteKey('invalid'), isNull);
  });

  test('therapy goals completed when only completed goals exist', () {
    const progress = PatientJourneyProgress(
      activeQuestionnaireCount: 0,
      completedQuestionnaireCount: 0,
      hasMonitorToday: false,
      releasedResourceCount: 0,
      completedResourceCount: 0,
      activeTherapyGoalCount: 0,
      completedTherapyGoalCount: 2,
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
    final goals = steps.firstWhere((s) => s.id == JourneyStepId.therapyGoals);
    expect(goals.availability, JourneyStepAvailability.completed);
  });

  test('blocked and inDevelopment open placeholder', () {
    expect(JourneyStepAvailability.blocked.opensPlaceholder, isTrue);
    expect(JourneyStepAvailability.inDevelopment.opensPlaceholder, isTrue);
    expect(JourneyStepAvailability.available.isNavigableToModule, isTrue);
  });

  test('journey uses clinical labels aligned with scope', () {
    final steps = buildPatientJourneySteps(null);
    final byId = {for (final s in steps) s.id: s};

    expect(byId[JourneyStepId.timeline]!.title, 'Linha da vida');
    expect(byId[JourneyStepId.problems]!.title, 'Problemas e demandas');
    expect(byId[JourneyStepId.library]!.title, 'Biblioteca terapêutica');
    expect(
      byId[JourneyStepId.mentalMap]!.subtitle,
      contains('formulação clínica'),
    );
  });

  group('progressFraction reflete o preenchimento real', () {
    test(
        'genograma e linha da vida escalam com o preenchimento real, contra '
        'uma meta de referência (5 pessoas / 5 eventos = 100%)', () {
      final poucoDado = buildPatientJourneySteps(_progress(
        genogramPeopleCount: 1,
        timelineEventCount: 1,
      ));
      final poucoById = {for (final s in poucoDado) s.id: s};
      expect(
        poucoById[JourneyStepId.genogram]!.progressFraction,
        closeTo(0.2, 1e-9), // 1/5
      );
      expect(
        poucoById[JourneyStepId.timeline]!.progressFraction,
        closeTo(0.2, 1e-9),
      );
      expect(
        poucoById[JourneyStepId.genogram]!.availability,
        JourneyStepAvailability.inProgress,
      );

      final metade = buildPatientJourneySteps(_progress(
        genogramPeopleCount: 3,
        timelineEventCount: 4,
      ));
      final metadeById = {for (final s in metade) s.id: s};
      expect(
        metadeById[JourneyStepId.genogram]!.progressFraction,
        closeTo(0.6, 1e-9), // 3/5
      );
      expect(
        metadeById[JourneyStepId.timeline]!.progressFraction,
        closeTo(0.8, 1e-9), // 4/5
      );

      // Acima da meta: trava em 1.0 (não passa de 100%) e vira "concluído",
      // mesmo que a lista continue crescendo depois disso.
      final muitoDado = buildPatientJourneySteps(_progress(
        genogramPeopleCount: 25,
        genogramRelationshipCount: 20,
        timelineEventCount: 40,
      ));
      final muitoById = {for (final s in muitoDado) s.id: s};
      expect(muitoById[JourneyStepId.genogram]!.progressFraction, 1.0);
      expect(muitoById[JourneyStepId.timeline]!.progressFraction, 1.0);
      expect(
        muitoById[JourneyStepId.genogram]!.availability,
        JourneyStepAvailability.completed,
      );
      expect(
        muitoById[JourneyStepId.timeline]!.availability,
        JourneyStepAvailability.completed,
      );
    });

    test(
        'questionários bloqueado (sem instrumento liberado) não tem anel — '
        'antes retornava 0.0, indistinguível visualmente de "disponível"',
        () {
      final step = buildPatientJourneySteps(_progress())
          .firstWhere((s) => s.id == JourneyStepId.questionnaires);
      expect(step.availability, JourneyStepAvailability.blocked);
      expect(step.progressFraction, isNull);
    });

    test('questionários parcial: fração bate com concluído/ativo', () {
      final step = buildPatientJourneySteps(_progress(
        activeQuestionnaireCount: 5,
        completedQuestionnaireCount: 2,
      )).firstWhere((s) => s.id == JourneyStepId.questionnaires);
      expect(step.progressFraction, closeTo(0.4, 1e-9));
    });

    test('questionários 100%: fração vira 1.0 quando todos concluídos', () {
      final step = buildPatientJourneySteps(_progress(
        activeQuestionnaireCount: 5,
        completedQuestionnaireCount: 5,
      )).firstWhere((s) => s.id == JourneyStepId.questionnaires);
      expect(step.progressFraction, 1.0);
    });

    test('objetivos: fração bate mesmo quando availability não é "completed"',
        () {
      // 1 ativo + 9 concluídos = 90% real, mas availability fica "available"
      // (regra: qualquer objetivo ativo mantém o passo "disponível").
      final step = buildPatientJourneySteps(_progress(
        activeTherapyGoalCount: 1,
        completedTherapyGoalCount: 9,
      )).firstWhere((s) => s.id == JourneyStepId.therapyGoals);
      expect(step.availability, JourneyStepAvailability.available);
      expect(step.progressFraction, closeTo(0.9, 1e-9));
    });

    test('problemas: fração bate com resolvido/total', () {
      final step = buildPatientJourneySteps(_progress(
        totalProblemCount: 5,
        openProblemCount: 2,
      )).firstWhere((s) => s.id == JourneyStepId.problems);
      expect(step.progressFraction, closeTo(0.6, 1e-9));
    });

    test(
        '"Conhecendo você" reflete o preenchimento real — antes ficava '
        'travado em "Não iniciado" mesmo com campos preenchidos, porque a '
        'disponibilidade era hardcoded, sem nenhuma lógica ligada', () {
      // Sem progresso algum: disponível, sem anel de fato começado.
      final semDado = buildPatientJourneySteps(null)
          .firstWhere((s) => s.id == JourneyStepId.initialAssessment);
      expect(semDado.availability, JourneyStepAvailability.available);
      expect(semDado.progressFraction, 0.0);

      // Parcialmente preenchido: vira "em andamento" e mostra a fração real.
      final parcial = buildPatientJourneySteps(
        _progress(initialAssessmentFraction: 0.25),
      ).firstWhere((s) => s.id == JourneyStepId.initialAssessment);
      expect(parcial.availability, JourneyStepAvailability.inProgress);
      expect(parcial.progressFraction, closeTo(0.25, 1e-9));

      // 100% dos 24 campos: vira "concluído".
      final completo = buildPatientJourneySteps(
        _progress(initialAssessmentFraction: 1.0),
      ).firstWhere((s) => s.id == JourneyStepId.initialAssessment);
      expect(completo.availability, JourneyStepAvailability.completed);
      expect(completo.progressFraction, 1.0);
    });

    test(
        'nenhum passo bloqueado ou em desenvolvimento mostra anel — '
        'invariante geral do catálogo, não só do caso testado manualmente',
        () {
      final steps = buildPatientJourneySteps(_progress(
        activeQuestionnaireCount: 3,
        completedQuestionnaireCount: 1,
        genogramPeopleCount: 4,
        timelineEventCount: 2,
      ));
      for (final step in steps) {
        if (step.availability == JourneyStepAvailability.blocked ||
            step.availability == JourneyStepAvailability.inDevelopment) {
          expect(
            step.progressFraction,
            isNull,
            reason: '${step.id} está ${step.availability} mas tem anel',
          );
        }
      }
    });
  });
}

/// Constrói um [PatientJourneyProgress] com todos os campos zerados, exceto
/// os informados — evita repetir os 17 campos em cada teste novo.
PatientJourneyProgress _progress({
  int activeQuestionnaireCount = 0,
  int completedQuestionnaireCount = 0,
  bool hasMonitorToday = false,
  int releasedResourceCount = 0,
  int completedResourceCount = 0,
  int activeTherapyGoalCount = 0,
  int completedTherapyGoalCount = 0,
  int totalProblemCount = 0,
  int openProblemCount = 0,
  bool hasCheckInToday = false,
  int timelineEventCount = 0,
  int genogramPeopleCount = 0,
  int genogramRelationshipCount = 0,
  int checkInCount = 0,
  int dailyMonitorCount = 0,
  bool hasYsqStructuredResult = false,
  bool hasYamiStructuredResult = false,
  double initialAssessmentFraction = 0.0,
}) =>
    PatientJourneyProgress(
      activeQuestionnaireCount: activeQuestionnaireCount,
      completedQuestionnaireCount: completedQuestionnaireCount,
      hasMonitorToday: hasMonitorToday,
      releasedResourceCount: releasedResourceCount,
      completedResourceCount: completedResourceCount,
      activeTherapyGoalCount: activeTherapyGoalCount,
      completedTherapyGoalCount: completedTherapyGoalCount,
      totalProblemCount: totalProblemCount,
      openProblemCount: openProblemCount,
      hasCheckInToday: hasCheckInToday,
      timelineEventCount: timelineEventCount,
      genogramPeopleCount: genogramPeopleCount,
      genogramRelationshipCount: genogramRelationshipCount,
      checkInCount: checkInCount,
      dailyMonitorCount: dailyMonitorCount,
      hasYsqStructuredResult: hasYsqStructuredResult,
      hasYamiStructuredResult: hasYamiStructuredResult,
      initialAssessmentFraction: initialAssessmentFraction,
    );
