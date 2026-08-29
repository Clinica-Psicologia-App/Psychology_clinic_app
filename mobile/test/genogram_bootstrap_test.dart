import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_bootstrap.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_layout.dart';

bool _has(List<GEdgeProposal> ps, String a, String b, GEdgeType t) =>
    ps.any((p) => p.edge.a == a && p.edge.b == b && p.edge.type == t);

void main() {
  group('proposeStructure', () {
    test('família nuclear: propõe casal + filiações', () {
      final ps = proposeStructure(
        people: const [
          GBootstrapPerson('P', role: 'Paciente', name: 'Bruno'),
          GBootstrapPerson('Fa', role: 'Pai', sex: GSex.male, name: 'João'),
          GBootstrapPerson('Mo', role: 'Mãe', sex: GSex.female, name: 'Carla'),
          GBootstrapPerson('Si', role: 'Irmão', name: 'Pedro'),
        ],
        existing: const [],
      );

      expect(ps.length, 5);
      expect(_has(ps, 'Fa', 'Mo', GEdgeType.spouse), isTrue);
      expect(_has(ps, 'Fa', 'P', GEdgeType.parentChild), isTrue);
      expect(_has(ps, 'Mo', 'P', GEdgeType.parentChild), isTrue);
      expect(_has(ps, 'Fa', 'Si', GEdgeType.parentChild), isTrue);
      expect(_has(ps, 'Mo', 'Si', GEdgeType.parentChild), isTrue);
    });

    test('não propõe vínculos que já existem', () {
      final ps = proposeStructure(
        people: const [
          GBootstrapPerson('P', role: 'Paciente'),
          GBootstrapPerson('Fa', role: 'Pai', sex: GSex.male),
          GBootstrapPerson('Mo', role: 'Mãe', sex: GSex.female),
        ],
        existing: const [
          GEdge('Fa', 'Mo', GEdgeType.spouse), // já existe
          GEdge('Fa', 'P', GEdgeType.parentChild), // já existe
        ],
      );

      // Só sobra Mãe → Paciente
      expect(ps.length, 1);
      expect(_has(ps, 'Mo', 'P', GEdgeType.parentChild), isTrue);
    });

    test('avós com lado explícito ligam ao pai/mãe certo + casal', () {
      final ps = proposeStructure(
        people: const [
          GBootstrapPerson('P', role: 'Paciente'),
          GBootstrapPerson('Fa', role: 'Pai', sex: GSex.male),
          GBootstrapPerson('Mo', role: 'Mãe', sex: GSex.female),
          GBootstrapPerson('GpP', role: 'Avô paterno', sex: GSex.male),
          GBootstrapPerson('GmP', role: 'Avó paterna', sex: GSex.female),
        ],
        existing: const [],
      );

      expect(_has(ps, 'GpP', 'Fa', GEdgeType.parentChild), isTrue);
      expect(_has(ps, 'GmP', 'Fa', GEdgeType.parentChild), isTrue);
      expect(_has(ps, 'GpP', 'GmP', GEdgeType.spouse), isTrue);
      // Avô paterno NÃO liga à mãe
      expect(_has(ps, 'GpP', 'Mo', GEdgeType.parentChild), isFalse);
    });

    test('normaliza acentos e caixa; avó sem lado é ignorada', () {
      final ps = proposeStructure(
        people: const [
          GBootstrapPerson('P', role: '  PACIENTE '),
          GBootstrapPerson('Fa', role: 'PAI', sex: GSex.male),
          GBootstrapPerson('Mo', role: 'mãe', sex: GSex.female),
          GBootstrapPerson('Gp', role: 'Avó', sex: GSex.female), // sem lado
        ],
        existing: const [],
      );

      // Pai/Mãe reconhecidos mesmo em caixa/acualto variados
      expect(_has(ps, 'Fa', 'Mo', GEdgeType.spouse), isTrue);
      expect(_has(ps, 'Fa', 'P', GEdgeType.parentChild), isTrue);
      // Avó sem lado explícito não gera proposta (fica para confirmação manual)
      expect(ps.any((x) => x.edge.a == 'Gp' || x.edge.b == 'Gp'), isFalse);
    });

    test('reconhece as CHAVES do enum em inglês (formato real do banco)', () {
      final ps = proposeStructure(
        people: const [
          GBootstrapPerson('P', role: 'Paciente'),
          GBootstrapPerson('Fa', role: 'father', sex: GSex.male),
          GBootstrapPerson('Mo', role: 'mother', sex: GSex.female),
          GBootstrapPerson('Si', role: 'brother'),
          GBootstrapPerson('Fi', role: 'son'),
          GBootstrapPerson('Sp', role: 'partner'),
          GBootstrapPerson('Gp', role: 'grandfather', sex: GSex.male), // sem lado
        ],
        existing: const [],
      );

      expect(_has(ps, 'Fa', 'Mo', GEdgeType.spouse), isTrue);
      expect(_has(ps, 'Fa', 'P', GEdgeType.parentChild), isTrue);
      expect(_has(ps, 'Mo', 'P', GEdgeType.parentChild), isTrue);
      expect(_has(ps, 'Fa', 'Si', GEdgeType.parentChild), isTrue);
      expect(_has(ps, 'P', 'Fi', GEdgeType.parentChild), isTrue);
      expect(_has(ps, 'P', 'Sp', GEdgeType.spouse), isTrue);
      // avô sem lado explícito não é ligado
      expect(ps.any((x) => x.edge.a == 'Gp' || x.edge.b == 'Gp'), isFalse);
    });

    test('filho do paciente vira parent_child do paciente', () {
      final ps = proposeStructure(
        people: const [
          GBootstrapPerson('P', role: 'Paciente'),
          GBootstrapPerson('Fi', role: 'Filha'),
        ],
        existing: const [],
      );
      expect(_has(ps, 'P', 'Fi', GEdgeType.parentChild), isTrue);
    });
  });

  group('grandparentsNeedingSide / grandparentSideEdges', () {
    test('lista os avós sem lado + o pai/mãe alvo', () {
      final plan = grandparentsNeedingSide(
        people: const [
          GBootstrapPerson('P', role: 'Paciente'),
          GBootstrapPerson('Fa', role: 'father', sex: GSex.male),
          GBootstrapPerson('Mo', role: 'mother', sex: GSex.female),
          GBootstrapPerson('G1', role: 'grandfather', sex: GSex.male),
          GBootstrapPerson('G2', role: 'grandmother', sex: GSex.female),
        ],
        existing: const [],
      );
      expect(plan.fatherId, 'Fa');
      expect(plan.motherId, 'Mo');
      expect(plan.grandparents.map((g) => g.id).toSet(), {'G1', 'G2'});
      expect(plan.isUsable, isTrue);
    });

    test('avô já com lado explícito NÃO entra na lista', () {
      final plan = grandparentsNeedingSide(
        people: const [
          GBootstrapPerson('P', role: 'Paciente'),
          GBootstrapPerson('Fa', role: 'father', sex: GSex.male),
          GBootstrapPerson('G1', role: 'Avô paterno', sex: GSex.male),
        ],
        existing: const [],
      );
      expect(plan.grandparents, isEmpty);
    });

    test('dois avós no mesmo lado → parent_child + casal', () {
      const plan = GSidePlan(
        [
          GGrandparentSideChoice('G1', 'Antônio', GSex.male),
          GGrandparentSideChoice('G2', 'Cecília', GSex.female),
        ],
        'Fa',
        'Mo',
      );
      final edges = grandparentSideEdges(
        plan: plan,
        paternalById: const {'G1': true, 'G2': true}, // ambos paternos
      );
      bool has(String a, String b, GEdgeType t) =>
          edges.any((e) => e.a == a && e.b == b && e.type == t);
      expect(has('G1', 'Fa', GEdgeType.parentChild), isTrue);
      expect(has('G2', 'Fa', GEdgeType.parentChild), isTrue);
      expect(edges.any((e) => e.type == GEdgeType.spouse), isTrue);
    });

    test('avós em lados diferentes → sem casal, cada um no seu pai/mãe', () {
      const plan = GSidePlan(
        [
          GGrandparentSideChoice('G1', 'Antônio', GSex.male),
          GGrandparentSideChoice('G2', 'Rosa', GSex.female),
        ],
        'Fa',
        'Mo',
      );
      final edges = grandparentSideEdges(
        plan: plan,
        paternalById: const {'G1': true, 'G2': false},
      );
      bool has(String a, String b, GEdgeType t) =>
          edges.any((e) => e.a == a && e.b == b && e.type == t);
      expect(has('G1', 'Fa', GEdgeType.parentChild), isTrue);
      expect(has('G2', 'Mo', GEdgeType.parentChild), isTrue);
      expect(edges.any((e) => e.type == GEdgeType.spouse), isFalse);
    });
  });
}
