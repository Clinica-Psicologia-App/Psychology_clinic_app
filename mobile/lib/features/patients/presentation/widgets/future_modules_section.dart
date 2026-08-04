import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_motion.dart';
import '../../../../shared/widgets/module_grid_card.dart';
import '../../../clinic_entitlements/domain/clinic_feature_entitlement.dart';
import '../../../clinic_entitlements/providers/clinic_entitlements_providers.dart';
import '../../../clinical_dashboard/presentation/clinical_dashboard_routes.dart';
import '../../../daily_monitors/presentation/daily_monitor_routes.dart';
import '../../../initial_assessment/presentation/initial_assessment_routes.dart';
import '../../../mental_map/presentation/mental_map_routes.dart';
import '../../../patient_infographic/presentation/patient_infographic_route_helpers.dart';
import '../../../patient_library/presentation/patient_library_routes.dart';
import '../../../psychoeducation/presentation/psychoeducation_routes.dart';
import '../../../patient_check_ins/presentation/patient_check_in_routes.dart';
import '../../../patient_problems/presentation/patient_problem_routes.dart';
import '../../../personality_reference/presentation/personality_reference_routes.dart';
import '../../../profile/domain/profile_role.dart';
import '../../../questionnaires/presentation/questionnaire_routes.dart';
import '../../../results/presentation/result_routes.dart';
import '../../../therapy_goals/presentation/therapy_goal_routes.dart';
import '../../../therapy_resources/presentation/therapy_resource_routes.dart';

class _ModuleSpec {
  const _ModuleSpec({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback? onTap;
}

class _ModuleGroup {
  const _ModuleGroup({
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.modules,
  });

  final String title;
  final String subtitle;
  final Color accentColor;
  final List<_ModuleSpec> modules;
}

/// Seção de módulos clínicos do paciente (visão do psicólogo).
/// Organizada em 5 grandes eixos: Conhecer, Avaliar, Compreender, Intervir e Acompanhar.
class FutureModulesSection extends ConsumerWidget {
  const FutureModulesSection({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entitlementsAsync = ref.watch(currentClinicEntitlementsProvider);
    final entitlements =
        entitlementsAsync.valueOrNull ?? ClinicFeatureEntitlements.empty;
    final isLoading = entitlementsAsync.isLoading;

    VoidCallback? gatedTap(String featureKey, VoidCallback action) {
      if (isLoading) return null;
      return entitlements.isEnabled(featureKey) ? action : null;
    }

    String gatedSubtitle({
      required String featureKey,
      required String subtitle,
    }) {
      if (isLoading) return 'Validando permissões...';
      if (!entitlements.isEnabled(featureKey)) {
        return 'Bloqueado pelo plano da clínica.';
      }
      return subtitle;
    }

    final groups = <_ModuleGroup>[
      // ── 1. Conhecer meu paciente ──────────────────────────────────────────
      _ModuleGroup(
        title: 'Conhecer meu paciente',
        subtitle: 'História, vínculos e contexto de vida.',
        accentColor: AppColors.cyan,
        modules: [
          _ModuleSpec(
            icon: Icons.assignment_ind_outlined,
            title: 'Dados Iniciais',
            subtitle: 'Motivo, funcionamento e impressões.',
            accentColor: AppColors.cyan,
            onTap: () => context.push(
              InitialAssessmentRoutes.staff(role: role, patientId: patientId),
            ),
          ),
          const _ModuleSpec(
            icon: Icons.workspaces_outlined,
            title: 'Contexto de Vida',
            subtitle: 'Em breve',
            accentColor: AppColors.cyan,
            onTap: null,
          ),
          _ModuleSpec(
            icon: Icons.timeline_outlined,
            title: 'Linha do Tempo',
            subtitle: 'Eventos da história terapêutica.',
            accentColor: AppColors.moduleTimeline,
            onTap: () => context.push(
              InitialAssessmentRoutes.staffHistory(
                role: role,
                patientId: patientId,
              ),
            ),
          ),
          _ModuleSpec(
            icon: Icons.report_problem_outlined,
            title: 'Demandas Terapêuticas',
            subtitle: 'Queixas e focos de trabalho.',
            accentColor: AppColors.moduleProblems,
            onTap: () => context.push(
              PatientProblemRoutes.staffList(
                role: role,
                patientId: patientId,
              ),
            ),
          ),
          _ModuleSpec(
            icon: Icons.family_restroom_outlined,
            title: 'Genograma',
            subtitle: 'Pessoas e relações familiares.',
            accentColor: AppColors.moduleGenogram,
            onTap: () => context.push(
              InitialAssessmentRoutes.staffFamily(
                role: role,
                patientId: patientId,
              ),
            ),
          ),
          const _ModuleSpec(
            icon: Icons.self_improvement_outlined,
            title: 'Recursos Internos',
            subtitle: 'Em breve',
            accentColor: AppColors.cyan,
            onTap: null,
          ),
          const _ModuleSpec(
            icon: Icons.summarize_outlined,
            title: 'Síntese',
            subtitle: 'Em breve',
            accentColor: AppColors.cyan,
            onTap: null,
          ),
        ],
      ),

      // ── 2. Avaliar ────────────────────────────────────────────────────────
      _ModuleGroup(
        title: 'Avaliar',
        subtitle: 'Instrumentos psicológicos e resultados.',
        accentColor: AppColors.blue,
        modules: [
          _ModuleSpec(
            icon: Icons.schema_outlined,
            title: 'Esquemas',
            subtitle: gatedSubtitle(
              featureKey: 'questionnaires',
              subtitle: 'YPI, YSQ e instrumentos de esquema.',
            ),
            accentColor: AppColors.moduleQuestionnaires,
            onTap: gatedTap(
              'questionnaires',
              () => context.push(
                QuestionnaireRoutes.list(role: role, patientId: patientId),
              ),
            ),
          ),
          _ModuleSpec(
            icon: Icons.psychology_alt_outlined,
            title: 'Personalidade',
            subtitle: 'Fatores, facetas e leituras clínicas.',
            accentColor: AppColors.purple,
            onTap: () => context.push(
              PersonalityReferenceRoutes.staffList(
                role: role,
                patientId: patientId,
              ),
            ),
          ),
          _ModuleSpec(
            icon: Icons.handshake_outlined,
            title: 'Apego',
            subtitle: gatedSubtitle(
              featureKey: 'questionnaires',
              subtitle: 'Estilos e padrões de vinculação.',
            ),
            accentColor: AppColors.moduleQuestionnaires,
            onTap: gatedTap(
              'questionnaires',
              () => context.push(
                QuestionnaireRoutes.list(role: role, patientId: patientId),
              ),
            ),
          ),
          _ModuleSpec(
            icon: Icons.analytics_outlined,
            title: 'Dashboard Clínico',
            subtitle: gatedSubtitle(
              featureKey: 'reports',
              subtitle: 'Resultados consolidados e perfil esquemático.',
            ),
            accentColor: AppColors.cyan,
            onTap: gatedTap(
              'reports',
              () => context.push(
                ResultRoutes.list(role: role, patientId: patientId),
              ),
            ),
          ),
          _ModuleSpec(
            icon: Icons.bar_chart_outlined,
            title: 'Síntese',
            subtitle: gatedSubtitle(
              featureKey: 'reports',
              subtitle: 'Dashboard gráfico integrado.',
            ),
            accentColor: AppColors.moduleDashboard,
            onTap: gatedTap(
              'reports',
              () => context.push(
                ClinicalDashboardRoutes.staffList(
                  role: role,
                  patientId: patientId,
                ),
              ),
            ),
          ),
        ],
      ),

      // ── 3. Compreender ────────────────────────────────────────────────────
      _ModuleGroup(
        title: 'Compreender',
        subtitle: 'Formulação e visão integrada do caso.',
        accentColor: AppColors.purple,
        modules: [
          _ModuleSpec(
            icon: Icons.hub_outlined,
            title: 'Mapa Mental',
            subtitle: 'Visão integrada dos dados clínicos.',
            accentColor: AppColors.moduleMentalMap,
            onTap: () => context.push(
              MentalMapRoutes.staffList(role: role, patientId: patientId),
            ),
          ),
          _ModuleSpec(
            icon: Icons.auto_graph_outlined,
            title: 'Infográficos',
            subtitle: gatedSubtitle(
              featureKey: 'reports',
              subtitle: 'Retrato visual do caso, pronto para exportar.',
            ),
            accentColor: AppColors.purple,
            onTap: gatedTap(
              'reports',
              () => context.push(
                PatientInfographicRoutes.staffList(
                  role: role,
                  patientId: patientId,
                ),
              ),
            ),
          ),
          const _ModuleSpec(
            icon: Icons.description_outlined,
            title: 'Formulação em Word',
            subtitle: 'Em breve',
            accentColor: AppColors.purple,
            onTap: null,
          ),
        ],
      ),

      // ── 4. Intervir ───────────────────────────────────────────────────────
      _ModuleGroup(
        title: 'Intervir',
        subtitle: 'Planejamento e recursos de intervenção.',
        accentColor: AppColors.moduleGoals,
        modules: [
          _ModuleSpec(
            icon: Icons.flag_outlined,
            title: 'Plano Terapêutico',
            subtitle: 'Metas e objetivos da terapia.',
            accentColor: AppColors.moduleGoals,
            onTap: () => context.push(
              TherapyGoalRoutes.staffList(role: role, patientId: patientId),
            ),
          ),
          _ModuleSpec(
            icon: Icons.menu_book_outlined,
            title: 'Recursos Terapêuticos',
            subtitle: gatedSubtitle(
              featureKey: 'resources',
              subtitle: 'Materiais e progresso do paciente.',
            ),
            accentColor: AppColors.moduleResources,
            onTap: gatedTap(
              'resources',
              () => context.push(
                TherapyResourceRoutes.staffList(
                  role: role,
                  patientId: patientId,
                ),
              ),
            ),
          ),
          _ModuleSpec(
            icon: Icons.movie_filter_outlined,
            title: 'Biblioteca de filmes',
            subtitle: gatedSubtitle(
              featureKey: 'resources',
              subtitle: 'Filmes e séries por esquema — indicar ao paciente.',
            ),
            accentColor: AppColors.purple,
            onTap: gatedTap(
              'resources',
              () => context.push(
                PatientLibraryRoutes.staffCatalog(
                  role: role,
                  patientId: patientId,
                ),
              ),
            ),
          ),
          _ModuleSpec(
            icon: Icons.auto_stories_outlined,
            title: 'Psicoeducação',
            subtitle: gatedSubtitle(
              featureKey: 'resources',
              subtitle: 'Módulos que o paciente vê na jornada.',
            ),
            accentColor: AppColors.moduleMentalMap,
            onTap: gatedTap(
              'resources',
              () => context.push(PsychoeducationRoutes.psychologist),
            ),
          ),
        ],
      ),

      // ── 5. Acompanhar ─────────────────────────────────────────────────────
      _ModuleGroup(
        title: 'Acompanhar',
        subtitle: 'Monitoramento contínuo entre sessões.',
        accentColor: AppColors.moduleCheckIn,
        modules: [
          _ModuleSpec(
            icon: Icons.fact_check_outlined,
            title: 'Check-in',
            subtitle: 'Humor, modos e esquemas em linha do tempo.',
            accentColor: AppColors.moduleCheckIn,
            onTap: () => context.push(
              PatientCheckInRoutes.staffList(role: role, patientId: patientId),
            ),
          ),
          _ModuleSpec(
            icon: Icons.monitor_heart_outlined,
            title: 'Diário',
            subtitle: 'Acompanhamentos do paciente.',
            accentColor: AppColors.moduleMonitor,
            onTap: () => context.push(
              DailyMonitorRoutes.staffHistory(role: role, patientId: patientId),
            ),
          ),
          const _ModuleSpec(
            icon: Icons.task_outlined,
            title: 'Exercícios e Tarefas',
            subtitle: 'Em breve',
            accentColor: AppColors.moduleCheckIn,
            onTap: null,
          ),
          const _ModuleSpec(
            icon: Icons.summarize_outlined,
            title: 'Síntese',
            subtitle: 'Em breve',
            accentColor: AppColors.moduleCheckIn,
            onTap: null,
          ),
        ],
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final (groupIndex, group) in groups.indexed) ...[
          Padding(
            padding: EdgeInsets.only(
              top: groupIndex == 0 ? 0 : AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: _GroupHeader(group: group),
          ),
          ..._buildGroupRows(group),
        ],
      ],
    );
  }

  List<Widget> _buildGroupRows(_ModuleGroup group) {
    final rows = <Widget>[];
    final modules = group.modules;
    for (var i = 0; i < modules.length; i += 2) {
      final left = modules[i];
      final right = i + 1 < modules.length ? modules[i + 1] : null;
      rows.add(
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: MotionReveal(
            delay: staggerDelay(
              i ~/ 2,
              interval: const Duration(milliseconds: 45),
              maxStaggered: 4,
            ),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: _buildCard(left)),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: right != null
                        ? _buildCard(right)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    return rows;
  }

  Widget _buildCard(_ModuleSpec spec) {
    return ModuleGridCard(
      icon: spec.icon,
      title: spec.title,
      subtitle: spec.subtitle,
      accentColor: spec.accentColor,
      onTap: spec.onTap,
      enabled: spec.onTap != null,
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({required this.group});

  final _ModuleGroup group;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 36,
          decoration: BoxDecoration(
            color: group.accentColor,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.title,
                style: textTheme.titleMedium?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                group.subtitle,
                style: textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
