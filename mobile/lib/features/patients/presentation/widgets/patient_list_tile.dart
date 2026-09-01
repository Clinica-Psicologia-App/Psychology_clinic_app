import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/clay_card.dart';
import '../../../profile/domain/profile_role.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../domain/patient.dart';
import '../../domain/patient_data_completion.dart';

class PatientListTile extends StatelessWidget {
  const PatientListTile({
    super.key,
    required this.patient,
    required this.onTap,
    this.hasPendingResultsRelease = false,
    this.checkinMissingDays,
    this.dataCompletion,
  });

  final Patient patient;
  final VoidCallback onTap;

  /// Questionário concluído, resultado ainda não liberado ao paciente.
  final bool hasPendingResultsRelease;

  /// Dias sem check-in (de psychologistAlertsProvider). Null = sem alerta.
  final int? checkinMissingDays;

  /// Preenchimento da avaliação inicial + questionários. Null = sem dado
  /// (paciente/lista ainda carregando, ou visão do paciente).
  final PatientDataCompletion? dataCompletion;

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

  Color _completionColor(PatientDataCompletion c) {
    if (c.isComplete) return AppColors.success;
    if (c.filledSections == 0) return AppColors.error;
    return AppColors.warning;
  }

  String _checkinSubtitle() {
    if (checkinMissingDays == null) return 'Em dia esta semana';
    if (checkinMissingDays! >= 999) return 'Nunca fez check-in';
    return '${checkinMissingDays!} dias sem check-in';
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
    final stripColor = _ringColor(theme);
    final completion = dataCompletion;

    final statusLabel = patient.isActive
        ? (patient.accessStatus?.label ?? 'Ativo')
        : 'Inativo';
    final statusColor =
        patient.isActive ? AppColors.success : theme.colorScheme.onSurfaceVariant;
    final statusBg = patient.isActive
        ? AppColors.successContainer
        : theme.colorScheme.outline.withValues(alpha: 0.2);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: ClayCard(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Faixa de status (saúde do acompanhamento) ─────────────────
            Container(height: 4, color: stripColor),

            // ── Topo: avatar + nome + status ─────────────────────────────
            InkWell(
              onTap: onTap,
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
                    _StatusRingAvatar(patient: patient, ringColor: stripColor),
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
                          _MiniChip(
                            label: statusLabel,
                            color: statusColor,
                            bg: statusBg,
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

            if (patient.isActive) ...[
              Divider(
                height: 1,
                thickness: 0.5,
                color: theme.colorScheme.outline.withValues(alpha: 0.5),
              ),
              // ── Métrica: check-ins da semana ──────────────────────────
              _MetricRow(
                icon: Icons.schedule_rounded,
                accent: barColor,
                title: 'Check-ins esta semana',
                subtitle: _checkinSubtitle(),
                valueText: '$filledDays/7',
                content: _WeekCheckinBar(
                  filledDays: filledDays,
                  fillColor: barColor,
                ),
              ),

              // ── Métrica: preenchimento dos dados ──────────────────────
              if (completion != null) ...[
                Divider(
                  height: 1,
                  thickness: 0.5,
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
                _MetricRow(
                  icon: Icons.assignment_turned_in_outlined,
                  accent: _completionColor(completion),
                  title: 'Preenchimento dos dados',
                  subtitle: completion.isComplete
                      ? 'Tudo preenchido'
                      : 'Falta: ${completion.sections.where((s) => !s.done).map((s) => s.label).join(', ')}',
                  valueText: '${completion.percent}%',
                  content: _CompletionSegments(completion: completion),
                ),
              ],
            ],

            // ── Footer com ações contextuais ─────────────────────────────
            Divider(height: 1, thickness: 0.5, color: theme.colorScheme.outline),
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
// Linha de métrica: ícone + título/subtítulo + valor, com conteúdo abaixo
// ─────────────────────────────────────────────────────────────────────────────

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.valueText,
    required this.content,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final String valueText;
  final Widget content;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(icon, size: 16, color: accent),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontSize: 10,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                valueText,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: accent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.only(left: 38),
            child: content,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Segmentos de preenchimento (6 seções)
// ─────────────────────────────────────────────────────────────────────────────

class _CompletionSegments extends StatelessWidget {
  const _CompletionSegments({required this.completion});

  final PatientDataCompletion completion;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sections = completion.sections;
    return Row(
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: sections[i].done
                    ? AppColors.success
                    : theme.colorScheme.outline.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ],
      ],
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
// Chip de status
// ─────────────────────────────────────────────────────────────────────────────

class _MiniChip extends StatelessWidget {
  const _MiniChip({
    required this.label,
    required this.color,
    required this.bg,
  });

  final String label;
  final Color color;
  final Color bg;

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
    final todayIndex = DateTime.now().weekday - 1; // 0=seg, 6=dom

    // Apenas os 7 segmentos com o rótulo do dia abaixo de cada um. O título e
    // a contagem "x/7" ficam na linha da métrica (cabeçalho da seção).
    return Row(
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
