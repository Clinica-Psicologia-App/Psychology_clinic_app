import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/life_chapter.dart';
import '../../domain/timeline_entry.dart';
import 'life_chapter_style.dart';

/// Peças da Linha do Tempo desenhada como uma linha de verdade: um fio
/// contínuo que atravessa a tela de cima a baixo, com a idade virando o nó
/// sobre o fio e os capítulos como marcos no próprio fio — em vez de faixas
/// que cortam a leitura em blocos separados.

/// Centro do fio, a partir da borda esquerda.
const double kSpineX = 46;

const double _nodeRadius = 15;
const Color _railColor = Color(0xFFE2E9F6);

/// O fio, desenhado atrás de tudo em cada bloco.
class _Rail extends StatelessWidget {
  const _Rail({this.top = 0, this.height});

  final double top;

  /// Null = desce até o fim do bloco. Com valor, o fio para antes — usado nas
  /// pontas da linha.
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: kSpineX - 1,
      top: top,
      bottom: height == null ? 0 : null,
      height: height,
      child: Container(width: 2, color: _railColor),
    );
  }
}

/// Começo da linha.
class TimelineBirthCap extends StatelessWidget {
  const TimelineBirthCap({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 34,
      child: Stack(
        children: [
          const _Rail(top: 16),
          Positioned(
            left: kSpineX - 5,
            top: 12,
            child: Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.borderStrong,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: kSpineX + 16,
            top: 9,
            child: Text(
              'Nascimento',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Fim da linha: onde a pessoa está agora.
class TimelineTodayCap extends StatelessWidget {
  const TimelineTodayCap({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Stack(
        children: [
          const _Rail(height: 14),
          Positioned(
            left: kSpineX - 7,
            top: 12,
            child: Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.turquoise, width: 3),
              ),
            ),
          ),
          const Positioned(
            left: kSpineX + 16,
            top: 11,
            child: Text(
              'Hoje',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.turquoise,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Marco de capítulo: um nó maior no próprio fio, com rótulo e o "+" ao lado.
class TimelineChapterMarker extends StatelessWidget {
  const TimelineChapterMarker({
    super.key,
    required this.chapter,
    required this.onAdd,
  });

  /// Null = "Outros acontecimentos".
  final LifeChapter? chapter;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final s = styleForChapter(chapter);
    final label = chapter?.label ?? 'Outros acontecimentos';

    return SizedBox(
      height: 48,
      child: Stack(
        children: [
          const _Rail(),
          Positioned(
            left: kSpineX - 13,
            top: 11,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: s.bg,
                shape: BoxShape.circle,
                border: Border.all(color: s.accent, width: 2),
              ),
              child: Icon(s.icon, size: 13, color: s.accent),
            ),
          ),
          Positioned(
            left: kSpineX + 24,
            right: 8,
            top: 8,
            child: Row(
              children: [
                // flex 0 + loose: o rótulo fica com a largura que precisa e a
                // régua absorve o resto. Com `Flexible` normal os dois
                // dividiriam o espaço e o nome do capítulo saía cortado.
                Flexible(
                  flex: 0,
                  child: Text(
                    label.toUpperCase(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: s.text,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Container(
                    height: 1,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          s.accent.withValues(alpha: 0.35),
                          s.accent.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: onAdd,
                  icon: Icon(Icons.add_rounded, size: 18, color: s.accent),
                  tooltip: 'Adicionar acontecimento em $label',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 34,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Capítulo sem nenhum acontecimento: o fio segue, com uma nota discreta.
class TimelineEmptyChapterHint extends StatelessWidget {
  const TimelineEmptyChapterHint({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      height: 26,
      child: Stack(
        children: [
          const _Rail(),
          Positioned(
            left: kSpineX + 24,
            top: 4,
            child: Text(
              'nenhum acontecimento registrado',
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 10.5,
                fontStyle: FontStyle.italic,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Acontecimento: a idade é o nó sobre o fio, e o cartão fica ao lado.
class TimelineEventNode extends StatelessWidget {
  const TimelineEventNode({
    super.key,
    required this.entry,
    required this.chapter,
    required this.hasComment,
    required this.onTap,
  });

  final TimelineEntry entry;
  final LifeChapter? chapter;

  /// Já tem anotação clínica do terapeuta.
  final bool hasComment;

  final VoidCallback onTap;

  static Color impactColor(int value) => value >= 7
      ? AppColors.error
      : value >= 4
          ? AppColors.warning
          : AppColors.success;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = styleForChapter(chapter);
    final impact = entry.emotionalImpact;

    return IntrinsicHeight(
      child: Stack(
        children: [
          const _Rail(),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: kSpineX + _nodeRadius,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: _AgeNode(
                        age: entry.ageAtEvent,
                        style: s,
                        surface: theme.colorScheme.surface,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Material(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onTap,
                        child: Container(
                          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(14),
                            border:
                                Border.all(color: theme.colorScheme.outline),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (entry.isSensitive)
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                right: 5, top: 2),
                                            child: Icon(
                                              Icons.lock_outline,
                                              size: 13,
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        Expanded(
                                          child: Text(
                                            entry.title,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontSize: 13.5,
                                              fontWeight: FontWeight.w700,
                                              height: 1.25,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    if (impact != null || hasComment) ...[
                                      const SizedBox(height: 5),
                                      Row(
                                        children: [
                                          if (impact != null) ...[
                                            ImpactBar(
                                              value: impact,
                                              color: impactColor(impact),
                                            ),
                                            const SizedBox(width: 6),
                                            Text(
                                              'impacto $impact',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: impactColor(impact),
                                              ),
                                            ),
                                          ],
                                          if (hasComment) ...[
                                            if (impact != null)
                                              const SizedBox(width: 8),
                                            const Icon(
                                              Icons.sticky_note_2_rounded,
                                              size: 12,
                                              color: AppColors.turquoise,
                                            ),
                                            const SizedBox(width: 3),
                                            const Text(
                                              'anotado',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w600,
                                                color: AppColors.turquoise,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
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
          ),
        ],
      ),
    );
  }
}

class _AgeNode extends StatelessWidget {
  const _AgeNode({
    required this.age,
    required this.style,
    required this.surface,
  });

  final int? age;
  final LifeChapterStyle style;
  final Color surface;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: age == null ? 'Idade não informada' : '$age anos',
      child: Container(
        width: _nodeRadius * 2,
        height: _nodeRadius * 2,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: surface,
          shape: BoxShape.circle,
          border: Border.all(color: style.accent, width: 2),
          boxShadow: [
            BoxShadow(
              color: style.accent.withValues(alpha: 0.18),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          age?.toString() ?? '–',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: style.text,
          ),
        ),
      ),
    );
  }
}

/// Cinco tracinhos crescentes: mostra a intensidade sem virar mais um número
/// solto no canto do cartão.
class ImpactBar extends StatelessWidget {
  const ImpactBar({super.key, required this.value, required this.color});

  /// 0–10.
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final filled = (value / 2).ceil().clamp(0, 5);
    final track =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.8);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < 5; i++) ...[
          if (i > 0) const SizedBox(width: 2),
          Container(
            width: 4,
            height: math.max(4, 4 + i * 1.6),
            decoration: BoxDecoration(
              color: i < filled ? color : track,
              borderRadius: BorderRadius.circular(1.5),
            ),
          ),
        ],
      ],
    );
  }
}
