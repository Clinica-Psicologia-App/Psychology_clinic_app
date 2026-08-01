import 'package:flutter/material.dart';

abstract final class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration emphasis = Duration(milliseconds: 400);
  static const Duration kpi = Duration(milliseconds: 320);
  static const Duration bar = Duration(milliseconds: 420);
  static const Duration section = Duration(milliseconds: 220);

  // Classificadas por propósito ("Living Clinical Map") — usar estas em
  // composições novas; os nomes acima seguem servindo o código existente.
  /// Feedback imediato: seleção, press, chips.
  static const Duration micro = Duration(milliseconds: 140);

  /// Superfícies interativas reagindo a hover/foco.
  static const Duration hover = Duration(milliseconds: 180);

  /// Entrada de blocos, troca de pergunta, revelação estrutural.
  static const Duration block = Duration(milliseconds: 300);

  /// Transição de página.
  static const Duration page = Duration(milliseconds: 320);

  /// Bottom sheets e modais.
  static const Duration sheet = Duration(milliseconds: 360);

  /// Celebração pontual (ex.: conclusão de questionário). Não bloqueia navegação.
  static const Duration celebration = Duration(milliseconds: 900);

  /// Loop ambiental (respiração, glow). Máx. 1–2 controllers ativos por tela.
  static const Duration ambient = Duration(milliseconds: 6000);

  static const Curve standardCurve = Curves.easeOutCubic;
  static const Curve enterCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;

  /// Respeita preferência de redução de movimento do sistema.
  static Duration resolve(BuildContext context, Duration duration) {
    final disable = MediaQuery.disableAnimationsOf(context);
    return disable ? Duration.zero : duration;
  }

  static bool shouldAnimate(BuildContext context) {
    return !MediaQuery.disableAnimationsOf(context);
  }
}
