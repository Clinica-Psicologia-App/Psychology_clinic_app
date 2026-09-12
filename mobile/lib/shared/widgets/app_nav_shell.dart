import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_branding_assets.dart';
import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';

/// Destino de navegação do shell lateral.
class AppNavDestination {
  const AppNavDestination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.route,
    this.exactMatch = false,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String route;

  /// Quando true, só seleciona se a localização for exatamente [route]
  /// (usado para a home, que é prefixo de todas as outras).
  final bool exactMatch;

  bool matches(String location) {
    if (exactMatch) return location == route;
    return location == route || location.startsWith('$route/');
  }
}

/// Shell persistente de navegação por papel.
///
/// Em telas largas exibe uma NavigationRail fixa à esquerda do conteúdo;
/// em telas compactas renderiza apenas o conteúdo (a navegação continua
/// pelos fluxos das próprias telas). Os paths das rotas não mudam — o
/// shell apenas envolve a subárvore no go_router.
class AppNavShell extends StatelessWidget {
  const AppNavShell({
    super.key,
    required this.destinations,
    required this.child,
  });

  final List<AppNavDestination> destinations;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!AppBreakpoints.isWide(context)) return child;

    final location = GoRouterState.of(context).matchedLocation;
    var selectedIndex =
        destinations.indexWhere((d) => !d.exactMatch && d.matches(location));
    if (selectedIndex < 0) {
      selectedIndex = destinations.indexWhere((d) => d.matches(location));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SafeArea(
          child: NavigationRail(
            backgroundColor: Theme.of(context).colorScheme.surface,
            selectedIndex: selectedIndex < 0 ? null : selectedIndex,
            extended: true,
            minExtendedWidth: 220,
            leading: const _NavBrandHeader(),
            onDestinationSelected: (index) {
              final destination = destinations[index];
              if (!destination.matches(location) || destination.exactMatch) {
                context.go(destination.route);
              }
            },
            destinations: [
              for (final destination in destinations)
                NavigationRailDestination(
                  icon: Icon(destination.icon),
                  selectedIcon: Icon(destination.selectedIcon),
                  label: Text(destination.label),
                ),
            ],
          ),
        ),
        const VerticalDivider(width: 1),
        Expanded(child: child),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Cabeçalho de marca do sidebar web
// ---------------------------------------------------------------------------

class _NavBrandHeader extends StatelessWidget {
  const _NavBrandHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.xl,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Ícone com sombra colorida
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1A2A3A)
                  : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppColors.turquoise.withValues(alpha: 0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              AppBrandingAssets.icon,
              fit: BoxFit.contain,
            ),
          ),

          const SizedBox(height: AppSpacing.md),

          // Nome com cores de marca
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'Esquema',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
                TextSpan(
                  text: 'Core',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.turquoise,
                    letterSpacing: -0.3,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 3),

          // Tagline
          Text(
            'raciocínio clínico em mapa',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 0.1,
            ),
          ),

          const SizedBox(height: AppSpacing.lg),

          // Divisória suave
          Divider(
            height: 1,
            thickness: 1,
            color: theme.colorScheme.outlineVariant,
          ),
        ],
      ),
    );
  }
}
