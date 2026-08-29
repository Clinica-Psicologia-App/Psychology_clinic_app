import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_data.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_gender.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_layout_adapter.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_person.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship_type.dart';
import 'package:terapia_esquema/features/genogram/presentation/widgets/motor_genogram_diagram.dart';

final _t = DateTime(2024);

GenogramPerson _p(String id, {GenogramGender? g, String? rel}) => GenogramPerson(
    id: id,
    clinicId: 'c',
    patientId: 'pat',
    fullName: id,
    relationshipToPatient: rel,
    gender: g,
    isDeceased: false,
    isSensitive: false,
    createdAt: _t,
    updatedAt: _t);

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
        updatedAt: _t);

final _data = GenogramData(
  people: [
    _p('P', g: GenogramGender.male, rel: 'Paciente'),
    _p('Fa', g: GenogramGender.male, rel: 'Pai'),
    _p('Mo', g: GenogramGender.female, rel: 'Mãe'),
  ],
  relationships: [
    _r('Fa', 'P', GenogramRelationshipType.parentChild),
    _r('Mo', 'P', GenogramRelationshipType.parentChild),
    _r('Fa', 'Mo', GenogramRelationshipType.spouse),
  ],
);

void main() {
  testWidgets('tocar num símbolo dispara onTapPerson com o id da pessoa',
      (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    String? tapped;
    final diagram = buildGenogramDiagram(
        people: _data.people, relationships: _data.relationships)!;
    final patient = diagram.byId('P')!;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MotorGenogramDiagram(
          data: _data,
          showEmotional: false,
          onTapPerson: (id) => tapped = id,
        ),
      ),
    ));
    await tester.pump();

    // O InteractiveViewer (constrained:false) posiciona o filho no topo-esquerda,
    // então as coordenadas do diagrama batem com as globais.
    await tester.tapAt(Offset(patient.x, patient.y));
    await tester.pump();

    expect(tapped, 'P');
  });

  testWidgets('tocar no vazio não dispara nada', (tester) async {
    tester.view.physicalSize = const Size(1200, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    var calls = 0;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: MotorGenogramDiagram(
          data: _data,
          showEmotional: false,
          onTapPerson: (_) => calls++,
        ),
      ),
    ));
    await tester.pump();

    await tester.tapAt(const Offset(5, 5)); // canto vazio
    await tester.pump();

    expect(calls, 0);
  });
}
