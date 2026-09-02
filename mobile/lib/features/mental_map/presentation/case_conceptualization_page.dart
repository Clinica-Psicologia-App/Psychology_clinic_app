import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_severity.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/mental_map_case_summary.dart';
import '../domain/mental_map_data.dart';
import '../domain/mental_map_score_highlight.dart';
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
        dataBuilder: (data) => _Body(data: data),
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.data});

  final MentalMapData data;

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

        // 5. Funcionamento — depende de avaliação por área (a preencher).
        const _Section(
          number: '5',
          title: 'Funcionamento · áreas da vida',
          child: _Placeholder(
            'Avaliação das 5 áreas da vida (1–6) — a preencher.',
          ),
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

        // 7. Origens — necessidades não atendidas (a preencher).
        const _Section(
          number: '7',
          title: 'Origens · necessidades não atendidas',
          child: _Placeholder(
            'Avaliação das necessidades essenciais (0–5), origem e esquemas '
            '— a preencher.',
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
              : _highlightChips(core.topModes),
        ),

        // 10. Sequência de modos (a preencher).
        const _Section(
          number: '10',
          title: 'Sequência de modos',
          child: _Placeholder(
            'Gatilho → sequência de modos — a preencher.',
          ),
        ),

        // 11. Relação terapêutica (a preencher).
        const _Section(
          number: '11',
          title: 'Relação terapêutica',
          child: _Placeholder(
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
                      _GoalRow(
                        index: i + 1,
                        title: data.activeGoals[i].title,
                        meta: data.activeGoals[i].targetDateLabel,
                      ),
                  ],
                ),
        ),
      ],
    );
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
  const _GoalRow({required this.index, required this.title, this.meta});

  final int index;
  final String title;
  final String? meta;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
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
                  title,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: AppColors.textPrimary, height: 1.4),
                ),
                if ((meta ?? '').isNotEmpty)
                  Text(
                    meta!,
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textMuted),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
