import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/life_story/domain/life_story_enums.dart';
import 'package:terapia_esquema/shared/widgets/relationship_role_picker.dart';

Widget _host(RelationshipRole? selected,
        ValueChanged<RelationshipRole?> onChanged) =>
    MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child:
              RelationshipRolePicker(selected: selected, onChanged: onChanged),
        ),
      ),
    );

void main() {
  testWidgets('todas as categorias aparecem de uma vez em tela pequena',
      (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(_host(null, (_) {}));

    for (final label in [
      'Pais',
      'Irmãos',
      'Avós',
      'Tios/primos',
      'Filhos',
      'Cônjuge',
      'Outros',
    ]) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('escolher categoria mostra os parentescos e seleciona um',
      (tester) async {
    RelationshipRole? picked;
    await tester.pumpWidget(_host(null, (r) => picked = r));

    await tester.tap(find.text('Avós'));
    await tester.pumpAndSettle();
    expect(find.text('Avó'), findsOneWidget);
    expect(find.text('Avô'), findsOneWidget);

    await tester.tap(find.text('Avó'));
    expect(picked, RelationshipRole.grandmother);
  });
}
