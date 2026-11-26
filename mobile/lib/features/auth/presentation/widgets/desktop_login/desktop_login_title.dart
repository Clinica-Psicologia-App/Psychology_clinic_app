import 'package:flutter/material.dart';

import '../../../../../core/theme/app_animations.dart';
import 'desktop_login_lifecycle.dart';
import 'desktop_login_tokens.dart';

/// "Acesso clínico" com o gradiente da marca deslizando devagar
/// (9 s, vai e volta). Para com "reduzir movimento".
class DesktopLoginTitle extends StatefulWidget {
  const DesktopLoginTitle({super.key, required this.fontSize});

  final double fontSize;

  @override
  State<DesktopLoginTitle> createState() => DesktopLoginTitleState();
}

class DesktopLoginTitleState extends State<DesktopLoginTitle>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        DesktopLoginLifecycle {
  late final AnimationController _c;

  /// Para testes: o controller está rodando?
  bool get isAnimating => _c.isAnimating;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(seconds: 9));
    attachLifecycle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncAnimation();
  }

  @override
  void syncAnimation() {
    if (AppAnimations.shouldAnimate(context) && !inBackground) {
      if (!_c.isAnimating) _c.repeat(reverse: true);
    } else {
      _c.stop();
    }
  }

  @override
  void dispose() {
    detachLifecycle();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.displaySmall?.copyWith(
          fontSize: widget.fontSize,
          fontWeight: FontWeight.w700,
          height: 1.06,
          letterSpacing: -.03 * widget.fontSize,
          color: Colors.white,
        );
    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _c,
        builder: (_, child) => ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (rect) => LinearGradient(
            colors: const [
              DesktopLoginTokens.cyan,
              DesktopLoginTokens.blue,
              DesktopLoginTokens.purple,
              DesktopLoginTokens.blue,
              DesktopLoginTokens.cyan,
            ],
            transform: _Slide(Curves.easeInOut.transform(_c.value)),
            tileMode: TileMode.mirror,
          ).createShader(Rect.fromLTWH(0, 0, rect.width * 1.6, rect.height)),
          child: child,
        ),
        child: Text('Acesso clínico', style: style),
      ),
    );
  }
}

class _Slide extends GradientTransform {
  const _Slide(this.t);
  final double t;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) =>
      Matrix4.translationValues(-bounds.width * .6 * t, 0, 0);
}
