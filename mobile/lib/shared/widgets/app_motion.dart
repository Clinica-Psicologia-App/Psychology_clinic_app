import 'package:flutter/material.dart';

import '../../core/theme/app_animations.dart';

/// Entrada sutil para blocos de conteúdo, respeitando redução de movimento.
class MotionReveal extends StatefulWidget {
  const MotionReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = const Offset(0, 0.035),
  });

  final Widget child;
  final Duration delay;
  final Offset offset;

  @override
  State<MotionReveal> createState() => _MotionRevealState();
}

class _MotionRevealState extends State<MotionReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _position;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppAnimations.emphasis,
    );
    final curved = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.enterCurve,
    );
    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _position = Tween<Offset>(
      begin: widget.offset,
      end: Offset.zero,
    ).animate(curved);
    _start();
  }

  Future<void> _start() async {
    if (widget.delay > Duration.zero) {
      await Future<void>.delayed(widget.delay);
    }
    if (mounted) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!AppAnimations.shouldAnimate(context)) return widget.child;
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _position, child: widget.child),
    );
  }
}

/// Revela uma lista de blocos em cascata (cada item entra com um pequeno
/// atraso em relação ao anterior). O atraso é limitado para listas longas.
class MotionStaggered extends StatelessWidget {
  const MotionStaggered({
    super.key,
    required this.children,
    this.interval = const Duration(milliseconds: 55),
    this.baseDelay = Duration.zero,
    this.maxStaggered = 10,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
  });

  final List<Widget> children;
  final Duration interval;
  final Duration baseDelay;
  final int maxStaggered;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: crossAxisAlignment,
      children: [
        for (var i = 0; i < children.length; i++)
          MotionReveal(
            delay: baseDelay + interval * (i < maxStaggered ? i : maxStaggered),
            child: children[i],
          ),
      ],
    );
  }
}

/// Atraso escalonado para uso em `ListView.builder` (limitado por [maxStaggered]).
Duration staggerDelay(
  int index, {
  Duration interval = const Duration(milliseconds: 55),
  int maxStaggered = 10,
}) {
  final steps = index < maxStaggered ? index : maxStaggered;
  return interval * steps;
}

/// Superfície interativa com hover e pressão discretos.
class MotionSurface extends StatefulWidget {
  const MotionSurface({
    super.key,
    required this.child,
    this.onTap,
    this.borderRadius = const BorderRadius.all(Radius.circular(16)),
    this.hoverScale = 1.008,
    this.pressedScale = 0.992,
  });

  final Widget child;
  final VoidCallback? onTap;
  final BorderRadius borderRadius;
  final double hoverScale;
  final double pressedScale;

  @override
  State<MotionSurface> createState() => _MotionSurfaceState();
}

class _MotionSurfaceState extends State<MotionSurface> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final animate = AppAnimations.shouldAnimate(context);
    final scale = !animate
        ? 1.0
        : _pressed
            ? widget.pressedScale
            : _hovered
                ? widget.hoverScale
                : 1.0;

    return MouseRegion(
      cursor:
          widget.onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() {
        _hovered = false;
        _pressed = false;
      }),
      child: GestureDetector(
        excludeFromSemantics: true,
        onTapDown: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: widget.onTap == null
            ? null
            : () => setState(() => _pressed = false),
        onTapUp: widget.onTap == null
            ? null
            : (_) => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: scale,
          duration: AppAnimations.resolve(context, AppAnimations.fast),
          curve: AppAnimations.standardCurve,
          child: widget.child,
        ),
      ),
    );
  }
}
