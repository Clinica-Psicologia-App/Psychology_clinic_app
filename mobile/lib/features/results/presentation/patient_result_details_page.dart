import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/category_result.dart';
import '../domain/patient_result_detail.dart';
import '../domain/questionnaire_response_status.dart';
import '../domain/result_disclaimer.dart';
import '../domain/result_snapshot.dart';
import '../domain/schema_activation.dart';
import '../domain/scoring_severity.dart';
import '../domain/snapshot_context_result.dart';
import '../providers/results_providers.dart';
import 'widgets/schema_ativados_card.dart';
import 'widgets/schema_bar_chart_section.dart';
import 'widgets/scoring_demo_section.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class PatientResultDetailsPage extends ConsumerWidget {
  const PatientResultDetailsPage({
    super.key,
    required this.role,
    required this.patientId,
    required this.responseId,
  });

  final ProfileRole role;
  final String patientId;
  final String responseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailContext = PatientResultDetailContext(
      role: role,
      responseId: responseId,
    );
    final detailAsync = ref.watch(patientResultDetailProvider(detailContext));

    return AppScaffold(
      title: 'Detalhe do resultado',
      accent: AppColors.purple,
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.invalidate(patientResultDetailProvider(detailContext)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: detailAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Não foi possível carregar o resultado.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () => ref
                      .invalidate(patientResultDetailProvider(detailContext)),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  role == ProfileRole.patient
                      ? 'Em análise com seu psicólogo. O resultado ficará '
                          'disponível assim que a análise for concluída.'
                      : 'Resposta não encontrada.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return _DetailBody(
            detail: detail,
            role: role,
            patientId: patientId,
            responseId: responseId,
          );
        },
      ),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({
    required this.detail,
    required this.role,
    required this.patientId,
    required this.responseId,
  });

  final PatientResultDetail detail;
  final ProfileRole role;
  final String patientId;
  final String responseId;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  @override
  Widget build(BuildContext context) {
    final detail = widget.detail;
    final loc = MaterialLocalizations.of(context);
    final showScoringDemo = detail.hasScoringDemo;
    final scoring = detail.scoringDemo;
    final snapshotContexts = detail.snapshotContexts;
    final structuredDisclaimer = showScoringDemo
        ? ResultStructuredDisclaimer.messageForStructuredSnapshot(
            detail.questionnaireCode,
          )
        : null;
    // Régua removida: esta tela é somente leitura. A validação acontece pela
    // ativação de esquemas no Dashboard Clínico; a liberação ao paciente é uma
    // ação por paciente (fora desta tela).
    final isStaff = widget.role != ProfileRole.patient;
    final activationsAsync = ref.watch(
      schemaActivationsProvider(
        SchemaActivationsContext(
          responseId: widget.responseId,
          isStaff: isStaff,
        ),
      ),
    );
    final activations = activationsAsync.valueOrNull ?? <SchemaActivation>[];

    return MotionReveal(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxl,
        ),
        children: [
          AppPageHeader(
            icon: Icons.analytics_outlined,
            title: detail.questionnaireName,
            subtitle:
                'Detalhe da resposta, resultados calculados e revisão clínica do instrumento.',
            metadata: [
              StatusChip(
                label: detail.questionnaireCode,
                tone: AppStatusTone.info,
                icon: Icons.tag_outlined,
              ),
              StatusChip(
                label: detail.status.label,
                tone: _responseStatusTone(detail.status),
                icon: _responseStatusIcon(detail.status),
              ),
              StatusChip(
                label: '${detail.answeredCount} resposta(s)',
                tone: AppStatusTone.neutral,
                icon: Icons.format_list_numbered_outlined,
              ),
              StatusChip(
                label: detail.hasResults ? 'Com resultado' : 'Sem resultado',
                tone: detail.hasResults
                    ? AppStatusTone.completed
                    : AppStatusTone.warning,
                icon: detail.hasResults
                    ? Icons.analytics_outlined
                    : Icons.hourglass_empty_outlined,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          const _SectionTitle('Resposta'),
          ClayCard(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    detail.questionnaireName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  _InfoRow(label: 'Código', value: detail.questionnaireCode),
                  _InfoRow(label: 'Status', value: detail.status.label),
                  _InfoRow(
                    label: 'Início',
                    value: detail.startedAt != null
                        ? loc.formatFullDate(detail.startedAt!)
                        : '-',
                  ),
                  _InfoRow(
                    label: 'Conclusão',
                    value: detail.completedAt != null
                        ? loc.formatFullDate(detail.completedAt!)
                        : '-',
                  ),
                  _InfoRow(
                    label: 'Respostas registradas',
                    value:
                        '${detail.answeredCount} de ${detail.answers.length}',
                  ),
                ],
              ),
            ),
          ),
          // ── Perfil esquemático: gráfico + ativados/não ativados ──────────
          if (showScoringDemo &&
              scoring != null &&
              scoring.schemas.isNotEmpty) ...[
            const SizedBox(height: 16),
            SchemaBarChartSection(
              scoring: scoring,
              activations: activations,
              showLegend: !isStaff,
            ),
            const SizedBox(height: 12),
            SchemaAtivadosCard(
              scoring: scoring,
              activations: activations,
              isStaff: isStaff,
              responseId: widget.responseId,
            ),
          ],
          if (showScoringDemo && scoring != null) ...[
            const SizedBox(height: 16),
            ScoringStructuredDisclaimerBanner(message: structuredDisclaimer!),
            const SizedBox(height: 16),
            const _SectionTitle('Apuração estruturada'),
            ScoringDemoSection(
              scoring: scoring,
              snapshotVersion: detail.snapshotVersion,
            ),
            const SizedBox(height: 24),
          ],
          if (detail.isParentalStyles && snapshotContexts.isNotEmpty) ...[
            const _SectionTitle('Resultados por figura parental'),
            ...snapshotContexts.map(
              (ctx) => _ParentalContextCard(
                context: ctx,
                scaleMin: scoring?.scaleMin,
                scaleMax: scoring?.scaleMax,
              ),
            ),
          ] else ...[
            _SectionTitle(
              showScoringDemo
                  ? 'Categorias (legado)'
                  : 'Resultados por categoria',
            ),
            if (!detail.hasResults)
              ClayCard(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    showScoringDemo
                        ? 'Nenhum resultado por categoria.'
                        : 'Nenhum resultado calculado ainda. '
                            'Finalize o questionário para gerar o snapshot MVP.',
                  ),
                ),
              )
            else
              ..._buildCategoryCards(detail, showScoringDemo),
          ],
          const SizedBox(height: 16),
          if (detail.status == QuestionnaireResponseStatus.completed)
            Text(
              showScoringDemo
                  ? 'Sem interpretação clínica automática nesta versão.'
                  : 'Interpretação clínica automática não está disponível nesta versão.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  List<Widget> _buildCategoryCards(
    PatientResultDetail detail,
    bool showScoringDemo,
  ) {
    final cards = <Widget>[];
    String? currentGroup;

    for (final result in detail.sortedCategoryResults) {
      final shouldGroup =
          detail.isParentalStyles && result.parentalFigureLabel != 'Geral';
      final groupLabel = shouldGroup ? result.parentalFigureLabel : null;

      if (groupLabel != null && groupLabel != currentGroup) {
        currentGroup = groupLabel;
        cards.add(_CategoryGroupHeader(groupLabel));
      }

      cards.add(
        _CategoryResultCard(
          result: result,
          legacyOnly: showScoringDemo,
          compactParentalLabel: detail.isParentalStyles,
        ),
      );
    }

    return cards;
  }
}

AppStatusTone _responseStatusTone(QuestionnaireResponseStatus status) {
  return switch (status) {
    QuestionnaireResponseStatus.completed => AppStatusTone.completed,
    QuestionnaireResponseStatus.cancelled => AppStatusTone.error,
    QuestionnaireResponseStatus.draft => AppStatusTone.warning,
  };
}

IconData _responseStatusIcon(QuestionnaireResponseStatus status) {
  return switch (status) {
    QuestionnaireResponseStatus.completed => Icons.check_circle_outline,
    QuestionnaireResponseStatus.cancelled => Icons.cancel_outlined,
    QuestionnaireResponseStatus.draft => Icons.edit_note_outlined,
  };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _CategoryResultCard extends StatelessWidget {
  const _CategoryResultCard({
    required this.result,
    this.legacyOnly = false,
    this.compactParentalLabel = false,
  });

  final CategoryResult result;
  final bool legacyOnly;
  final bool compactParentalLabel;

  double? get _effectiveScore => result.professionalAverageScore;

  @override
  Widget build(BuildContext context) {
    final snap = result.snapshot;
    final displaySnap = snap.hasContent ? snap : ResultSnapshot.fromJson(null);
    final effectiveScore = _effectiveScore;

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              compactParentalLabel
                  ? result.shortCategoryLabel
                  : result.categoryName ?? result.categoryCode ?? 'Categoria',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Classificação',
              value: result.classificationLabel,
            ),
            if (result.totalScore != null)
              _InfoRow(
                label: 'Pontuação total',
                value: result.totalScore!.toStringAsFixed(2),
              ),
            if (result.averageScore != null)
              _InfoRow(
                label: 'Média',
                value: result.averageScore!.toStringAsFixed(2),
              ),
            if (effectiveScore != null) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.straighten_outlined,
                      size: 16,
                      color: AppColors.purple,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Score validado: ${effectiveScore.toStringAsFixed(2)}',
                        style:
                            Theme.of(context).textTheme.labelMedium?.copyWith(
                                  color: AppColors.purple,
                                  fontWeight: FontWeight.w700,
                                ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            if (result.professionalNote != null &&
                result.professionalNote!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                result.professionalNote!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (!legacyOnly && displaySnap.hasContent) ...[
              const SizedBox(height: 12),
              Text(
                'Snapshot MVP',
                style: Theme.of(context).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              if (displaySnap.version != null)
                _InfoRow(label: 'Versão', value: displaySnap.version!),
              if (displaySnap.categoryCode != null)
                _InfoRow(label: 'Código', value: displaySnap.categoryCode!),
              if (displaySnap.answerCount != null)
                _InfoRow(
                  label: 'Itens no snapshot',
                  value: '${displaySnap.answerCount}',
                ),
              if (displaySnap.totalWeightedScore != null)
                _InfoRow(
                  label: 'Soma ponderada',
                  value: displaySnap.totalWeightedScore!.toStringAsFixed(2),
                ),
              if (displaySnap.note != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    displaySnap.note!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
            ] else if (!legacyOnly)
              const Padding(
                padding: EdgeInsets.only(top: 8),
                child: Text('Snapshot não disponível para esta categoria.'),
              ),
          ],
        ),
      ),
    );
  }
}

class _CategoryGroupHeader extends StatelessWidget {
  const _CategoryGroupHeader(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _ParentalContextCard extends StatelessWidget {
  const _ParentalContextCard({
    required this.context,
    this.scaleMin,
    this.scaleMax,
  });

  final SnapshotContextResult context;
  final int? scaleMin;
  final int? scaleMax;

  String _cleanName(String name) {
    for (final sep in [' — ${context.label}', ' – ${context.label}']) {
      if (name.endsWith(sep)) {
        return name.substring(0, name.length - sep.length).trim();
      }
    }
    // fallback: strip last " — Xxx" if it's the parental figure suffix
    final idx = name.lastIndexOf(' — ');
    if (idx > name.length ~/ 2) return name.substring(0, idx).trim();
    return name;
  }

  @override
  Widget build(BuildContext ctx) {
    final tt = Theme.of(ctx).textTheme;
    final cs = Theme.of(ctx).colorScheme;
    final avg = context.summary.averageScore;
    final avgColor = _parentalSeverityColor(avg, scaleMin, scaleMax, ctx);

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Cabeçalho ──────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        context.label,
                        style: tt.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${context.answerCount ?? 0}/${context.totalQuestions ?? 0} itens respondidos',
                        style:
                            tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (avg != null) ...[
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        avg.toStringAsFixed(2),
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: avgColor,
                          height: 1,
                        ),
                      ),
                      Text(
                        'média',
                        style:
                            tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          // ── Esquemas ───────────────────────────────────────────
          if (context.schemas.isNotEmpty) ...[
            Divider(height: 1, color: cs.outlineVariant),
            ...context.schemas.map(
              (schema) => _ParentalSchemaRow(
                name: _cleanName(schema.name),
                score: schema.averageScore,
                severity: schema.severity,
                scaleMin: scaleMin,
                scaleMax: scaleMax,
              ),
            ),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }
}

Color _parentalSeverityColor(
  double? avg,
  int? scaleMin,
  int? scaleMax,
  BuildContext context,
) {
  if (avg == null) return Theme.of(context).colorScheme.onSurface;
  final mn = (scaleMin ?? 1).toDouble();
  final mx = (scaleMax ?? 6).toDouble();
  if (mx <= mn) return Theme.of(context).colorScheme.onSurface;
  final ratio = (avg - mn) / (mx - mn);
  if (ratio >= 0.70) return const Color(0xFFE24B4A);
  if (ratio >= 0.45) return const Color(0xFFBA7517);
  if (ratio >= 0.25) return const Color(0xFF639922);
  return const Color(0xFF0F6E56);
}

Color _parentalSchemaColor(
  ScoringSeverity? severity,
  double? score,
  int? scaleMin,
  int? scaleMax,
  BuildContext context,
) {
  if (severity != null && severity.hasLabel) {
    final l = severity.label.toLowerCase();
    if (l.contains('ativado') || l.contains('alto') || l.contains('severo')) {
      return const Color(0xFFE24B4A);
    }
    if (l.contains('médio') || l.contains('medio') || l.contains('moderado')) {
      return const Color(0xFFBA7517);
    }
    if (l.contains('leve') || l.contains('baixo'))
      return const Color(0xFF639922);
    if (l.contains('mínimo') || l.contains('minimo'))
      return const Color(0xFF0F6E56);
  }
  return _parentalSeverityColor(score, scaleMin, scaleMax, context);
}

class _ParentalSchemaRow extends StatelessWidget {
  const _ParentalSchemaRow({
    required this.name,
    this.score,
    this.severity,
    this.scaleMin,
    this.scaleMax,
  });

  final String name;
  final double? score;
  final ScoringSeverity? severity;
  final int? scaleMin;
  final int? scaleMax;

  double? _progress() {
    final s = score;
    final mn = (scaleMin ?? 1).toDouble();
    final mx = (scaleMax ?? 6).toDouble();
    if (s == null || mx <= mn) return null;
    return ((s - mn) / (mx - mn)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final color =
        _parentalSchemaColor(severity, score, scaleMin, scaleMax, context);
    final progress = _progress();
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: tt.bodySmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                score?.toStringAsFixed(2) ?? '-',
                style: tt.labelLarge?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 3,
                  backgroundColor: cs.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(
                    color.withValues(alpha: 0.7),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
        ],
      ),
    );
  }
}
