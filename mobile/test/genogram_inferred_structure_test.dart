import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_data.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_gender.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_layout_adapter.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_person.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship_type.dart';
import 'package:terapia_esquema/features/genogram/presentation/widgets/motor_genogram_diagram.dart';

final _t = DateTime(2026, 1, 1);

GenogramPerson _p(String id, String role, GenogramGender g) => GenogramPerson(
      id: id,
      clinicId: 'c',
      patientId: 'p',
      fullName: role,
      relationshipToPatient: role,
      gender: g,
      isDeceased: false,
      isSensitive: false,
      createdAt: _t,
      updatedAt: _t,
    );

GenogramRelationship _r(
        String id, String a, String b, GenogramRelationshipType type) =>
    GenogramRelationship(
      id: id,
      clinicId: 'c',
      patientId: 'p',
      personAId: a,
      personBId: b,
      relationshipType: type,
      isSensitive: false,
      createdAt: _t,
      updatedAt: _t,
    );

void main() {
  final people = [
    _p('eu', 'Paciente', GenogramGender.female),
    _p('pai', 'pai', GenogramGender.male),
    _p('mae', 'mãe', GenogramGender.female),
  ];

  test('pessoas com papéis mas sem vínculos: sem a inferência não há estrutura',
      () {
    final raw = GenogramData(people: people, relationships: const []);
    expect(MotorGenogramDiagram.hasStructure(raw), isFalse);
  });

  test('a inferência liga pai e mãe ao paciente e o desenho passa a existir',
      () {
    final data = withInferredStructure(
        GenogramData(people: people, relationships: const []));
    expect(MotorGenogramDiagram.hasStructure(data), isTrue);

    final parentChild = data.relationships
        .where((r) => r.relationshipType == GenogramRelationshipType.parentChild)
        .map((r) => '${r.personAId}>${r.personBId}')
        .toSet();
    expect(parentChild, containsAll(['pai>eu', 'mae>eu']));
    expect(data.relationships.every((r) => r.id.startsWith('inferred_')), isTrue);
    expect(data.people, same(people));
  });

  test('o que já está cadastrado prevalece e não é duplicado', () {
    final existing = [_r('1', 'pai', 'eu', GenogramRelationshipType.parentChild)];
    final data = withInferredStructure(
        GenogramData(people: people, relationships: existing));
    final paiParaEu = data.relationships.where((r) =>
        r.relationshipType == GenogramRelationshipType.parentChild &&
        r.personAId == 'pai' &&
        r.personBId == 'eu');
    expect(paiParaEu, hasLength(1));
    expect(data.relationships.first.id, '1');
  });

  test('sem pessoas ou sem nada a inferir devolve os mesmos dados', () {
    const empty = GenogramData(people: [], relationships: []);
    expect(withInferredStructure(empty), same(empty));

    final only = GenogramData(
        people: [_p('eu', 'Paciente', GenogramGender.female)],
        relationships: const []);
    expect(withInferredStructure(only), same(only));
  });
}
