import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/life_chapter.dart';
import '../domain/patient_history.dart';
import '../domain/timeline_belief.dart';
import '../domain/timeline_entry.dart';
import '../providers/patient_history_providers.dart';
import 'widgets/timeline_event_editor.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Tela 2 do fluxo Conhecer na lente do terapeuta — a Linha do Tempo com os
/// eventos do paciente (leitura) e um comentário clínico por evento.
class InitialAssessmentHistoryTherapistPage extends ConsumerStatefulWidget {
  const InitialAssessmentHistoryTherapistPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  ConsumerState<InitialAssessmentHistoryTherapistPage> createState() =>
      _InitialAssessmentHistoryTherapistPageState();
}

class _InitialAssessmentHistoryTherapistPageState
    extends ConsumerState<InitialAssessmentHistoryTherapistPage> {
  final Map<String, TextEditingController> _comments = {};
  bool _saving = false;

  InitialAssessmentContext get _ctx =>
      InitialAssessmentContext(role: widget.role, patientId: widget.patientId);

  @override
  void dispose() {
    for (final c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  /// Controller do comentário de um evento — criado sob demanda com o valor
  /// já salvo, e preservado entre rebuilds (inclusive após recarregar).
  TextEditingController _commentFor(TimelineEntry entry) {
    return _comments.putIfAbsent(
      entry.id,
      () => TextEditingController(text: entry.clinicalComment ?? ''),
    );
  }

  Future<void> _saveComments(PatientHistory history) async {
    setState(() => _saving = true);
    final repo = ref.read(patientHistoryRepositoryProvider);
    try {
      for (final entry in history.entries) {
        final controller = _comments[entry.id];
        if (controller == null) continue;
        await repo.saveEntryNote(
          patientId: widget.patientId,
          eventId: entry.id,
          clinicalComment: controller.text,
        );
      }
      ref.invalidate(patientHistoryProvider(_ctx));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentários salvos.')),
      );
    } catch (e) {
      if (!mounted) return;
      showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(patientHistoryProvider(_ctx));

    return AppScaffold(
      title: 'Linha do Tempo',
      body: AsyncStateBody<PatientHistory>(
        asyncValue: async,
        onRetry: () => ref.invalidate(patientHistoryProvider(_ctx)),
        dataBuilder: (history) {
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  for (final chapter in kLifeChaptersInOrder)
                    _chapterBlock(context, chapter, history.entriesFor(chapter)),
                  if (history.unchaptered.isNotEmpty)
                    _chapterBlockRaw(
                        context, 'Outros acontecimentos', history.unchaptered),
                  if (history.eventCount == 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: Text(
                        'O paciente ainda não registrou acontecimentos. '
                        'Você pode adicioná-los por ele.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: FilledButton.icon(
                  onPressed: _saving ? null : () => _saveComments(history),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Salvando...' : 'Salvar comentários'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chapterBlock(
    BuildContext context,
    LifeChapter chapter,
    List<TimelineEntry> entries,
  ) {
    if (entries.isEmpty) return const SizedBox.shrink();
    return _chapterBlockRaw(context, chapter.label, entries);
  }

  Widget _chapterBlockRaw(
    BuildContext context,
    String title,
    List<TimelineEntry> entries,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
              ),
              IconButton(
                tooltip: 'Adicionar acontecimento',
                icon: const Icon(Icons.add),
                onPressed: () => showTimelineEventEditor(
                  context: context,
                  ctx: _ctx,
                ),
              ),
            ],
          ),
          for (final entry in entries) _eventCard(context, entry),
        ],
      ),
    );
  }

  Widget _eventCard(BuildContext context, TimelineEntry entry) {
    final theme = Theme.of(context);
    final meta = <String>[
      if (entry.ageAtEvent != null) '${entry.ageAtEvent} anos',
      if (entry.emotionalImpact != null) 'Impacto ${entry.emotionalImpact}/10',
    ];
    return ClayCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(entry.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                InkWell(
                  onTap: () => showTimelineEventEditor(
                      context: context, ctx: _ctx, entry: entry),
                  child: const Padding(
                    padding: EdgeInsets.all(2),
                    child: Icon(Icons.edit_outlined, size: 16),
                  ),
                ),
              ],
            ),
            if (meta.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(meta.join(' · '),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textSecondary)),
              ),
            if ((entry.description ?? '').isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(entry.description!, style: theme.textTheme.bodySmall),
              ),
            if (entry.beliefs.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Crenças: ${entry.beliefs.map((b) => b.label).join(' · ')}',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: AppColors.purple),
                ),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _commentFor(entry),
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentário clínico',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
