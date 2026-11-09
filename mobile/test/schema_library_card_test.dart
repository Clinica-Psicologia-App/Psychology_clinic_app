import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/domain/schema_catalog.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/psychoeducation/domain/psychoeducation_module.dart';
import 'package:terapia_esquema/features/psychoeducation/domain/schema_library_card.dart';
import 'package:terapia_esquema/features/psychoeducation/presentation/psychoeducation_module_page.dart';
import 'package:terapia_esquema/features/psychoeducation/presentation/psychoeducation_routes.dart';
import 'package:terapia_esquema/features/psychoeducation/providers/psychoeducation_providers.dart';

void main() {
  group('tabela esquema → card da Biblioteca 8', () {
    test('cobre os 18 esquemas do catálogo, sem repetir nem faltar', () {
      expect(kSchemaLibraryOrder.length, 18);
      expect(kSchemaLibraryOrder.toSet().length, 18);
      expect(kSchemaLibraryOrder.toSet(), kSchemaCatalog.keys.toSet());
    });

    test('os esquemas ocupam os cards 4 a 21, na ordem da biblioteca', () {
      expect(
          schemaLibraryCardNumber('YSQ_SCHEMA_ABANDONMENT_INSTABILITY'), 4);
      expect(schemaLibraryCardNumber('YSQ_SCHEMA_DEFECTIVENESS_SHAME'), 7);
      expect(schemaLibraryCardNumber('YSQ_SCHEMA_FAILURE'), 12);
      expect(schemaLibraryCardNumber('YSQ_SCHEMA_PUNITIVENESS'), 21);
      final numbers = [
        for (final code in kSchemaLibraryOrder) schemaLibraryCardNumber(code)!
      ];
      expect(numbers, [for (var n = 4; n <= 21; n++) n]);
    });

    test('código desconhecido ou nulo não tem card', () {
      expect(schemaLibraryCardNumber('YAMI_MODE_ANGRY_CHILD'), isNull);
      expect(schemaLibraryCardNumber(null), isNull);
    });
  });

  group('rotas do módulo', () {
    test('o card entra como parâmetro e some quando não há card', () {
      expect(PsychoeducationRoutes.patientModule('m1'),
          '/patient/psychoeducation/m1');
      expect(PsychoeducationRoutes.patientModule('m1', card: 4),
          '/patient/psychoeducation/m1?card=4');
      expect(PsychoeducationRoutes.psychologistModule('m1', card: 12),
          '/psychologist/psychoeducation/m1?card=12');
    });
  });

  group('leitor do módulo', () {
    PsychoeducationModule module() => PsychoeducationModule(
          id: 'm8',
          number: kSchemaLibraryNumber,
          stage: 'Compreender',
          title: 'Conhecendo os 18 Esquemas',
          cards: [
            for (var i = 1; i <= 22; i++)
              PsychoeducationCard(title: 'Card $i', patientText: 'Texto $i'),
          ],
        );

    Future<void> pump(WidgetTester tester, {int? initialCard}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            psychoeducationJourneyProvider
                .overrideWith((ref) async => [module()]),
          ],
          child: MaterialApp(
            home: PsychoeducationModulePage(
              moduleId: 'm8',
              initialCard: initialCard,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('abre direto no card pedido', (tester) async {
      await pump(tester, initialCard: 4);
      expect(find.text('Card 4'), findsOneWidget);
      expect(find.text('Card 1'), findsNothing);
    });

    testWidgets('sem card pedido, abre na apresentação', (tester) async {
      await pump(tester);
      expect(find.text('Card 4'), findsNothing);
    });
  });

  test('o paciente também tem rota para o módulo', () {
    expect(ProfileRole.patient, isNotNull);
    expect(PsychoeducationRoutes.patientModule('m8', card: 4),
        startsWith('/patient/'));
  });
}
