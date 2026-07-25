import 'package:flutter/material.dart';

/// Paleta oficial EsquemaCore + cores semânticas para UI clínica.
abstract final class AppColors {
  // Marca
  static const Color turquoise = Color(0xFF00B2A9);
  static const Color cyan = Color(0xFF0096D6);
  static const Color blue = Color(0xFF3B82F6);
  static const Color purple = Color(0xFF7B5CF6);
  static const Color navy = Color(0xFF0D1B3D);

  // Superfícies (light) — pastéis do Claymorphism
  static const Color background = Color(0xFFE9EEF9);
  static const Color surface = Color(0xFFFDFDFF);
  static const Color surfaceMuted = Color(0xFFDDE5F4);
  static const Color surfaceTint = Color(0xFFEFF3FC);

  // Tints de superfície por acento (fundos tonais suaves)
  static const Color surfaceTintTurquoise = Color(0xFFE6F7F6);
  static const Color surfaceTintBlue = Color(0xFFEAF1FE);
  static const Color surfaceTintPurple = Color(0xFFF0EDFE);

  // Texto
  static const Color textPrimary = navy;
  static const Color textSecondary = Color(0xFF4A5568);
  static const Color textMuted = Color(0xFF718096);
  static const Color textOnBrand = Color(0xFFFFFFFF);
  static const Color textOnTurquoise = navy;

  // Bordas — quase invisíveis no clay (profundidade vem das sombras)
  static const Color border = Color(0xFFE2E9F6);
  static const Color borderStrong = Color(0xFFCBD7EC);

  // Semânticas (não confundir com marca)
  static const Color success = Color(0xFF059669);
  static const Color successContainer = Color(0xFFD1FAE5);
  static const Color onSuccessContainer = Color(0xFF065F46);

  static const Color warning = Color(0xFFD97706);
  static const Color warningContainer = Color(0xFFFEF3C7);
  static const Color onWarningContainer = Color(0xFF92400E);

  static const Color error = Color(0xFFDC2626);
  static const Color errorContainer = Color(0xFFFEE2E2);
  static const Color onErrorContainer = Color(0xFF991B1B);

  static const Color info = Color(0xFF0284C7);
  static const Color infoContainer = Color(0xFFE0F2FE);
  static const Color onInfoContainer = Color(0xFF075985);

  static const Color disabled = Color(0xFF94A3B8);
  static const Color disabledSurface = Color(0xFFF1F5F9);

  // Acentos por módulo clínico (uso pontual)
  static const Color moduleQuestionnaires = blue;
  static const Color moduleMentalMap = purple;
  static const Color moduleCheckIn = turquoise;
  static const Color moduleTimeline = cyan;
  static const Color moduleGoals = turquoise;
  static const Color moduleProblems = warning;
  static const Color moduleResources = purple;
  static const Color moduleDashboard = navy;
  static const Color moduleMonitor = cyan;
  static const Color moduleGenogram = blue;
}
