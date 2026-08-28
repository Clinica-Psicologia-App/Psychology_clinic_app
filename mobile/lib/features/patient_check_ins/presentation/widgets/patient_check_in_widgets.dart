import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/patient_check_in.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class PatientCheckInListTile extends StatelessWidget {
  const PatientCheckInListTile({
    super.key,
    required this.checkIn,
    required this.onTap,
    this.highlightToday = false,
  });

  final PatientCheckIn checkIn;
  final VoidCallback onTap;
  final bool highlightToday;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final date = loc.formatFullDate(checkIn.checkedInAt.toLocal());
    final time = loc.formatTimeOfDay(
      TimeOfDay.fromDateTime(checkIn.checkedInAt.toLocal()),
    );
    const accent = AppColors.turquoise;

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 12),
      color: highlightToday ? AppColors.turquoise.withValues(alpha: 0.08) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: accent.withValues(alpha: 0.16)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [accent, accent.withValues(alpha: 0.78)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.32),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(
                  highlightToday ? Icons.today : Icons.fact_check_outlined,
                  color: Colors.white,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      highlightToday ? 'Check-in de hoje' : date,
                      style: theme.textTheme.titleSmall?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$time · ${checkIn.summaryLine}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (checkIn.notes != null &&
                        checkIn.notes!.trim().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          checkIn.notes!.trim(),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right,
                color: theme.colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScoreSliderField extends StatelessWidget {
  const ScoreSliderField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.lowLabel,
    this.highLabel,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;
  final String? lowLabel;
  final String? highLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: theme.textTheme.titleSmall),
            Text(
              '$value',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: 0,
          max: 10,
          divisions: 10,
          label: '$value',
          onChanged: (v) => onChanged(v.round()),
        ),
        if (lowLabel != null || highLabel != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                lowLabel ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              Text(
                highLabel ?? '',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class CheckInScoresSummary extends StatelessWidget {
  const CheckInScoresSummary({super.key, required this.checkIn});

  final PatientCheckIn checkIn;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        if (checkIn.moodScore != null)
          _ScoreChip(label: 'Humor', value: checkIn.moodScore!),
        if (checkIn.anxietyScore != null)
          _ScoreChip(label: 'Ansiedade', value: checkIn.anxietyScore!),
        if (checkIn.energyScore != null)
          _ScoreChip(label: 'Energia', value: checkIn.energyScore!),
        if (checkIn.problemIntensityScore != null)
          _ScoreChip(
            label: 'Problemas',
            value: checkIn.problemIntensityScore!,
          ),
      ],
    );
  }
}

class _ScoreChip extends StatelessWidget {
  const _ScoreChip({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: CircleAvatar(
        child: Text('$value', style: const TextStyle(fontSize: 12)),
      ),
      label: Text(label),
    );
  }
}
