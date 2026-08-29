// Prova visual do WIDGET de produção MotorGenogramDiagram, com dados no
// formato real de B (GenogramData: pessoas + relações).
//
//   flutter test test/tools/render_motor_widget.dart
//
// Saída em build/genograma_motor_widget.png
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
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship_type.dart';
import 'package:terapia_esquema/features/genogram/presentation/widgets/motor_genogram_diagram.dart';

final _t = DateTime(2024);

GenogramPerson _p(String id, String name,
        {GenogramGender? gender,
        String? rel,
        int? birth,
        bool deceased = false,
        int? death}) =>
    GenogramPerson(
      id: id,
      clinicId: 'c',
      patientId: 'pat',
      fullName: name,
      relationshipToPatient: rel,
      gender: gender,
      birthYear: birth,
      deathYear: death,
      isDeceased: deceased,
      isSensitive: false,
      createdAt: _t,
      updatedAt: _t,
    );

GenogramRelationship _r(String a, String b, GenogramRelationshipType type) =>
    GenogramRelationship(
      id: '$a-$b',
      clinicId: 'c',
      patientId: 'pat',
      personAId: a,
      personBId: b,
      relationshipType: type,
      isSensitive: false,
      createdAt: _t,
      updatedAt: _t,
    );

final _data = GenogramData(
  people: [
    _p('P', 'Bruno', gender: GenogramGender.male, rel: 'Paciente', birth: 1998),
    _p('Fa', 'João', gender: GenogramGender.male, rel: 'Pai', birth: 1972),
    _p('Mo', 'Carla', gender: GenogramGender.female, rel: 'Mãe', birth: 1975),
    _p('Si', 'Pedro', gender: GenogramGender.male, rel: 'Irmão', birth: 2003),
    _p('GpP', 'Antônio',
        gender: GenogramGender.male,
        rel: 'Avô paterno',
        birth: 1946,
        deceased: true,
        death: 2019),
    _p('GmP', 'Cecília',
        gender: GenogramGender.female, rel: 'Avó paterna', birth: 1949),
    _p('GpM', 'Jorge',
        gender: GenogramGender.male, rel: 'Avô materno', birth: 1944),
    _p('GmM', 'Rosa',
        gender: GenogramGender.female, rel: 'Avó materna', birth: 1947),
    _p('Tia', 'Sofia',
        gender: GenogramGender.female, rel: 'Tia paterna', birth: 1978),
  ],
  relationships: [
    _r('Fa', 'P', GenogramRelationshipType.parentChild),
    _r('Mo', 'P', GenogramRelationshipType.parentChild),
    _r('Fa', 'Si', GenogramRelationshipType.parentChild),
    _r('Mo', 'Si', GenogramRelationshipType.parentChild),
    _r('Fa', 'Mo', GenogramRelationshipType.spouse),
    _r('GpP', 'Fa', GenogramRelationshipType.parentChild),
    _r('GmP', 'Fa', GenogramRelationshipType.parentChild),
    _r('GpP', 'Tia', GenogramRelationshipType.parentChild),
    _r('GmP', 'Tia', GenogramRelationshipType.parentChild),
    _r('GpP', 'GmP', GenogramRelationshipType.spouse),
    _r('GpM', 'Mo', GenogramRelationshipType.parentChild),
    _r('GmM', 'Mo', GenogramRelationshipType.parentChild),
    _r('GpM', 'GmM', GenogramRelationshipType.spouse),
  ],
);

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    for (final f in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']) {
      await ui.loadFontFromList(File('$dir\\$f').readAsBytesSync(),
          fontFamily: 'Roboto');
    }
  });

  testWidgets('MotorGenogramDiagram (widget de produção)', (tester) async {
    final input = buildLayoutInput(
        people: _data.people, relationships: _data.relationships)!;
    final layout = buildGenogramStructure(
        people: input.people, edges: input.edges, focusId: input.focusId);
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
            child: MotorGenogramDiagram(data: _data),
          ),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first);
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/genograma_motor_widget.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/genograma_motor_widget.png');
  });
}
