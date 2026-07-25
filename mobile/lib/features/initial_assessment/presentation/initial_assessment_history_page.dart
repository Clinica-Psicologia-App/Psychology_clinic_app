import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/life_chapter.dart';
import '../domain/patient_history.dart';
import '../domain/timeline_belief.dart';
import '../domain/timeline_entry.dart';
import '../providers/patient_history_providers.dart';
import 'widgets/timeline_event_editor.dart';

/// Tela 2 do fluxo Conhecer na lente do paciente — "Minha História",
/// agrupada pelos capítulos da vida.
class InitialAssessmentHistoryPage extends ConsumerWidget {
  const InitialAssessmentHistoryPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = InitialAssessmentContext(role: role, patientId: patientId);
    final async = ref.watch(patientHistoryProvider(ctx));

    return AppScaffold(
      title: 'Minha História',
      body: AsyncStateBody<PatientHistory>(
        asyncValue: async,
        onRetry: () => ref.invalidate(patientHistoryProvider(ctx)),
        dataBuilder: (history) => ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Text(
              'Nossa história é formada por experiências importantes. Vamos '
              'percorrer alguns momentos da sua vida para compreender como ela '
              'foi sendo construída.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
            ),
            const SizedBox(height: 20),
            for (final chapter in kLifeChaptersInOrder)
              _ChapterSection(
                ctx: ctx,
                chapter: chapter,
                entries: history.entriesFor(chapter),
              ),
            if (history.unchaptered.isNotEmpty)
              _UnchapteredSection(ctx: ctx, entries: history.unchaptered),
          ],
        ),
      ),
    );
  }
}

class _ChapterSection extends StatelessWidget {
  const _ChapterSection({
    required this.ctx,
    required this.chapter,
    required this.entries,
  });

  final InitialAssessmentContext ctx;
  final LifeChapter chapter;
  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            chapter.label,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          for (final entry in entries)
            _EventCard(ctx: ctx, entry: entry),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => showTimelineEventEditor(
                context: context,
                ctx: ctx,
                initialChapter: chapter,
              ),
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Adicionar acontecimento'),
            ),
          ),
        ],
      ),
    );
  }
}

class _UnchapteredSection extends StatelessWidget {
  const _UnchapteredSection({required this.ctx, required this.entries});

  final InitialAssessmentContext ctx;
  final List<TimelineEntry> entries;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Outros acontecimentos',
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        for (final entry in entries) _EventCard(ctx: ctx, entry: entry),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.ctx, required this.entry});

  final InitialAssessmentContext ctx;
  final TimelineEntry entry;

  Color _impactColor(int value) {
    if (value >= 7) return AppColors.error;
    if (value >= 4) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => showTimelineEventEditor(
          context: context,
          ctx: ctx,
          entry: entry,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.isSensitive)
                    const Padding(
                      padding: EdgeInsets.only(right: 6, top: 2),
                      child: Icon(Icons.lock_outline,
                          size: 15, color: AppColors.textMuted),
                    ),
                  Expanded(
                    child: Text(
                      entry.title,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  if (entry.ageAtEvent != null)
                    Text(
                      '${entry.ageAtEvent} anos',
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.textSecondary),
                    ),
                ],
              ),
              if (entry.emotionalImpact != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.favorite,
                        size: 13,
                        color: _impactColor(entry.emotionalImpact!)),
                    const SizedBox(width: 4),
                    Text(
                      'Impacto ${entry.emotionalImpact}/10',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: _impactColor(entry.emotionalImpact!),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
              if ((entry.description ?? '').isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(entry.description!,
                    style: theme.textTheme.bodySmall,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
              ],
              if (entry.beliefs.isNotEmpty) ...[
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final belief in entry.beliefs)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceTintPurple,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          belief.label,
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.purple),
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
