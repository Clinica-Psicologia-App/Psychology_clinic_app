// Prova visual (#37 e #41) com o WIDGET de produção MotorGenogramDiagram e
// dados FICTÍCIOS: casal + filha, e irmãos fora de ordem de idade.
//
//   RENDER_OUT=<pasta> flutter test test/tools/render_genograma_idade_casal.dart
//
// Saída em RENDER_OUT (padrão build/).
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
        {GenogramGender? gender, String? rel, int? birth}) =>
    GenogramPerson(
      id: id,
      clinicId: 'c',
      patientId: 'pat',
      fullName: name,
      relationshipToPatient: rel,
      gender: gender,
      birthYear: birth,
      isDeceased: false,
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

const _pc = GenogramRelationshipType.parentChild;
const _sp = GenogramRelationshipType.spouse;

// #41: a esposa tem id que vem ANTES do paciente; a filha está ligada só a ele.
final _casal = GenogramData(
  people: [
    _p('Fa', 'Pai', gender: GenogramGender.male, rel: 'Pai', birth: 1960),
    _p('Mo', 'Mãe', gender: GenogramGender.female, rel: 'Mãe', birth: 1962),
    _p('z_pac', 'Paciente',
        gender: GenogramGender.male, rel: 'Paciente', birth: 1988),
    _p('a_esposa', 'Esposa',
        gender: GenogramGender.female, rel: 'Esposa', birth: 1990),
    _p('m_filha', 'Filha',
        gender: GenogramGender.female, rel: 'Filha', birth: 2018),
  ],
  relationships: [
    _r('Fa', 'Mo', _sp),
    _r('Fa', 'z_pac', _pc),
    _r('Mo', 'z_pac', _pc),
    _r('z_pac', 'a_esposa', _sp),
    _r('z_pac', 'm_filha', _pc),
  ],
);

// #37: irmãos cadastrados fora de ordem de idade; o mais velho (1980) tem ex e
// cônjuge atual, o mais novo (1995) é o paciente; uma irmã sem ano de nascimento.
final _irmaos = GenogramData(
  people: [
    _p('Fa', 'Pai', gender: GenogramGender.male, rel: 'Pai', birth: 1955),
    _p('Mo', 'Mãe', gender: GenogramGender.female, rel: 'Mãe', birth: 1957),
    _p('b_pac', 'Paciente 1995',
        gender: GenogramGender.female, rel: 'Paciente', birth: 1995),
    _p('c_meio', 'Irmão 1988',
        gender: GenogramGender.male, rel: 'Irmão', birth: 1988),
    _p('d_velho', 'Irmão 1980',
        gender: GenogramGender.male, rel: 'Irmão', birth: 1980),
    _p('e_ex', 'Ex 1981',
        gender: GenogramGender.female, rel: 'Ex-cônjuge', birth: 1981),
    _p('f_atual', 'Atual 1983',
        gender: GenogramGender.female, rel: 'Cônjuge', birth: 1983),
    _p('g_semano', 'Irmã sem ano', gender: GenogramGender.female, rel: 'Irmã'),
  ],
  relationships: [
    _r('Fa', 'Mo', _sp),
    for (final k in ['b_pac', 'c_meio', 'd_velho', 'g_semano']) ...[
      _r('Fa', k, _pc),
      _r('Mo', k, _pc),
    ],
    _r('d_velho', 'e_ex', GenogramRelationshipType.exSpouse),
    _r('d_velho', 'f_atual', _sp),
  ],
);

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    for (final f in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf'
    ]) {
      await ui.loadFontFromList(File('$dir/$f').readAsBytesSync(),
          fontFamily: 'Roboto');
    }
  });

  final out = Platform.environment['RENDER_OUT'] ?? 'build';
  for (final (name, data) in [
    ('41_genograma_casal_filha', _casal),
    ('37_genograma_irmaos', _irmaos),
  ]) {
    testWidgets(name, (tester) async {
      final input = buildLayoutInput(
          people: data.people, relationships: data.relationships)!;
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
              child: MotorGenogramDiagram(
                  data: data, showEmotional: false, interactive: false),
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
      File('$out/$name.png')
        ..parent.createSync(recursive: true)
        ..writeAsBytesSync(png);
    });
  }
}
