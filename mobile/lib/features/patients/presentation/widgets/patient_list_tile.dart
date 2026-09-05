import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../profile/domain/profile_role.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../domain/patient.dart';
import '../../domain/patient_attention.dart';
import '../../domain/patient_data_completion.dart';

/// Linha de paciente na lista (~84px). Quem está em dia mostra os sete
/// tracinhos da semana; quem precisa de atenção troca os tracinhos pelo motivo
/// e ganha tarja lateral, fundo levemente tingido, selo no avatar e um botão
/// que leva direto à ação daquele motivo.
class PatientListTile extends StatelessWidget {
  const PatientListTile({
    super.key,
    required this.patient,
    required this.onTap,
    this.attention,
    this.checkinMissingDays,
    this.dataCompletion,
    this.showEmail = false,
    this.onQuickAction,
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

  /// Ação do motivo (ligar, liberar resultado, preencher avaliação). Só rende
  /// botão quando há [attention].
  final VoidCallback? onQuickAction;

  int get _filledDays {
    if (!patient.isActive) return 0;
    final missing = checkinMissingDays ?? 0;
    return (7 - missing).clamp(0, 7);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = attention;
    final active = patient.isActive;
    final accent = a != null
        ? attentionColor(a.kind)
        : active
            ? AppColors.success
            : theme.colorScheme.onSurfaceVariant;
    final completion = dataCompletion;
    final email = patient.email;
    final showStatusChip = !active ||
        patient.accessStatus == PatientAccessStatus.noAppAccess;
    final surface = theme.colorScheme.surface;
    final onQuick = onQuickAction;
    final quick = (a != null && onQuick != null)
        ? (kind: a.kind, run: onQuick)
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Material(
        // Tint quase imperceptível da cor da urgência: dá pertencimento ao
        // grupo sem transformar a lista num semáforo.
        color: a != null
            ? Color.alphaBlend(accent.withValues(alpha: 0.035), surface)
            : surface,
        borderRadius: BorderRadius.circular(18),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: a != null
                    ? accent.withValues(alpha: 0.22)
                    : theme.colorScheme.outline.withValues(alpha: 0.7),
              ),
            ),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  if (a != null)
                    Container(
                      width: 4,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [accent, accent.withValues(alpha: 0.45)],
                        ),
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding:
                          EdgeInsets.fromLTRB(a != null ? 10 : 12, 10, 8, 10),
                      child: Row(
                        children: [
                          _AvatarWithBadge(
                            patient: patient,
                            attention: a,
                            accent: accent,
                          ),
                          const SizedBox(width: 10),
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
                                          height: 1.15,
                                          color: active
                                              ? null
                                              : theme.colorScheme
                                                  .onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                    if (showStatusChip) ...[
                                      const SizedBox(width: 6),
                                      _MutedChip(
                                        label: active ? 'Sem app' : 'Inativo',
                                      ),
                                    ],
                                  ],
                                ),
                                if (showEmail &&
                                    email != null &&
                                    email.isNotEmpty) ...[
                                  const SizedBox(height: 1),
                                  Text(
                                    email,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style:
                                        theme.textTheme.bodySmall?.copyWith(
                                      fontSize: 11,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 5),
                                if (a != null)
                                  _ReasonPill(label: a.label, color: accent)
                                else if (active)
                                  _WeekStrip(
                                    filled: _filledDays,
                                    color: accent,
                                  )
                                else
                                  Text(
                                    'Acompanhamento encerrado',
                                    style:
                                        theme.textTheme.labelSmall?.copyWith(
                                      fontSize: 11,
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          // Anel só faz sentido em quem está em acompanhamento:
                          // no inativo vira ruído colorido.
                          if (completion != null && active)
                            CompletionRing(completion: completion),
                          if (quick != null) ...[
                            const SizedBox(width: 6),
                            _QuickActionButton(
                              kind: quick.kind,
                              color: accent,
                              onPressed: quick.run,
                            ),
                          ] else
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
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Cores e ícones por motivo. O selo do avatar diz o ESTADO; o botão diz a AÇÃO
// — por isso são ícones diferentes para o mesmo motivo.
// ─────────────────────────────────────────────────────────────────────────────

Color attentionColor(PatientAttentionKind kind) => switch (kind) {
      PatientAttentionKind.noCheckin => AppColors.error,
      PatientAttentionKind.pendingRelease => AppColors.info,
      PatientAttentionKind.emptyData => AppColors.warning,
      PatientAttentionKind.fewCheckins => AppColors.warning,
    };

IconData _stateIcon(PatientAttentionKind kind) => switch (kind) {
      PatientAttentionKind.noCheckin => Icons.event_busy_rounded,
      PatientAttentionKind.pendingRelease => Icons.lock_rounded,
      PatientAttentionKind.emptyData => Icons.assignment_late_rounded,
      PatientAttentionKind.fewCheckins => Icons.schedule_rounded,
    };

IconData _actionIcon(PatientAttentionKind kind) => switch (kind) {
      PatientAttentionKind.noCheckin => Icons.phone_rounded,
      PatientAttentionKind.pendingRelease => Icons.lock_open_rounded,
      PatientAttentionKind.emptyData => Icons.edit_rounded,
      PatientAttentionKind.fewCheckins => Icons.phone_rounded,
    };

String actionLabelFor(PatientAttentionKind kind) => switch (kind) {
      PatientAttentionKind.noCheckin => 'Ligar para o paciente',
      PatientAttentionKind.pendingRelease => 'Abrir resultados para liberar',
      PatientAttentionKind.emptyData => 'Abrir avaliação inicial',
      PatientAttentionKind.fewCheckins => 'Ligar para o paciente',
    };

// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.kind,
    required this.color,
    required this.onPressed,
  });

  final PatientAttentionKind kind;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: actionLabelFor(kind),
      child: Semantics(
        button: true,
        label: actionLabelFor(kind),
        child: Material(
          color: color,
          shape: const CircleBorder(),
          elevation: 2,
          shadowColor: color.withValues(alpha: 0.5),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(_actionIcon(kind), size: 16, color: Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}

class _ReasonPill extends StatelessWidget {
  const _ReasonPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

/// Sete dias da semana, com o de hoje marcado por um ponto embaixo.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.filled, required this.color});

  final int filled;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = DateTime.now().weekday - 1; // 0 = segunda
    return Row(
      children: [
        for (var i = 0; i < 7; i++) ...[
          if (i > 0) const SizedBox(width: 3.5),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 11,
                decoration: BoxDecoration(
                  color: i < filled
                      ? color
                      : theme.colorScheme.outline.withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(height: 2.5),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: i == today ? color : Colors.transparent,
                ),
              ),
            ],
          ),
        ],
        const SizedBox(width: 8),
        Text(
          '$filled/7',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Anel de preenchimento: um arco por seção da avaliação inicial
// ─────────────────────────────────────────────────────────────────────────────

class CompletionRing extends StatelessWidget {
  const CompletionRing({super.key, required this.completion, this.size = 36});

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
    final missing =
        completion.sections.where((s) => !s.done).map((s) => s.label).join(', ');

    return Tooltip(
      message: completion.isComplete
          ? 'Avaliação inicial completa'
          : 'Falta: $missing',
      child: SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            done: completion.filledSections,
            total: completion.totalSections,
            color: color,
            trackColor: theme.colorScheme.outline.withValues(alpha: 0.7),
          ),
          child: Center(
            child: Text(
              '${completion.percent}',
              style: TextStyle(
                fontSize: size * 0.31,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.done,
    required this.total,
    required this.color,
    required this.trackColor,
  });

  final int done;
  final int total;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (total <= 0) return;
    final center = size.center(Offset.zero);
    final radius = size.width / 2 - 2.6;
    const gap = 0.26; // folga entre os arcos, em radianos
    final step = math.pi * 2 / total;

    for (var i = 0; i < total; i++) {
      final start = -math.pi / 2 + i * step + gap / 2;
      final paint = Paint()
        ..color = i < done ? color : trackColor
        ..strokeWidth = 3.4
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        start,
        step - gap,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.done != done ||
      old.total != total ||
      old.color != color ||
      old.trackColor != trackColor;
}

// ─────────────────────────────────────────────────────────────────────────────
// Cabeçalho de grupo
// ─────────────────────────────────────────────────────────────────────────────

class PatientGroupHeader extends StatelessWidget {
  const PatientGroupHeader({
    super.key,
    required this.label,
    required this.icon,
    required this.count,
    required this.color,
    this.topSpacing = 8,
  });

  final String label;
  final IconData icon;
  final int count;
  final Color color;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(16, topSpacing, 16, 8),
      child: Row(
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 13, color: color),
          ),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.13),
              borderRadius: BorderRadius.circular(20),
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
          const SizedBox(width: 10),
          // Régua que ancora o grupo e se dissolve à direita.
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withValues(alpha: 0.28),
                    color.withValues(alpha: 0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Avatar com selo do estado
// ─────────────────────────────────────────────────────────────────────────────

class _AvatarWithBadge extends StatelessWidget {
  const _AvatarWithBadge({
    required this.patient,
    required this.attention,
    required this.accent,
  });

  final Patient patient;
  final PatientAttention? attention;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = attention;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Opacity(
            opacity: patient.isActive ? 1 : 0.45,
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border:
                    Border.all(color: accent.withValues(alpha: 0.55), width: 2),
              ),
              padding: const EdgeInsets.all(2),
              child: UserAvatar.parts(
                fullName: patient.fullName,
                initials: _initials(patient.fullName),
                role: ProfileRole.patient,
                avatarType: patient.avatarType,
                photoUrl: patient.photoUrl,
                avatarConfig: patient.avatarConfig,
                size: 36,
                borderRadius: BorderRadius.circular(36),
              ),
            ),
          ),
          if (a != null)
            Positioned(
              right: -2,
              bottom: -2,
              child: Container(
                width: 19,
                height: 19,
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: theme.colorScheme.surface, width: 2),
                ),
                child: Icon(_stateIcon(a.kind), size: 10, color: Colors.white),
              ),
            ),
        ],
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
