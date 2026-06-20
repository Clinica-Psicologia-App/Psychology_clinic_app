import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

abstract final class AppTypography {
  static TextTheme? _cached;

  static TextTheme textTheme() {
    return _cached ??= _buildTextTheme();
  }

  static TextTheme _buildTextTheme() {
    final base = GoogleFonts.poppinsTextTheme();
    TextStyle style(TextStyle? s, {Color? color, double? height}) {
      return (s ?? const TextStyle()).copyWith(
        fontFamily: 'Poppins',
        color: color,
        height: height,
      );
    }

    return base.copyWith(
      displayLarge: style(
        base.displayLarge,
        color: AppColors.textPrimary,
        height: 1.2,
      ),
      displayMedium: style(
        base.displayMedium,
        color: AppColors.textPrimary,
        height: 1.25,
      ),
      headlineLarge: style(
        base.headlineLarge,
        color: AppColors.textPrimary,
        height: 1.3,
      ),
      headlineMedium: style(
        base.headlineMedium,
        color: AppColors.textPrimary,
        height: 1.35,
      ),
      headlineSmall: style(base.headlineSmall, color: AppColors.textPrimary),
      titleLarge: style(base.titleLarge, color: AppColors.textPrimary),
      titleMedium: style(base.titleMedium, color: AppColors.textPrimary),
      titleSmall: style(base.titleSmall, color: AppColors.textPrimary),
      bodyLarge: style(
        base.bodyLarge,
        color: AppColors.textPrimary,
        height: 1.5,
      ),
      bodyMedium: style(
        base.bodyMedium,
        color: AppColors.textPrimary,
        height: 1.45,
      ),
      bodySmall: style(
        base.bodySmall,
        color: AppColors.textSecondary,
        height: 1.4,
      ),
      labelLarge: style(base.labelLarge, color: AppColors.textPrimary),
      labelMedium: style(base.labelMedium, color: AppColors.textSecondary),
      labelSmall: style(base.labelSmall, color: AppColors.textMuted),
    );
  }
}
