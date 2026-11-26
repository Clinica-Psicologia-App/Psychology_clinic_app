import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../../core/theme/app_branding_assets.dart';
import '../../../../../shared/widgets/app_motion.dart';
import 'desktop_login_background.dart';
import 'desktop_login_form_panel.dart';
import 'desktop_login_showcase.dart';
import 'desktop_login_title.dart';
import 'desktop_login_tokens.dart';

/// Casca do login desktop (C2): fundo vivo, cabeçalho com a marca, título,
/// vitrine animada e painel do formulário. Notebook/desktop em duas colunas;
/// tablet com a vitrine acima do painel.
class DesktopLoginShell extends StatelessWidget {
  const DesktopLoginShell({super.key, required this.formPanel});

  /// Painel do formulário (montado pela página, que guarda o estado).
  final Widget Function(DesktopLoginSize size) formPanel;

  @override
  Widget build(BuildContext context) {
    final tk = DesktopLoginTokens.of(context);
    return ColoredBox(
      color: tk.bg,
      child: LayoutBuilder(
        builder: (context, box) {
          final size = desktopLoginSizeOf(box.maxWidth);
          final tablet = size == DesktopLoginSize.tablet;
          // Altura mínima do conteúdo: abaixo disso a página rola (janela baixa).
          final minH = tablet ? 980.0 : 660.0;
          final content = _Content(size: size, formPanel: formPanel, tk: tk);
          return Stack(
            children: [
              const Positioned.fill(child: DesktopLoginBackground()),
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 3,
                child: DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: DesktopLoginTokens.brandGradient),
                ),
              ),
              Positioned.fill(
                child: box.maxHeight >= minH
                    ? content
                    : SingleChildScrollView(
                        child: SizedBox(height: minH, child: content),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.size,
    required this.formPanel,
    required this.tk,
  });

  final DesktopLoginSize size;
  final Widget Function(DesktopLoginSize size) formPanel;
  final DesktopLoginTokens tk;

  @override
  Widget build(BuildContext context) {
    final tablet = size == DesktopLoginSize.tablet;
    final big = size == DesktopLoginSize.desktop;
    final hPad = tablet ? 40.0 : (big ? 64.0 : 48.0);

    final editorial = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MotionReveal(
          child: Text(
            'FEITO PARA PSICÓLOGOS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: .88,
              color: tk.tq,
            ),
          ),
        ),
        const SizedBox(height: 6),
        MotionReveal(
          delay: const Duration(milliseconds: 70),
          child: DesktopLoginTitle(fontSize: tablet ? 44 : (big ? 88 : 58)),
        ),
        const SizedBox(height: 2),
        MotionReveal(
          delay: const Duration(milliseconds: 140),
          child: Text(
            'Entre para continuar seu trabalho com segurança.',
            style: TextStyle(
              fontSize: tablet ? 15 : (big ? 20 : 16),
              color: tk.tx2,
            ),
          ),
        ),
        SizedBox(height: tablet ? 12 : (big ? 28 : 16)),
        Expanded(
          child: MotionReveal(
            delay: const Duration(milliseconds: 210),
            child: DesktopLoginShowcase(compact: tablet),
          ),
        ),
      ],
    );

    final panel = MotionReveal(
      delay: const Duration(milliseconds: 140),
      child: formPanel(size),
    );

    return Column(
      children: [
        MotionReveal(
          child: Padding(
            padding: EdgeInsets.fromLTRB(hPad, 18, hPad, 10),
            child: Align(
              alignment: Alignment.centerLeft,
              child: _Brand(size: big ? 42 : 36, tk: tk),
            ),
          ),
        ),
        Expanded(
          child: tablet
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(40, 0, 40, 22),
                  child: Column(
                    children: [
                      Expanded(child: editorial),
                      const SizedBox(height: 22),
                      SizedBox(width: 480, child: panel),
                    ],
                  ),
                )
              : Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: big ? 1568 : 1440),
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          hPad, big ? 16 : 4, hPad, big ? 48 : 22),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(child: editorial),
                          SizedBox(width: big ? 96 : 56),
                          SizedBox(
                            width: big ? 520 : 440,
                            child: Center(
                              child: SingleChildScrollView(
                                child: panel,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
        MotionReveal(
          delay: const Duration(milliseconds: 280),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: hPad - 4, vertical: 4),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: tk.bd)),
            ),
            child: Row(
              children: [
                DesktopLoginLegalLinks(tk: tk),
                const Spacer(),
                _TrustRow(tk: tk),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _Brand extends StatelessWidget {
  const _Brand({required this.size, required this.tk});
  final double size;
  final DesktopLoginTokens tk;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * .14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size * .26),
            border: Border.all(color: tk.bd),
          ),
          child: Image.asset(AppBrandingAssets.icon, fit: BoxFit.contain),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(text: 'Esquema', style: TextStyle(color: tk.tx)),
                  TextSpan(text: 'Core', style: TextStyle(color: tk.tq)),
                ],
                style: TextStyle(
                  fontSize: size * .47,
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                  letterSpacing: -.01 * size * .47,
                ),
              ),
            ),
            Text(
              'seu raciocínio clínico em mapa',
              style: TextStyle(fontSize: math.max(10.5, size * .3), color: tk.tx2),
            ),
          ],
        ),
      ],
    );
  }
}

class _TrustRow extends StatelessWidget {
  const _TrustRow({required this.tk});
  final DesktopLoginTokens tk;

  @override
  Widget build(BuildContext context) {
    Widget item(IconData i, String t) => Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(i, size: 14, color: tk.tq),
              const SizedBox(width: 6),
              Text(t,
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: tk.tx2)),
            ],
          ),
        );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        item(Icons.lock_outline, 'Seguro'),
        item(Icons.verified_user_outlined, 'Profissional'),
        item(Icons.favorite_border, 'Clínico'),
      ],
    );
  }
}
