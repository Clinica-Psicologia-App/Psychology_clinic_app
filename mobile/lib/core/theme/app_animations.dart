import 'package:flutter/material.dart';

abstract final class AppAnimations {
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration standard = Duration(milliseconds: 250);
  static const Duration emphasis = Duration(milliseconds: 400);
  static const Duration kpi = Duration(milliseconds: 320);
  static const Duration bar = Duration(milliseconds: 420);
  static const Duration section = Duration(milliseconds: 220);

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
