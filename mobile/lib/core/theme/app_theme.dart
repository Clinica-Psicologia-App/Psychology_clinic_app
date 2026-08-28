import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_animations.dart';
import 'app_radius.dart';
import 'app_spacing.dart';
import 'app_typography.dart';

// Superfícies dark — tom slate-azul (menos navy/preto, mais cinza-azulado)
abstract final class _Dark {
  static const background = Color(0xFF1A2130);  // escuro mas não preto
  static const surface = Color(0xFF232D3F);     // cards visivelmente mais claros
  static const surfaceElevated = Color(0xFF2A3449); // modais, cards sobre cards
  static const surfaceMuted = Color(0xFF2E3A50); // faixas e separadores
  static const surfaceTint = Color(0xFF202C3E);
  static const textPrimary = Color(0xFFEDF1FA);  // branco quase puro com toque azul
  static const textSecondary = Color(0xFFB0BDD5); // leitura confortável
  static const textMuted = Color(0xFF7C8CA8);
  static const border = Color(0xFF2D3B55);
  static const borderStrong = Color(0xFF3B4F6E);
}

abstract final class AppTheme {
  static const String appName = 'EsquemaCore';
  static const String appTagline = 'seu raciocínio clínico em mapa';

  static final ThemeData light = _buildLightTheme();
  static final ThemeData dark = _buildDarkTheme();

  static ThemeData _buildLightTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.turquoise,
      onPrimary: AppColors.textOnTurquoise,
      primaryContainer: Color(0xFFB2F0EB),
      onPrimaryContainer: AppColors.navy,
      secondary: AppColors.cyan,
      onSecondary: AppColors.textOnBrand,
      secondaryContainer: Color(0xFFBAE6FD),
      onSecondaryContainer: AppColors.navy,
      tertiary: AppColors.purple,
      onTertiary: AppColors.textOnBrand,
      tertiaryContainer: Color(0xFFDDD6FE),
      onTertiaryContainer: AppColors.navy,
      error: AppColors.error,
      onError: AppColors.textOnBrand,
      errorContainer: AppColors.errorContainer,
      onErrorContainer: AppColors.onErrorContainer,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      onSurfaceVariant: AppColors.textSecondary,
      outline: AppColors.border,
      outlineVariant: AppColors.borderStrong,
      shadow: AppColors.navy,
      scrim: AppColors.navy,
      inverseSurface: AppColors.navy,
      onInverseSurface: AppColors.textOnBrand,
      inversePrimary: AppColors.turquoise,
      surfaceContainerHighest: AppColors.surfaceMuted,
      surfaceContainerHigh: AppColors.surfaceTint,
      surfaceContainer: AppColors.surfaceTint,
      surfaceContainerLow: AppColors.background,
      surfaceContainerLowest: AppColors.surface,
    );

    final textTheme = AppTypography.textTheme();

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: AppColors.background,
      textTheme: textTheme,
      fontFamily: 'Poppins',
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.navy,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: AppColors.navy,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      // Rede de segurança para qualquer ClayCard() remanescente — o padrão do
      // app é o claymorphism de ClayCard (sombra dupla, sem borda), então a
      // elevação Material fica em 0 aqui para não competir com ela.
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: AppColors.navy.withValues(alpha: 0.08),
        color: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _AppPageTransitionsBuilder(),
          TargetPlatform.iOS: _AppPageTransitionsBuilder(),
          TargetPlatform.macOS: _AppPageTransitionsBuilder(),
          TargetPlatform.windows: _AppPageTransitionsBuilder(),
          TargetPlatform.linux: _AppPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.focusRing, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        labelStyle:
            textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        errorStyle: textTheme.bodySmall?.copyWith(color: AppColors.error),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.navy,
          foregroundColor: AppColors.textOnBrand,
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.navy,
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          side: const BorderSide(color: AppColors.borderStrong),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.cyan,
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.navy,
        foregroundColor: AppColors.textOnBrand,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surfaceElevated,
        selectedColor: const Color(0xFFB2F0EB),
        labelStyle: textTheme.labelSmall,
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: const WidgetStatePropertyAll(AppColors.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        overlayColor: WidgetStatePropertyAll(
          AppColors.turquoise.withValues(alpha: 0.05),
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: AppColors.border),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        textStyle: WidgetStatePropertyAll(textTheme.bodyMedium),
        hintStyle: WidgetStatePropertyAll(
          textTheme.bodyMedium?.copyWith(color: AppColors.textMuted),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: AppColors.border,
        indicatorColor: AppColors.navy,
        labelColor: AppColors.navy,
        unselectedLabelColor: AppColors.textMuted,
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: const Color(0xFFB2F0EB),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.navy,
            );
          }
          return textTheme.labelSmall?.copyWith(color: AppColors.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.navy, size: 24);
          }
          return const IconThemeData(color: AppColors.textMuted, size: 24);
        }),
        height: 72,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.navy,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: AppColors.textOnBrand),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.turquoise,
        linearTrackColor: AppColors.surfaceMuted,
        circularTrackColor: AppColors.surfaceMuted,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.turquoise,
        inactiveTrackColor: AppColors.surfaceMuted,
        thumbColor: AppColors.navy,
        overlayColor: AppColors.turquoise.withValues(alpha: 0.12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.surface;
          }
          return AppColors.surface;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.turquoise;
          }
          return AppColors.border;
        }),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        minVerticalPadding: AppSpacing.sm,
        iconColor: AppColors.cyan,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: AppColors.infoContainer,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: AppColors.onInfoContainer,
        ),
      ),
    );
  }

  static ThemeData _buildDarkTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppColors.turquoise,
      onPrimary: AppColors.navy,
      primaryContainer: Color(0xFF005753),
      onPrimaryContainer: Color(0xFFB2F0EB),
      secondary: AppColors.cyan,
      onSecondary: Colors.white,
      secondaryContainer: Color(0xFF004D75),
      onSecondaryContainer: Color(0xFFBAE6FD),
      tertiary: AppColors.purple,
      onTertiary: Colors.white,
      tertiaryContainer: Color(0xFF3B2D8A),
      onTertiaryContainer: Color(0xFFDDD6FE),
      error: Color(0xFFFF6B6B),
      onError: Color(0xFF5C0202),
      errorContainer: Color(0xFF4C1515),
      onErrorContainer: Color(0xFFFECDCD),
      surface: _Dark.surface,
      onSurface: _Dark.textPrimary,
      onSurfaceVariant: _Dark.textSecondary,
      outline: _Dark.border,
      outlineVariant: _Dark.borderStrong,
      shadow: Colors.black,
      scrim: Colors.black,
      inverseSurface: _Dark.textPrimary,
      onInverseSurface: AppColors.navy,
      inversePrimary: Color(0xFF005753),
      surfaceContainerHighest: _Dark.surfaceMuted,
      surfaceContainerHigh: _Dark.surfaceTint,
      surfaceContainer: _Dark.surfaceTint,
      surfaceContainerLow: _Dark.background,
      surfaceContainerLowest: Color(0xFF0A0F1A),
    );

    final textTheme = AppTypography.textTheme().apply(
      bodyColor: _Dark.textPrimary,
      displayColor: _Dark.textPrimary,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: _Dark.background,
      textTheme: textTheme,
      fontFamily: 'Poppins',
      appBarTheme: AppBarTheme(
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        backgroundColor: _Dark.background,
        foregroundColor: _Dark.textPrimary,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          color: _Dark.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        color: _Dark.surface,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: _AppPageTransitionsBuilder(),
          TargetPlatform.iOS: _AppPageTransitionsBuilder(),
          TargetPlatform.macOS: _AppPageTransitionsBuilder(),
          TargetPlatform.windows: _AppPageTransitionsBuilder(),
          TargetPlatform.linux: _AppPageTransitionsBuilder(),
        },
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _Dark.surfaceElevated,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + 2,
        ),
        border: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: _Dark.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: _Dark.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: AppColors.focusRing, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: Color(0xFFFF6B6B)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.mdAll,
          borderSide: const BorderSide(color: Color(0xFFFF6B6B), width: 2),
        ),
        labelStyle: textTheme.bodyMedium?.copyWith(color: _Dark.textSecondary),
        hintStyle: textTheme.bodyMedium?.copyWith(color: _Dark.textMuted),
        errorStyle: textTheme.bodySmall?.copyWith(color: const Color(0xFFFF6B6B)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.turquoise,
          foregroundColor: AppColors.navy,
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.turquoise,
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.sm,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          side: const BorderSide(color: _Dark.borderStrong),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.turquoise,
          minimumSize: const Size(0, AppSpacing.minTouchTarget),
          textStyle:
              textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.turquoise,
        foregroundColor: AppColors.navy,
        elevation: 2,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppRadius.lg)),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: _Dark.surfaceElevated,
        selectedColor: const Color(0xFF005753),
        labelStyle: textTheme.labelSmall,
        side: const BorderSide(color: _Dark.border),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.smAll),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      ),
      searchBarTheme: SearchBarThemeData(
        elevation: const WidgetStatePropertyAll(0),
        backgroundColor: const WidgetStatePropertyAll(_Dark.surface),
        surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        overlayColor: WidgetStatePropertyAll(
          AppColors.turquoise.withValues(alpha: 0.08),
        ),
        side: const WidgetStatePropertyAll(
          BorderSide(color: _Dark.border),
        ),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: AppSpacing.md),
        ),
        textStyle: WidgetStatePropertyAll(textTheme.bodyMedium),
        hintStyle: WidgetStatePropertyAll(
          textTheme.bodyMedium?.copyWith(color: _Dark.textMuted),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        dividerColor: _Dark.border,
        indicatorColor: AppColors.turquoise,
        labelColor: AppColors.turquoise,
        unselectedLabelColor: _Dark.textMuted,
        labelStyle: textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: textTheme.labelLarge,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _Dark.surface,
        indicatorColor: const Color(0xFF005753),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppColors.turquoise,
            );
          }
          return textTheme.labelSmall?.copyWith(color: _Dark.textMuted);
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.turquoise, size: 24);
          }
          return const IconThemeData(color: _Dark.textMuted, size: 24);
        }),
        height: 72,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: _Dark.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _Dark.surfaceElevated,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        ),
        showDragHandle: true,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: _Dark.surfaceMuted,
        contentTextStyle:
            textTheme.bodyMedium?.copyWith(color: _Dark.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      dividerTheme: const DividerThemeData(
        color: _Dark.border,
        thickness: 1,
        space: 1,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.turquoise,
        linearTrackColor: _Dark.surfaceMuted,
        circularTrackColor: _Dark.surfaceMuted,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.turquoise,
        inactiveTrackColor: _Dark.surfaceMuted,
        thumbColor: AppColors.turquoise,
        overlayColor: AppColors.turquoise.withValues(alpha: 0.12),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return _Dark.surface;
          return _Dark.surfaceMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.turquoise;
          return _Dark.border;
        }),
      ),
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        minVerticalPadding: AppSpacing.sm,
        iconColor: AppColors.turquoise,
        titleTextStyle: textTheme.titleMedium,
        subtitleTextStyle: textTheme.bodySmall,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
      ),
      bannerTheme: MaterialBannerThemeData(
        backgroundColor: const Color(0xFF004D75),
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: const Color(0xFFBAE6FD),
        ),
      ),
    );
  }
}

class _AppPageTransitionsBuilder extends PageTransitionsBuilder {
  const _AppPageTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (route.settings.name == Navigator.defaultRouteName ||
        !AppAnimations.shouldAnimate(context)) {
      return child;
    }

    final curved = CurvedAnimation(
      parent: animation,
      curve: AppAnimations.enterCurve,
      reverseCurve: AppAnimations.exitCurve,
    );
    final secondaryCurved = CurvedAnimation(
      parent: secondaryAnimation,
      curve: AppAnimations.standardCurve,
    );

    // Fade-through: a tela que entra surge com fade + leve scale; a tela
    // que fica embaixo recua discretamente quando outra é empilhada.
    return FadeTransition(
      opacity: curved,
      child: ScaleTransition(
        scale: Tween<double>(begin: 0.985, end: 1).animate(curved),
        child: FadeTransition(
          opacity: Tween<double>(begin: 1, end: 0.6).animate(secondaryCurved),
          child: ScaleTransition(
            scale: Tween<double>(begin: 1, end: 0.99).animate(secondaryCurved),
            child: child,
          ),
        ),
      ),
    );
  }
}
