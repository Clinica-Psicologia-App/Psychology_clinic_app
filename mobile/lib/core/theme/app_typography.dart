import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Escala tipográfica EsquemaCore.
///
/// Regras:
/// - Dois pesos de destaque no máximo: w600 para títulos e w700 apenas
///   para valores de métrica e o título de página. Nunca usar w800/w900.
/// - Metadata e captions são discretos (textMuted), nunca competem com
///   títulos.
/// - Números clínicos usam [metricValue] com tabular figures.
abstract final class AppTypography {
  static TextTheme? _cached;

  static TextTheme textTheme() {
    return _cached ??= _buildTextTheme();
  }

  static TextTheme _buildTextTheme() {
    final base = GoogleFonts.poppinsTextTheme();
    TextStyle style(
      TextStyle? s, {
      Color? color,
      double? size,
      FontWeight? weight,
      double? height,
      double? letterSpacing,
    }) {
      return (s ?? const TextStyle()).copyWith(
        fontFamily: 'Poppins',
        color: color,
        fontSize: size,
        fontWeight: weight,
        height: height,
        letterSpacing: letterSpacing,
      );
    }

    return base.copyWith(
      // Display — telas de marketing internas (login, onboarding).
      displayLarge: style(
        base.displayLarge,
        color: AppColors.textPrimary,
        size: 44,
        weight: FontWeight.w600,
        height: 1.15,
        letterSpacing: -0.5,
      ),
      displayMedium: style(
        base.displayMedium,
        color: AppColors.textPrimary,
        size: 36,
        weight: FontWeight.w600,
        height: 1.2,
        letterSpacing: -0.25,
      ),
      // Headline — título de página.
      headlineLarge: style(
        base.headlineLarge,
        color: AppColors.textPrimary,
        size: 28,
        weight: FontWeight.w600,
        height: 1.25,
      ),
      headlineMedium: style(
        base.headlineMedium,
        color: AppColors.textPrimary,
        size: 24,
        weight: FontWeight.w600,
        height: 1.3,
      ),
      headlineSmall: style(
        base.headlineSmall,
        color: AppColors.textPrimary,
        size: 20,
        weight: FontWeight.w600,
        height: 1.3,
      ),
      // Title — seções e cards.
      titleLarge: style(
        base.titleLarge,
        color: AppColors.textPrimary,
        size: 18,
        weight: FontWeight.w600,
        height: 1.35,
      ),
      titleMedium: style(
        base.titleMedium,
        color: AppColors.textPrimary,
        size: 16,
        weight: FontWeight.w600,
        height: 1.4,
      ),
      titleSmall: style(
        base.titleSmall,
        color: AppColors.textPrimary,
        size: 14,
        weight: FontWeight.w600,
        height: 1.4,
      ),
      // Body.
      bodyLarge: style(
        base.bodyLarge,
        color: AppColors.textPrimary,
        size: 16,
        weight: FontWeight.w400,
        height: 1.55,
      ),
      bodyMedium: style(
        base.bodyMedium,
        color: AppColors.textPrimary,
        size: 14,
        weight: FontWeight.w400,
        height: 1.5,
      ),
      bodySmall: style(
        base.bodySmall,
        color: AppColors.textSecondary,
        size: 12.5,
        weight: FontWeight.w400,
        height: 1.45,
      ),
      // Label — botões, chips, metadata.
      labelLarge: style(
        base.labelLarge,
        color: AppColors.textPrimary,
        size: 14,
        weight: FontWeight.w500,
        height: 1.4,
      ),
      labelMedium: style(
        base.labelMedium,
        color: AppColors.textSecondary,
        size: 12.5,
        weight: FontWeight.w500,
        height: 1.35,
      ),
      labelSmall: style(
        base.labelSmall,
        color: AppColors.textMuted,
        size: 11.5,
        weight: FontWeight.w500,
        height: 1.35,
        letterSpacing: 0.2,
      ),
    );
  }
}

/// Estilos semânticos que não têm slot no TextTheme do Material.
extension AppTextStyles on TextTheme {
  /// Valor numérico de métrica clínica (contadores, escores).
  TextStyle get metricValue => titleLarge!.copyWith(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  /// Rótulo discreto acima ou abaixo de uma métrica.
  TextStyle get metricLabel => labelSmall!.copyWith(
        color: AppColors.textSecondary,
      );

  /// Metadata: datas, contagens, informações auxiliares.
  TextStyle get metadata => labelSmall!;
}
