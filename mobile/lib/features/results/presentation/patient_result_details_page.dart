import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../mental_map/providers/mental_map_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/answered_question.dart';
import '../domain/category_result.dart';
import '../domain/patient_result_detail.dart';
import '../domain/questionnaire_response_status.dart';
import '../domain/result_disclaimer.dart';
import '../domain/result_snapshot.dart';
import '../domain/snapshot_context_result.dart';
import '../providers/results_providers.dart';
import 'widgets/scoring_demo_section.dart';

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
    final detailAsync = ref.watch(patientResultDetailProvider(responseId));

    return AppScaffold(
      title: 'Detalhe do resultado',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.invalidate(patientResultDetailProvider(responseId)),
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
                  onPressed: () =>
                      ref.invalidate(patientResultDetailProvider(responseId)),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (detail) {
          if (detail == null) {
            return const Center(child: Text('Resposta não encontrada.'));
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
  bool _savingReview = false;
  late final TextEditingController _reviewNotesController;

  @override
  void initState() {
    super.initState();
    _reviewNotesController =
        TextEditingController(text: widget.detail.reviewNotes ?? '');
  }

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

    return MotionReveal(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle('Resposta'),
          Card(
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
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Validação do terapeuta',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
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
                                : const Icon(Icons.verified_outlined),
                            label: Text(
                              detail.isReviewed
                                  ? 'Revisado'
                                  : 'Marcar como revisado',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_supportsClinicalReview && detail.requiresTherapistReview) ...[
            const SizedBox(height: 16),
            const Card(
              child: ListTile(
                leading: Icon(Icons.verified_user_outlined),
                title: Text('Revisão clínica pendente'),
                subtitle: Text(
                  'Este resultado ainda deve ser revisado pelo terapeuta antes de ser usado como leitura consolidada do caso.',
                ),
              ),
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
            ...snapshotContexts
                .map((context) => _ParentalContextCard(context: context)),
          ] else ...[
            _SectionTitle(
              showScoringDemo
                  ? 'Categorias (legado)'
                  : 'Resultados por categoria',
            ),
            if (!detail.hasResults)
              Card(
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
          const SizedBox(height: 24),
          const _SectionTitle('Perguntas e respostas'),
          if (detail.answers.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('Nenhuma resposta gravada.'),
              ),
            )
          else
            ...detail.answers.map((a) => _AnswerCard(answer: a)),
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
      await ref
          .read(reviewQuestionnaireResponseProvider(widget.responseId).notifier)
          .submit(
            reviewed: reviewed,
            reviewNotes: _reviewNotesController.text,
          );

      ref.invalidate(patientResultDetailProvider(widget.responseId));
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
                ? 'Revisão clínica registrada.'
                : 'Revisão clínica removida.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingReview = false);
    }
  }
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

  @override
  Widget build(BuildContext context) {
    final snap = result.snapshot;
    final displaySnap = snap.hasContent ? snap : ResultSnapshot.fromJson(null);

    return Card(
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

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer});

  final AnsweredQuestion answer;

  @override
  Widget build(BuildContext context) {
    final a = answer;
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              a.code,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(a.text),
            const SizedBox(height: 8),
            if (a.contextLabel != null &&
                a.contextLabel!.trim().isNotEmpty) ...[
              Text(
                'Figura parental: ${a.contextLabel}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 8),
            ],
            Text(
              'Resposta: ${a.answerDisplayLabel}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _ParentalContextCard extends StatelessWidget {
  const _ParentalContextCard({required this.context});

  final SnapshotContextResult context;

  @override
  Widget build(BuildContext contextWidget) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              context.label,
              style: Theme.of(contextWidget).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            _InfoRow(
              label: 'Progresso',
              value:
                  '${context.answerCount ?? 0}/${context.totalQuestions ?? 0}',
            ),
            if (context.summary.averageScore != null)
              _InfoRow(
                label: 'Média geral',
                value: context.summary.averageScore!.toStringAsFixed(2),
              ),
            if (context.schemas.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                'Esquemas',
                style: Theme.of(contextWidget).textTheme.labelLarge,
              ),
              const SizedBox(height: 8),
              ...context.schemas.map(
                (schema) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      Expanded(child: Text(schema.name)),
                      Text(
                        schema.averageScore?.toStringAsFixed(2) ?? '-',
                        style: Theme.of(contextWidget).textTheme.labelLarge,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
