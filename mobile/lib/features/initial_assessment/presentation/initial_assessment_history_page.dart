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
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

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
      accent: AppColors.turquoise,
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
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final accent = _chapterAccentColor(chapter);
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
          if (entries.isNotEmpty)
            _RailEntryList(ctx: ctx, entries: entries, accentColor: accent),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              style: TextButton.styleFrom(foregroundColor: accent),
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
        _RailEntryList(
          ctx: ctx,
          entries: entries,
          accentColor: const Color(0xFF64748B),
        ),
      ],
    );
  }
}

class _RailEntryList extends StatelessWidget {
  const _RailEntryList({
    required this.ctx,
    required this.entries,
    required this.accentColor,
  });

  final InitialAssessmentContext ctx;
  final List<TimelineEntry> entries;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < entries.length; i++)
          _RailEntryNode(
            ctx: ctx,
            entry: entries[i],
            accentColor: accentColor,
            isLast: i == entries.length - 1,
          ),
      ],
    );
  }
}

class _RailEntryNode extends StatelessWidget {
  const _RailEntryNode({
    required this.ctx,
    required this.entry,
    required this.accentColor,
    required this.isLast,
  });

  final InitialAssessmentContext ctx;
  final TimelineEntry entry;
  final Color accentColor;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 18,
            child: Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1.5,
                      margin: const EdgeInsets.only(top: 4),
                      color: accentColor.withValues(alpha: 0.22),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(left: 6, bottom: isLast ? 0 : 10),
              child: _EventCard(
                ctx: ctx,
                entry: entry,
                accentColor: accentColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.ctx,
    required this.entry,
    required this.accentColor,
  });

  final InitialAssessmentContext ctx;
  final TimelineEntry entry;
  final Color accentColor;

  Color _impactColor(int value) {
    if (value >= 7) return AppColors.error;
    if (value >= 4) return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClayCard(
      child: InkWell(
        onTap: () => showTimelineEventEditor(
          context: context,
          ctx: ctx,
          entry: entry,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 3, color: accentColor),
            Expanded(
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (entry.isSensitive)
                    Padding(
                      padding: const EdgeInsets.only(right: 6, top: 2),
                      child: Icon(Icons.lock_outline,
                          size: 15,
                          color: theme.colorScheme.onSurfaceVariant),
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
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                ],
              ),
              if (entry.emotionalImpact != null) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.favorite,
                        size: 13, color: _impactColor(entry.emotionalImpact!)),
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
          ],
        ),
      ),
    );
  }
}

Color _chapterAccentColor(LifeChapter chapter) => switch (chapter) {
      LifeChapter.childhood => const Color(0xFFD85A30),
      LifeChapter.adolescence => const Color(0xFFBA7517),
      LifeChapter.adulthood => const Color(0xFF1D9E75),
      LifeChapter.maturity => const Color(0xFF378ADD),
      LifeChapter.today => const Color(0xFF6B46C1),
    };
