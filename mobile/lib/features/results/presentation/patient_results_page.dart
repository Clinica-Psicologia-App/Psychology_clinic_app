import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../clinical_dashboard/domain/clinical_dashboard_data.dart';
import '../../clinical_dashboard/presentation/widgets/clinical_dashboard_widgets.dart';
import '../../clinical_dashboard/providers/clinical_dashboard_providers.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/results_providers.dart';
import 'result_routes.dart';
import 'widgets/response_summary_tile.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';
import '../../../shared/widgets/brand_loading.dart';

class PatientResultsPage extends ConsumerWidget {
  const PatientResultsPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isPatient = role == ProfileRole.patient;
    final dashboardCtx =
        StaffClinicalDashboardContext(role: role, patientId: patientId);

    final dashboardAsync = isPatient
        ? ref.watch(myClinicalDashboardProvider)
        : ref.watch(staffClinicalDashboardProvider(dashboardCtx));

    void refreshDashboard() {
      if (isPatient) {
        ref.read(myClinicalDashboardProvider.notifier).refresh();
      } else {
        ref.invalidate(staffClinicalDashboardProvider(dashboardCtx));
      }
    }

    return AppScaffold(
      title: 'Dashboard clínico',
      accent: AppColors.purple,
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: refreshDashboard,
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<ClinicalDashboardData>(
        asyncValue: dashboardAsync,
        onRetry: refreshDashboard,
        emptyIcon: Icons.analytics_outlined,
        dataBuilder: (data) {
          final patientName =
              ref.watch(patientDetailProvider(patientId)).valueOrNull?.fullName;
          return RefreshIndicator(
            onRefresh: () async {
              refreshDashboard();
            },
            child: _ConsolidatedResultsView(
              data: data,
              role: role,
              patientId: patientId,
              patientName: isPatient ? null : patientName,
              onActivationChanged: refreshDashboard,
            ),
          );
        },
      ),
    );
  }
}

/// Corpo principal: cabeçalho + card consolidado. As respostas por
/// questionário ficam recolhidas num expansível ("passar a régua").
class _ConsolidatedResultsView extends StatelessWidget {
  const _ConsolidatedResultsView({
    required this.data,
    required this.role,
    required this.patientId,
    required this.onActivationChanged,
    this.patientName,
  });

  final ClinicalDashboardData data;
  final ProfileRole role;
  final String patientId;
  final VoidCallback onActivationChanged;
  final String? patientName;

  @override
  Widget build(BuildContext context) {
    final isStaff = role != ProfileRole.patient;
    final activated = data.activatedSchemas.length;
    final total = data.consolidatedSchemas.length;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      children: [
        AppPageHeader(
          icon: Icons.analytics_outlined,
          title: 'Perfil consolidado',
          subtitle: patientName == null
              ? 'Todos os esquemas e modos reunidos numa visão única, '
                  'com o que está ativado e não ativado.'
              : 'Perfil de $patientName reunindo todos os instrumentos, '
                  'com esquemas ativados e não ativados.',
          metadata: [
            StatusChip(
              label: '$total esquema(s)',
              tone: AppStatusTone.info,
              icon: Icons.schema_outlined,
            ),
            StatusChip(
              label: '$activated ativado(s)',
              tone: AppStatusTone.success,
              icon: Icons.check_circle_outline,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        if (data.hasConsolidatedSchemas)
          ConsolidatedSchemaProfileCard(
            data: data,
            isStaff: isStaff,
            onActivationChanged: onActivationChanged,
          )
        else
          const ClayCard(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  Icon(Icons.analytics_outlined,
                      size: 40, color: AppColors.textMuted),
                  SizedBox(height: 12),
                  Text(
                    'Ainda não há resultados consolidados.',
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Assim que um questionário for concluído com resultados, '
                    'o perfil aparecerá aqui.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.md),
        // Acesso às respostas por questionário (régua item a item).
        _ResponsesByQuestionnaireSection(
          role: role,
          patientId: patientId,
        ),
      ],
    );
  }
}

/// Seção recolhível com as respostas por questionário — mantém o acesso
/// ao fluxo de "passar a régua" sem poluir a visão consolidada.
class _ResponsesByQuestionnaireSection extends ConsumerWidget {
  const _ResponsesByQuestionnaireSection({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = PatientResultsContext(role: role, patientId: patientId);
    final listAsync = ref.watch(patientResultsListProvider(ctx));
    final theme = Theme.of(context);

    return ClayCard(
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(
            Icons.fact_check_outlined,
            color: AppColors.moduleQuestionnaires,
          ),
          title: Text(
            'Respostas por questionário',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          subtitle: Text(
            'Abrir cada resposta e ver o detalhe',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
            ),
          ),
          children: [
            listAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(16),
                child: BrandLoader(),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Não foi possível carregar as respostas.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Nenhuma resposta registrada.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < items.length; i++)
                      MotionReveal(
                        delay: staggerDelay(i),
                        child: ResponseSummaryTile(
                          summary: items[i],
                          onTap: () => context.push(
                            ResultRoutes.detail(
                              role: role,
                              patientId: patientId,
                              responseId: items[i].id,
                            ),
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
