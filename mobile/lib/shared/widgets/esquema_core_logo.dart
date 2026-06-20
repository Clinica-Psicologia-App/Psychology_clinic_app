import 'package:flutter/material.dart';

import '../../core/theme/app_branding_assets.dart';
import '../../core/theme/app_gradients.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';

enum EsquemaCoreLogoVariant { stacked, horizontal, icon, monochrome }

/// Logo EsquemaCore com fallback seguro via [Image.asset].
class EsquemaCoreLogo extends StatelessWidget {
  const EsquemaCoreLogo({
    super.key,
    this.size = 72,
    this.showName = false,
    this.showTagline = false,
    this.variant = EsquemaCoreLogoVariant.stacked,
    this.nameColor,
    this.taglineColor,
  }) : _isHorizontalConstructor = false;

  const EsquemaCoreLogo.horizontal({
    super.key,
    this.size = 40,
    this.showName = false,
    this.showTagline = false,
    this.nameColor,
    this.taglineColor,
  })  : variant = EsquemaCoreLogoVariant.horizontal,
        _isHorizontalConstructor = true;

  /// Mark compacto (ícone oficial).
  const EsquemaCoreLogo.icon({
    super.key,
    this.size = 40,
    this.showName = false,
    this.showTagline = false,
    this.nameColor,
    this.taglineColor,
  })  : variant = EsquemaCoreLogoVariant.icon,
        _isHorizontalConstructor = false;

  /// Versão monocromática para fundos escuros / gradiente de marca.
  const EsquemaCoreLogo.monochrome({
    super.key,
    this.size = 72,
    this.showName = false,
    this.showTagline = false,
    this.nameColor,
    this.taglineColor,
  })  : variant = EsquemaCoreLogoVariant.monochrome,
        _isHorizontalConstructor = false;

  final double size;
  final bool showName;
  final bool showTagline;
  final EsquemaCoreLogoVariant variant;
  final Color? nameColor;
  final Color? taglineColor;
  final bool _isHorizontalConstructor;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final nameStyle = textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.5,
      color: nameColor,
    );
    final taglineStyle = textTheme.bodySmall?.copyWith(
      color: taglineColor ?? Theme.of(context).colorScheme.onSurfaceVariant,
    );

    if (variant == EsquemaCoreLogoVariant.horizontal ||
        _isHorizontalConstructor) {
      return _LogoColumn(
        image: _LogoImage(
          assetPath: AppBrandingAssets.logoHorizontal,
          width: size * 3.2,
          height: size,
          fallbackSize: size,
        ),
        showName: showName,
        showTagline: showTagline,
        nameStyle: nameStyle,
        taglineStyle: taglineStyle,
        crossAxisAlignment: CrossAxisAlignment.start,
        direction: Axis.horizontal,
      );
    }

    if (variant == EsquemaCoreLogoVariant.icon) {
      return _LogoImage(
        assetPath: AppBrandingAssets.icon,
        width: size,
        height: size,
        fallbackSize: size,
      );
    }

    final assetPath = variant == EsquemaCoreLogoVariant.monochrome
        ? AppBrandingAssets.logoMonochrome
        : AppBrandingAssets.logoPrincipal;

    final imageWidth =
        variant == EsquemaCoreLogoVariant.stacked ? size * 2.6 : size;

    return _LogoColumn(
      image: _LogoImage(
        assetPath: assetPath,
        width: imageWidth,
        height: size,
        fallbackSize: size,
      ),
      showName: showName,
      showTagline: showTagline,
      nameStyle: nameStyle,
      taglineStyle: taglineStyle,
      crossAxisAlignment: CrossAxisAlignment.center,
      direction: Axis.vertical,
    );
  }
}

class _LogoColumn extends StatelessWidget {
  const _LogoColumn({
    required this.image,
    required this.showName,
    required this.showTagline,
    required this.nameStyle,
    required this.taglineStyle,
    required this.crossAxisAlignment,
    required this.direction,
  });

  final Widget image;
  final bool showName;
  final bool showTagline;
  final TextStyle? nameStyle;
  final TextStyle? taglineStyle;
  final CrossAxisAlignment crossAxisAlignment;
  final Axis direction;

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          image,
          if (showName || showTagline) ...[
            const SizedBox(width: AppSpacing.sm),
            Flexible(
              child: Column(
                crossAxisAlignment: crossAxisAlignment,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (showName) Text(AppTheme.appName, style: nameStyle),
                  if (showTagline)
                    Text(AppTheme.appTagline, style: taglineStyle),
                ],
              ),
            ),
          ],
        ],
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        image,
        if (showName) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(AppTheme.appName, style: nameStyle, textAlign: TextAlign.center),
        ],
        if (showTagline) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            AppTheme.appTagline,
            style: taglineStyle,
            textAlign: TextAlign.center,
          ),
        ],
      ],
    );
  }
}

class _LogoImage extends StatelessWidget {
  const _LogoImage({
    required this.assetPath,
    required this.width,
    required this.height,
    required this.fallbackSize,
  });

  final String assetPath;
  final double width;
  final double height;
  final double fallbackSize;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: AppTheme.appName,
      image: true,
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          assetPath,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => _FallbackMark(size: fallbackSize),
        ),
      ),
    );
  }
}

class _FallbackMark extends StatelessWidget {
  const _FallbackMark({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: AppRadius.lgAll,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00B2A9).withValues(alpha: 0.35),
            blurRadius: size * 0.2,
            offset: Offset(0, size * 0.06),
          ),
        ],
      ),
      child: Icon(
        Icons.hub_outlined,
        size: size * 0.48,
        color: Colors.white,
      ),
    );
  }
}
