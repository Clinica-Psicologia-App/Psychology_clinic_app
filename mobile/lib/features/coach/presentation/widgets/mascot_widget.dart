import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_animations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_gradients.dart';
import '../../domain/coach_step.dart';

class MascotWidget extends StatefulWidget {
  const MascotWidget({
    super.key,
    required this.pose,
    this.size = 96,
  });

  final MascotPose pose;
  final double size;

  @override
  State<MascotWidget> createState() => MascotWidgetState();
}

class MascotWidgetState extends State<MascotWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  MascotPose? _previousPose;
  late MascotPose _currentPose;
  _MascotMotion _motion = _MascotMotion.static;

  @override
  void initState() {
    super.initState();
    _currentPose = widget.pose;
    _controller = AnimationController(vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !AppAnimations.shouldAnimate(context)) return;
      _playEntry();
    });
  }

  @override
  void didUpdateWidget(covariant MascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pose == widget.pose) return;
    _previousPose = _currentPose;
    _currentPose = widget.pose;
    if (!AppAnimations.shouldAnimate(context)) {
      _previousPose = null;
      setState(() {});
      return;
    }
    _playPoseTransition();
  }

  Future<void> animateReact() async {
    if (!mounted || !AppAnimations.shouldAnimate(context)) return;
    _controller
      ..stop()
      ..duration = const Duration(milliseconds: 520);
    setState(() => _motion = _MascotMotion.reaction);
    await _controller.forward(from: 0);
    if (mounted) _startAmbient();
  }

  void _playEntry() {
    _controller
      ..stop()
      ..duration = const Duration(milliseconds: 420);
    setState(() => _motion = _MascotMotion.entry);
    _controller.forward(from: 0).whenComplete(() {
      if (mounted) _startAmbient();
    });
  }

  void _playPoseTransition() {
    _controller
      ..stop()
      ..duration = AppAnimations.standard;
    setState(() => _motion = _MascotMotion.pose);
    _controller.forward(from: 0).whenComplete(() {
      if (!mounted) return;
      _previousPose = null;
      _startAmbient();
    });
  }

  void _startAmbient() {
    if (!AppAnimations.shouldAnimate(context)) {
      setState(() => _motion = _MascotMotion.static);
      return;
    }
    _controller
      ..stop()
      ..duration = const Duration(milliseconds: 2400);
    setState(() => _motion = _MascotMotion.ambient);
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = AppAnimations.shouldAnimate(context);
    if (!animate) {
      return SizedBox(
        width: widget.size,
        height: widget.size,
        child: _PoseAsset(pose: _currentPose),
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        var offsetY = 0.0;
        var scale = 1.0;
        var rotation = 0.0;
        var opacity = 1.0;

        switch (_motion) {
          case _MascotMotion.entry:
            opacity = Curves.easeOut.transform(t);
            scale = 0.82 + Curves.elasticOut.transform(t) * 0.18;
          case _MascotMotion.ambient:
            final wave = math.sin(t * math.pi);
            offsetY = -6 * wave;
            scale = 1 + wave * 0.025;
          case _MascotMotion.reaction:
            final jump = math.sin(t * math.pi);
            offsetY = -16 * jump;
            scale = 1 + jump * 0.08;
            rotation = math.sin(t * math.pi * 2) * 0.10;
          case _MascotMotion.pose:
          case _MascotMotion.static:
            break;
        }

        return Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(0, offsetY),
            child: Transform.rotate(
              angle: rotation,
              child: Transform.scale(scale: scale, child: child),
            ),
          ),
        );
      },
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: _PoseStack(
          current: _currentPose,
          previous: _previousPose,
          animation: _controller,
          motion: _motion,
        ),
      ),
    );
  }
}

enum _MascotMotion { static, entry, ambient, reaction, pose }

class _PoseStack extends StatelessWidget {
  const _PoseStack({
    required this.current,
    required this.previous,
    required this.animation,
    required this.motion,
  });

  final MascotPose current;
  final MascotPose? previous;
  final Animation<double> animation;
  final _MascotMotion motion;

  @override
  Widget build(BuildContext context) {
    final previousPose = previous;
    if (previousPose == null || motion != _MascotMotion.pose) {
      return _PoseAsset(pose: current);
    }

    final t = Curves.easeInOut.transform(animation.value);
    return Stack(
      fit: StackFit.expand,
      children: [
        Opacity(opacity: 1 - t, child: _PoseAsset(pose: previousPose)),
        Opacity(opacity: t, child: _PoseAsset(pose: current)),
      ],
    );
  }
}

class _PoseAsset extends StatelessWidget {
  const _PoseAsset({required this.pose});

  final MascotPose pose;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath(pose),
      fit: BoxFit.contain,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) {
        if (pose != MascotPose.idle) {
          return Image.asset(
            _assetPath(MascotPose.idle),
            fit: BoxFit.contain,
            gaplessPlayback: true,
            errorBuilder: (_, __, ___) => const _MascotPlaceholder(),
          );
        }
        return const _MascotPlaceholder();
      },
    );
  }

  static String _assetPath(MascotPose pose) => 'assets/mascot/${pose.name}.png';
}

class _MascotPlaceholder extends StatelessWidget {
  const _MascotPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppGradients.brand,
      ),
      child: Container(
        margin: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white.withValues(alpha: 0.18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.45)),
        ),
        child: const Icon(
          Icons.psychology_alt_outlined,
          color: Colors.white,
          size: 54,
          shadows: [
            Shadow(
              color: AppColors.navy,
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
