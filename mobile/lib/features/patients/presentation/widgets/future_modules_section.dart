import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/clinical_module_card.dart';
import '../../../../shared/widgets/responsive_content.dart';

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
        const AppSectionHeader(
          title: 'Central clínica',
          subtitle:
              'Acesse os módulos por finalidade para reduzir ruído e acelerar a navegação.',
        ),
        const SizedBox(height: AppSpacing.md),
        _ModuleGroup(
          title: 'Avaliação',
          children: [
            ClinicalModuleCard(
              icon: Icons.bar_chart_outlined,
              title: 'Dashboard clínico',
              subtitle: 'Síntese dos dados clínicos estruturados.',
              accentColor: AppColors.moduleDashboard,
              onTap: onClinicalDashboardTap,
              enabled: onClinicalDashboardTap != null,
            ),
            ClinicalModuleCard(
              icon: Icons.assignment_outlined,
              title: 'Questionários',
              subtitle: 'Ver disponíveis e iniciar aplicação.',
              accentColor: AppColors.moduleQuestionnaires,
              onTap: onQuestionnairesTap,
              enabled: onQuestionnairesTap != null,
            ),
            ClinicalModuleCard(
              icon: Icons.analytics_outlined,
              title: 'Resultados',
              subtitle: 'Respostas concluídas e detalhe por categoria.',
              accentColor: AppColors.cyan,
              onTap: onResultsTap,
              enabled: onResultsTap != null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ModuleGroup(
          title: 'Formulação',
          children: [
            ClinicalModuleCard(
              icon: Icons.hub_outlined,
              title: 'Mapa mental',
              subtitle: 'Visão integrada dos dados clínicos.',
              accentColor: AppColors.moduleMentalMap,
              onTap: onMentalMapTap,
              enabled: onMentalMapTap != null,
            ),
            ClinicalModuleCard(
              icon: Icons.family_restroom_outlined,
              title: 'Genograma',
              subtitle: 'Pessoas e relações familiares.',
              accentColor: AppColors.moduleGenogram,
              onTap: onGenogramTap,
              enabled: onGenogramTap != null,
            ),
            ClinicalModuleCard(
              icon: Icons.timeline_outlined,
              title: 'Linha do tempo',
              subtitle: 'Eventos importantes da história.',
              accentColor: AppColors.moduleTimeline,
              onTap: onTimelineTap,
              enabled: onTimelineTap != null,
            ),
            ClinicalModuleCard(
              icon: Icons.psychology_alt_outlined,
              title: 'Referência de personalidade',
              subtitle: 'Fatores, facetas e leitura clínica.',
              accentColor: AppColors.purple,
              onTap: onPersonalityReferenceTap,
              enabled: onPersonalityReferenceTap != null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ModuleGroup(
          title: 'Acompanhamento',
          children: [
            ClinicalModuleCard(
              icon: Icons.fact_check_outlined,
              title: 'Check-ins',
              subtitle: 'Registros rápidos do paciente.',
              accentColor: AppColors.moduleCheckIn,
              onTap: onCheckInsTap,
              enabled: onCheckInsTap != null,
            ),
            ClinicalModuleCard(
              icon: Icons.monitor_heart_outlined,
              title: 'Monitor diário',
              subtitle: 'Histórico de acompanhamentos.',
              accentColor: AppColors.moduleMonitor,
              onTap: onDailyMonitorsTap,
              enabled: onDailyMonitorsTap != null,
            ),
            ClinicalModuleCard(
              icon: Icons.flag_outlined,
              title: 'Objetivos da terapia',
              subtitle: 'Metas terapêuticas do paciente.',
              accentColor: AppColors.moduleGoals,
              onTap: onTherapyGoalsTap,
              enabled: onTherapyGoalsTap != null,
            ),
            ClinicalModuleCard(
              icon: Icons.report_problem_outlined,
              title: 'Problemas',
              subtitle: 'Queixas e focos de trabalho.',
              accentColor: AppColors.moduleProblems,
              onTap: onProblemsTap,
              enabled: onProblemsTap != null,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        _ModuleGroup(
          title: 'Intervenção',
          children: [
            ClinicalModuleCard(
              icon: Icons.menu_book_outlined,
              title: 'Recursos terapêuticos',
              subtitle: 'Liberar materiais e acompanhar progresso.',
              accentColor: AppColors.moduleResources,
              onTap: onTherapyResourcesTap,
              enabled: onTherapyResourcesTap != null,
            ),
          ],
        ),
      ],
    );
  }
}

class _ModuleGroup extends StatelessWidget {
  const _ModuleGroup({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceWarm,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ResponsiveGrid(
              mediumColumns: 2,
              expandedColumns: 2,
              spacing: AppSpacing.sm,
              children: children,
            ),
          ],
        ),
      ),
    );
  }
}
