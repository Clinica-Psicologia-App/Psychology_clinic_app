import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_breakpoints.dart';
import 'esquema_core_logo.dart';

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
            labelType: NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: EsquemaCoreLogo(size: 36),
            ),
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
