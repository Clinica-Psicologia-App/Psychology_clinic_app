// Prova visual da Etapa 4: gêmeos (Λ) + adoção (descida tracejada).
//
//   flutter test test/tools/render_motor_etapa4.dart
//
// Saída em build/genograma_motor_etapa4.png
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
        {GenogramGender? gender, String? rel, int? birth, String? caregiver}) =>
    GenogramPerson(
      id: id,
      clinicId: 'c',
      patientId: 'pat',
      fullName: name,
      relationshipToPatient: rel,
      gender: gender,
      birthYear: birth,
      isDeceased: false,
      caregiverRole: caregiver,
      isSensitive: false,
      createdAt: _t,
      updatedAt: _t,
    );

GenogramRelationship _r(String a, String b, GenogramRelationshipType type,
        {bool adoptive = false}) =>
    GenogramRelationship(
      id: '$a-$b-${type.storageValue}',
      clinicId: 'c',
      patientId: 'pat',
      personAId: a,
      personBId: b,
      relationshipType: type,
      isAdoptive: adoptive,
      isSensitive: false,
      createdAt: _t,
      updatedAt: _t,
    );

final _data = GenogramData(
  people: [
    _p('P', 'Bruno', gender: GenogramGender.male, rel: 'Paciente', birth: 1996),
    _p('Fa', 'João',
        gender: GenogramGender.male,
        rel: 'Pai',
        birth: 1968,
        caregiver: 'partial'),
    _p('Mo', 'Carla',
        gender: GenogramGender.female,
        rel: 'Mãe',
        birth: 1970,
        caregiver: 'important'),
    _p('Ga', 'Ana', gender: GenogramGender.female, rel: 'Irmã', birth: 2000),
    _p('Gb', 'Beto', gender: GenogramGender.male, rel: 'Irmão', birth: 2000),
    _p('Ad', 'Caio', gender: GenogramGender.male, rel: 'Irmão', birth: 2005),
  ],
  relationships: [
    _r('Fa', 'Mo', GenogramRelationshipType.spouse),
    _r('Fa', 'P', GenogramRelationshipType.parentChild),
    _r('Mo', 'P', GenogramRelationshipType.parentChild),
    _r('Fa', 'Ga', GenogramRelationshipType.parentChild),
    _r('Mo', 'Ga', GenogramRelationshipType.parentChild),
    _r('Fa', 'Gb', GenogramRelationshipType.parentChild),
    _r('Mo', 'Gb', GenogramRelationshipType.parentChild),
    // Caio é filho adotivo (descida tracejada):
    _r('Fa', 'Ad', GenogramRelationshipType.parentChild, adoptive: true),
    _r('Mo', 'Ad', GenogramRelationshipType.parentChild, adoptive: true),
    // Ana e Beto são gêmeos (Λ):
    _r('Ga', 'Gb', GenogramRelationshipType.twin),
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

  testWidgets('Etapa 4: gêmeos + adoção', (tester) async {
    final input = buildLayoutInput(
        people: _data.people, relationships: _data.relationships)!;
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
            child: MotorGenogramDiagram(data: _data, showEmotional: false),
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
    File('build/genograma_motor_etapa4.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/genograma_motor_etapa4.png');
  });
}
