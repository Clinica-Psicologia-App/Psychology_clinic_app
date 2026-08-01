import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppShadows {
  static List<BoxShadow> get soft => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.06),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get card => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.05),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get elevated => [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ];

  /// Sombra dupla do claymorphism — um destaque claro (canto superior
  /// esquerdo) e uma sombra colorida mais funda (canto inferior direito),
  /// dando a sensação de que a superfície foi moldada/extrudada em vez de
  /// apenas flutuar sobre um fundo plano. Sem [accent], usa navy — sombra
  /// neutra para cards de conteúdo. Com [accent], a sombra ganha a cor do
  /// elemento — usado nos boxes de ícone que carregam identidade própria.
  static List<BoxShadow> clay([Color? accent]) => [
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.55),
          blurRadius: 6,
          offset: const Offset(-3, -3),
        ),
        BoxShadow(
          color: (accent ?? AppColors.navy)
              .withValues(alpha: accent != null ? 0.30 : 0.09),
          blurRadius: 16,
          offset: const Offset(4, 6),
        ),
      ];
}
