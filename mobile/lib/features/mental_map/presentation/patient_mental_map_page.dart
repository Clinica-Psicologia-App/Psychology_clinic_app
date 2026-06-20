import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../profile/domain/profile_role.dart';
import '../../../shared/widgets/homologation_ui.dart';
import '../domain/mental_map_check_in_summary.dart';
import '../domain/mental_map_data.dart';
import '../domain/mental_map_hub_builder.dart';
import '../providers/mental_map_providers.dart';
import 'mental_map_navigation_targets.dart';
import 'mental_map_node_state.dart';
import 'widgets/mental_map_formulation_widgets.dart';
import 'widgets/mental_map_widgets.dart';

class PatientMentalMapPage extends ConsumerWidget {
  const PatientMentalMapPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapAsync = ref.watch(myMentalMapProvider);

    return AppScaffold(
      title: 'Mapa mental',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.read(myMentalMapProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<MentalMapData>(
        asyncValue: mapAsync,
        onRetry: () => ref.read(myMentalMapProvider.notifier).refresh(),
        emptyMessage:
            'Ainda não há dados clínicos suficientes para montar o mapa mental. '
            'Conforme você registra questionários, problemas, objetivos e outros '
            'módulos, as seções aparecerão aqui.',
        emptyIcon: Icons.hub_outlined,
        dataBuilder: (data) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(myMentalMapProvider.notifier).refresh();
          },
          child: _MentalMapBody(
            data: data,
            role: ProfileRole.patient,
          ),
        ),
      ),
    );
  }
}

class StaffPatientMentalMapPage extends ConsumerWidget {
  const StaffPatientMentalMapPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = StaffMentalMapContext(role: role, patientId: patientId);
    final mapAsync = ref.watch(staffMentalMapProvider(ctx));

    return AppScaffold(
      title: 'Mapa mental',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(staffMentalMapProvider(ctx)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<MentalMapData>(
        asyncValue: mapAsync,
        onRetry: () => ref.invalidate(staffMentalMapProvider(ctx)),
        emptyMessage:
            'Ainda não há dados clínicos registrados para este paciente.',
        emptyIcon: Icons.hub_outlined,
        dataBuilder: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(staffMentalMapProvider(ctx));
            await ref.read(staffMentalMapProvider(ctx).future);
          },
          child: _MentalMapBody(
            data: data,
            role: role,
            patientId: patientId,
          ),
        ),
      ),
    );
  }
}

class _MentalMapBody extends StatelessWidget {
  const _MentalMapBody({
    required this.data,
    required this.role,
    this.patientId,
  });

  final MentalMapData data;
  final ProfileRole role;
  final String? patientId;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const MentalMapDisclaimerBanner(),
        const SizedBox(height: 16),
        MentalMapValidationBanner(summary: data.validationSummary),
        const SizedBox(height: 16),
        MentalMapVisualHub(
          caseMap: data.caseMap,
          nodes: _buildHubNodes(context),
        ),
        MentalMapFormulationTabs(
          clinicalCore: data.clinicalCore,
          historyLinks: data.historyLinks,
          therapyPlan: data.therapyPlan,
          role: role,
          patientId: patientId,
        ),
        MentalMapCaseSummaryCard(summary: data.caseSummary),
        if (!data.hasRelevantData) ...[
          const SizedBox(height: 8),
          const HomologationEmptyPanel(
            icon: Icons.hub_outlined,
            title: 'Mapa ainda em formação',
            message:
                'Ainda há poucos dados clínicos registrados para este caso.',
            hint:
                'Os módulos abaixo vão ganhando densidade conforme a jornada é preenchida.',
          ),
          const SizedBox(height: 16),
        ],
        const HomologationSectionHeader(
          icon: Icons.dashboard_outlined,
          title: 'Resumo por módulo',
          subtitle: 'Destaques dos dados já registrados na jornada',
        ),
        const SizedBox(height: 12),
        MentalMapSectionCard(
          title: 'Resultados dos questionários',
          icon: Icons.assignment_outlined,
          isEmpty: data.questionnaires.isEmpty,
          emptyMessage: 'Nenhum resultado clínico concluído disponível.',
          emptyHint: 'Conclua os instrumentos na trilha.',
          onViewDetails: _route(
            MentalMapNavigationTargets.questionnaireResults(
              role: role,
              patientId: patientId,
            ),
            context,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (final block in data.questionnaires) ...[
                Text(
                  block.questionnaireName,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (block.completedAt != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Concluído em ${loc.formatFullDate(block.completedAt!.toLocal())}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                if (block.requiresTherapistReview)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Aguardando revisão clínica do terapeuta.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                if (block.highlights.isEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      'Sem scores estruturados nesta resposta.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  )
                else
                  ...block.highlights.map(
                    (h) => MentalMapScoreHighlightTile(
                      name: h.name,
                      code: h.code,
                      kind: h.kind,
                      displayScore: h.displayScore,
                    ),
                  ),
                const Divider(height: 24),
              ],
            ],
          ),
        ),
        MentalMapSectionCard(
          title: 'Problemas ativos',
          icon: Icons.report_problem_outlined,
          isEmpty: data.activeProblems.isEmpty,
          emptyMessage: 'Nenhum problema em acompanhamento.',
          emptyHint: 'Registre problemas na trilha.',
          onViewDetails: _route(
            MentalMapNavigationTargets.problems(
              role: role,
              patientId: patientId,
            ),
            context,
          ),
          child: Column(
            children: data.activeProblems
                .map(
                  (p) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(p.title),
                    subtitle: Text(
                      [
                        p.statusLabel,
                        if (p.intensity != null)
                          'Intensidade ${p.intensity}/10',
                      ].join(' · '),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        MentalMapSectionCard(
          title: 'Objetivos ativos',
          icon: Icons.flag_outlined,
          isEmpty: data.activeGoals.isEmpty,
          emptyMessage: 'Nenhum objetivo ativo.',
          emptyHint: 'Defina objetivos com seu psicólogo.',
          onViewDetails: _route(
            MentalMapNavigationTargets.therapyGoals(
              role: role,
              patientId: patientId,
            ),
            context,
          ),
          child: Column(
            children: data.activeGoals
                .map(
                  (g) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(g.title),
                    subtitle: Text(
                      [
                        g.statusLabel,
                        if (g.targetDateLabel != null)
                          'Meta: ${g.targetDateLabel}',
                      ].join(' · '),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        MentalMapSectionCard(
          title: 'Check-in recente',
          icon: Icons.fact_check_outlined,
          isEmpty: data.recentCheckIn == null,
          emptyMessage: 'Nenhum check-in registrado.',
          emptyHint: 'Faça seu check-in na trilha.',
          onViewDetails: _route(
            MentalMapNavigationTargets.checkIns(
              role: role,
              patientId: patientId,
            ),
            context,
          ),
          child: data.recentCheckIn == null
              ? const SizedBox.shrink()
              : _CheckInScores(checkIn: data.recentCheckIn!),
        ),
        MentalMapSectionCard(
          title: 'Monitor diário recente',
          icon: Icons.monitor_heart_outlined,
          isEmpty: data.recentMonitors.isEmpty,
          emptyMessage: 'Nenhum registro no monitor diário.',
          emptyHint: 'Use o monitor diário na trilha.',
          onViewDetails: _route(
            MentalMapNavigationTargets.dailyMonitors(
              role: role,
              patientId: patientId,
            ),
            context,
          ),
          child: Column(
            children: data.recentMonitors
                .map(
                  (m) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(m.summaryLine),
                    subtitle: Text(
                      loc.formatFullDate(m.createdAt.toLocal()),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        MentalMapSectionCard(
          title: 'Linha do tempo',
          icon: Icons.timeline_outlined,
          isEmpty: data.recentTimelineEvents.isEmpty,
          emptyMessage: 'Nenhum evento na linha do tempo.',
          emptyHint: 'Adicione eventos importantes na trilha.',
          onViewDetails: _route(
            MentalMapNavigationTargets.timeline(
              role: role,
              patientId: patientId,
            ),
            context,
          ),
          child: Column(
            children: data.recentTimelineEvents
                .map(
                  (e) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: e.isSensitive
                        ? Icon(
                            Icons.lock_outline,
                            color: Theme.of(context).colorScheme.error,
                          )
                        : null,
                    title: Text(e.title),
                    subtitle: Text(e.dateLabel),
                    tileColor: e.isSensitive
                        ? Theme.of(context)
                            .colorScheme
                            .errorContainer
                            .withValues(alpha: 0.2)
                        : null,
                  ),
                )
                .toList(),
          ),
        ),
        MentalMapSectionCard(
          title: 'Genograma',
          icon: Icons.family_restroom_outlined,
          isEmpty: !data.genogram.hasContent,
          emptyMessage: 'Genograma ainda não preenchido.',
          emptyHint: 'Cadastre pessoas e relações no genograma.',
          onViewDetails: _route(
            MentalMapNavigationTargets.genogram(
              role: role,
              patientId: patientId,
            ),
            context,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${data.genogram.peopleCount} pessoa(s)'),
              Text('${data.genogram.relationshipCount} relação(ões)'),
              if (data.genogram.hasSensitiveItems)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 18,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${data.genogram.totalSensitiveCount} item(ns) sensível(is) no genograma',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  VoidCallback? _route(String? path, BuildContext context) {
    if (path == null) return null;
    return () => context.push(path);
  }

  List<MentalMapHubNodeData> _buildHubNodes(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return data.caseMap.allNodes.map((node) {
      final detail = buildMentalMapNodeDetail(
        node: node,
        role: role,
        patientId: patientId,
      );

      final icon = switch (node.id) {
        'schemas' => Icons.psychology_outlined,
        'modes' => Icons.self_improvement_outlined,
        'problems' => Icons.report_problem_outlined,
        'attachment' => Icons.favorite_border,
        'coping' => Icons.shield_outlined,
        'parental' => Icons.family_restroom_outlined,
        'goals' => Icons.flag_outlined,
        'history' => Icons.timeline_outlined,
        _ => Icons.hub_outlined,
      };

      final accentColor = switch (node.id) {
        'schemas' => colors.primary,
        'modes' => colors.tertiary,
        'problems' => colors.error,
        'attachment' => colors.primary,
        'coping' => colors.secondary,
        'parental' => colors.tertiary,
        'goals' => colors.secondary,
        'history' => colors.primary,
        _ => colors.primary,
      };

      return MentalMapHubNodeData(
        id: node.id,
        title: node.title,
        subtitle: node.shortLabel,
        items: node.items,
        emptyLabel: node.emptyLabel,
        icon: icon,
        accentColor: accentColor,
        isFilled: node.isFilled,
        visualState: resolveMentalMapNodeVisualState(node),
        onTap: () {
          final primaryRoute = resolvePrimaryRoute(
            detail: detail,
            role: role,
            patientId: patientId,
          );
          final secondaryRoute = resolveSecondaryRoute(
            detail: detail,
            role: role,
            patientId: patientId,
          );

          showMentalMapNodeDetailSheet(
            context: context,
            detail: detail,
            onPrimaryTap: _route(primaryRoute, context),
            onSecondaryTap: _route(secondaryRoute, context),
          );
        },
      );
    }).toList(growable: false);
  }
}

class _CheckInScores extends StatelessWidget {
  const _CheckInScores({required this.checkIn});

  final MentalMapCheckInSummary checkIn;

  @override
  Widget build(BuildContext context) {
    final c = checkIn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (c.moodScore != null) Text('Humor: ${c.moodScore}/10'),
        if (c.anxietyScore != null) Text('Ansiedade: ${c.anxietyScore}/10'),
        if (c.energyScore != null) Text('Energia: ${c.energyScore}/10'),
        if (c.problemIntensityScore != null)
          Text('Intensidade dos problemas: ${c.problemIntensityScore}/10'),
      ],
    );
  }
}
