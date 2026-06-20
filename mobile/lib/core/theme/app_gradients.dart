import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppGradients {
  static const LinearGradient brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.turquoise,
      AppColors.blue,
      AppColors.purple,
    ],
  );

  static const LinearGradient brandHorizontal = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.turquoise,
      AppColors.cyan,
      AppColors.blue,
    ],
  );

  static const LinearGradient subtleSurface = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFF8FAFC),
      Color(0xFFF0F5FA),
    ],
  );

  static const LinearGradient splashBackground = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFFFFFFF),
      Color(0xFFF0F9FF),
      Color(0xFFEFF6FF),
    ],
  );

  static LinearGradient progress({double? stops}) => LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: const [
          AppColors.turquoise,
          AppColors.blue,
        ],
      );
}
