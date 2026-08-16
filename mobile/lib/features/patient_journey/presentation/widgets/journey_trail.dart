import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_motion.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../domain/journey_phase.dart';
import '../../domain/journey_step.dart';
import '../../domain/journey_step_availability.dart';
import '../../domain/journey_step_id.dart';

/// Trilha em zig-zag estilo "mapa de jornada": o caminho sinuoso e os nós são
/// o protagonista; o detalhe de cada parada aparece num balão ancorado ao
/// tocar o nó (nada de cards fixos ocupando a trilha).
///
/// O trecho já percorrido é sólido, com um brilho de energia que corre pelo
/// caminho; o nó atual pulsa para se destacar. As fases clínicas viram
/// checkpoints que o caminho atravessa por trás (sem cortar o traçado).
///
/// É só uma nova apresentação de [JourneyStep] — mesmos dados e navegação.
class JourneyTrail extends StatefulWidget {
  const JourneyTrail({
    super.key,
    required this.steps,
    required this.onStepTap,
  });

  final List<JourneyStep> steps;
  final void Function(JourneyStep step) onStepTap;

  @override
  State<JourneyTrail> createState() => _JourneyTrailState();
}

class _JourneyTrailState extends State<JourneyTrail>
    with SingleTickerProviderStateMixin {
  // Os nós balançam suavemente em torno do centro (não nas bordas): mantém a
  // trilha coesa e deixa o balão ancorado caber na largura.
  static const double _centerX = 0.5;
  static const double _sway = 0.17;

  final Map<int, LayerLink> _links = {};
  late final AnimationController _anim;
  OverlayEntry? _popup;
  int? _openIndex;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
  }

  double _sideX(int index) =>
      index.isEven ? _centerX - _sway : _centerX + _sway;

  LayerLink _linkFor(int index) => _links.putIfAbsent(index, LayerLink.new);

  @override
  void dispose() {
    _removePopup();
    _anim.dispose();
    super.dispose();
  }

  void _removePopup() {
    _popup?.remove();
    _popup = null;
    _openIndex = null;
  }

  void _closePopup() {
    if (_popup == null) return;
    setState(_removePopup);
  }

  void _toggle(int index, JourneyStep step) {
    if (_openIndex == index) {
      _closePopup();
      return;
    }
    _removePopup();
    final entry = OverlayEntry(
      builder: (context) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _closePopup,
            ),
          ),
          CompositedTransformFollower(
            link: _linkFor(index),
            showWhenUnlinked: false,
            targetAnchor: Alignment.topCenter,
            followerAnchor: Alignment.bottomCenter,
            offset: const Offset(0, -12),
            child: _StepBubble(
              step: step,
              onAction: () {
                _closePopup();
                widget.onStepTap(step);
              },
            ),
          ),
        ],
      ),
    );
    Overlay.of(context).insert(entry);
    setState(() {
      _popup = entry;
      _openIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final animate = AppAnimations.shouldAnimate(context);
    if (animate && !_anim.isAnimating) {
      _anim.repeat();
    } else if (!animate && _anim.isAnimating) {
      _anim.stop();
    }

    final sorted = List<JourneyStep>.from(widget.steps)
      ..sort((a, b) => a.order.compareTo(b.order));

    // Separa nós de processo (fio principal) dos nós de apoio laterais.
    final mainSteps = sorted.where((s) => !s.isSupportNode).toList();
    final supportMap = <JourneyStepId, List<JourneyStep>>{};
    for (final s in sorted.where((s) => s.isSupportNode)) {
      supportMap.putIfAbsent(s.parentStepId!, () => []).add(s);
    }

    var solidThrough = -1;
    for (var i = 0; i < mainSteps.length; i++) {
      final a = mainSteps[i].availability;
      if (a == JourneyStepAvailability.completed ||
          a == JourneyStepAvailability.inProgress) {
        solidThrough = i;
      }
    }
    var currentIndex = mainSteps.indexWhere(
        (s) => s.availability == JourneyStepAvailability.inProgress);
    if (currentIndex < 0) {
      currentIndex = mainSteps.indexWhere(
          (s) => s.availability == JourneyStepAvailability.available);
    }

    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (_popup != null && n is ScrollUpdateNotification) _closePopup();
        return false;
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 44),
        children: [
          ...List.generate(mainSteps.length, (index) {
            final step = mainSteps[index];
            final isFirstOfPhase =
                index == 0 || mainSteps[index - 1].phase != step.phase;

            return MotionReveal(
              delay: Duration(milliseconds: math.min(index, 8) * 40),
              child: _TrailStop(
                step: step,
                link: _linkFor(index),
                anim: _anim,
                animate: animate,
                flowOffset: (index * 0.13) % 1,
                thisX: _sideX(index),
                entryX: index == 0
                    ? _sideX(index)
                    : (_sideX(index) + _sideX(index - 1)) / 2,
                exitX: index == mainSteps.length - 1
                    ? _sideX(index)
                    : (_sideX(index) + _sideX(index + 1)) / 2,
                incomingSolid: index <= solidThrough,
                outgoingSolid: index + 1 <= solidThrough,
                hasIncoming: index > 0,
                hasOutgoing: index < mainSteps.length - 1,
                isCurrent: index == currentIndex,
                showHere: index == currentIndex && _openIndex != index,
                phase: isFirstOfPhase ? step.phase : null,
                supportNodes: supportMap[step.id] ?? [],
                onSupportTap: widget.onStepTap,
                onTap: () => _toggle(index, step),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _TrailStop extends StatelessWidget {
  const _TrailStop({
    required this.step,
    required this.link,
    required this.anim,
    required this.animate,
    required this.flowOffset,
    required this.thisX,
    required this.entryX,
    required this.exitX,
    required this.incomingSolid,
    required this.outgoingSolid,
    required this.hasIncoming,
    required this.hasOutgoing,
    required this.isCurrent,
    required this.showHere,
    required this.phase,
    required this.supportNodes,
    required this.onSupportTap,
    required this.onTap,
  });

  final JourneyStep step;
  final LayerLink link;
  final Animation<double> anim;
  final bool animate;
  final double flowOffset;
  final double thisX;
  final double entryX;
  final double exitX;
  final bool incomingSolid;
  final bool outgoingSolid;
  final bool hasIncoming;
  final bool hasOutgoing;
  final bool isCurrent;
  final bool showHere;
  final JourneyPhase? phase;
  final List<JourneyStep> supportNodes;
  final void Function(JourneyStep) onSupportTap;
  final VoidCallback onTap;

  // Folga a mais que a original: o rótulo agora tem título + linha de estado,
  // e ambos cresceram (13,5 / 11 pt) — cabe até duas linhas de título.
  static const double _baseHeight = 150;
  // Nó menor que o anel de progresso (r=36): sobra folga entre a face branca
  // e o fio do anel, evitando que os dois se leiam como um alvo concêntrico.
  static const double _nodeSize = 60;
  static const double _supportNodeSize = 44.0;
  static const double _phaseBand = 40;
  static const double _baseNodeCenterY = 44;

  /// Áreas onde o caminho deve abrir folga: o rótulo do nó e, quando houver,
  /// o divisor de fase. Medidas com o texto real (não com a caixa reservada),
  /// para o corte acompanhar exatamente o que está escrito.
  static const double _gapPadX = 6;
  static const double _gapPadY = 3;

  List<Rect> _textGaps(
    BuildContext context, {
    required double width,
    required double nodeCenterX,
    required double nodeCenterY,
  }) {
    final theme = Theme.of(context);
    final scaler = MediaQuery.textScalerOf(context);

    Size measure(String text, TextStyle? style, int maxLines, double maxWidth) {
      final painter = TextPainter(
        text: TextSpan(text: text, style: style),
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        maxLines: maxLines,
        textScaler: scaler,
      )..layout(maxWidth: maxWidth);
      return Size(painter.width, painter.height);
    }

    Rect centered(Size size, double centerX, double top) => Rect.fromLTWH(
          centerX - size.width / 2 - _gapPadX,
          top - _gapPadY,
          size.width + _gapPadX * 2,
          size.height + _gapPadY * 2,
        );

    final gaps = <Rect>[];

    // Rótulo do nó: título (até 2 linhas) e a linha de estado abaixo.
    final labelTop = nodeCenterY + _nodeSize / 2 + 6;
    final title =
        measure(step.title, _NodeLabel.titleStyle(theme), 2, _NodeLabel.width);
    gaps.add(centered(title, nodeCenterX, labelTop));

    final status = _NodeLabel.statusOf(step);
    if (status != null) {
      final statusSize =
          measure(status, _NodeLabel.statusStyle(theme), 1, _NodeLabel.width);
      gaps.add(
        centered(statusSize, nodeCenterX, labelTop + title.height + 2),
      );
    }

    // Divisor de fase: o texto fica centrado na largura toda da parada.
    if (phase != null) {
      final label = _PhaseCheckpoint.labelOf(phase!);
      final size = measure(
        label,
        _PhaseCheckpoint.labelStyle(theme),
        1,
        double.infinity,
      );
      gaps.add(centered(size, width / 2, 6));
    }

    return gaps;
  }

  @override
  Widget build(BuildContext context) {
    final hasPhase = phase != null;
    final hasPill =
        supportNodes.any((s) => s.recommendedByTherapistName != null);
    final extraHeight = hasPill ? 20.0 : 0.0;
    final bodyHeight =
        _baseHeight + (hasPhase ? _phaseBand : 0) + extraHeight;
    final nodeCenterY =
        _baseNodeCenterY + (hasPhase ? _phaseBand : 0) + extraHeight;

    return SizedBox(
      height: bodyHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth;
          final nodeCenterX = thisX * w;
          // Nós de apoio ficam do lado oposto ao nó de processo.
          final supportOnRight = thisX < 0.5;
          final supportCenterX =
              supportOnRight ? w * 0.84 : w * 0.16;
          final supportR = _supportNodeSize / 2;
          final gaps = _textGaps(
            context,
            width: w,
            nodeCenterX: nodeCenterX,
            nodeCenterY: nodeCenterY,
          );

          return Stack(
            clipBehavior: Clip.none,
            children: [
              // Caminho contínuo — desenhado através da faixa da fase também.
              Positioned.fill(
                child: CustomPaint(
                  painter: _TrailPathPainter(
                    anim: anim,
                    animate: animate,
                    flowOffset: flowOffset,
                    entryX: entryX,
                    thisX: thisX,
                    exitX: exitX,
                    nodeCenterY: nodeCenterY,
                    incomingSolid: incomingSolid,
                    outgoingSolid: outgoingSolid,
                    hasIncoming: hasIncoming,
                    hasOutgoing: hasOutgoing,
                    gaps: gaps,
                    solidColor: AppColors.turquoise,
                    trackColor: AppColors.borderStrong,
                  ),
                ),
              ),
              // Checkpoint de fase: pílula opaca sobre o caminho (o traçado
              // passa por trás, sem ser cortado).
              if (hasPhase)
                Positioned(
                  top: 6,
                  left: 0,
                  right: 0,
                  child: _PhaseCheckpoint(phase: phase!),
                ),
              if (showHere)
                Positioned(
                  // Acima do anel de progresso (r=39), não só do nó.
                  top: nodeCenterY - 39 - 30,
                  left: nodeCenterX - 62,
                  width: 124,
                  child: const Center(child: _HereTag()),
                ),
              Positioned(
                top: nodeCenterY - _nodeSize / 2,
                left: nodeCenterX - _nodeSize / 2,
                width: _nodeSize,
                height: _nodeSize,
                child: CompositedTransformTarget(
                  link: link,
                  child: _TrailNode(
                    step: step,
                    isCurrent: isCurrent,
                    anim: anim,
                    animate: animate,
                    onTap: onTap,
                  ),
                ),
              ),
              Positioned(
                top: nodeCenterY + _nodeSize / 2 + 6,
                left: nodeCenterX - 74,
                width: 148,
                child: _NodeLabel(step: step, isCurrent: isCurrent),
              ),
              // ── Nós de apoio laterais ──────────────────────────────────────
              for (final support in supportNodes) ...[
                // Ramal tracejado do nó de processo ao nó de apoio.
                Positioned.fill(
                  child: CustomPaint(
                    painter: _SupportBranchPainter(
                      mainCenterX: nodeCenterX,
                      supportCenterX: supportCenterX,
                      atY: nodeCenterY,
                      mainRadius: _nodeSize / 2,
                      supportRadius: supportR,
                      isRecommended:
                          support.recommendedByTherapistName != null,
                    ),
                  ),
                ),
                // Badge "Indicado por" acima do círculo de apoio.
                if (support.recommendedByTherapistName != null)
                  Positioned(
                    top: nodeCenterY - supportR - 20,
                    left: supportCenterX - 58,
                    width: 116,
                    child: _TherapistPill(
                        name: support.recommendedByTherapistName!),
                  ),
                // Círculo do nó de apoio.
                Positioned(
                  top: nodeCenterY - supportR,
                  left: supportCenterX - supportR,
                  width: _supportNodeSize,
                  height: _supportNodeSize,
                  child: _SupportNodeButton(
                    step: support,
                    onTap: () => onSupportTap(support),
                  ),
                ),
                // Anel de progresso do nó de apoio — ACIMA do círculo.
                if (support.progressFraction != null)
                  Positioned(
                    top: nodeCenterY - 36,
                    left: supportCenterX - 36,
                    width: 72,
                    height: 72,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ProgressRingPainter(
                          fraction: support.progressFraction!,
                          accent: support.recommendedByTherapistName != null
                              ? const Color(0xFF0EA5E9)
                              : const Color(0xFFD97706),
                          backgroundColor: Colors.white,
                          radius: 29.0,
                          strokeWidth: 2.0,
                        ),
                      ),
                    ),
                  ),
                // Rótulo abaixo do círculo de apoio.
                Positioned(
                  top: nodeCenterY + supportR + 6,
                  left: supportCenterX - 58,
                  width: 116,
                  child: Text(
                    support.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 11.5,
                          height: 1.2,
                          fontWeight: FontWeight.w600,
                          color: support.recommendedByTherapistName != null
                              ? const Color(0xFF1D4ED8)
                              : AppColors.textSecondary,
                        ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _NodeLabel extends StatelessWidget {
  const _NodeLabel({required this.step, required this.isCurrent});

  final JourneyStep step;
  final bool isCurrent;

  /// Largura útil do rótulo. Também é o limite usado para medir a área que
  /// abre folga no caminho.
  static const double width = 148;

  /// Linha de estado sob o título. É ela que tira a sensação de tela vazia:
  /// o paciente lê o que falta em cada parada sem precisar tocar no nó.
  static String? statusOf(JourneyStep step) {
    final f = step.progressFraction;
    return switch (step.availability) {
      JourneyStepAvailability.completed => 'Concluído',
      JourneyStepAvailability.inProgress =>
        f != null ? '${(f * 100).round()}% concluído' : 'Em andamento',
      JourneyStepAvailability.available =>
        f != null && f > 0 ? '${(f * 100).round()}% concluído' : 'Não iniciado',
      JourneyStepAvailability.blocked => 'Bloqueado',
      JourneyStepAvailability.inDevelopment => 'Em breve',
    };
  }

  static TextStyle? titleStyle(ThemeData theme) =>
      theme.textTheme.labelSmall?.copyWith(
        fontSize: 13.5,
        height: 1.25,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.1,
      );

  static TextStyle? statusStyle(ThemeData theme) =>
      theme.textTheme.labelSmall?.copyWith(
        fontSize: 11,
        height: 1.2,
        fontWeight: FontWeight.w400,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dimmed = step.availability == JourneyStepAvailability.blocked ||
        step.availability == JourneyStepAvailability.inDevelopment;
    final status = statusOf(step);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          step.title,
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: titleStyle(theme)?.copyWith(
            color: dimmed ? AppColors.textMuted : AppColors.textPrimary,
          ),
        ),
        if (status != null) ...[
          const SizedBox(height: 2),
          Text(
            status,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: statusStyle(theme)?.copyWith(
              color: isCurrent
                  ? _accentForStep(step)
                  : AppColors.textMuted.withValues(alpha: 0.9),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Nó ──────────────────────────────────────────────────────────────────────

class _TrailNode extends StatelessWidget {
  const _TrailNode({
    required this.step,
    required this.isCurrent,
    required this.anim,
    required this.animate,
    required this.onTap,
  });

  final JourneyStep step;
  final bool isCurrent;
  final Animation<double> anim;
  final bool animate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accent = _accentForStep(step);
    final visual = _nodeVisual(step.availability, accent);

    Widget circle(double pulse) {
      // Volume vem de luz coerente, não de degrau de cor: a face é uma esfera
      // iluminada do alto-esquerdo, com sombra de contato curta e sombra de
      // projeção longa. O nó atual só levanta um pouco mais do plano.
      final lift = isCurrent ? 1.0 : 0.0;
      // Tom de sombreado da face, derivado do próprio acento (mantém a
      // esfera na família cromática do módulo em vez de cinza morto).
      final shade = Color.lerp(visual.fill, accent, 0.10)!;
      final deepShade = Color.lerp(visual.fill, accent, 0.22)!;

      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            center: const Alignment(-0.42, -0.52),
            radius: 1.05,
            colors: [Colors.white, visual.fill, shade, deepShade],
            stops: const [0.0, 0.38, 0.78, 1.0],
          ),
          border: visual.ringWidth > 0
              ? Border.all(color: visual.ring, width: visual.ringWidth)
              : null,
          boxShadow: [
            // Sombra de contato: curta, escura, logo abaixo do nó.
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.13 + 0.05 * lift),
              offset: Offset(0, 2 + 1 * lift),
              blurRadius: 3 + 2 * lift,
            ),
            // Sombra de projeção: longa e difusa, deslocada para a direita
            // porque a luz vem do alto-esquerdo.
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.10 + 0.05 * lift),
              offset: Offset(1.5, 7 + 3 * lift),
              blurRadius: 14 + 8 * lift,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Realce especular no alto: a "quina" de luz da esfera.
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withValues(alpha: 0.85),
                      Colors.white.withValues(alpha: 0.0),
                    ],
                    stops: const [0.0, 0.42],
                  ),
                ),
              ),
            ),
            // Ícone em relevo: uma cópia clara deslocada para baixo faz o
            // traço parecer gravado na face, em vez de colado por cima.
            Transform.translate(
              offset: const Offset(0, 1),
              child: Icon(
                step.icon,
                size: isCurrent ? 34 : 32,
                color: Colors.white.withValues(alpha: 0.75),
              ),
            ),
            Icon(step.icon, size: isCurrent ? 34 : 32, color: visual.icon),
            // Anel de progresso ENTRE o ícone e o badge — o badge renderiza
            // acima, o anel renderiza acima das sombras do Container.
            //
            // Positioned.fill (em vez de offsets fixos) mantém o anel sempre
            // concêntrico ao nó: o painter desenha com raio maior que a caixa
            // e transborda, o que o Stack com Clip.none permite.
            if (step.progressFraction != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _ProgressRingPainter(
                      fraction: step.progressFraction!,
                      accent: accent,
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
              ),
            if (visual.badge != null)
              Positioned(
                right: -2,
                bottom: -1,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.10),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Icon(visual.badge, size: 10, color: visual.badgeColor),
                ),
              ),
          ],
        ),
      );
    }

    final node = (isCurrent && animate)
        ? AnimatedBuilder(
            animation: anim,
            builder: (context, _) {
              final pulse = (math.sin(anim.value * 2 * math.pi) + 1) / 2;
              return circle(pulse);
            },
          )
        : circle(isCurrent ? 0.5 : 0);

    return GestureDetector(onTap: onTap, child: node);
  }
}

// ── Balão de detalhe (overlay) ──────────────────────────────────────────────

class _StepBubble extends StatelessWidget {
  const _StepBubble({required this.step, required this.onAction});

  final JourneyStep step;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentForStep(step);
    final width = math.min(232.0, MediaQuery.sizeOf(context).width - 28);

    return Material(
      color: Colors.transparent,
      child: SizedBox(
        width: width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: AppRadius.xlAll,
                boxShadow: AppShadows.elevated,
              ),
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step.title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    step.subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  if (step.progressHint != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.insights_outlined, size: 14, color: accent),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            step.progressHint!,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: AppColors.textSecondary,
                              height: 1.3,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  StatusChip(
                    label: step.availability.label,
                    tone: _toneFor(step.availability),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: onAction,
                      style: FilledButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.mdAll,
                        ),
                      ),
                      child: Text(_actionLabel(step.availability)),
                    ),
                  ),
                ],
              ),
            ),
            // Seta apontando para o nó.
            Transform.translate(
              offset: const Offset(0, -6),
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhaseCheckpoint extends StatelessWidget {
  const _PhaseCheckpoint({required this.phase});

  final JourneyPhase phase;

  /// Cor da fase: acompanha as três auras da atmosfera de fundo, então a
  /// divisória e o ambiente falam a mesma língua cromática.
  static const _phaseTints = [
    Color(0xFF0E8F88),
    Color(0xFF6B52C9),
    Color(0xFF9A6A33),
  ];

  static String labelOf(JourneyPhase phase) =>
      'Fase ${phase.stepNumber} · ${phase.label}';

  static TextStyle? labelStyle(ThemeData theme) =>
      theme.textTheme.labelSmall?.copyWith(
        fontWeight: FontWeight.w600,
        fontSize: 11.5,
        letterSpacing: 1.3,
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tint = _phaseTints[(phase.stepNumber - 1) % _phaseTints.length];

    Widget rule(bool toRight) => Expanded(
          child: Container(
            height: 1,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: toRight ? Alignment.centerLeft : Alignment.centerRight,
                end: toRight ? Alignment.centerRight : Alignment.centerLeft,
                colors: [
                  tint.withValues(alpha: 0.0),
                  tint.withValues(alpha: 0.28),
                ],
              ),
            ),
          ),
        );

    // Divisor tipográfico: linhas finas que se dissolvem nas bordas com o nome
    // da fase em maiúsculas espaçadas — sumário editorial, não placa.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          rule(true),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              labelOf(phase),
              style: labelStyle(theme)?.copyWith(color: tint),
            ),
          ),
          rule(false),
        ],
      ),
    );
  }
}

class _HereTag extends StatelessWidget {
  const _HereTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navy.withValues(alpha: 0.90),
        borderRadius: BorderRadius.circular(11),
      ),
      child: Text(
        'VOCÊ ESTÁ AQUI',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w500,
              fontSize: 9,
              letterSpacing: 0.6,
            ),
      ),
    );
  }
}

// ── Nó de apoio lateral ─────────────────────────────────────────────────────

class _SupportNodeButton extends StatelessWidget {
  const _SupportNodeButton({required this.step, required this.onTap});

  final JourneyStep step;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isRecommended = step.recommendedByTherapistName != null;
    final base =
        isRecommended ? const Color(0xFF0EA5E9) : const Color(0xFFD97706);
    // Mesma gramática dos nós principais: branco, fio fino, ícone colorido.
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.88),
              border: Border.all(
                color: base.withValues(alpha: 0.26),
                width: 1.4,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.06),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Center(
              child: Icon(step.icon, size: 25, color: base),
            ),
          ),
          if (isRecommended)
            Positioned(
              right: -2,
              bottom: -1,
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.navy.withValues(alpha: 0.10),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  size: 9,
                  color: base,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TherapistPill extends StatelessWidget {
  const _TherapistPill({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        border: Border.all(color: const Color(0xFF93C5FD)),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '👩‍⚕️ $name',
        style: const TextStyle(
          fontSize: 8.5,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1D4ED8),
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Ramal tracejado para nó de apoio ────────────────────────────────────────

class _SupportBranchPainter extends CustomPainter {
  const _SupportBranchPainter({
    required this.mainCenterX,
    required this.supportCenterX,
    required this.atY,
    required this.mainRadius,
    required this.supportRadius,
    required this.isRecommended,
  });

  final double mainCenterX;
  final double supportCenterX;
  final double atY;
  final double mainRadius;
  final double supportRadius;
  final bool isRecommended;

  @override
  void paint(Canvas canvas, Size size) {
    final goRight = mainCenterX < supportCenterX;
    final x1 =
        goRight ? mainCenterX + mainRadius : mainCenterX - mainRadius;
    final x2 = goRight
        ? supportCenterX - supportRadius
        : supportCenterX + supportRadius;

    // Ramal discreto: fio fino e translúcido. É um desvio opcional da trilha,
    // não deve competir com o caminho principal nem com os nós.
    final paint = Paint()
      ..color = (isRecommended
              ? const Color(0xFF1D4ED8)
              : const Color(0xFFD97706))
          .withValues(alpha: 0.34)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    const dashLen = 3.0;
    const gapLen = 4.0;
    final dx = goRight ? 1.0 : -1.0;
    var x = x1;
    while (goRight ? x < x2 : x > x2) {
      final end = goRight
          ? math.min(x + dashLen, x2)
          : math.max(x - dashLen, x2);
      canvas.drawLine(Offset(x, atY), Offset(end, atY), paint);
      x += dx * (dashLen + gapLen);
    }
  }

  @override
  bool shouldRepaint(_SupportBranchPainter old) =>
      old.mainCenterX != mainCenterX ||
      old.supportCenterX != supportCenterX ||
      old.atY != atY ||
      old.isRecommended != isRecommended;
}

// ── Anel de progresso circular ──────────────────────────────────────────────

class _ProgressRingPainter extends CustomPainter {
  const _ProgressRingPainter({
    required this.fraction,
    required this.accent,
    required this.backgroundColor,
    this.radius = 39.0,
    this.strokeWidth = 2.5,
  });

  final double fraction;
  final Color accent;
  /// Cor de fundo da tela — usada para mascarar a trilha dentro da área do
  /// anel e evitar a aparência de arco torto.
  final Color backgroundColor;
  final double radius;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    final ringColor = fraction >= 1.0 ? AppColors.success : accent;

    // Halo branco discreto: mascara a trilha que cruza a faixa radial sem
    // virar um disco visível em volta do nó. Stroke (não disco cheio) para
    // não apagar a face do nó.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 2.5
        ..color = backgroundColor.withValues(alpha: 0.30),
    );

    // Trilho do anel: fio da mesma cor em opacidade baixa, sempre visível —
    // mesmo em 0% — para o círculo nunca parecer quebrado.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = ringColor.withValues(alpha: 0.16),
    );

    if (fraction <= 0) return;

    // Arco de preenchimento — sentido horário a partir do topo.
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * fraction.clamp(0.0, 1.0),
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..color = ringColor,
    );
  }

  @override
  bool shouldRepaint(_ProgressRingPainter old) =>
      old.fraction != fraction ||
      old.accent != accent ||
      old.backgroundColor != backgroundColor ||
      old.radius != radius ||
      old.strokeWidth != strokeWidth;
}

// ── Pintura do caminho ──────────────────────────────────────────────────────

class _TrailPathPainter extends CustomPainter {
  _TrailPathPainter({
    required this.anim,
    required this.animate,
    required this.flowOffset,
    required this.entryX,
    required this.thisX,
    required this.exitX,
    required this.nodeCenterY,
    required this.incomingSolid,
    required this.outgoingSolid,
    required this.hasIncoming,
    required this.hasOutgoing,
    required this.gaps,
    required this.solidColor,
    required this.trackColor,
  }) : super(repaint: animate ? anim : null);

  final Animation<double> anim;
  final bool animate;
  final double flowOffset;
  final double entryX;
  final double thisX;
  final double exitX;
  final double nodeCenterY;
  final bool incomingSolid;
  final bool outgoingSolid;
  final bool hasIncoming;
  final bool hasOutgoing;

  /// Áreas onde o caminho é interrompido (rótulos e divisores de fase), como
  /// num mapa de metrô: a linha passa "por baixo" do texto sem cruzá-lo.
  final List<Rect> gaps;

  final Color solidColor;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final ex = entryX * w;
    final tx = thisX * w;
    final xx = exitX * w;
    final ny = nodeCenterY;

    // Sem trecho de entrada no primeiro nó nem de saída no último: o caminho
    // começa e termina nos nós, em vez de virar um toco cortado pela borda.
    final incoming = hasIncoming
        ? (Path()
          ..moveTo(ex, 0)
          ..cubicTo(ex, ny * 0.6, tx, ny * 0.4, tx, ny))
        : null;
    final outgoing = hasOutgoing
        ? (Path()
          ..moveTo(tx, ny)
          ..cubicTo(tx, ny + (h - ny) * 0.5, xx, ny + (h - ny) * 0.4, xx, h))
        : null;

    if (incoming != null) _stroke(canvas, incoming, incomingSolid);
    if (outgoing != null) _stroke(canvas, outgoing, outgoingSolid);

    if (!animate) return;

    // Partículas subindo pelo trecho já concluído: sobem do fim para o começo,
    // no sentido inverso ao da leitura, sugerindo o caminho de onde o paciente
    // veio em vez de apontar para onde ir.
    if (incoming != null && incomingSolid) _drawParticles(canvas, incoming);
    if (outgoing != null && outgoingSolid) _drawParticles(canvas, outgoing);
  }

  // Halo branco largo que separa o caminho da atmosfera, depois a linha fina.
  // O trecho percorrido recebe cor; o restante fica cinza com pontilhado fino
  // por cima — progresso vira informação cromática, sem ornamento.
  static const _halo = 15.0;
  static const _line = 5.0;
  static const _dot = Color(0xFFBFCAD8);

  /// Quebra o traçado nos pontos em que entra numa área de folga, devolvendo
  /// só os trechos visíveis. Amostra a cada 2px — resolução suficiente para
  /// as curvas suaves da trilha.
  List<Path> _visibleRuns(Path path) {
    if (gaps.isEmpty) return [path];

    const step = 2.0;
    final runs = <Path>[];
    for (final metric in path.computeMetrics()) {
      double? runStart;
      var d = 0.0;
      while (d <= metric.length) {
        final position = metric.getTangentForOffset(d)?.position;
        final blocked =
            position != null && gaps.any((rect) => rect.contains(position));
        if (blocked) {
          if (runStart != null && d - runStart > 1) {
            runs.add(metric.extractPath(runStart, d));
          }
          runStart = null;
        } else {
          runStart ??= d;
        }
        d += step;
      }
      if (runStart != null && metric.length - runStart > 1) {
        runs.add(metric.extractPath(runStart, metric.length));
      }
    }
    return runs;
  }

  void _stroke(Canvas canvas, Path path, bool solid) {
    final halo = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _halo
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.62);
    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _line
      ..strokeCap = StrokeCap.round
      ..color = solid ? solidColor : trackColor.withValues(alpha: 0.55);

    for (final run in _visibleRuns(path)) {
      canvas.drawPath(run, halo);
      canvas.drawPath(run, line);
    }

    if (solid) return;

    // Pontilhado do trecho pendente: estático de propósito. O único movimento
    // do caminho são as partículas no trecho concluído — duas animações
    // simultâneas brigariam entre si e com as auras do fundo.
    const gap = 10.0;
    final dots = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..strokeCap = StrokeCap.round
      ..color = _dot.withValues(alpha: 0.85);
    for (final metric in _visibleRuns(path)
        .expand((run) => run.computeMetrics())) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 1, metric.length)),
          dots,
        );
        d += gap;
      }
    }
  }

  /// Partículas viajando pelo trecho concluído, do fim para o começo.
  ///
  /// Três por segmento, defasadas igualmente, cada uma com um halo difuso.
  /// Aparecem e somem nas pontas do segmento para não piscar na emenda com o
  /// segmento vizinho.
  static const _particles = 3;
  static const _fadeZone = 0.18;

  void _drawParticles(Canvas canvas, Path path) {
    for (final metric in path.computeMetrics()) {
      for (var i = 0; i < _particles; i++) {
        final phase = (anim.value + flowOffset + i / _particles) % 1.0;
        // (1 - phase): sobe, andando do fim do traço para o começo.
        final tangent = metric.getTangentForOffset((1.0 - phase) * metric.length);
        if (tangent == null) continue;

        // Some junto com o traço nas áreas de folga.
        if (gaps.any((rect) => rect.contains(tangent.position))) continue;

        final fade =
            (math.min(phase, 1.0 - phase) / _fadeZone).clamp(0.0, 1.0);
        if (fade <= 0) continue;

        // Levemente maior no meio do percurso do que nas pontas.
        final r = 1.7 + 0.6 * math.sin(phase * math.pi);

        canvas.drawCircle(
          tangent.position,
          r + 1.8,
          Paint()
            ..color = Colors.white.withValues(alpha: 0.24 * fade)
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.2),
        );
        canvas.drawCircle(
          tangent.position,
          r,
          Paint()..color = Colors.white.withValues(alpha: 0.92 * fade),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_TrailPathPainter old) =>
      old.entryX != entryX ||
      old.thisX != thisX ||
      old.exitX != exitX ||
      old.nodeCenterY != nodeCenterY ||
      old.incomingSolid != incomingSolid ||
      old.outgoingSolid != outgoingSolid ||
      old.hasIncoming != hasIncoming ||
      old.hasOutgoing != hasOutgoing ||
      !listEquals(old.gaps, gaps) ||
      old.animate != animate;
}

// ── Mapeamentos de estilo ───────────────────────────────────────────────────

typedef _NodeVisual = ({
  Color fill,
  bool useGradient,
  bool gloss,
  Color ring,
  double ringWidth,
  Color icon,
  Color base3d,
  IconData? badge,
  Color badgeColor,
});

/// Todos os nós são brancos: o que muda entre estados é o anel (fio de 1,4px),
/// a cor do ícone e a opacidade. Nada de preenchimento saturado, relevo 3D ou
/// brilho — a hierarquia vem do anel de progresso e do rótulo, não do volume.
_NodeVisual _nodeVisual(JourneyStepAvailability availability, Color accent) {
  switch (availability) {
    case JourneyStepAvailability.completed:
      return (
        fill: Colors.white,
        useGradient: false,
        gloss: false,
        ring: AppColors.success.withValues(alpha: 0.32),
        ringWidth: 1.4,
        icon: AppColors.success,
        base3d: Colors.transparent,
        badge: null,
        badgeColor: AppColors.success,
      );
    case JourneyStepAvailability.inProgress:
      return (
        fill: Colors.white,
        useGradient: false,
        gloss: false,
        ring: accent.withValues(alpha: 0.28),
        ringWidth: 1.4,
        icon: accent,
        base3d: Colors.transparent,
        badge: null,
        badgeColor: accent,
      );
    case JourneyStepAvailability.available:
      return (
        fill: Colors.white.withValues(alpha: 0.88),
        useGradient: false,
        gloss: false,
        ring: accent.withValues(alpha: 0.24),
        ringWidth: 1.4,
        icon: accent.withValues(alpha: 0.85),
        base3d: Colors.transparent,
        badge: null,
        badgeColor: accent,
      );
    case JourneyStepAvailability.blocked:
      return (
        fill: Colors.white.withValues(alpha: 0.70),
        useGradient: false,
        gloss: false,
        ring: AppColors.borderStrong.withValues(alpha: 0.55),
        ringWidth: 1.2,
        icon: AppColors.textMuted.withValues(alpha: 0.75),
        base3d: Colors.transparent,
        badge: Icons.lock_outline_rounded,
        badgeColor: AppColors.textMuted,
      );
    case JourneyStepAvailability.inDevelopment:
      return (
        fill: Colors.white.withValues(alpha: 0.70),
        useGradient: false,
        gloss: false,
        ring: AppColors.borderStrong.withValues(alpha: 0.55),
        ringWidth: 1.2,
        icon: AppColors.textMuted.withValues(alpha: 0.75),
        base3d: Colors.transparent,
        badge: Icons.schedule_outlined,
        badgeColor: AppColors.textMuted,
      );
  }
}

String _actionLabel(JourneyStepAvailability availability) {
  return switch (availability) {
    JourneyStepAvailability.completed => 'Rever',
    JourneyStepAvailability.inProgress => 'Continuar',
    JourneyStepAvailability.available => 'Começar',
    JourneyStepAvailability.blocked => 'Ver detalhes',
    JourneyStepAvailability.inDevelopment => 'Em breve',
  };
}

AppStatusTone _toneFor(JourneyStepAvailability availability) {
  return switch (availability) {
    JourneyStepAvailability.available => AppStatusTone.available,
    JourneyStepAvailability.inProgress => AppStatusTone.inProgress,
    JourneyStepAvailability.completed => AppStatusTone.completed,
    JourneyStepAvailability.inDevelopment => AppStatusTone.development,
    JourneyStepAvailability.blocked => AppStatusTone.blocked,
  };
}

Color _accentForStep(JourneyStep step) {
  return switch (step.id) {
    JourneyStepId.initialAssessment => AppColors.moduleDashboard,
    JourneyStepId.psychoeducation => AppColors.purple,
    JourneyStepId.questionnaires => AppColors.moduleQuestionnaires,
    JourneyStepId.mentalMap => AppColors.moduleMentalMap,
    JourneyStepId.checkIn => AppColors.moduleCheckIn,
    JourneyStepId.timeline => AppColors.moduleTimeline,
    JourneyStepId.therapyGoals => AppColors.moduleGoals,
    JourneyStepId.problems => AppColors.moduleProblems,
    JourneyStepId.library => AppColors.moduleResources,
    JourneyStepId.results => AppColors.moduleDashboard,
    JourneyStepId.dailyMonitor => AppColors.moduleMonitor,
    JourneyStepId.genogram => AppColors.moduleGenogram,
  };
}
