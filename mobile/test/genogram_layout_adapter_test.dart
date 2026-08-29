import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_gender.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_layout.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_layout_adapter.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_person.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship_type.dart';

final _t = DateTime(2024);

GenogramPerson _p(String id, {GenogramGender? gender, String? rel}) =>
    GenogramPerson(
      id: id,
      clinicId: 'c',
      patientId: 'pat',
      fullName: id,
      isDeceased: false,
      isSensitive: false,
      createdAt: _t,
      updatedAt: _t,
      gender: gender,
      relationshipToPatient: rel,
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

void main() {
  group('buildLayoutInput', () {
    test('acha o foco, mapeia sexo e ignora vínculos emocionais', () {
      final input = buildLayoutInput(
        people: [
          _p('P', rel: 'Paciente'),
          _p('Fa', gender: GenogramGender.male),
          _p('Mo', gender: GenogramGender.female),
        ],
        relationships: [
          _r('Fa', 'P', GenogramRelationshipType.parentChild),
          _r('Mo', 'P', GenogramRelationshipType.parentChild),
          _r('Fa', 'Mo', GenogramRelationshipType.spouse),
          _r('Fa', 'P', GenogramRelationshipType.conflict), // emocional → dropa
        ],
      );

      expect(input, isNotNull);
      expect(input!.focusId, 'P');
      expect(input.people.length, 3);
      // 3 estruturais, o conflito foi filtrado
      expect(input.edges.length, 3);
      final fa = input.people.firstWhere((p) => p.id == 'Fa');
      expect(fa.sex, GSex.male);
      final mo = input.people.firstWhere((p) => p.id == 'Mo');
      expect(mo.sex, GSex.female);
    });

    test('emotionalRelations extrai só as emocionais', () {
      final em = emotionalRelations([
        _r('a', 'b', GenogramRelationshipType.conflict),
        _r('a', 'c', GenogramRelationshipType.close),
        _r('a', 'd', GenogramRelationshipType.parentChild), // estrutural
        _r('a', 'e', GenogramRelationshipType.spouse), // estrutural
      ]);
      expect(em.length, 2);
      expect(em.any((x) => x.kind == GEmotion.conflict), isTrue);
      expect(em.any((x) => x.kind == GEmotion.close), isTrue);
    });

    test('twinPairs extrai só os gêmeos; adoção vira aresta marcada', () {
      final rels = [
        _r('Fa', 'C', GenogramRelationshipType.parentChild),
        _r('Ga', 'Gb', GenogramRelationshipType.twin),
        _r('Fa', 'Mo', GenogramRelationshipType.spouse),
      ];
      final twins = twinPairs(rels);
      expect(twins.length, 1);
      expect(twins.single.a, 'Ga');
      expect(twins.single.b, 'Gb');

      final adoptiveRel = GenogramRelationship(
        id: 'a',
        clinicId: 'c',
        patientId: 'pat',
        personAId: 'Fa',
        personBId: 'Kid',
        relationshipType: GenogramRelationshipType.parentChild,
        isAdoptive: true,
        isSensitive: false,
        createdAt: _t,
        updatedAt: _t,
      );
      final edges = structuralEdges([adoptiveRel]);
      expect(edges.single.type, GEdgeType.parentChild);
      expect(edges.single.adopted, isTrue);
    });

    test('sem paciente na lista → null', () {
      final input = buildLayoutInput(
        people: [_p('Fa', gender: GenogramGender.male)],
        relationships: const [],
      );
      expect(input, isNull);
    });
  });

  group('buildGenogramDiagram', () {
    test('pipeline completo produz a árvore bilateral a partir de B', () {
      final d = buildGenogramDiagram(
        people: [
          _p('P', rel: 'Paciente'),
          _p('Fa', gender: GenogramGender.male),
          _p('Mo', gender: GenogramGender.female),
          _p('GpP', gender: GenogramGender.male),
          _p('GmP', gender: GenogramGender.female),
          _p('GpM', gender: GenogramGender.male),
          _p('GmM', gender: GenogramGender.female),
        ],
        relationships: [
          _r('Fa', 'P', GenogramRelationshipType.parentChild),
          _r('Mo', 'P', GenogramRelationshipType.parentChild),
          _r('Fa', 'Mo', GenogramRelationshipType.spouse),
          _r('GpP', 'Fa', GenogramRelationshipType.parentChild),
          _r('GmP', 'Fa', GenogramRelationshipType.parentChild),
          _r('GpP', 'GmP', GenogramRelationshipType.spouse),
          _r('GpM', 'Mo', GenogramRelationshipType.parentChild),
          _r('GmM', 'Mo', GenogramRelationshipType.parentChild),
          _r('GpM', 'GmM', GenogramRelationshipType.spouse),
        ],
      );

      expect(d, isNotNull);
      // Paciente na geração 0, própria linhagem
      final p = d!.byId('P')!;
      expect(p.generation, 0);
      expect(p.lineage, GLineage.self);
      // Avô paterno na linhagem paterna, geração -2
      final gpp = d.byId('GpP')!;
      expect(gpp.generation, -2);
      expect(gpp.lineage, GLineage.paternal);
      // Avó materna na linhagem materna
      expect(d.byId('GmM')!.lineage, GLineage.maternal);
      // Paterna à esquerda da materna
      expect(gpp.x, lessThan(d.byId('GmM')!.x));
    });
  });
}
