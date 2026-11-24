import 'package:flutter/material.dart';

/// Tokens do login desktop (C2). Cores = identidade do app (CONTEXTO.md);
/// o escuro segue o protótipo `desktop_v2`.
class DesktopLoginTokens {
  const DesktopLoginTokens({
    required this.bg,
    required this.rz,
    required this.side,
    required this.bd,
    required this.bd2,
    required this.tx,
    required this.tx2,
    required this.tx3,
    required this.ac,
    required this.onAc,
    required this.foc,
    required this.tq,
    required this.lk,
    required this.err,
    required this.hov,
    required this.dark,
  });

  final Color bg;
  final Color rz;
  final Color side;
  final Color bd;
  final Color bd2;
  final Color tx;
  final Color tx2;
  final Color tx3;
  final Color ac;
  final Color onAc;
  final Color foc;
  final Color tq;
  final Color lk;
  final Color err;
  final Color hov;
  final bool dark;

  static const light = DesktopLoginTokens(
    bg: Color(0xFFFDFDFF),
    rz: Color(0xFFFFFFFF),
    side: Color(0xFFEFF3FC),
    bd: Color(0xFFE2E9F6),
    bd2: Color(0xFFCBD7EC),
    tx: Color(0xFF0D1B3D),
    tx2: Color(0xFF4A5568),
    tx3: Color(0xFF718096),
    ac: Color(0xFF0D1B3D),
    onAc: Color(0xFFFFFFFF),
    foc: Color(0xFF0EA5A0),
    tq: Color(0xFF00A39B),
    lk: Color(0xFF0284C7),
    err: Color(0xFFDC2626),
    hov: Color(0xFFEFF3FC),
    dark: false,
  );

  static const darkTheme = DesktopLoginTokens(
    bg: Color(0xFF1A2130),
    rz: Color(0xFF232D3F),
    side: Color(0xFF232D3F),
    bd: Color(0xFF2D3B55),
    bd2: Color(0xFF3D4D6C),
    tx: Color(0xFFEDF1FA),
    tx2: Color(0xFFB0BDD5),
    tx3: Color(0xFF7C8CA8),
    ac: Color(0xFFEDF1FA),
    onAc: Color(0xFF0D1B3D),
    foc: Color(0xFF0EA5A0),
    tq: Color(0xFF4FD1C5),
    lk: Color(0xFF7DD3FC),
    err: Color(0xFFF87171),
    hov: Color(0xFF2A3449),
    dark: true,
  );

  static DesktopLoginTokens of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTheme : light;

  static const teal = Color(0xFF00B2A9);
  static const blue = Color(0xFF3B82F6);
  static const purple = Color(0xFF7B5CF6);
  static const cyan = Color(0xFF0096D6);

  /// Faixa de 3 px com o gradiente da marca (topo da página e do painel).
  static const brandGradient = LinearGradient(colors: [teal, blue, purple]);
}

/// Pontos de quebra do login: tablet (768–1023), notebook e desktop (≥ 1440).
enum DesktopLoginSize { tablet, notebook, desktop }

DesktopLoginSize desktopLoginSizeOf(double width) {
  if (width >= 1440) return DesktopLoginSize.desktop;
  if (width >= 1024) return DesktopLoginSize.notebook;
  return DesktopLoginSize.tablet;
}
