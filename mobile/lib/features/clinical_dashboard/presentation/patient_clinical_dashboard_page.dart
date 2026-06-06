import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/homologation_ui.dart';
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
        onRetry: () =>
            ref.read(myClinicalDashboardProvider.notifier).refresh(),
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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const ClinicalDashboardDisclaimerBanner(),
        const SizedBox(height: 16),
        const HomologationSectionHeader(
          icon: Icons.insights_outlined,
          title: 'Dashboard home',
          subtitle: 'Instrumentos atuais e áreas reservadas aos próximos ciclos',
        ),
        const SizedBox(height: 12),
        if (data.ysq != null)
          InstrumentDashboardCard(
            title: 'YSQ — esquemas iniciais',
            panel: data.ysq!,
            icon: Icons.psychology_outlined,
          )
        else
          const ClinicalDashboardEmptyInstrumentCard(
            title: 'YSQ — esquemas iniciais',
            message:
                'Nenhuma resposta YSQ concluída com snapshot estruturado.',
            icon: Icons.psychology_outlined,
          ),
        if (data.yami != null)
          InstrumentDashboardCard(
            title: 'YAMI — modos',
            panel: data.yami!,
            icon: Icons.self_improvement_outlined,
          )
        else
          const ClinicalDashboardEmptyInstrumentCard(
            title: 'YAMI — modos',
            message:
                'Nenhuma resposta YAMI concluída com snapshot estruturado.',
            icon: Icons.self_improvement_outlined,
          ),
        const ClinicalDashboardFutureSectionCard(
          title: 'Estilos parentais',
          icon: Icons.family_restroom_outlined,
        ),
        const ClinicalDashboardFutureSectionCard(
          title: 'Estilos de apego',
          icon: Icons.favorite_border,
        ),
        const ClinicalDashboardFutureSectionCard(
          title: 'Estilos de enfrentamento',
          icon: Icons.shield_outlined,
        ),
        const ClinicalDashboardFutureSectionCard(
          title: 'Personalidade',
          icon: Icons.psychology_alt_outlined,
        ),
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
              trailing: role != ProfileRole.patient && patientId != null
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
