import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/clay_card.dart';
import '../../../profile/domain/profile_role.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../domain/patient.dart';

class PatientListTile extends StatelessWidget {
  const PatientListTile({
    super.key,
    required this.patient,
    required this.onTap,
    this.hasPendingResultsRelease = false,
    this.checkinMissingDays,
  });

  final Patient patient;
  final VoidCallback onTap;

  /// Questionário concluído, resultado ainda não liberado ao paciente.
  final bool hasPendingResultsRelease;

  /// Dias sem check-in (de psychologistAlertsProvider). Null = sem alerta.
  final int? checkinMissingDays;

  Color _ringColor(ThemeData theme) {
    if (!patient.isActive) return theme.colorScheme.outline;
    if (checkinMissingDays != null && checkinMissingDays! >= 5) {
      return AppColors.error;
    }
    if (checkinMissingDays != null && checkinMissingDays! >= 3) {
      return AppColors.warning;
    }
    if (hasPendingResultsRelease) return AppColors.info;
    return AppColors.success;
  }

  int get _filledDays {
    if (!patient.isActive) return 0;
    final missing = checkinMissingDays ?? 0;
    return (7 - missing).clamp(0, 7);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filledDays = _filledDays;
    final barColor = filledDays >= 6
        ? AppColors.success
        : filledDays >= 4
            ? AppColors.warning
            : AppColors.error;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ClayCard(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Topo: avatar + nome + chips ──────────────────────────────
            InkWell(
              onTap: onTap,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusRingAvatar(patient: patient, ringColor: _ringColor(theme)),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            patient.fullName,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          if (patient.email?.isNotEmpty == true) ...[
                            const SizedBox(height: 2),
                            Text(
                              patient.email!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xs),
                          _StatusChipsRow(
                            patient: patient,
                            hasPendingResultsRelease: hasPendingResultsRelease,
                            checkinMissingDays: checkinMissingDays,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),

            // ── Barra de check-ins semanal ────────────────────────────────
            if (patient.isActive)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: _WeekCheckinBar(
                  filledDays: filledDays,
                  fillColor: barColor,
                ),
              ),

            // ── Footer com ações contextuais ─────────────────────────────
            Divider(height: 1, thickness: 0.5, color: Theme.of(context).colorScheme.outline),
            _CardFooter(
              hasPendingResultsRelease: hasPendingResultsRelease,
              checkinMissingDays: checkinMissingDays,
              isActive: patient.isActive,
              onTap: onTap,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar com anel de status colorido
// ─────────────────────────────────────────────────────────────────────────────

class _StatusRingAvatar extends StatelessWidget {
  const _StatusRingAvatar({required this.patient, required this.ringColor});

  final Patient patient;
  final Color ringColor;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: patient.isActive ? 1.0 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: ringColor, width: 2.5),
        ),
        padding: const EdgeInsets.all(2),
        child: UserAvatar.parts(
          fullName: patient.fullName,
          initials: _initials(patient.fullName),
          role: ProfileRole.patient,
          avatarType: patient.avatarType,
          photoUrl: patient.photoUrl,
          avatarConfig: patient.avatarConfig,
          size: 46,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Chips de status + alerta
// ─────────────────────────────────────────────────────────────────────────────

class _StatusChipsRow extends StatelessWidget {
  const _StatusChipsRow({
    required this.patient,
    required this.hasPendingResultsRelease,
    required this.checkinMissingDays,
  });

  final Patient patient;
  final bool hasPendingResultsRelease;
  final int? checkinMissingDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusLabel =
        patient.isActive ? (patient.accessStatus?.label ?? 'Ativo') : 'Inativo';
    final statusColor = patient.isActive ? AppColors.success : theme.colorScheme.onSurfaceVariant;
    final statusBg =
        patient.isActive ? AppColors.successContainer : theme.colorScheme.outline.withValues(alpha: 0.2);

    return Wrap(
      spacing: AppSpacing.xxs,
      runSpacing: AppSpacing.xxs,
      children: [
        _MiniChip(label: statusLabel, color: statusColor, bg: statusBg),
        if (hasPendingResultsRelease)
          const _MiniChip(
            label: 'Resultado pendente',
            color: AppColors.info,
            bg: AppColors.infoContainer,
            icon: Icons.fact_check_outlined,
          ),
        if (checkinMissingDays != null && checkinMissingDays! >= 3)
          _MiniChip(
            label: checkinMissingDays! >= 999
                ? 'Nunca fez check-in'
                : '${checkinMissingDays!} dias sem check-in',
            color: checkinMissingDays! >= 5 ? AppColors.error : AppColors.warning,
            bg: checkinMissingDays! >= 5
                ? AppColors.errorContainer
                : AppColors.warningContainer,
          ),
      ],
    );
  }
}

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.color,
    required this.bg,
    this.icon,
  });

  final String label;
  final Color color;
  final Color bg;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Barra de check-ins semanal (7 segmentos animados)
// ─────────────────────────────────────────────────────────────────────────────

class _WeekCheckinBar extends StatefulWidget {
  const _WeekCheckinBar({
    required this.filledDays,
    required this.fillColor,
  });

  final int filledDays;
  final Color fillColor;

  @override
  State<_WeekCheckinBar> createState() => _WeekCheckinBarState();
}

class _WeekCheckinBarState extends State<_WeekCheckinBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  static const _dayLabels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final todayIndex = DateTime.now().weekday - 1; // 0=seg, 6=dom

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Label + contagem
        Row(
          children: [
            Text(
              'Check-ins esta semana',
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
                fontSize: 10,
              ),
            ),
            const Spacer(),
            Text(
              '${widget.filledDays} / 7',
              style: theme.textTheme.labelSmall?.copyWith(
                color: widget.fillColor,
                fontWeight: FontWeight.w800,
                fontSize: 11,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // 7 segmentos
        Row(
          children: [
            for (var i = 0; i < 7; i++) ...[
              if (i > 0) const SizedBox(width: 3),
              Expanded(
                child: _Segment(
                  label: _dayLabels[i],
                  isToday: i == todayIndex,
                  isFilled: i < widget.filledDays,
                  fillColor: widget.fillColor,
                  controller: _ctrl,
                  index: i,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.isToday,
    required this.isFilled,
    required this.fillColor,
    required this.controller,
    required this.index,
  });

  final String label;
  final bool isToday;
  final bool isFilled;
  final Color fillColor;
  final AnimationController controller;
  final int index;

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(
      parent: controller,
      curve: Interval(
        index * 0.09,
        math.min(1.0, index * 0.09 + 0.5),
        curve: Curves.elasticOut,
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: animation,
          builder: (context, _) {
            return Transform.scale(
              scaleY: isFilled ? animation.value.clamp(0.0, 1.0) : 1.0,
              alignment: Alignment.bottomCenter,
              child: Container(
                height: 26,
                decoration: BoxDecoration(
                  color: isFilled ? fillColor : Theme.of(context).colorScheme.outline,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: (isFilled && isToday)
                      ? [
                          BoxShadow(
                            color: fillColor.withValues(alpha: 0.45),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ]
                      : null,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w600,
            color: isToday ? Theme.of(context).colorScheme.onSurface : Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer com duas ações contextuais
// ─────────────────────────────────────────────────────────────────────────────

class _CardFooter extends StatelessWidget {
  const _CardFooter({
    required this.hasPendingResultsRelease,
    required this.checkinMissingDays,
    required this.isActive,
    required this.onTap,
  });

  final bool hasPendingResultsRelease;
  final int? checkinMissingDays;
  final bool isActive;
  final VoidCallback onTap;

  ({String label, IconData icon, Color color}) _leftActionForTheme(ThemeData theme) {
    if (!isActive) {
      return (
        label: 'Ver histórico',
        icon: Icons.history_rounded,
        color: theme.colorScheme.onSurfaceVariant,
      );
    }
    if (hasPendingResultsRelease) {
      return (
        label: 'Liberar resultado',
        icon: Icons.fact_check_outlined,
        color: AppColors.success,
      );
    }
    if (checkinMissingDays != null && checkinMissingDays! >= 5) {
      return (
        label: 'Contatar',
        icon: Icons.phone_outlined,
        color: AppColors.error,
      );
    }
    if (checkinMissingDays != null && checkinMissingDays! >= 3) {
      return (
        label: 'Atenção',
        icon: Icons.warning_amber_rounded,
        color: AppColors.warning,
      );
    }
    return (
      label: 'Questionários',
      icon: Icons.assignment_outlined,
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Resolve muted/secondary action colors from theme so they stay legible in dark mode.
    final action = _leftActionForTheme(theme);

    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(action.icon, size: 14, color: action.color),
                  const SizedBox(width: 5),
                  Text(
                    action.label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: action.color,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(width: 0.5, height: 38, color: Theme.of(context).colorScheme.outline),
        Expanded(
          child: InkWell(
            onTap: onTap,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ver ficha',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 13,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
