import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../mental_map/providers/mental_map_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../data/results_repository.dart'
    show SchemaAdjustmentInput, ResultAdjustmentInput;
import '../domain/category_result.dart';
import '../domain/patient_result_detail.dart';
import '../domain/questionnaire_response_status.dart';
import '../domain/result_disclaimer.dart';
import '../domain/result_snapshot.dart';
import '../domain/schema_activation.dart';
import '../domain/scoring_schema_result.dart';
import '../domain/scoring_severity.dart';
import '../domain/scoring_snapshot.dart';
import '../domain/snapshot_context_result.dart';
import '../providers/results_providers.dart';
import 'widgets/schema_ativados_card.dart';
import 'widgets/schema_bar_chart_section.dart';
import 'widgets/scoring_demo_section.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

const _supportsClinicalReview = true;

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

typedef _PendingResultAdj = ({double? score, String? note});

class _DetailBodyState extends ConsumerState<_DetailBody> {
  bool _savingReview = false;
  late final TextEditingController _reviewNotesController;

  final Map<String, _PendingResultAdj> _pendingSchemaAdjs = {};
  final Map<String, _PendingResultAdj> _pendingResultAdjs = {};

  @override
  void initState() {
    super.initState();
    _reviewNotesController =
        TextEditingController(text: widget.detail.reviewNotes ?? '');
  }

  int get _adjustedCount =>
      _pendingSchemaAdjs.values.where((a) => a.score != null).length +
      _pendingResultAdjs.values.where((a) => a.score != null).length;

  bool get _hasPendingChanges =>
      _pendingSchemaAdjs.isNotEmpty || _pendingResultAdjs.isNotEmpty;

  @override
  void dispose() {
    _reviewNotesController.dispose();
    super.dispose();
  }

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
    final canAdjust = widget.role != ProfileRole.patient &&
        detail.status == QuestionnaireResponseStatus.completed &&
        !detail.isReviewed &&
        !_savingReview;

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
        padding: const EdgeInsets.all(16),
        children: [
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
                  if (_supportsClinicalReview)
                    _InfoRow(
                      label: 'Revisão clínica',
                      value: detail.isReviewed ? 'Concluída' : 'Pendente',
                    ),
                  if (_supportsClinicalReview && detail.reviewedAt != null)
                    _InfoRow(
                      label: 'Revisado em',
                      value: loc.formatFullDate(detail.reviewedAt!),
                    ),
                  if (_supportsClinicalReview && detail.reviewedByName != null)
                    _InfoRow(
                      label: 'Revisado por',
                      value: detail.reviewedByName!,
                    ),
                ],
              ),
            ),
          ),
          if (_supportsClinicalReview &&
              widget.role != ProfileRole.patient) ...[
            const SizedBox(height: 16),
            ClayCard(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: detail.isReviewed
                      ? AppColors.success.withValues(alpha: 0.35)
                      : AppColors.warning.withValues(alpha: 0.35),
                  width: 1.4,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          detail.isReviewed
                              ? Icons.verified_outlined
                              : Icons.pending_actions_outlined,
                          size: 22,
                          color: detail.isReviewed
                              ? AppColors.success
                              : AppColors.warning,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Passar a régua',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: detail.isReviewed
                                ? AppColors.successContainer
                                : AppColors.warningContainer,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            detail.isReviewed
                                ? 'Liberado ao paciente'
                                : 'Não liberado',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: detail.isReviewed
                                      ? AppColors.onSuccessContainer
                                      : AppColors.onWarningContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      detail.isReviewed
                          ? 'O paciente já pode visualizar este resultado. '
                              'Remover a revisão volta a ocultá-lo.'
                          : 'Ajuste os scores consolidados diretamente nos '
                              'esquemas e categorias abaixo. Ao concluir, os '
                              'scores validados são registrados e o resultado '
                              'é liberado ao paciente.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.4,
                          ),
                    ),
                    if (_adjustedCount > 0) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.purple.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.straighten_outlined,
                              size: 16,
                              color: AppColors.purple,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              '$_adjustedCount score(s) ajustado(s) pelo terapeuta',
                              style: Theme.of(context)
                                  .textTheme
                                  .labelMedium
                                  ?.copyWith(
                                    color: AppColors.purple,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _reviewNotesController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Observação da revisão',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _savingReview || !detail.isReviewed
                                ? null
                                : () => _setReviewed(false),
                            icon: const Icon(Icons.undo_outlined),
                            label: const Text('Remover revisão'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: _savingReview || detail.isReviewed
                                ? null
                                : () => _setReviewed(true),
                            icon: _savingReview
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.straighten_outlined),
                            label: Text(
                              detail.isReviewed
                                  ? 'Régua concluída'
                                  : 'Concluir régua e liberar',
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_hasPendingChanges && !detail.isReviewed) ...[
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          onPressed:
                              _savingReview ? null : () => _setReviewed(false),
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Salvar scores sem concluir'),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (_supportsClinicalReview && detail.requiresTherapistReview) ...[
            const SizedBox(height: 16),
            const ClayCard(
              child: ListTile(
                leading: Icon(Icons.verified_user_outlined),
                title: Text('Revisão clínica pendente'),
                subtitle: Text(
                  'Este resultado ainda deve ser revisado pelo terapeuta antes de ser usado como leitura consolidada do caso.',
                ),
              ),
            ),
          ],
          // ── Régua visual: gráfico + ativados/inativos ─────────────────────
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
              canAdjust: canAdjust,
              pendingSchemaScores: _pendingSchemaAdjs.map(
                (id, adj) => MapEntry(id, adj.score),
              ),
              onSchemaAdjust: canAdjust
                  ? (schema) => _openSchemaAdjustDialog(schema, scoring)
                  : null,
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
              ..._buildCategoryCards(detail, showScoringDemo, canAdjust),
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

  Future<void> _setReviewed(bool reviewed) async {
    setState(() => _savingReview = true);
    try {
      final schemaAdjs = [
        for (final entry in _pendingSchemaAdjs.entries)
          if (entry.value.score != null)
            SchemaAdjustmentInput(
              schemaId: entry.key,
              professionalScore: entry.value.score,
              professionalNote: entry.value.note,
            ),
      ];
      final resultAdjs = [
        for (final entry in _pendingResultAdjs.entries)
          if (entry.value.score != null)
            ResultAdjustmentInput(
              resultId: entry.key,
              professionalScore: entry.value.score,
              professionalNote: entry.value.note,
            ),
      ];

      await ref
          .read(reviewQuestionnaireResponseProvider(widget.responseId).notifier)
          .submit(
            reviewed: reviewed,
            reviewNotes: _reviewNotesController.text,
            schemaAdjustments: schemaAdjs,
            resultAdjustments: resultAdjs,
          );
      _pendingSchemaAdjs.clear();
      _pendingResultAdjs.clear();

      ref.invalidate(
        patientResultDetailProvider(
          PatientResultDetailContext(
            role: widget.role,
            responseId: widget.responseId,
          ),
        ),
      );
      ref.invalidate(
        patientResultsListProvider(
          PatientResultsContext(
            role: widget.role,
            patientId: widget.patientId,
          ),
        ),
      );
      if (widget.role != ProfileRole.patient) {
        ref.invalidate(
          staffMentalMapProvider(
            StaffMentalMapContext(
              role: widget.role,
              patientId: widget.patientId,
            ),
          ),
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            reviewed
                ? 'Régua concluída — resultado validado e liberado.'
                : 'Revisão clínica removida.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingReview = false);
    }
  }

  Future<void> _openSchemaAdjustDialog(
    ScoringSchemaResult schema,
    ScoringSnapshot scoring,
  ) async {
    final existing = _pendingSchemaAdjs[schema.id];
    final result = await showDialog<_PendingResultAdj>(
      context: context,
      builder: (_) => _AdjustResultDialog(
        name: schema.name,
        code: schema.code,
        currentScore: schema.averageScore,
        scaleMin: scoring.scaleMin?.toDouble(),
        scaleMax: scoring.scaleMax?.toDouble(),
        initialScore: existing?.score ?? schema.professionalAverageScore,
        initialNote: existing?.note,
      ),
    );
    if (result == null) return;
    setState(() {
      if (result.score == null &&
          (result.note == null || result.note!.isEmpty)) {
        _pendingSchemaAdjs.remove(schema.id);
      } else {
        _pendingSchemaAdjs[schema.id] = result;
      }
    });
  }

  Future<void> _openResultAdjustDialog(CategoryResult result) async {
    final scoring = widget.detail.scoringDemo;
    final existing = _pendingResultAdjs[result.id];
    final dialogResult = await showDialog<_PendingResultAdj>(
      context: context,
      builder: (_) => _AdjustResultDialog(
        name: result.categoryName ?? result.categoryCode ?? 'Categoria',
        currentScore: result.averageScore,
        scaleMin: scoring?.scaleMin?.toDouble(),
        scaleMax: scoring?.scaleMax?.toDouble(),
        initialScore: existing?.score ?? result.professionalAverageScore,
        initialNote: existing?.note ?? result.professionalNote,
      ),
    );
    if (dialogResult == null) return;
    setState(() {
      if (dialogResult.score == null &&
          (dialogResult.note == null || dialogResult.note!.isEmpty)) {
        _pendingResultAdjs.remove(result.id);
      } else {
        _pendingResultAdjs[result.id] = dialogResult;
      }
    });
  }

  List<Widget> _buildCategoryCards(
    PatientResultDetail detail,
    bool showScoringDemo,
    bool canAdjust,
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

      final pending = _pendingResultAdjs[result.id];
      cards.add(
        _CategoryResultCard(
          result: result,
          legacyOnly: showScoringDemo,
          compactParentalLabel: detail.isParentalStyles,
          canAdjust: canAdjust,
          pendingScore: pending?.score,
          onAdjust: canAdjust ? () => _openResultAdjustDialog(result) : null,
        ),
      );
    }

    return cards;
  }
}

class _AdjustResultDialog extends StatefulWidget {
  const _AdjustResultDialog({
    required this.name,
    this.code,
    this.currentScore,
    this.scaleMin,
    this.scaleMax,
    this.initialScore,
    this.initialNote,
  });

  final String name;
  final String? code;
  final double? currentScore;
  final double? scaleMin;
  final double? scaleMax;
  final double? initialScore;
  final String? initialNote;

  @override
  State<_AdjustResultDialog> createState() => _AdjustResultDialogState();
}

class _AdjustResultDialogState extends State<_AdjustResultDialog> {
  late double _selectedScore;
  late final TextEditingController _noteController;

  double get _min => widget.scaleMin ?? 1.0;
  double get _max => widget.scaleMax ?? 6.0;
  int get _divisions => ((_max - _min) * 10).round();

  bool get _hasExisting => widget.initialScore != null;

  @override
  void initState() {
    super.initState();
    _selectedScore =
        (widget.initialScore ?? widget.currentScore ?? _min).clamp(_min, _max);
    _noteController = TextEditingController(text: widget.initialNote ?? '');
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _apply() {
    final note = _noteController.text.trim();
    Navigator.of(context).pop(
      (score: _selectedScore, note: note.isEmpty ? null : note),
    );
  }

  void _remove() {
    Navigator.of(context).pop(
      (score: null as double?, note: null as String?),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final currentScore = widget.currentScore;
    final isChanged =
        currentScore != null && (_selectedScore - currentScore).abs() > 0.01;

    return AlertDialog(
      title: const Text('Ajustar score'),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.name, style: tt.titleSmall),
            if (widget.code != null)
              Text(
                widget.code!,
                style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            const SizedBox(height: 14),
            // Score de referência
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Score do sistema',
                          style: tt.labelSmall
                              ?.copyWith(color: cs.onSurfaceVariant),
                        ),
                        Text(
                          currentScore?.toStringAsFixed(2) ?? '-',
                          style: tt.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  if (widget.scaleMin != null && widget.scaleMax != null)
                    Text(
                      'Escala ${_min.toStringAsFixed(0)}–${_max.toStringAsFixed(0)}',
                      style:
                          tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // Score selecionado em destaque
            Center(
              child: Column(
                children: [
                  Text(
                    'Score validado',
                    style: tt.labelMedium?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        _selectedScore.toStringAsFixed(1),
                        style: tt.displaySmall?.copyWith(
                          color: AppColors.purple,
                          fontWeight: FontWeight.w600,
                          height: 1,
                        ),
                      ),
                      Text(
                        ' /${_max.toStringAsFixed(0)}',
                        style: tt.titleMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                  if (isChanged)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        _selectedScore > currentScore
                            ? '▲ ${(_selectedScore - currentScore).toStringAsFixed(1)} acima do sistema'
                            : '▼ ${(currentScore - _selectedScore).toStringAsFixed(1)} abaixo do sistema',
                        style: tt.labelSmall?.copyWith(
                          color: _selectedScore > currentScore
                              ? AppColors.warning
                              : AppColors.purple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            // Slider
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.purple,
                thumbColor: AppColors.purple,
                inactiveTrackColor: AppColors.purple.withValues(alpha: 0.2),
                overlayColor: AppColors.purple.withValues(alpha: 0.12),
                trackHeight: 4,
              ),
              child: Slider(
                value: _selectedScore,
                min: _min,
                max: _max,
                divisions: _divisions,
                onChanged: (v) => setState(() => _selectedScore = v),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                children: [
                  Text(
                    _min.toStringAsFixed(0),
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const Spacer(),
                  Text(
                    _max.toStringAsFixed(0),
                    style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteController,
              minLines: 2,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Observação (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 4),
          ],
        ),
      ),
      actions: [
        if (_hasExisting)
          TextButton(
            onPressed: _remove,
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Remover'),
          ),
        const Spacer(),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _apply,
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
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
    this.canAdjust = false,
    this.pendingScore,
    this.onAdjust,
  });

  final CategoryResult result;
  final bool legacyOnly;
  final bool compactParentalLabel;
  final bool canAdjust;
  final double? pendingScore;
  final VoidCallback? onAdjust;

  double? get _effectiveScore =>
      pendingScore ?? result.professionalAverageScore;

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
                        'Score validado: ${effectiveScore.toStringAsFixed(2)}'
                        '${pendingScore != null ? ' (pendente)' : ''}',
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
                result.professionalNote!.trim().isNotEmpty &&
                pendingScore == null) ...[
              const SizedBox(height: 6),
              Text(
                result.professionalNote!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
            if (canAdjust)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onAdjust,
                  icon: const Icon(Icons.straighten_outlined, size: 18),
                  label: Text(
                    effectiveScore != null ? 'Editar ajuste' : 'Ajustar score',
                  ),
                ),
              ),
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
