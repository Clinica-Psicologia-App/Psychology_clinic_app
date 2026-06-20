import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_branding_assets.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_case_map.dart';
import 'package:terapia_esquema/features/mental_map/presentation/mental_map_node_state.dart';
import 'package:terapia_esquema/shared/widgets/esquema_core_logo.dart';

void main() {
  testWidgets('EsquemaCoreLogo renders official asset and tagline',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EsquemaCoreLogo(showTagline: true),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(AppTheme.appTagline), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.hub_outlined), findsNothing);
  });

  testWidgets('EsquemaCoreLogo horizontal variant builds', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light,
        home: const Scaffold(
          body: EsquemaCoreLogo.horizontal(size: 32),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(EsquemaCoreLogo), findsOneWidget);
  });

  test('AppBrandingAssets uses official filenames', () {
    expect(AppBrandingAssets.logoPrincipal,
        contains('esquema_core_logo_principal.png'));
    expect(AppBrandingAssets.logoHorizontal,
        contains('esquema_core_logo_horizontal.png'));
    expect(AppBrandingAssets.icon, contains('esquema_core_icon.png'));
    expect(AppBrandingAssets.logoMonochrome,
        contains('esquema_core_logo_monochrome.png'));
  });

  test('AppTheme exposes brand constants', () {
    expect(AppTheme.appName, 'EsquemaCore');
    expect(AppTheme.appTagline, isNotEmpty);
    expect(AppTheme.light.useMaterial3, isTrue);
  });

  test('resolveMentalMapNodeVisualState derives pending and filled', () {
    const pending = MentalCaseMapNode(
      id: 'schemas',
      title: 'Esquemas',
      shortLabel: 'Pendente',
      items: [],
      emptyLabel: 'Pendente',
      dataSource: 'test',
    );
    const filled = MentalCaseMapNode(
      id: 'schemas',
      title: 'Esquemas',
      shortLabel: 'Preenchido',
      items: ['Abandono 5.0', 'Privação 4.0'],
      emptyLabel: 'Pendente',
      dataSource: 'test',
    );

    expect(resolveMentalMapNodeVisualState(pending),
        MentalMapNodeVisualState.pending);
    expect(
      resolveMentalMapNodeVisualState(filled),
      MentalMapNodeVisualState.filled,
    );
  });
}
