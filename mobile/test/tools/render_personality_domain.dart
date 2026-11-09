// Renderiza a navegação Mapa Mental → domínio → facetas → guia clínico.
//
//   flutter test test/tools/render_personality_domain.dart
//
// Saída: build/personality_sheet.png, personality_domain.png, personality_guide.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/psychoeducation/domain/psychoeducation_module.dart';
import 'package:terapia_esquema/features/psychoeducation/presentation/schema_card_link.dart';
import 'package:terapia_esquema/features/psychoeducation/providers/psychoeducation_providers.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_node_detail.dart';
import 'package:terapia_esquema/features/mental_map/presentation/widgets/mental_map_widgets.dart';
import 'package:terapia_esquema/features/personality_assessment/domain/personality_assessment.dart';
import 'package:terapia_esquema/features/personality_assessment/domain/personality_instrument.dart';
import 'package:terapia_esquema/features/personality_assessment/presentation/personality_domain_facets_page.dart';
import 'package:terapia_esquema/features/personality_reference/presentation/personality_reference_page.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    await ui.loadFontFromList(
      File('$dir\\materialicons-regular.otf').readAsBytesSync(),
      fontFamily: 'MaterialIcons',
    );
    for (final f in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
      'roboto-black.ttf'
    ]) {
      await ui.loadFontFromList(
        File('$dir\\$f').readAsBytesSync(),
        fontFamily: 'Roboto',
      );
    }
  });

  schemaSheetTest();

  Future<void> shot(WidgetTester tester, String name, Widget child,
      {int waitMs = 900}) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: RepaintBoundary(key: const Key('cap'), child: child),
      ),
    );
    await tester.pump();
    for (var i = 0; i < waitMs ~/ 100; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pump(const Duration(milliseconds: 400));
    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/$name.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/$name.png');
  }

  ScoreEntry t(num s) => ScoreEntry(score: s);

  testWidgets('folha do nó Personalidade com os 5 domínios', (tester) async {
    await shot(
      tester,
      'personality_sheet',
      Scaffold(
        backgroundColor: Colors.black12,
        body: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.white,
            child: MentalMapNodeDetailSheet(
              detail: const MentalMapNodeDetail(
                id: 'personality',
                title: 'Personalidade',
                items: [
                  'Neuroticismo: Alto',
                  'Extroversão: Médio',
                  'Abertura à experiência: Médio',
                  'Amabilidade: Baixo',
                  'Conscienciosidade: Médio',
                ],
                itemKeys: [
                  'neuroticism',
                  'extraversion',
                  'openness',
                  'agreeableness',
                  'conscientiousness',
                ],
                dataSource: 'NEO PI-R - avaliação de personalidade',
                ctaLabel: 'Abrir avaliação de personalidade',
              ),
              onPrimaryTap: () {},
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );
  });

  testWidgets('facetas do domínio Neuroticismo', (tester) async {
    final result = DomainResult(
      overall: t(62),
      facets: {
        'anxiety': t(64),
        'anger': t(66),
        'depression': t(50),
        'self_consciousness': t(52),
        'impulsiveness': t(47),
        'vulnerability': t(40),
      },
    );
    await shot(
      tester,
      'personality_domain',
      Scaffold(
        body: PersonalityDomainFacetsBody(
          role: ProfileRole.psychologist,
          patientId: 'p1',
          domainIndex: 0,
          domain: kNeoPiR.domains.first,
          result: result,
        ),
      ),
    );
  });

  testWidgets('guia clínico aberto na faceta Ansiedade', (tester) async {
    await shot(
      tester,
      'personality_guide',
      const StaffPersonalityReferencePage(
        role: ProfileRole.psychologist,
        patientId: 'p1',
        focusFactor: 0,
        focusFacet: 0,
      ),
      waitMs: 6000,
    );
  });
}

// ── Esquemas: botão "Ver card" na folha do nó ────────────────────────────
void schemaSheetTest() {
  testWidgets('folha do nó Esquemas com Ver card', (tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    final module = PsychoeducationModule(
      id: 'm8',
      number: 8,
      stage: 'Compreender',
      title: 'Conhecendo os 18 Esquemas',
      cards: const [],
    );
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          psychoeducationJourneyProvider.overrideWith((ref) async => [module]),
        ],
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(fontFamily: 'Roboto'),
          home: RepaintBoundary(
            key: const Key('cap'),
            child: Scaffold(
              backgroundColor: Colors.black12,
              body: Align(
                alignment: Alignment.bottomCenter,
                child: Material(
                  color: Colors.white,
                  child: MentalMapNodeDetailSheet(
                    detail: const MentalMapNodeDetail(
                      id: 'schemas',
                      title: 'Esquemas',
                      items: [
                        'Abandono/Instabilidade: 4.2',
                        'Defectividade/Vergonha: 3.9',
                        'Padrões inflexíveis/Crítica exagerada: 3.7',
                      ],
                      itemKeys: [
                        'YSQ_SCHEMA_ABANDONMENT_INSTABILITY',
                        'YSQ_SCHEMA_DEFECTIVENESS_SHAME',
                        'YSQ_SCHEMA_UNRELENTING_STANDARDS',
                      ],
                      dataSource: 'Questionário de Esquemas (YSQ)',
                      ctaLabel: 'Abrir questionário',
                    ),
                    onPrimaryTap: () {},
                    itemTrailingBuilder: (code) => SchemaCardButton(
                      schemaCode: code,
                      role: ProfileRole.patient,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/schemas_sheet.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/schemas_sheet.png');
  });
}
