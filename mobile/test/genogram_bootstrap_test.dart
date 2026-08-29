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
}
