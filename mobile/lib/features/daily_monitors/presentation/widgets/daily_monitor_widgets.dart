import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../domain/daily_monitor.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class DailyMonitorListTile extends StatelessWidget {
  const DailyMonitorListTile({
    super.key,
    required this.monitor,
    required this.onTap,
  });

  final DailyMonitor monitor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = monitor.createdAt.toLocal();
    final dateLabel =
        '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final intensity = monitor.emotionPayload.intensity;

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side:
            BorderSide(color: AppColors.moduleMonitor.withValues(alpha: 0.16)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _IntensityRingNode(intensity: intensity),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      monitor.summaryLine,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
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
    );
  }
}

/// Nodo em anel com a intensidade no centro — linguagem da marca aplicada ao
/// registro pontual do monitor diário.
class _IntensityRingNode extends StatelessWidget {
  const _IntensityRingNode({required this.intensity});

  final int? intensity;

  @override
  Widget build(BuildContext context) {
    const accent = AppColors.moduleMonitor;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.10),
            ),
          ),
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 1.6),
            ),
          ),
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: accent,
            ),
            child: Center(
              child: Text(
                intensity?.toString() ?? '·',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DailyMonitorDetailBody extends StatelessWidget {
  const DailyMonitorDetailBody({
    super.key,
    required this.monitor,
    this.readOnly = true,
  });

  final DailyMonitor monitor;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final payload = monitor.emotionPayload;
    final date = monitor.createdAt.toLocal();

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxxl,
      ),
      children: [
        AppPageHeader(
          title: 'Registro diário',
          subtitle:
              '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} às ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}',
          icon: Icons.monitor_heart_outlined,
          metadata: [
            if (payload.intensity != null)
              Chip(label: Text('Intensidade ${payload.intensity}/10')),
            if (readOnly) const Chip(label: Text('Somente leitura')),
          ],
        ),
        if (!readOnly && !monitor.isEditableToday)
          const Padding(
            padding: EdgeInsets.only(top: AppSpacing.lg),
            child: AppInfoCard(
              title: 'Edição indisponível',
              body: 'Registro de dias anteriores não pode ser editado.',
              icon: Icons.lock_clock_outlined,
              tone: AppInfoCardTone.warning,
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        const AppSectionHeader(
          title: 'Conteúdo do registro',
          subtitle: 'Informações preenchidas no monitor diário.',
        ),
        const SizedBox(height: AppSpacing.sm),
        _Section(
          title: 'Humor / estado emocional',
          body: monitor.moodState,
        ),
        _Section(
          title: 'Intensidade',
          body: payload.intensity != null ? '${payload.intensity}/10' : null,
        ),
        _Section(title: 'Gatilhos', body: payload.triggers),
        _Section(title: 'Comportamentos', body: monitor.behaviors),
        _Section(title: 'Observações', body: monitor.observations),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, this.body});

  final String title;
  final String? body;

  @override
  Widget build(BuildContext context) {
    if (body == null || body!.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: AppInfoCard(
        title: title,
        body: body!,
      ),
    );
  }
}
