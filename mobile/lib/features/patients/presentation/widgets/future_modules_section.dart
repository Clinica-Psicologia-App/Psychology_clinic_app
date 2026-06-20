import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/clinical_module_card.dart';

/// Módulos do paciente (staff).
class FutureModulesSection extends StatelessWidget {
  const FutureModulesSection({
    super.key,
    this.onQuestionnairesTap,
    this.onResultsTap,
    this.onTherapyResourcesTap,
    this.onDailyMonitorsTap,
    this.onTherapyGoalsTap,
    this.onProblemsTap,
    this.onCheckInsTap,
    this.onTimelineTap,
    this.onGenogramTap,
    this.onMentalMapTap,
    this.onClinicalDashboardTap,
    this.onPersonalityReferenceTap,
  });

  final VoidCallback? onQuestionnairesTap;
  final VoidCallback? onResultsTap;
  final VoidCallback? onTherapyResourcesTap;
  final VoidCallback? onDailyMonitorsTap;
  final VoidCallback? onTherapyGoalsTap;
  final VoidCallback? onProblemsTap;
  final VoidCallback? onCheckInsTap;
  final VoidCallback? onTimelineTap;
  final VoidCallback? onGenogramTap;
  final VoidCallback? onMentalMapTap;
  final VoidCallback? onClinicalDashboardTap;
  final VoidCallback? onPersonalityReferenceTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Módulos', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _gap(ClinicalModuleCard(
          icon: Icons.assignment_outlined,
          title: 'Questionários',
          subtitle: 'Ver disponíveis e iniciar aplicação para este paciente.',
          accentColor: AppColors.moduleQuestionnaires,
          onTap: onQuestionnairesTap,
          enabled: onQuestionnairesTap != null,
        )),
        _gap(ClinicalModuleCard(
          icon: Icons.analytics_outlined,
          title: 'Resultados (lista)',
          subtitle: 'Respostas concluídas e detalhe por categoria.',
          accentColor: AppColors.cyan,
          onTap: onResultsTap,
          enabled: onResultsTap != null,
        )),
        _gap(ClinicalModuleCard(
          icon: Icons.bar_chart_outlined,
          title: 'Dashboard clínico',
          subtitle: 'Gráficos YSQ/YAMI a partir do snapshot (somente leitura).',
          accentColor: AppColors.moduleDashboard,
          onTap: onClinicalDashboardTap,
          enabled: onClinicalDashboardTap != null,
        )),
        _gap(ClinicalModuleCard(
          icon: Icons.psychology_alt_outlined,
          title: 'Referência de personalidade',
          subtitle: 'Fatores, facetas e sugestões clínicas de leitura.',
          accentColor: AppColors.purple,
          onTap: onPersonalityReferenceTap,
          enabled: onPersonalityReferenceTap != null,
        )),
        _gap(ClinicalModuleCard(
          icon: Icons.menu_book_outlined,
          title: 'Recursos terapêuticos',
          subtitle: 'Liberar materiais e acompanhar progresso do paciente.',
          accentColor: AppColors.moduleResources,
          onTap: onTherapyResourcesTap,
          enabled: onTherapyResourcesTap != null,
        )),
        _gap(ClinicalModuleCard(
          icon: Icons.report_problem_outlined,
          title: 'Problemas',
          subtitle: 'Queixas e focos de trabalho do paciente.',
          accentColor: AppColors.moduleProblems,
          onTap: onProblemsTap,
          enabled: onProblemsTap != null,
        )),
        _gap(ClinicalModuleCard(
          icon: Icons.flag_outlined,
          title: 'Objetivos da terapia',
          subtitle: 'Metas terapêuticas do paciente.',
          accentColor: AppColors.moduleGoals,
          onTap: onTherapyGoalsTap,
          enabled: onTherapyGoalsTap != null,
        )),
        _gap(ClinicalModuleCard(
          icon: Icons.fact_check_outlined,
          title: 'Check-ins',
          subtitle: 'Registros rápidos do paciente (somente leitura).',
          accentColor: AppColors.moduleCheckIn,
          onTap: onCheckInsTap,
          enabled: onCheckInsTap != null,
        )),
        _gap(ClinicalModuleCard(
          icon: Icons.hub_outlined,
          title: 'Mapa mental',
          subtitle: 'Visão integrada dos dados clínicos do paciente.',
          accentColor: AppColors.moduleMentalMap,
          onTap: onMentalMapTap,
          enabled: onMentalMapTap != null,
        )),
        _gap(ClinicalModuleCard(
          icon: Icons.family_restroom_outlined,
          title: 'Genograma',
          subtitle: 'Pessoas e relações familiares do paciente.',
          accentColor: AppColors.moduleGenogram,
          onTap: onGenogramTap,
          enabled: onGenogramTap != null,
        )),
        _gap(ClinicalModuleCard(
          icon: Icons.timeline_outlined,
          title: 'Linha do tempo',
          subtitle:
              'Eventos importantes da história e do processo terapêutico.',
          accentColor: AppColors.moduleTimeline,
          onTap: onTimelineTap,
          enabled: onTimelineTap != null,
        )),
        _gap(ClinicalModuleCard(
          icon: Icons.monitor_heart_outlined,
          title: 'Monitor diário',
          subtitle: 'Histórico de acompanhamentos registrados pelo paciente.',
          accentColor: AppColors.moduleMonitor,
          onTap: onDailyMonitorsTap,
          enabled: onDailyMonitorsTap != null,
        )),
      ],
    );
  }

  Widget _gap(Widget child) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: child,
      );
}
