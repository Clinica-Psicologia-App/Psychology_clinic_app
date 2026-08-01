import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/patient_timeline_event.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class PatientTimelineEventTile extends StatelessWidget {
  const PatientTimelineEventTile({
    super.key,
    required this.event,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final PatientTimelineEvent event;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sensitive = event.isSensitive;
    final accent = sensitive ? AppColors.error : AppColors.turquoise;
    final lineColor = accent.withValues(alpha: 0.22);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(width: 2, color: lineColor),
                  ),
                _TimelineNode(accent: accent),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: lineColor),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: isFirst ? 0 : 4,
                bottom: isLast ? 0 : 12,
              ),
              child: ClayCard(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: accent.withValues(alpha: 0.18)),
                ),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                event.title,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  color: AppColors.navy,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  _DatePill(
                                    label: event.dateLabel,
                                    accent: accent,
                                  ),
                                  if (sensitive)
                                    const _SensitiveChip(),
                                ],
                              ),
                              if (event.subtitleLine != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 6),
                                  child: Text(
                                    event.subtitleLine!,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                ),
                              if (event.description != null &&
                                  event.description!.trim().isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    event.description!.trim(),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.chevron_right,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Nodo em anel com ponto central e halo suave — mesma linguagem do mapa
/// mental aplicada à linha do tempo.
class _TimelineNode extends StatelessWidget {
  const _TimelineNode({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
            ),
          ),
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 1.4),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
          ),
        ],
      ),
    );
  }
}

class _DatePill extends StatelessWidget {
  const _DatePill({required this.label, required this.accent});

  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: accent,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _SensitiveChip extends StatelessWidget {
  const _SensitiveChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.lock_outline, size: 11, color: AppColors.error),
          const SizedBox(width: 4),
          Text(
            'Sensível',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: AppColors.error,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class TimelineEventDetailBody extends StatelessWidget {
  const TimelineEventDetailBody({super.key, required this.event});

  final PatientTimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (event.isSensitive)
          ClayCard(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.35),
            child: const ListTile(
              leading: Icon(Icons.lock_outline),
              title: Text('Evento marcado como sensível'),
            ),
          ),
        ClayCard(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  event.dateLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
                if (event.category != null && event.category!.trim().isNotEmpty)
                  _DetailRow(label: 'Categoria', value: event.category!.trim()),
                if (event.periodLabel != null &&
                    event.periodLabel!.trim().isNotEmpty)
                  _DetailRow(
                    label: 'Período',
                    value: event.periodLabel!.trim(),
                  ),
                if (event.emotionalImpact != null)
                  _DetailRow(
                    label: 'Impacto emocional',
                    value: '${event.emotionalImpact}/10',
                  ),
                if (event.description != null &&
                    event.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text('Descrição', style: theme.textTheme.labelLarge),
                  const SizedBox(height: 8),
                  Text(event.description!.trim()),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
