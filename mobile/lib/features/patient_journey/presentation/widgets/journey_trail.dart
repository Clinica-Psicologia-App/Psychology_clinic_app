import 'dart:math' as math;

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
  final bool isCurrent;
  final bool showHere;
  final JourneyPhase? phase;
  final List<JourneyStep> supportNodes;
  final void Function(JourneyStep) onSupportTap;
  final VoidCallback onTap;

  static const double _baseHeight = 120;
  static const double _nodeSize = 64;
  static const double _supportNodeSize = 44.0;
  static const double _phaseBand = 40;
  static const double _baseNodeCenterY = 44;

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
                  child: Center(child: _PhaseCheckpoint(phase: phase!)),
                ),
              if (showHere)
                Positioned(
                  top: nodeCenterY - _nodeSize / 2 - 26,
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
              // Anel de progresso ACIMA do nó — cobre sombras e a trilha que
              // passam pelo raio do anel, garantindo aparência circular limpa.
              if (step.progressFraction != null)
                Positioned(
                  top: nodeCenterY - 44,
                  left: nodeCenterX - 44,
                  width: 88,
                  height: 88,
                  child: IgnorePointer(
                    child: CustomPaint(
                      painter: _ProgressRingPainter(
                        fraction: step.progressFraction!,
                        accent: _accentForStep(step),
                        backgroundColor: AppColors.background,
                      ),
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
                    top: nodeCenterY - 33,
                    left: supportCenterX - 33,
                    width: 66,
                    height: 66,
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _ProgressRingPainter(
                          fraction: support.progressFraction!,
                          accent: support.recommendedByTherapistName != null
                              ? const Color(0xFF0EA5E9)
                              : const Color(0xFFD97706),
                          backgroundColor: AppColors.background,
                          radius: 27.0,
                          strokeWidth: 3.5,
                        ),
                      ),
                    ),
                  ),
                // Rótulo abaixo do círculo de apoio.
                Positioned(
                  top: nodeCenterY + supportR + 4,
                  left: supportCenterX - 55,
                  width: 110,
                  child: Text(
                    support.title,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          fontSize: 10,
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

  @override
  Widget build(BuildContext context) {
    final dimmed = step.availability == JourneyStepAvailability.blocked ||
        step.availability == JourneyStepAvailability.inDevelopment;
    return Text(
      step.title,
      textAlign: TextAlign.center,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontSize: 11.5,
            height: 1.2,
            fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w600,
            color: isCurrent
                ? AppColors.turquoise
                : dimmed
                    ? AppColors.textMuted
                    : AppColors.textSecondary,
          ),
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
      final glowSpread = 4 + 5 * pulse;
      final glowAlpha = 0.22 + 0.20 * pulse;
      return Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: visual.fill,
          gradient: visual.useGradient
              ? LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [accent, Color.lerp(accent, AppColors.purple, 0.5)!],
                )
              : null,
          border: visual.ringWidth > 0
              ? Border.all(color: visual.ring, width: visual.ringWidth)
              : null,
          boxShadow: [
            if (isCurrent)
              BoxShadow(
                color: accent.withValues(alpha: glowAlpha),
                spreadRadius: glowSpread,
                blurRadius: 0,
              ),
            // Relevo "apertável": um degrau mais escuro embaixo.
            BoxShadow(
              color: visual.base3d,
              offset: const Offset(0, 5),
              blurRadius: 0,
            ),
            BoxShadow(
              color: AppColors.navy.withValues(alpha: 0.14),
              offset: const Offset(0, 9),
              blurRadius: 14,
            ),
          ],
        ),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            // Brilho superior (gloss) — dá acabamento de botão aos nós cheios.
            if (visual.gloss)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      center: const Alignment(-0.35, -0.55),
                      radius: 0.85,
                      colors: [
                        Colors.white.withValues(alpha: 0.38),
                        Colors.white.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
              ),
            Icon(step.icon, size: 28, color: visual.icon),
            if (visual.badge != null)
              Positioned(
                right: -3,
                bottom: -1,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: visual.badgeColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 3),
                  ),
                  child: Icon(visual.badge, size: 11, color: Colors.white),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Text(
              '${phase.stepNumber}',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.turquoise,
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
              ),
            ),
          ),
          const SizedBox(width: 7),
          Text(
            'Fase ${phase.stepNumber} · ${phase.label}',
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.navy,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
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
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(999),
        boxShadow: AppShadows.card,
      ),
      child: Text(
        '✦ Você está aqui',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 10,
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
    final top = Color.lerp(base, Colors.white, 0.25)!;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [top, base],
              ),
              boxShadow: [
                BoxShadow(
                  color: base.withValues(alpha: 0.40),
                  offset: const Offset(0, 4),
                  blurRadius: 0,
                ),
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.12),
                  offset: const Offset(0, 7),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Center(
              child: Icon(step.icon, size: 20, color: Colors.white),
            ),
          ),
          if (isRecommended)
            Positioned(
              right: -2,
              bottom: -1,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: const Color(0xFF0369A1),
                  shape: BoxShape.circle,
                  border:
                      Border.all(color: AppColors.background, width: 2.5),
                ),
                child:
                    const Icon(Icons.person_rounded, size: 9, color: Colors.white),
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

    final paint = Paint()
      ..color = isRecommended
          ? const Color(0xFF1D4ED8)
          : const Color(0xFFD97706)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const dashLen = 5.0;
    const gapLen = 3.5;
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
    this.radius = 38.0,
    this.strokeWidth = 4.5,
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

    // Stroke de fundo: mascara a trilha bézier na exata faixa radial do anel
    // e forma o "track" da parte não preenchida. Usa stroke (não disco cheio)
    // para não apagar a face do nó quando o painter renderiza acima dele.
    // Largura ligeiramente maior (+ 1.5px) garante cobertura do traço de 6px
    // da trilha principal.
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 1.5
        ..color = backgroundColor,
    );

    if (fraction <= 0) {
      _drawDashedCircle(
        canvas,
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..color = AppColors.borderStrong.withValues(alpha: 0.35),
      );
      return;
    }

    final ringColor = fraction >= 1.0 ? AppColors.success : accent;

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

  void _drawDashedCircle(
      Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    const dashLen = 4.5;
    const gapLen = 4.5;
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + dashLen, metric.length)),
          paint,
        );
        d += dashLen + gapLen;
      }
    }
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

    final incoming = Path()
      ..moveTo(ex, 0)
      ..cubicTo(ex, ny * 0.6, tx, ny * 0.4, tx, ny);
    final outgoing = Path()
      ..moveTo(tx, ny)
      ..cubicTo(tx, ny + (h - ny) * 0.5, xx, ny + (h - ny) * 0.4, xx, h);

    _stroke(canvas, incoming, incomingSolid);
    _stroke(canvas, outgoing, outgoingSolid);

    // Brilho de energia correndo pelo trecho já concluído (sólido).
    if (animate && (incomingSolid || outgoingSolid)) {
      final flow = Path();
      if (incomingSolid) flow.addPath(incoming, Offset.zero);
      if (outgoingSolid) {
        flow.addPath(outgoing, Offset.zero);
      }
      _drawFlow(canvas, flow);
    }
  }

  void _stroke(Canvas canvas, Path path, bool solid) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = solid ? solidColor : trackColor;

    if (solid) {
      canvas.drawPath(path, paint);
      return;
    }
    for (final metric in path.computeMetrics()) {
      var d = 0.0;
      while (d < metric.length) {
        canvas.drawPath(
          metric.extractPath(d, math.min(d + 1.5, metric.length)),
          paint,
        );
        d += 11;
      }
    }
  }

  void _drawFlow(Canvas canvas, Path path) {
    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    const window = 22.0;
    for (final metric in path.computeMetrics()) {
      final phase = (anim.value + flowOffset) % 1;
      final start = phase * (metric.length + window) - window;
      final a = start.clamp(0.0, metric.length);
      final b = (start + window).clamp(0.0, metric.length);
      if (b > a) canvas.drawPath(metric.extractPath(a, b), glow);
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

_NodeVisual _nodeVisual(JourneyStepAvailability availability, Color accent) {
  switch (availability) {
    case JourneyStepAvailability.completed:
      return (
        fill: AppColors.success,
        useGradient: false,
        gloss: true,
        ring: AppColors.success,
        ringWidth: 0,
        icon: Colors.white,
        base3d: Color.lerp(AppColors.success, Colors.black, 0.28)!,
        badge: Icons.check_rounded,
        badgeColor: AppColors.success,
      );
    case JourneyStepAvailability.inProgress:
      return (
        fill: accent,
        useGradient: true,
        gloss: true,
        ring: accent,
        ringWidth: 0,
        icon: Colors.white,
        base3d: Color.lerp(accent, AppColors.navy, 0.45)!,
        badge: null,
        badgeColor: accent,
      );
    case JourneyStepAvailability.available:
      return (
        fill: AppColors.surface,
        useGradient: false,
        gloss: false,
        ring: accent,
        ringWidth: 3,
        icon: accent,
        base3d: accent.withValues(alpha: 0.35),
        badge: null,
        badgeColor: accent,
      );
    case JourneyStepAvailability.blocked:
      return (
        fill: AppColors.disabledSurface,
        useGradient: false,
        gloss: false,
        ring: AppColors.borderStrong,
        ringWidth: 2,
        icon: AppColors.textMuted,
        base3d: AppColors.borderStrong,
        badge: Icons.lock_rounded,
        badgeColor: AppColors.textMuted,
      );
    case JourneyStepAvailability.inDevelopment:
      return (
        fill: AppColors.surface,
        useGradient: false,
        gloss: false,
        ring: AppColors.borderStrong,
        ringWidth: 2,
        icon: AppColors.textMuted,
        base3d: AppColors.borderStrong,
        badge: Icons.schedule_rounded,
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
