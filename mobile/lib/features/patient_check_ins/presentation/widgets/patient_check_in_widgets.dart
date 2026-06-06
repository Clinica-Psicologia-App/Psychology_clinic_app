import 'package:flutter/material.dart';

import '../../domain/patient_check_in.dart';

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

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: highlightToday
          ? theme.colorScheme.primaryContainer.withValues(alpha: 0.35)
          : null,
      child: ListTile(
        leading: Icon(
          highlightToday ? Icons.today : Icons.fact_check_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(highlightToday ? 'Check-in de hoje' : date),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$time · ${checkIn.summaryLine}'),
            if (checkIn.notes != null && checkIn.notes!.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  checkIn.notes!.trim(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
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
