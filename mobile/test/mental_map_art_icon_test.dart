import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/presentation/widgets/mental_map_art_icon.dart';

/// Os nodos preenchidos do mapa mental passaram a usar ícones multicolor
/// desenhados à mão (CustomPainter), em vez do glifo Material monocromático.
/// Estes testes travam o contrato entre o id do nodo e o desenho, e garantem
/// que todo desenho renderiza sem estourar.
void main() {
  test('cada id de nodo conhecido mapeia para um desenho', () {
    expect(MentalMapArt.forNodeId('schemas'), MentalMapArt.schemas);
    expect(MentalMapArt.forNodeId('modes'), MentalMapArt.modes);
    expect(MentalMapArt.forNodeId('problems'), MentalMapArt.problems);
    expect(MentalMapArt.forNodeId('attachment'), MentalMapArt.attachment);
    expect(MentalMapArt.forNodeId('coping'), MentalMapArt.coping);
    expect(MentalMapArt.forNodeId('parental'), MentalMapArt.parental);
    expect(MentalMapArt.forNodeId('goals'), MentalMapArt.goals);
    expect(MentalMapArt.forNodeId('history'), MentalMapArt.history);
  });

  test('id desconhecido não tem desenho (cai no ícone Material)', () {
    expect(MentalMapArt.forNodeId('outro'), isNull);
    expect(MentalMapArt.forNodeId(''), isNull);
  });

  testWidgets('todo desenho renderiza sem erro', (tester) async {
    for (final art in MentalMapArt.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(child: MentalMapArtIcon(art: art, size: 22)),
          ),
        ),
      );
      expect(tester.takeException(), isNull, reason: 'falhou em $art');
      expect(find.byType(MentalMapArtIcon), findsOneWidget);
    }
  });
}
