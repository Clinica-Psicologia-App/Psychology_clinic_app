import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_bootstrap.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_layout.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_person.dart';
import 'package:terapia_esquema/features/life_story/domain/life_story_enums.dart';

bool _has(List<GEdgeProposal> ps, String a, String b, GEdgeType t) =>
    ps.any((p) => p.edge.a == a && p.edge.b == b && p.edge.type == t);

GenogramPerson _person(String? role,
        {int? birth, int? death, bool deceased = false}) =>
    GenogramPerson(
      id: 'x',
      clinicId: 'c',
      patientId: 'p',
      fullName: 'Fulano',
      relationshipToPatient: role,
      birthYear: birth,
      deathYear: death,
      isDeceased: deceased,
      isSensitive: false,
      createdAt: DateTime(2024),
      updatedAt: DateTime(2024),
    );

void main() {
  group('rótulo do parentesco (chave gravada → português)', () {
    test('as chaves do formulário viram texto em português', () {
      expect(relationshipRoleDisplay('mother'), 'Mãe');
      expect(relationshipRoleDisplay('grandfather'), 'Avô');
      expect(relationshipRoleDisplay('cousin_f'), 'Prima');
      expect(relationshipRoleDisplay('ex_partner'), 'Ex-companheiro(a)');
    });

    test('texto livre antigo e o marcador do paciente passam como estão', () {
      expect(relationshipRoleDisplay('Meio-irmão'), 'Meio-irmão');
      expect(relationshipRoleDisplay('Paciente'), 'Paciente');
    });

    test('vazio ou nulo não gera rótulo', () {
      expect(relationshipRoleDisplay(null), isNull);
      expect(relationshipRoleDisplay('  '), isNull);
    });

    test('GenogramPerson.relationshipLabel usa o rótulo em português', () {
      expect(_person('sister').relationshipLabel, 'Irmã');
      expect(_person(null).relationshipLabel, isNull);
    });
  });

  group('inferência com as chaves reais do formulário', () {
    test('ex_partner vira ex-casal, não casamento atual nem sumiço', () {
      final ps = proposeStructure(
        people: const [
          GBootstrapPerson('P', role: 'Paciente', name: 'Marina'),
          GBootstrapPerson('Ex', role: 'ex_partner', name: 'Pedro'),
        ],
        existing: const [],
      );
      expect(_has(ps, 'P', 'Ex', GEdgeType.exSpouse), isTrue);
      expect(_has(ps, 'P', 'Ex', GEdgeType.spouse), isFalse);
    });

    test('partner continua sendo casamento atual', () {
      final ps = proposeStructure(
        people: const [
          GBootstrapPerson('P', role: 'Paciente'),
          GBootstrapPerson('Co', role: 'partner'),
        ],
        existing: const [],
      );
      expect(_has(ps, 'P', 'Co', GEdgeType.spouse), isTrue);
    });
  });

  group('texto livre que não deve virar parentesco "inteiro"', () {
    test('"Ex-marido" é ex-casal, não casamento atual', () {
      final ps = proposeStructure(
        people: const [
          GBootstrapPerson('P', role: 'Paciente'),
          GBootstrapPerson('Ex', role: 'Ex-marido'),
        ],
        existing: const [],
      );
      expect(_has(ps, 'P', 'Ex', GEdgeType.exSpouse), isTrue);
      expect(_has(ps, 'P', 'Ex', GEdgeType.spouse), isFalse);
    });

    test('meio-irmão, afilhada e enteado não viram filho/irmão do casal', () {
      final ps = proposeStructure(
        people: const [
          GBootstrapPerson('P', role: 'Paciente'),
          GBootstrapPerson('Fa', role: 'Pai'),
          GBootstrapPerson('Mo', role: 'Mãe'),
          GBootstrapPerson('Mi', role: 'Meio-irmão'),
          GBootstrapPerson('Ma', role: 'Meia-irmã'),
          GBootstrapPerson('Af', role: 'Afilhada'),
          GBootstrapPerson('En', role: 'Enteado'),
          GBootstrapPerson('Sb', role: 'stepbrother'),
        ],
        existing: const [],
      );
      for (final id in ['Mi', 'Ma', 'Af', 'En', 'Sb']) {
        expect(ps.any((p) => p.edge.a == id || p.edge.b == id), isFalse,
            reason: '$id não deveria ser ligado automaticamente');
      }
    });

    test('irmão e filho comuns continuam sendo ligados', () {
      final ps = proposeStructure(
        people: const [
          GBootstrapPerson('P', role: 'Paciente'),
          GBootstrapPerson('Fa', role: 'father'),
          GBootstrapPerson('Mo', role: 'mother'),
          GBootstrapPerson('Ir', role: 'brother'),
          GBootstrapPerson('Fi', role: 'son'),
        ],
        existing: const [],
      );
      expect(_has(ps, 'Fa', 'Ir', GEdgeType.parentChild), isTrue);
      expect(_has(ps, 'Mo', 'Ir', GEdgeType.parentChild), isTrue);
      expect(_has(ps, 'P', 'Fi', GEdgeType.parentChild), isTrue);
    });
  });
}
