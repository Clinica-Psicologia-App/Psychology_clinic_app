import 'package:flutter/material.dart';

import '../../../../../core/theme/app_animations.dart';
import 'desktop_login_lifecycle.dart';
import 'desktop_login_scenes.dart';
import 'desktop_login_tokens.dart';

/// Os 4 itens do carrossel (textos exatos do app).
const kDesktopLoginFeatures = [
  (
    icon: Icons.family_restroom_outlined,
    title: 'Genograma clínico',
    body: 'Mapeie vínculos familiares e padrões transgeracionais com precisão.',
  ),
  (
    icon: Icons.assignment_outlined,
    title: 'Questionários validados',
    body: 'PHQ-9, GAD-7, Young, NEO PI-R e mais — integrados ao prontuário.',
  ),
  (
    icon: Icons.route_outlined,
    title: 'Jornada do paciente',
    body: 'Acompanhe evolução, metas e check-ins em linha do tempo unificada.',
  ),
  (
    icon: Icons.shield_outlined,
    title: 'Segurança clínica',
    body: 'Dados criptografados, acesso por convite e conformidade com CFP.',
  ),
];

/// Vitrine em "janela de desktop" com as 4 cenas e as abas com progresso.
/// Um único controller de 16 s (4 s por cena). Pausa com o mouse em cima e
/// com o app em segundo plano; para com "reduzir movimento".
class DesktopLoginShowcase extends StatefulWidget {
  const DesktopLoginShowcase({super.key, this.compact = false});

  /// Tablet: alvos de toque de 48 px.
  final bool compact;

  @override
  State<DesktopLoginShowcase> createState() => DesktopLoginShowcaseState();
}

class DesktopLoginShowcaseState extends State<DesktopLoginShowcase>
    with
        SingleTickerProviderStateMixin,
        WidgetsBindingObserver,
        DesktopLoginLifecycle {
  static const _cycle = Duration(seconds: 16);
  late final AnimationController _c;
  bool _hover = false;
  int _manual = 0; // cena mostrada quando o movimento está reduzido

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: _cycle);
    attachLifecycle();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    syncAnimation();
  }

  /// Para testes: o controller está rodando?
  bool get isAnimating => _c.isAnimating;

  @override
  void syncAnimation() {
    final run = AppAnimations.shouldAnimate(context) && !_hover && !inBackground;
    if (run) {
      if (!_c.isAnimating) _c.repeat(min: 0, max: 1, reverse: false, period: _cycle);
    } else {
      _c.stop();
    }
  }

  /// Escolhe a cena [i] (clique na aba) e reinicia a contagem dela.
  void select(int i) {
    setState(() => _manual = i);
    _c.value = i * .25;
    syncAnimation();
  }

  /// Cena atual (para testes e semântica).
  int get index => AppAnimations.shouldAnimate(context)
      ? (_c.value * 4).floor().clamp(0, 3)
      : _manual;

  @override
  void dispose() {
    detachLifecycle();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tk = DesktopLoginTokens.of(context);
    final theme = Theme.of(context);
    final animate = AppAnimations.shouldAnimate(context);
    return MouseRegion(
      onEnter: (_) {
        _hover = true;
        syncAnimation();
      },
      onExit: (_) {
        _hover = false;
        syncAnimation();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: tk.rz,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: tk.bd2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D1B3D)
                        .withValues(alpha: tk.dark ? .35 : .10),
                    blurRadius: 40,
                    offset: const Offset(0, 18),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: Column(
                  children: [
                    _WindowBar(tk: tk),
                    Expanded(
                      child: ColoredBox(
                        color: tk.bg,
                        child: CustomPaint(
                          painter: _DotGridPainter(tk.bd),
                          child: RepaintBoundary(
                            child: AnimatedBuilder(
                              animation: _c,
                              builder: (_, __) {
                                final v = animate ? _c.value : 0.0;
                                final i = animate
                                    ? (v * 4).floor().clamp(0, 3)
                                    : _manual;
                                final t = animate ? (v * 4 - i) * 4 : 99.0;
                                return AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: SizedBox.expand(
                                    key: ValueKey('desktop_login_scene_$i'),
                                    child: Semantics(
                                      label: kDesktopLoginFeatures[i].title,
                                      child: CustomPaint(
                                        painter: DesktopLoginScenePainter(
                                          scene: i,
                                          t: t,
                                          tokens: tk,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    _Legend(c: _c, manual: _manual, animate: animate, tk: tk),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < 4; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _Tab(
                    index: i,
                    c: _c,
                    manual: _manual,
                    animate: animate,
                    tk: tk,
                    minHeight: widget.compact ? 48 : 36,
                    fontSize: widget.compact ? 12.5 : 12.5,
                    onTap: () => select(i),
                    style: theme.textTheme.labelMedium,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _WindowBar extends StatelessWidget {
  const _WindowBar({required this.tk});
  final DesktopLoginTokens tk;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: tk.side,
        border: Border(bottom: BorderSide(color: tk.bd)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < 3; i++)
            Container(
              width: 9,
              height: 9,
              margin: const EdgeInsets.only(right: 6),
              decoration: BoxDecoration(color: tk.bd2, shape: BoxShape.circle),
            ),
          const Spacer(),
          Text('EsquemaCore',
              style: TextStyle(
                  fontSize: 11.5, color: tk.tx3, fontWeight: FontWeight.w500)),
          const Spacer(),
          const SizedBox(width: 45),
        ],
      ),
    );
  }
}

class _DotGridPainter extends CustomPainter {
  const _DotGridPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = color;
    for (var y = 9.0; y < size.height; y += 18) {
      for (var x = 9.0; x < size.width; x += 18) {
        canvas.drawCircle(Offset(x, y), .7, p);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DotGridPainter old) => old.color != color;
}

class _Legend extends StatelessWidget {
  const _Legend({
    required this.c,
    required this.manual,
    required this.animate,
    required this.tk,
  });

  final Animation<double> c;
  final int manual;
  final bool animate;
  final DesktopLoginTokens tk;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: c,
      builder: (_, __) {
        final i = animate ? (c.value * 4).floor().clamp(0, 3) : manual;
        final f = kDesktopLoginFeatures[i];
        return Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: tk.bd)),
          ),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: tk.rz,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tk.bd2),
                ),
                child: Icon(f.icon, size: 16, color: tk.tq),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text.rich(
                  TextSpan(children: [
                    TextSpan(
                      text: '${f.title}  ',
                      style:
                          TextStyle(color: tk.tx, fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: f.body, style: TextStyle(color: tk.tx2)),
                  ]),
                  style: const TextStyle(fontSize: 13.5, height: 1.35),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.index,
    required this.c,
    required this.manual,
    required this.animate,
    required this.tk,
    required this.minHeight,
    required this.fontSize,
    required this.onTap,
    required this.style,
  });

  final int index;
  final Animation<double> c;
  final int manual;
  final bool animate;
  final DesktopLoginTokens tk;
  final double minHeight;
  final double fontSize;
  final VoidCallback onTap;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final f = kDesktopLoginFeatures[index];
    return Semantics(
      button: true,
      label: f.title,
      child: InkWell(
        key: ValueKey('desktop_login_tab_$index'),
        borderRadius: BorderRadius.circular(4),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: minHeight),
          child: AnimatedBuilder(
            animation: c,
            builder: (_, __) {
              final cur = animate ? (c.value * 4).floor().clamp(0, 3) : manual;
              final on = cur == index;
              final frac = !on ? 0.0 : (animate ? (c.value * 4 - cur) : 1.0);
              return Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Container(
                      height: 3,
                      color: tk.bd2,
                      alignment: Alignment.centerLeft,
                      child: FractionallySizedBox(
                        widthFactor: frac.clamp(0.0, 1.0),
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(colors: [
                              DesktopLoginTokens.teal,
                              DesktopLoginTokens.blue,
                            ]),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  Row(
                    children: [
                      Icon(f.icon, size: 14, color: on ? tk.tx : tk.tx3),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          f.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: fontSize,
                            color: on ? tk.tx : tk.tx3,
                            fontWeight: on ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
