import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../domain/coach_tour.dart';
import 'mascot_widget.dart';
import 'speech_bubble.dart';

class CoachOverlay extends StatefulWidget {
  const CoachOverlay({
    super.key,
    required this.tour,
    required this.index,
    required this.onNext,
    required this.onSkip,
  });

  final CoachTour tour;
  final int index;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  State<CoachOverlay> createState() => _CoachOverlayState();
}

class _CoachOverlayState extends State<CoachOverlay> {
  final _mascotKey = GlobalKey<MascotWidgetState>();

  @override
  Widget build(BuildContext context) {
    final step = widget.tour.steps[widget.index];
    final targetRect = _targetRect(step.targetKey);
    final size = MediaQuery.sizeOf(context);
    final padding = MediaQuery.paddingOf(context);
    final dimColor = Colors.black.withValues(
      alpha: targetRect == null ? 0.36 : 0.60,
    );

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          IgnorePointer(
            child: CustomPaint(
              painter: _SpotlightPainter(
                targetRect: targetRect,
                color: dimColor,
              ),
            ),
          ),
          Positioned.fill(
            child: _CoachPanelPositioner(
              screenSize: size,
              safePadding: padding,
              targetRect: targetRect,
              child: _CoachPanel(
                mascotKey: _mascotKey,
                tour: widget.tour,
                index: widget.index,
                onNext: widget.onNext,
                onSkip: widget.onSkip,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Rect? _targetRect(GlobalKey? key) {
    final context = key?.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;

    final offset = renderObject.localToGlobal(Offset.zero);
    return (offset & renderObject.size).inflate(AppSpacing.sm);
  }
}

class _CoachPanelPositioner extends StatelessWidget {
  const _CoachPanelPositioner({
    required this.screenSize,
    required this.safePadding,
    required this.targetRect,
    required this.child,
  });

  final Size screenSize;
  final EdgeInsets safePadding;
  final Rect? targetRect;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final availableWidth =
        math.max(240.0, screenSize.width - AppSpacing.xl * 2);
    final panelWidth = math.min(520.0, availableWidth);

    // Mede a altura real do balão e posiciona sem vazar a área segura:
    // abaixo do alvo se couber, senão acima, senão ancorado no rodapé seguro.
    return CustomSingleChildLayout(
      delegate: _CoachLayoutDelegate(
        screenSize: screenSize,
        safePadding: safePadding,
        targetRect: targetRect,
        panelWidth: panelWidth,
      ),
      child: child,
    );
  }
}

/// Posiciona o balão do coach usando a altura MEDIDA do filho, garantindo que
/// ele fique sempre inteiro dentro da área segura da tela.
class _CoachLayoutDelegate extends SingleChildLayoutDelegate {
  const _CoachLayoutDelegate({
    required this.screenSize,
    required this.safePadding,
    required this.targetRect,
    required this.panelWidth,
  });

  final Size screenSize;
  final EdgeInsets safePadding;
  final Rect? targetRect;
  final double panelWidth;

  static const _margin = AppSpacing.md;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    final maxHeight = math.max(
      0.0,
      screenSize.height - safePadding.top - safePadding.bottom - _margin * 2,
    );
    return BoxConstraints(
      minWidth: panelWidth,
      maxWidth: panelWidth,
      maxHeight: maxHeight,
    );
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final minTop = safePadding.top + _margin;
    final bottomLimit = size.height - safePadding.bottom - _margin;
    final maxTop = math.max(minTop, bottomLimit - childSize.height);

    final rect = targetRect;
    double top;
    if (rect == null) {
      top = maxTop; // sem alvo: ancora no rodapé seguro
    } else {
      final belowTop = rect.bottom + _margin;
      final aboveTop = rect.top - _margin - childSize.height;
      if (belowTop + childSize.height <= bottomLimit) {
        top = belowTop; // cabe abaixo
      } else if (aboveTop >= minTop) {
        top = aboveTop; // cabe acima
      } else {
        top = maxTop; // não cabe em nenhum: rodapé seguro (inteiro)
      }
    }
    top = top.clamp(minTop, maxTop);

    double left;
    if (rect == null) {
      left = (size.width - childSize.width) / 2;
    } else {
      final maxLeft = math.max(_margin, size.width - childSize.width - _margin);
      left = (rect.center.dx - childSize.width / 2)
          .clamp(_margin.toDouble(), maxLeft);
    }

    return Offset(left, top);
  }

  @override
  bool shouldRelayout(_CoachLayoutDelegate old) =>
      old.screenSize != screenSize ||
      old.safePadding != safePadding ||
      old.targetRect != targetRect ||
      old.panelWidth != panelWidth;
}

class _CoachPanel extends StatelessWidget {
  const _CoachPanel({
    required this.mascotKey,
    required this.tour,
    required this.index,
    required this.onNext,
    required this.onSkip,
  });

  final GlobalKey<MascotWidgetState> mascotKey;
  final CoachTour tour;
  final int index;
  final VoidCallback onNext;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final step = tour.steps[index];
    final mascotSize = MediaQuery.sizeOf(context).width < 360 ? 74.0 : 92.0;
    final animate = AppAnimations.shouldAnimate(context);
    // SizedBox garante largura/altura finitas ao mascote mesmo dentro do Row
    // (filho não-flex recebe constraint de largura infinita) e durante a
    // transição do AnimatedSwitcher.
    final mascot = SizedBox(
      width: mascotSize,
      height: mascotSize,
      child: GestureDetector(
        onTap: () => mascotKey.currentState?.animateReact(),
        child: MascotWidget(
          key: mascotKey,
          pose: step.pose,
          size: mascotSize,
        ),
      ),
    );
    final bubble = SpeechBubble(
      text: step.text,
      onNext: onNext,
      onSkip: onSkip,
      isLast: index == tour.steps.length - 1,
      index: index,
      total: tour.steps.length,
    );

    // O mascote é PERSISTENTE (uma única instância com a GlobalKey; troca de
    // pose sozinho via didUpdateWidget). Só o balão faz cross-fade entre os
    // passos — assim não há GlobalKey duplicada durante a transição.
    final animatedBubble = !animate
        ? bubble
        : AnimatedSwitcher(
            duration: AppAnimations.standard,
            switchInCurve: AppAnimations.enterCurve,
            switchOutCurve: AppAnimations.exitCurve,
            child: KeyedSubtree(
              key: ValueKey('${tour.id}-$index'),
              child: bubble,
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 360) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              mascot,
              const SizedBox(height: AppSpacing.sm),
              animatedBubble,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            mascot,
            const SizedBox(width: AppSpacing.sm),
            Expanded(child: animatedBubble),
          ],
        );
      },
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  const _SpotlightPainter({
    required this.targetRect,
    required this.color,
  });

  final Rect? targetRect;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()..addRect(Offset.zero & size);
    final rect = targetRect;
    if (rect != null) {
      path
        ..fillType = PathFillType.evenOdd
        ..addRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(18)),
        );
    }
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _SpotlightPainter oldDelegate) {
    return oldDelegate.targetRect != targetRect || oldDelegate.color != color;
  }
}
