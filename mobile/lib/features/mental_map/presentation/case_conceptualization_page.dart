import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_severity.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../initial_assessment/domain/initial_assessment.dart';
import '../../initial_assessment/domain/life_area.dart';
import '../../initial_assessment/providers/initial_assessment_providers.dart';
import '../../profile/domain/profile_role.dart';
import 'case_conceptualization_pdf.dart';
import 'mental_map_routes.dart';
import '../domain/case_conceptualization.dart';
import '../domain/mental_map_case_summary.dart';
import '../domain/mental_map_data.dart';
import '../domain/mental_map_goal_summary.dart';
import '../domain/mental_map_score_highlight.dart';
import '../domain/schema_mode_catalog.dart';
import '../providers/case_conceptualization_providers.dart';
import '../providers/mental_map_providers.dart';

/// Síntese "Conceitualização de caso" (módulo Síntese, lente do terapeuta).
///
/// Fase 1: visão só-leitura que consolida os dados que já existem (agregação
/// do Mapa mental) no layout do formulário padrão. As seções que dependem de
/// avaliação do terapeuta (necessidades 0–5, sequência de modos, relação
/// terapêutica) aparecem como "a preencher" até ganharem armazenamento próprio.
class CaseConceptualizationPage extends ConsumerWidget {
  const CaseConceptualizationPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = StaffMentalMapContext(role: role, patientId: patientId);
    final async = ref.watch(staffMentalMapProvider(ctx));

    return AppScaffold(
      title: 'Conceitualização de caso',
      accent: AppColors.navy,
      actions: [
        IconButton(
          tooltip: 'Exportar PDF',
          onPressed: () async {
            final data = ref.read(staffMentalMapProvider(ctx)).valueOrNull;
            if (data == null) {
              showErrorBanner(
                context,
                'Aguarde os dados carregarem para exportar.',
              );
              return;
            }
            try {
              await CaseConceptualizationPdf.shareOrPrint(
                data: data,
                concept:
                    ref.read(caseConceptualizationProvider(patientId)).valueOrNull,
                assessment: ref
                    .read(initialAssessmentProvider(
                      InitialAssessmentContext(
                          role: role, patientId: patientId),
                    ))
                    .valueOrNull,
              );
            } catch (e) {
              if (context.mounted) showErrorBanner(context, e);
            }
          },
          icon: const Icon(Icons.picture_as_pdf_outlined),
        ),
        IconButton(
          tooltip: 'Editar campos do terapeuta',
          onPressed: () async {
            await context.push(
              MentalMapRoutes.staffCaseConceptualizationEdit(
                role: role,
                patientId: patientId,
              ),
            );
            ref.invalidate(caseConceptualizationProvider(patientId));
          },
          icon: const Icon(Icons.edit_outlined),
        ),
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(staffMentalMapProvider(ctx)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<MentalMapData>(
        asyncValue: async,
        onRetry: () => ref.invalidate(staffMentalMapProvider(ctx)),
        emptyMessage:
            'Ainda não há dados clínicos suficientes para montar a síntese.',
        emptyIcon: Icons.summarize_outlined,
        dataBuilder: (data) => _Body(
          data: data,
          concept:
              ref.watch(caseConceptualizationProvider(patientId)).valueOrNull,
          assessment: ref
              .watch(initialAssessmentProvider(
                InitialAssessmentContext(role: role, patientId: patientId),
              ))
              .valueOrNull,
        ),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data, this.concept, this.assessment});

  final MentalMapData data;
  final CaseConceptualization? concept;
  final InitialAssessment? assessment;

  @override
  Widget build(BuildContext context) {
    final summary = data.caseSummary;
    final core = data.clinicalCore;

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      children: [
        _hero(context),
        const SizedBox(height: 12),

        // 2. Motivo da terapia
        _Section(
          number: '2',
          title: 'Motivo da terapia',
          child: _motivo(context, summary),
        ),

        // 3. Impressões gerais (campos do terapeuta).
        _Section(
          number: '3',
          title: 'Impressões gerais',
          child: (concept?.hasGeneralImpressions ?? false)
              ? _impressions(concept!.generalImpressions)
              : const _Placeholder(
                  'Como o cliente se apresenta (inicial/atual) — a preencher.',
                ),
        ),

        // 4. Perspectiva diagnóstica (campos do terapeuta).
        _Section(
          number: '4',
          title: 'Perspectiva diagnóstica',
          child: (concept?.hasDiagnosis ?? false)
              ? _diagnosisView(concept!.diagnosis)
              : const _Placeholder(
                  'Sistema (CID-11/DSM-5) e diagnósticos — a preencher.',
                ),
        ),

        // 5. Funcionamento — áreas da vida (do fluxo Conhecer, escala 1–10).
        _Section(
          number: '5',
          title: 'Funcionamento · áreas da vida',
          child: _lifeAreas(),
        ),

        // 6. Problemas de vida
        _Section(
          number: '6',
          title: 'Principais problemas de vida',
          child: data.activeProblems.isEmpty
              ? const _Placeholder('Nenhum problema registrado ainda.')
              : Column(
                  children: [
                    for (final p in data.activeProblems)
                      _BulletRow(
                        text: p.title,
                        trailing: p.intensity == null
                            ? null
                            : '${p.intensity}/10',
                      ),
                  ],
                ),
        ),

        // 7. Origens — necessidades não atendidas (campos do terapeuta).
        _Section(
          number: '7',
          title: 'Origens · necessidades não atendidas',
          child: (concept?.hasAnyNeed ?? false)
              ? _NeedsList(concept: concept!)
              : const _Placeholder(
                  'Avaliação das necessidades essenciais (0–5), origem e '
                  'esquemas — a preencher.',
                ),
        ),

        // 8. Esquemas centrais
        _Section(
          number: '8',
          title: 'Esquemas centrais',
          child: core.topSchemas.isEmpty
              ? const _Placeholder('Sem YSQ concluído.')
              : _highlightChips(core.topSchemas),
        ),

        // 9. Modos
        _Section(
          number: '9',
          title: 'Modos',
          child: core.topModes.isEmpty
              ? const _Placeholder('Sem YAMI concluído.')
              : _ModesList(modes: core.topModes),
        ),

        // 10. Sequência de modos (campos do terapeuta).
        _Section(
          number: '10',
          title: 'Sequência de modos',
          child: (concept?.hasAnySequence ?? false)
              ? _SequencesList(concept: concept!)
              : const _Placeholder('Gatilho → sequência de modos — a preencher.'),
        ),

        // 11. Relação terapêutica (campos do terapeuta).
        _Section(
          number: '11',
          title: 'Relação terapêutica',
          child: (concept?.hasRelationship ?? false)
              ? _RelationshipView(rel: concept!.relationship)
              : const _Placeholder(
                  'Colaboração e vínculo de reparentalização (1–5) — a preencher.',
                ),
        ),

        // 12. Objetivos da terapia
        _Section(
          number: '12',
          title: 'Objetivos da terapia',
          child: data.activeGoals.isEmpty
              ? const _Placeholder('Nenhum objetivo ativo.')
              : Column(
                  children: [
                    for (var i = 0; i < data.activeGoals.length; i++)
                      _GoalRow(index: i + 1, goal: data.activeGoals[i]),
                  ],
                ),
        ),

        // 13. Comentários adicionais (campo do terapeuta).
        _Section(
          number: '13',
          title: 'Comentários adicionais',
          child: (concept?.hasComments ?? false)
              ? Text(
                  concept!.additionalComments!.trim(),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                )
              : const _Placeholder('Sem comentários adicionais.'),
        ),
      ],
    );
  }

  Widget _impressions(GeneralImpressions g) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      Widget part(String label, String? value) {
        if ((value ?? '').trim().isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                  )),
              const SizedBox(height: 2),
              Text(value!.trim(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textPrimary, height: 1.45)),
            ],
          ),
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          part('Inicialmente', g.initial),
          part('Atualmente', g.current),
        ],
      );
    });
  }

  Widget _diagnosisView(Diagnosis d) {
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      final items = d.items.where((e) => !e.isEmpty).toList();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if ((d.system ?? '').trim().isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTintBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  d.system!.trim(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.blue,
                  ),
                ),
              ),
            ),
          for (final e in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textPrimary, height: 1.4),
                  children: [
                    TextSpan(
                      text: (e.name ?? '').trim(),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if ((e.code ?? '').trim().isNotEmpty)
                      TextSpan(
                        text: '  ·  ${e.code!.trim()}',
                        style: const TextStyle(color: AppColors.textMuted),
                      ),
                  ],
                ),
              ),
            ),
        ],
      );
    });
  }

  Widget _hero(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navy, Color(0xFF2E3F6E)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'TERAPIA DO ESQUEMA · SÍNTESE',
            style: theme.textTheme.labelSmall?.copyWith(
              color: const Color(0xFF9DB2E0),
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'Conceitualização de caso',
            style: theme.textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            data.patientName,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: const Color(0xFFC9D6F0)),
          ),
        ],
      ),
    );
  }

  Widget _motivo(BuildContext context, MentalMapCaseSummary s) {
    final parts = <({String label, String? value})>[
      (label: 'Contexto de vida atual', value: s.currentLifeContext),
      (label: 'Demandas terapêuticas', value: s.therapyDemands),
      (label: 'Resumo da queixa', value: s.intakeSummary),
    ].where((e) => (e.value ?? '').trim().isNotEmpty).toList();

    if (parts.isEmpty) {
      return const _Placeholder('Motivo/queixa ainda não registrado.');
    }
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final p in parts)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.label.toUpperCase(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                    fontWeight: FontWeight.w700,
                    fontSize: 9,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  p.value!.trim(),
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textPrimary, height: 1.45),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _lifeAreas() {
    final a = assessment;
    final rated = a == null
        ? const <(LifeArea, int)>[]
        : [
            for (final area in kLifeAreasInOrder)
              if (a.lifeAreaFor(area).score != null)
                (area, a.lifeAreaFor(area).score!),
          ];
    if (rated.isEmpty) {
      return const _Placeholder('Áreas da vida ainda não avaliadas.');
    }
    return Builder(builder: (context) {
      final theme = Theme.of(context);
      Color tone(int s) => s >= 7
          ? AppColors.success
          : s >= 4
              ? AppColors.warning
              : AppColors.error;
      return Column(
        children: [
          for (var i = 0; i < rated.length; i++)
            Padding(
              padding: EdgeInsets.only(bottom: i == rated.length - 1 ? 0 : 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          rated[i].$1.label,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '${rated[i].$2}/10',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: tone(rated[i].$2),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (rated[i].$2 / 10).clamp(0.0, 1.0),
                      minHeight: 5,
                      backgroundColor: tone(rated[i].$2).withValues(alpha: 0.15),
                      color: tone(rated[i].$2),
                    ),
                  ),
                ],
              ),
            ),
        ],
      );
    });
  }

  Widget _highlightChips(List<MentalMapScoreHighlight> items) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final h in items)
          Builder(builder: (context) {
            final sev = AppSeverity.fromColorKey(h.severityColorKey);
            final color = sev.hasSeverity ? sev.color : AppColors.cyan;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                h.scoreLabel == null ? h.name : '${h.name} · ${h.scoreLabel}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.number,
    required this.title,
    required this.child,
  });

  final String number;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Row(
              children: [
                Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.navy,
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
          ),
          Divider(
            height: 1,
            thickness: 0.5,
            color: theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 11, 12, 12),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _Placeholder extends StatelessWidget {
  const _Placeholder(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.edit_note_outlined, size: 15, color: AppColors.textMuted),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.textMuted,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}

class _BulletRow extends StatelessWidget {
  const _BulletRow({required this.text, this.trailing});

  final String text;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5, right: 7),
            child: SizedBox(
              width: 5,
              height: 5,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: AppColors.textPrimary, height: 1.4),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            Text(
              trailing!,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GoalRow extends StatelessWidget {
  const _GoalRow({required this.index, required this.goal});

  final int index;
  final MentalMapGoalSummary goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prazoColor = goal.isOverdue ? AppColors.error : AppColors.textMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 18,
            height: 18,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: AppColors.surfaceTintBlue,
              shape: BoxShape.circle,
            ),
            child: Text(
              '$index',
              style: const TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w800,
                color: AppColors.blue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  goal.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
                if ((goal.description ?? '').isNotEmpty) ...[
                  const SizedBox(height: 1),
                  Text(
                    goal.description!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ],
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (goal.progress / 100).clamp(0.0, 1.0),
                          minHeight: 5,
                          backgroundColor:
                              AppColors.blue.withValues(alpha: 0.15),
                          color: AppColors.blue,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${goal.progress}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppColors.blue,
                      ),
                    ),
                  ],
                ),
                if (goal.linkedLabels.isNotEmpty) ...[
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (final l in goal.linkedLabels)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceTintBlue,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            l,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.blue,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
                if ((goal.targetDateLabel ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        goal.isOverdue
                            ? Icons.event_busy_outlined
                            : Icons.event_outlined,
                        size: 12,
                        color: prazoColor,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        goal.isOverdue
                            ? 'Prazo vencido · ${goal.targetDateLabel}'
                            : 'Prazo: ${goal.targetDateLabel}',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: prazoColor,
                          fontWeight:
                              goal.isOverdue ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 7.2 — necessidades avaliadas (nota 0–5/X + origem + esquemas).
class _NeedsList extends StatelessWidget {
  const _NeedsList({required this.concept});

  final CaseConceptualization concept;

  Color _ratingColor(String? r) {
    final v = int.tryParse(r ?? '');
    if (v == null) return AppColors.textMuted; // 'X' ou vazio
    if (v <= 1) return AppColors.error;
    if (v <= 3) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final labels = {for (final n in kCoreNeeds) n.key: n.label};
    final filled = concept.unmetNeeds.where((u) => !u.isEmpty).toList();

    return Column(
      children: [
        for (var i = 0; i < filled.length; i++)
          Padding(
            padding: EdgeInsets.only(bottom: i == filled.length - 1 ? 0 : 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: _ratingColor(filled[i].rating).withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Text(
                    (filled[i].rating == null || filled[i].rating!.isEmpty)
                        ? '–'
                        : filled[i].rating!,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: _ratingColor(filled[i].rating),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        labels[filled[i].needKey] ?? filled[i].needKey,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      if ((filled[i].origin ?? '').trim().isNotEmpty)
                        Text(
                          'Origem: ${filled[i].origin!.trim()}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.textSecondary, height: 1.4),
                        ),
                      if ((filled[i].schemas ?? '').trim().isNotEmpty)
                        Text(
                          'Esquemas: ${filled[i].schemas!.trim()}',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.purple, height: 1.4),
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
}

/// 10 — sequências de modos preenchidas.
class _SequencesList extends StatelessWidget {
  const _SequencesList({required this.concept});

  final CaseConceptualization concept;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final seqs = concept.modeSequences.where((s) => !s.isEmpty).toList();

    Widget line(String label, String? value) {
      if ((value ?? '').trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(top: 3),
        child: RichText(
          text: TextSpan(
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textSecondary, height: 1.4),
            children: [
              TextSpan(
                text: '$label ',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              TextSpan(text: value!.trim()),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < seqs.length; i++)
          Container(
            margin: EdgeInsets.only(bottom: i == seqs.length - 1 ? 0 : 8),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceTint,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (seqs[i].trigger ?? '').trim().isEmpty
                      ? 'Sequência ${i + 1}'
                      : 'Gatilho: ${seqs[i].trigger!.trim()}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontWeight: FontWeight.w800, color: AppColors.navy),
                ),
                line('Modos:', seqs[i].activatedModes),
                line('Enfrentamento:', seqs[i].copingMode),
                line('Sequência:', seqs[i].sequence),
                line('Efeito:', seqs[i].effect),
                line('Perpetua:', seqs[i].perpetuation),
              ],
            ),
          ),
      ],
    );
  }
}

/// 11 — relação terapêutica (colaboração + vínculo + reações).
class _RelationshipView extends StatelessWidget {
  const _RelationshipView({required this.rel});

  final TherapeuticRelationship rel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget meter(String label, int? value) {
      final v = (value ?? 0).clamp(0, 5);
      final color = v >= 4
          ? AppColors.success
          : v >= 3
              ? AppColors.warning
              : AppColors.error;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              child: Text(label,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.textSecondary)),
            ),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: value == null ? 0 : v / 5,
                  minHeight: 5,
                  backgroundColor: color.withValues(alpha: 0.15),
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value == null ? '—' : '$v/5',
              style: theme.textTheme.labelSmall
                  ?.copyWith(fontWeight: FontWeight.w800, color: color),
            ),
          ],
        ),
      );
    }

    Widget note(String label, String? value) {
      if ((value ?? '').trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: RichText(
          text: TextSpan(
            style: theme.textTheme.labelSmall
                ?.copyWith(color: AppColors.textSecondary, height: 1.4),
            children: [
              TextSpan(
                  text: '$label ',
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              TextSpan(text: value!.trim()),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (rel.collaborationRating != null)
          meter('Colaboração', rel.collaborationRating),
        if (rel.bondRating != null) meter('Vínculo', rel.bondRating),
        note('Colaboração:', rel.collaborationNotes),
        note('Vínculo:', rel.bondNotes),
        note('Reações do terapeuta:', rel.therapistReactions),
      ],
    );
  }
}

/// 9 — modos priorizados do YAMI, com categoria e função (catálogo de ST).
class _ModesList extends StatelessWidget {
  const _ModesList({required this.modes});

  final List<MentalMapScoreHighlight> modes;

  static Color _color(String key) => switch (key) {
        'blue' => AppColors.blue,
        'warning' => AppColors.warning,
        'error' => AppColors.error,
        'success' => AppColors.success,
        _ => AppColors.cyan,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (var i = 0; i < modes.length; i++)
          Builder(builder: (context) {
            final h = modes[i];
            final info = schemaModeInfoForCode(h.code);
            final color =
                info == null ? AppColors.cyan : _color(info.category.colorKey);
            return Padding(
              padding: EdgeInsets.only(bottom: i == modes.length - 1 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 4,
                    height: 34,
                    margin: const EdgeInsets.only(top: 2, right: 10),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                info?.name ?? h.name,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                            if (h.scoreLabel != null &&
                                h.scoreLabel!.trim().isNotEmpty &&
                                h.scoreLabel != '-') ...[
                              const SizedBox(width: 8),
                              Text(
                                h.scoreLabel!,
                                style: theme.textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  color: color,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (info != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            info.category.label,
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                              color: color,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            info.description,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
      ],
    );
  }
}
