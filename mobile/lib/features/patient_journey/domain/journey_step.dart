import 'package:flutter/material.dart';

import 'journey_phase.dart';
import 'journey_step_availability.dart';
import 'journey_step_id.dart';
import 'patient_journey_progress.dart';
import '../../clinic_entitlements/domain/clinic_feature_entitlement.dart';

/// Definição de um passo na trilha do paciente.
class JourneyStep {
  const JourneyStep({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.availability,
    required this.phase,
    this.progressHint,
    required this.order,
  });

  final JourneyStepId id;
  final String title;
  final String subtitle;
  final IconData icon;
  final JourneyStepAvailability availability;

  /// Fase clínica à qual o passo pertence.
  final JourneyPhase phase;
  final String? progressHint;
  final int order;
}

/// Catálogo da trilha com disponibilidade derivada do progresso (quando houver).
List<JourneyStep> buildPatientJourneySteps(
  PatientJourneyProgress? progress, {
  ClinicFeatureEntitlements entitlements = ClinicFeatureEntitlements.empty,
  bool resultsReleased = true,
}) {
  final p = progress;

  bool enabled(String featureKey) {
    return entitlements.isEnabled(featureKey);
  }

  JourneyStepAvailability questionnairesStatus() {
    if (!enabled('questionnaires')) return JourneyStepAvailability.blocked;
    if (p == null) return JourneyStepAvailability.available;
    if (p.activeQuestionnaireCount == 0) {
      return JourneyStepAvailability.blocked;
    }
    if (p.allActiveQuestionnairesCompleted) {
      return JourneyStepAvailability.completed;
    }
    if (p.completedQuestionnaireCount > 0) {
      return JourneyStepAvailability.available;
    }
    return JourneyStepAvailability.available;
  }

  JourneyStepAvailability monitorStatus() {
    if (p == null) return JourneyStepAvailability.available;
    return p.hasMonitorToday
        ? JourneyStepAvailability.completed
        : JourneyStepAvailability.available;
  }

  JourneyStepAvailability libraryStatus() {
    if (!enabled('resources')) return JourneyStepAvailability.blocked;
    if (p == null) return JourneyStepAvailability.available;
    if (p.completedResourceCount > 0) {
      return JourneyStepAvailability.completed;
    }
    if (p.releasedResourceCount == 0) {
      return JourneyStepAvailability.available;
    }
    return JourneyStepAvailability.available;
  }

  String? questionnairesHint() {
    if (!enabled('questionnaires')) {
      return 'Módulo bloqueado pelo plano da clínica.';
    }
    if (p == null) return null;
    if (p.activeQuestionnaireCount == 0) {
      return 'Nenhum instrumento foi liberado para você.';
    }
    if (p.allActiveQuestionnairesCompleted) {
      return 'Todos os instrumentos disponíveis foram concluídos.';
    }
    return '${p.completedQuestionnaireCount} de ${p.activeQuestionnaireCount} instrumento(s) concluído(s).';
  }

  String? monitorHint() {
    if (p == null) return null;
    return p.hasMonitorToday
        ? 'Registro de hoje enviado.'
        : 'Nenhum registro hoje ainda.';
  }

  JourneyStepAvailability clinicalDashboardStatus() {
    if (!enabled('reports')) return JourneyStepAvailability.blocked;
    // Resultados só ficam disponíveis após o psicólogo liberar.
    if (!resultsReleased) return JourneyStepAvailability.blocked;
    if (p == null) return JourneyStepAvailability.available;
    if (!p.hasClinicalDashboardData) {
      return JourneyStepAvailability.available;
    }
    return JourneyStepAvailability.inProgress;
  }

  String? clinicalDashboardHint() {
    if (!enabled('reports')) return 'Módulo bloqueado pelo plano da clínica.';
    if (!resultsReleased) {
      return 'Aguardando a liberação do seu psicólogo.';
    }
    if (p == null) return null;
    if (!p.hasClinicalDashboardData) {
      return 'Conclua YSQ ou YAMI para ver gráficos.';
    }
    final parts = <String>[];
    if (p.hasYsqStructuredResult) parts.add('YSQ');
    if (p.hasYamiStructuredResult) parts.add('YAMI');
    return 'Resultados: ${parts.join(' e ')}.';
  }

  String? libraryHint() {
    if (!enabled('resources')) return 'Módulo bloqueado pelo plano da clínica.';
    if (p == null) return null;
    if (p.releasedResourceCount == 0) {
      return 'Aguardando liberação pelo psicólogo.';
    }
    if (p.completedResourceCount > 0) {
      return '${p.completedResourceCount} material(is) concluído(s).';
    }
    return '${p.releasedResourceCount} material(is) liberado(s).';
  }

  JourneyStepAvailability therapyGoalsStatus() {
    if (p == null) return JourneyStepAvailability.available;
    if (p.activeTherapyGoalCount > 0) {
      return JourneyStepAvailability.available;
    }
    if (p.completedTherapyGoalCount > 0) {
      return JourneyStepAvailability.completed;
    }
    return JourneyStepAvailability.available;
  }

  String? therapyGoalsHint() {
    if (p == null) return null;
    if (p.activeTherapyGoalCount > 0) {
      return '${p.activeTherapyGoalCount} objetivo(s) ativo(s).';
    }
    if (p.completedTherapyGoalCount > 0) {
      return '${p.completedTherapyGoalCount} objetivo(s) concluído(s).';
    }
    return 'Nenhum objetivo registrado ainda.';
  }

  JourneyStepAvailability problemsStatus() {
    if (p == null) return JourneyStepAvailability.available;
    if (p.totalProblemCount == 0) {
      return JourneyStepAvailability.available;
    }
    if (p.openProblemCount > 0) {
      return JourneyStepAvailability.inProgress;
    }
    return JourneyStepAvailability.completed;
  }

  String? problemsHint() {
    if (p == null) return null;
    if (p.totalProblemCount == 0) {
      return 'Nenhum problema registrado ainda.';
    }
    if (p.openProblemCount > 0) {
      return '${p.openProblemCount} problema(s) em acompanhamento.';
    }
    return 'Todos os problemas estão resolvidos ou arquivados.';
  }

  JourneyStepAvailability checkInStatus() {
    if (p == null) return JourneyStepAvailability.available;
    return p.hasCheckInToday
        ? JourneyStepAvailability.completed
        : JourneyStepAvailability.available;
  }

  String? checkInHint() {
    if (p == null) return null;
    return p.hasCheckInToday
        ? 'Check-in de hoje já registrado.'
        : 'Faça seu check-in de hoje.';
  }

  JourneyStepAvailability timelineStatus() {
    if (p == null) return JourneyStepAvailability.available;
    if (p.timelineEventCount == 0) {
      return JourneyStepAvailability.available;
    }
    return JourneyStepAvailability.inProgress;
  }

  String? timelineHint() {
    if (p == null) return null;
    if (p.timelineEventCount == 0) {
      return 'Nenhum evento registrado ainda.';
    }
    return '${p.timelineEventCount} evento(s) na linha do tempo.';
  }

  JourneyStepAvailability genogramStatus() {
    if (p == null) return JourneyStepAvailability.available;
    if (!p.hasGenogramContent) {
      return JourneyStepAvailability.available;
    }
    return JourneyStepAvailability.inProgress;
  }

  String? genogramHint() {
    if (p == null) return null;
    if (!p.hasGenogramContent) {
      return 'Nenhuma pessoa no genograma ainda.';
    }
    return '${p.genogramPeopleCount} pessoa(s), ${p.genogramRelationshipCount} relação(ões).';
  }

  JourneyStepAvailability mentalMapStatus() {
    // O mapa mental deriva dos resultados clínicos — bloqueado até liberar.
    if (!resultsReleased) return JourneyStepAvailability.blocked;
    if (p == null) return JourneyStepAvailability.available;
    if (!p.hasMentalMapRelevantData) {
      return JourneyStepAvailability.available;
    }
    return JourneyStepAvailability.inProgress;
  }

  String? mentalMapHint() {
    if (!resultsReleased) {
      return 'Aguardando a liberação do seu psicólogo.';
    }
    if (p == null) return null;
    if (!p.hasMentalMapRelevantData) {
      return 'Registre dados nos módulos para montar o mapa.';
    }
    return 'Visão integrada com dados já registrados.';
  }

  return [
    // ── Fase 1 · Conhecer ────────────────────────────────────────────────────
    const JourneyStep(
      id: JourneyStepId.initialAssessment,
      title: 'Conhecendo você',
      subtitle: 'Sua história atual e como está sua vida hoje.',
      icon: Icons.assignment_ind_outlined,
      availability: JourneyStepAvailability.available,
      phase: JourneyPhase.conhecer,
      order: 0,
    ),
    const JourneyStep(
      id: JourneyStepId.psychoeducation,
      title: 'Biblioteca de Psicoeducação',
      subtitle: 'Entenda os esquemas, os modos e o Adulto Saudável, no seu ritmo.',
      icon: Icons.auto_stories_outlined,
      availability: JourneyStepAvailability.available,
      phase: JourneyPhase.conhecer,
      order: 1,
    ),
    JourneyStep(
      id: JourneyStepId.genogram,
      title: 'Genograma',
      subtitle: 'Mapa das relações familiares e vínculos importantes.',
      icon: Icons.family_restroom_outlined,
      availability: genogramStatus(),
      phase: JourneyPhase.conhecer,
      progressHint: genogramHint(),
      order: 2,
    ),
    JourneyStep(
      id: JourneyStepId.timeline,
      title: 'Linha da vida',
      subtitle: 'Eventos importantes da sua história e da terapia.',
      icon: Icons.timeline_outlined,
      availability: timelineStatus(),
      phase: JourneyPhase.conhecer,
      progressHint: timelineHint(),
      order: 3,
    ),
    // ── Fase 2 · Avaliar ─────────────────────────────────────────────────────
    JourneyStep(
      id: JourneyStepId.questionnaires,
      title: 'Questionários',
      subtitle: 'Instrumentos clínicos como YSQ, YAMI e complementares.',
      icon: Icons.assignment_outlined,
      availability: questionnairesStatus(),
      phase: JourneyPhase.avaliar,
      progressHint: questionnairesHint(),
      order: 4,
    ),
    // ── Fase 3 · Compreender ─────────────────────────────────────────────────
    JourneyStep(
      id: JourneyStepId.problems,
      title: 'Problemas e demandas',
      subtitle: 'Focos, queixas e pontos de atenção em acompanhamento.',
      icon: Icons.report_problem_outlined,
      availability: problemsStatus(),
      phase: JourneyPhase.compreender,
      progressHint: problemsHint(),
      order: 5,
    ),
    JourneyStep(
      id: JourneyStepId.mentalMap,
      title: 'Mapa mental',
      subtitle: 'Síntese integrada da sua formulação clínica.',
      icon: Icons.hub_outlined,
      availability: mentalMapStatus(),
      phase: JourneyPhase.compreender,
      progressHint: mentalMapHint(),
      order: 6,
    ),
    // ── Fase 4 · Intervir ────────────────────────────────────────────────────
    JourneyStep(
      id: JourneyStepId.therapyGoals,
      title: 'Objetivos da terapia',
      subtitle: 'Metas acordadas com seu psicólogo.',
      icon: Icons.flag_outlined,
      availability: therapyGoalsStatus(),
      phase: JourneyPhase.intervir,
      progressHint: therapyGoalsHint(),
      order: 7,
    ),
    JourneyStep(
      id: JourneyStepId.library,
      title: 'Biblioteca terapêutica',
      subtitle: 'Psicoeducação e recursos liberados para você.',
      icon: Icons.menu_book_outlined,
      availability: libraryStatus(),
      phase: JourneyPhase.intervir,
      progressHint: libraryHint(),
      order: 8,
    ),
    // ── Fase 5 · Acompanhar ──────────────────────────────────────────────────
    JourneyStep(
      id: JourneyStepId.checkIn,
      title: 'Check-in',
      subtitle: 'Registro breve entre sessões.',
      icon: Icons.fact_check_outlined,
      availability: checkInStatus(),
      phase: JourneyPhase.acompanhar,
      progressHint: checkInHint(),
      order: 9,
    ),
    JourneyStep(
      id: JourneyStepId.dailyMonitor,
      title: 'Monitor diário',
      subtitle: 'Humor, rotina e percepção do dia a dia.',
      icon: Icons.monitor_heart_outlined,
      availability: monitorStatus(),
      phase: JourneyPhase.acompanhar,
      progressHint: monitorHint(),
      order: 10,
    ),
    JourneyStep(
      id: JourneyStepId.results,
      title: 'Meus resultados',
      subtitle: 'Resultados liberados e gráficos dos instrumentos.',
      icon: Icons.analytics_outlined,
      availability: clinicalDashboardStatus(),
      phase: JourneyPhase.acompanhar,
      progressHint: clinicalDashboardHint(),
      order: 11,
    ),
  ];
}
