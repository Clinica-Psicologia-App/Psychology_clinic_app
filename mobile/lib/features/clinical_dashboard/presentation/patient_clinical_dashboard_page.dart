import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../profile/domain/profile_role.dart';
import '../../results/presentation/result_routes.dart';
import '../domain/clinical_dashboard_data.dart';
import '../providers/clinical_dashboard_providers.dart';
import 'widgets/clinical_dashboard_widgets.dart';

class PatientClinicalDashboardPage extends ConsumerWidget {
  const PatientClinicalDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(myClinicalDashboardProvider);

    return AppScaffold(
      title: 'Dashboard clínico',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.read(myClinicalDashboardProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<ClinicalDashboardData>(
        asyncValue: dataAsync,
        onRetry: () => ref.read(myClinicalDashboardProvider.notifier).refresh(),
        dataBuilder: (data) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(myClinicalDashboardProvider.notifier).refresh();
          },
          child: DashboardHomePage(
            data: data,
            role: ProfileRole.patient,
            onRefresh: () =>
                ref.read(myClinicalDashboardProvider.notifier).refresh(),
          ),
        ),
      ),
    );
  }
}

class StaffPatientClinicalDashboardPage extends ConsumerWidget {
  const StaffPatientClinicalDashboardPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = StaffClinicalDashboardContext(role: role, patientId: patientId);
    final dataAsync = ref.watch(staffClinicalDashboardProvider(ctx));

    return AppScaffold(
      title: 'Dashboard clínico',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(staffClinicalDashboardProvider(ctx)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<ClinicalDashboardData>(
        asyncValue: dataAsync,
        onRetry: () => ref.invalidate(staffClinicalDashboardProvider(ctx)),
        dataBuilder: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(staffClinicalDashboardProvider(ctx));
            await ref.read(staffClinicalDashboardProvider(ctx).future);
          },
          child: DashboardHomePage(
            data: data,
            role: role,
            patientId: patientId,
            onRefresh: () => ref.invalidate(staffClinicalDashboardProvider(ctx)),
          ),
        ),
      ),
    );
  }
}

class DashboardHomePage extends StatelessWidget {
  const DashboardHomePage({
    super.key,
    required this.data,
    required this.role,
    this.patientId,
    this.onRefresh,
  });

  final ClinicalDashboardData data;
  final ProfileRole role;
  final String? patientId;
  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final isStaff = role != ProfileRole.patient;

    return ResponsiveContent(
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              0,
            ),
            sliver: SliverToBoxAdapter(
              child: AppPageHeader(
                icon: Icons.dashboard_customize_outlined,
                title: 'Dashboard clínico',
                subtitle: isStaff
                    ? 'Síntese técnica dos instrumentos, sinais recentes e focos ativos para apoiar a formulação do caso.'
                    : 'Resumo dos registros clínicos disponíveis na sua jornada terapêutica.',
                metadata: [
                  StatusChip(
                    label:
                        '${data.caseSummary.structuredResultCount} resultado(s)',
                    tone: AppStatusTone.info,
                    icon: Icons.analytics_outlined,
                  ),
                  StatusChip(
                    label: '${data.caseSummary.openProblemsCount} problema(s)',
                    tone: AppStatusTone.warning,
                    icon: Icons.report_problem_outlined,
                  ),
                  StatusChip(
                    label: '${data.caseSummary.activeGoalsCount} objetivo(s)',
                    tone: AppStatusTone.success,
                    icon: Icons.flag_outlined,
                  ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(
            child: ClinicalDashboardDisclaimerBanner(),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            sliver: SliverList(
              // Ordem por prioridade clínica: estado atual → riscos/alertas →
              // prioridades → sinais recentes → instrumentos → histórico.
              delegate: SliverChildListDelegate([
                ClinicalExecutiveHeader(summary: data.caseSummary),
                ClinicalDashboardCalloutsSection(callouts: data.callouts),
                ClinicalPriorityGrid(summary: data.caseSummary),
                ClinicalRecentSignalsCard(summary: data.caseSummary),
                // ── Card consolidado (principal) ─────────────────────────
                if (data.hasConsolidatedSchemas)
                  ConsolidatedSchemaProfileCard(
                    data: data,
                    isStaff: isStaff,
                    onActivationChanged: onRefresh,
                  ),
                // ── Detalhe por instrumento (visão técnica ampliada) ─────
                ClinicalInstrumentDetailsSection(
                  data: data,
                  isStaff: isStaff,
                  patientId: patientId,
                  role: role,
                ),
                if (isStaff)
                  ClinicalDashboardHistoryCard(
                    historyTiles: data.history.map((entry) {
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          entry.hasResults
                              ? Icons.check_circle_outline
                              : Icons.hourglass_empty,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(entry.questionnaireName),
                        subtitle: Text(
                          [
                            entry.questionnaireCode,
                            if (entry.completedAt != null)
                              loc.formatFullDate(entry.completedAt!.toLocal()),
                            entry.hasResults
                                ? 'Com resultados'
                                : 'Sem resultados',
                          ].join(' · '),
                        ),
                        trailing: patientId != null
                            ? IconButton(
                                icon: const Icon(Icons.chevron_right),
                                tooltip: 'Ver resposta',
                                onPressed: () => context.push(
                                  ResultRoutes.detail(
                                    role: role,
                                    patientId: patientId!,
                                    responseId: entry.responseId,
                                  ),
                                ),
                              )
                            : null,
                      );
                    }).toList(),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
