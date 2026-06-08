import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
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
  });

  final ClinicalDashboardData data;
  final ProfileRole role;
  final String? patientId;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final isStaff = role != ProfileRole.patient;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ClinicalDashboardDisclaimerBanner(),
        const SizedBox(height: 16),
        ClinicalExecutiveHeader(summary: data.caseSummary),
        ClinicalPriorityGrid(summary: data.caseSummary),
        ClinicalRecentSignalsCard(summary: data.caseSummary),
        ClinicalDashboardCalloutsSection(callouts: data.callouts),
        if (data.parental != null && data.parental!.figures.isNotEmpty)
          ParentalStylesDashboardSection(dashboard: data.parental!)
        else
          const ClinicalDashboardEmptyInstrumentCard(
            title: 'Estilos parentais',
            message:
                'Nenhuma resposta de estilos parentais concluída. Aplique o '
                'instrumento na trilha selecionando as figuras parentais.',
            icon: Icons.family_restroom_outlined,
          ),
        ClinicalInstrumentDetailsSection(data: data),
        const ClinicalDashboardFutureSectionCard(
          title: 'Personalidade',
          icon: Icons.psychology_alt_outlined,
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
                    entry.hasResults ? 'Com resultados' : 'Sem resultados',
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
      ],
    );
  }
}
