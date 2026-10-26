// Revisão do genograma: famílias cadastradas SÓ pelos papéis (sem vínculos
// gravados), passando pela inferência usada no infográfico e na tela.
//
//   flutter test test/tools/render_genogram_review.dart
//
// Saída em build/genograma_review_{1,2,3}.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_data.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_gender.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_layout.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_layout_adapter.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_person.dart';
import 'package:terapia_esquema/features/genogram/presentation/widgets/motor_genogram_diagram.dart';

final _t = DateTime(2024);

GenogramPerson _p(String id, String name, String rel, GenogramGender g,
        {int? birth, bool dead = false}) =>
    GenogramPerson(
      id: id,
      clinicId: 'c',
      patientId: 'pat',
      fullName: name,
      relationshipToPatient: rel,
      gender: g,
      birthYear: birth,
      isDeceased: dead,
      isSensitive: false,
      createdAt: _t,
      updatedAt: _t,
    );

const _f = GenogramGender.female;
const _m = GenogramGender.male;

final _scenarios = <String, List<GenogramPerson>>{
  '1': [
    _p('P', 'Marina', 'Paciente', _f, birth: 1994),
    _p('Fa', 'João', 'father', _m, birth: 1965, dead: true),
    _p('Mo', 'Carla', 'mother', _f, birth: 1968),
    _p('Ir', 'Lucas', 'brother', _m, birth: 1997),
    _p('Is', 'Paula', 'sister', _f, birth: 2001),
    _p('AvP', 'Antônio', 'grandfather', _m, birth: 1938, dead: true),
    _p('AoP', 'Rosa', 'grandmother', _f, birth: 1940),
    _p('AvM', 'Sérgio', 'grandfather', _m, birth: 1942),
    _p('AoM', 'Helena', 'grandmother', _f, birth: 1945),
    _p('Co', 'Rafael', 'partner', _m, birth: 1992),
    _p('Fi', 'Davi', 'son', _m, birth: 2020),
    _p('Fh', 'Alice', 'daughter', _f, birth: 2023),
  ],
  '2': [
    _p('P', 'Marina', 'Paciente', _f, birth: 1994),
    _p('Fa', 'João', 'father', _m, birth: 1965),
    _p('Mo', 'Carla', 'mother', _f, birth: 1968),
    _p('Mi', 'Bruno', 'brother', _m, birth: 2005),
    _p('Ma', 'Sandra', 'stepmother', _f, birth: 1975),
    _p('Ex', 'Pedro', 'ex_partner', _m, birth: 1990),
    _p('Fi', 'Davi', 'Filho', _m, birth: 2018),
    _p('Av', 'Rosa', 'grandmother', _f, birth: 1940),
    _p('Ti', 'Marcos', 'uncle', _m, birth: 1970),
    _p('Af', 'Júlia', 'other', _f, birth: 2015),
  ],
  '3': [
    _p('P', 'Marina', 'Paciente', _f, birth: 1994),
    _p('Mo', 'Carla', 'mother', _f, birth: 1968),
    _p('Is', 'Paula', 'sister', _f, birth: 2001),
  ],
};

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    for (final f in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']) {
      await ui.loadFontFromList(File('$dir\\$f').readAsBytesSync(),
          fontFamily: 'Roboto');
    }
  });

  for (final entry in _scenarios.entries) {
    testWidgets('cenário ${entry.key}', (tester) async {
      final raw = GenogramData(people: entry.value, relationships: const []);
      final data = withInferredStructure(raw);

      // ignore: avoid_print
      print('--- cenário ${entry.key}: ${data.relationships.length} vínculos '
          'inferidos, hasStructure=${MotorGenogramDiagram.hasStructure(data)}');
      for (final r in data.relationships) {
        final a = entry.value.firstWhere((p) => p.id == r.personAId).fullName;
        final b = entry.value.firstWhere((p) => p.id == r.personBId).fullName;
        // ignore: avoid_print
        print('   ${r.relationshipType.name}: $a -> $b'
            '${r.isAdoptive ? ' (adotivo)' : ''}');
      }

      final input = buildLayoutInput(
          people: data.people, relationships: data.relationships);
      if (input == null) {
        // ignore: avoid_print
        print('   (sem estrutura para desenhar)');
        return;
      }
      final layout = buildGenogramStructure(
          people: input.people,
          edges: input.edges,
          focusId: input.focusId,
          twins: input.twins);
      final diagram = positionGenogram(layout, colWidth: 116, rowHeight: 150);

      tester.view.physicalSize = Size(diagram.width, diagram.height);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(
          child: SizedBox(
            width: diagram.width,
            height: diagram.height,
            child: DefaultTextStyle.merge(
              style: const TextStyle(fontFamily: 'Roboto'),
              child: MotorGenogramDiagram(data: data, showEmotional: false),
            ),
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 200));
      await tester.pump(const Duration(seconds: 4));

      final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byType(RepaintBoundary).first);
      late final Uint8List png;
      await tester.runAsync(() async {
        final image = await boundary.toImage(pixelRatio: 2.0);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        png = bytes!.buffer.asUint8List();
      });
      File('build/genograma_review_${entry.key}.png')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(png);
    });
  }
}
