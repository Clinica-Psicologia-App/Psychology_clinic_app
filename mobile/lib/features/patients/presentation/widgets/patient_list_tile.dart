import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/clay_card.dart';
import '../../../profile/domain/profile_role.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../domain/patient.dart';
import '../../domain/patient_attention.dart';
import '../../domain/patient_data_completion.dart';

/// Linha de paciente na lista. Formato enxuto (~80px): quem está em dia mostra
/// os sete tracinhos da semana; quem precisa de atenção troca os tracinhos pelo
/// motivo escrito e ganha uma tarja lateral na cor da urgência.
class PatientListTile extends StatelessWidget {
  const PatientListTile({
    super.key,
    required this.patient,
    required this.onTap,
    this.attention,
    this.checkinMissingDays,
    this.dataCompletion,
    this.showEmail = false,
  });

  final Patient patient;
  final VoidCallback onTap;

  /// Motivo pelo qual o paciente precisa de atenção. Null = está em dia.
  final PatientAttention? attention;

  /// Dias sem check-in (de psychologistAlertsProvider). Null = sem alerta.
  final int? checkinMissingDays;

  /// Preenchimento da avaliação inicial + questionários. Null = sem dado
  /// (paciente/lista ainda carregando, ou visão do paciente).
  final PatientDataCompletion? dataCompletion;

  /// Mostra o e-mail sob o nome. Ligado durante a busca, já que é um dos
  /// campos pesquisáveis — fora dela, a linha fica mais limpa sem ele.
  final bool showEmail;

  int get _filledDays {
    if (!patient.isActive) return 0;
    final missing = checkinMissingDays ?? 0;
    return (7 - missing).clamp(0, 7);
  }

  Color _healthColor(ThemeData theme) {
    if (!patient.isActive) return theme.colorScheme.outline;
    final a = attention;
    if (a == null) return AppColors.success;
    return attentionColor(a.kind);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = attention;
    final health = _healthColor(theme);
    final completion = dataCompletion;
    final email = patient.email;
    final showStatusChip = !patient.isActive ||
        patient.accessStatus == PatientAccessStatus.noAppAccess;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 4,
      ),
      child: ClayCard(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Tarja lateral só existe quando há urgência: é ela que faz o
                // grupo "precisam de atenção" ser lido de relance.
                if (a != null) Container(width: 4, color: health),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
                    child: Row(
                      children: [
                        _StatusRingAvatar(patient: patient, ringColor: health),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      patient.fullName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                        fontWeight: FontWeight.w700,
                                        color: patient.isActive
                                            ? null
                                            : theme
                                                .colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  if (showStatusChip) ...[
                                    const SizedBox(width: 6),
                                    _MutedChip(
                                      label: patient.isActive
                                          ? 'Sem app'
                                          : 'Inativo',
                                    ),
                                  ],
                                ],
                              ),
                              if (showEmail && email != null &&
                                  email.isNotEmpty) ...[
                                const SizedBox(height: 1),
                                Text(
                                  email,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 3),
                              if (a != null)
                                _AttentionLine(attention: a, color: health)
                              else if (patient.isActive)
                                _WeekLine(
                                  filledDays: _filledDays,
                                  color: health,
                                )
                              else
                                Text(
                                  'Acompanhamento encerrado',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    fontSize: 11,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        // Anel de preenchimento só faz sentido em quem está em
                        // acompanhamento: no inativo vira ruído colorido.
                        if (completion != null && patient.isActive) ...[
                          const SizedBox(width: AppSpacing.xs),
                          CompletionDonut(completion: completion),
                        ],
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 20,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Cor de cada motivo de atenção — usada na tarja, no anel do avatar e no texto.
Color attentionColor(PatientAttentionKind kind) => switch (kind) {
      PatientAttentionKind.noCheckin => AppColors.error,
      PatientAttentionKind.pendingRelease => AppColors.info,
      PatientAttentionKind.emptyData => AppColors.warning,
      PatientAttentionKind.fewCheckins => AppColors.warning,
    };

IconData _attentionIcon(PatientAttentionKind kind) => switch (kind) {
      PatientAttentionKind.noCheckin => Icons.phone_outlined,
      PatientAttentionKind.pendingRelease => Icons.fact_check_outlined,
      PatientAttentionKind.emptyData => Icons.edit_note_rounded,
      PatientAttentionKind.fewCheckins => Icons.schedule_rounded,
    };

// ─────────────────────────────────────────────────────────────────────────────
// Segunda linha: motivo da urgência OU semana de check-ins
// ─────────────────────────────────────────────────────────────────────────────

class _AttentionLine extends StatelessWidget {
  const _AttentionLine({required this.attention, required this.color});

  final PatientAttention attention;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(_attentionIcon(attention.kind), size: 13, color: color),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            attention.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeekLine extends StatelessWidget {
  const _WeekLine({required this.filledDays, required this.color});

  final int filledDays;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 3),
          Container(
            width: 5,
            height: 10,
            decoration: BoxDecoration(
              color: i < filledDays
                  ? color
                  : theme.colorScheme.outline.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
        const SizedBox(width: 7),
        Text(
          '$filledDays/7',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Anel de preenchimento dos dados
// ─────────────────────────────────────────────────────────────────────────────

class CompletionDonut extends StatelessWidget {
  const CompletionDonut({super.key, required this.completion, this.size = 38});

  final PatientDataCompletion completion;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = completion.isComplete
        ? AppColors.success
        : completion.filledSections <= 2
            ? AppColors.error
            : AppColors.warning;

    return Tooltip(
      message: completion.isComplete
          ? 'Dados: tudo preenchido'
          : 'Falta: ${completion.sections.where((s) => !s.done).map((s) => s.label).join(', ')}',
      child: SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: completion.fraction,
                strokeWidth: 3.4,
                backgroundColor:
                    theme.colorScheme.outline.withValues(alpha: 0.5),
                valueColor: AlwaysStoppedAnimation(color),
                strokeCap: StrokeCap.round,
              ),
            ),
            Text(
              '${completion.percent}',
              style: TextStyle(
                fontSize: size * 0.29,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cabeçalho de grupo ("Precisam de atenção" / "Em dia" / "Inativos")
// ─────────────────────────────────────────────────────────────────────────────

class PatientGroupHeader extends StatelessWidget {
  const PatientGroupHeader({
    super.key,
    required this.label,
    required this.count,
    required this.color,
    this.topSpacing = AppSpacing.sm,
  });

  final String label;
  final int count;
  final Color color;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md + 2,
        topSpacing,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
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
          shape: BoxShape.circle,
          border: Border.all(color: ringColor, width: 2),
        ),
        padding: const EdgeInsets.all(2),
        child: UserAvatar.parts(
          fullName: patient.fullName,
          initials: _initials(patient.fullName),
          role: ProfileRole.patient,
          avatarType: patient.avatarType,
          photoUrl: patient.photoUrl,
          avatarConfig: patient.avatarConfig,
          size: 42,
          borderRadius: BorderRadius.circular(42),
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

class _MutedChip extends StatelessWidget {
  const _MutedChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.outline.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
