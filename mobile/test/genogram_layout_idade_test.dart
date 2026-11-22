import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_layout.dart';

// #37 (irmãos por idade) e #41 (cônjuge à direita; descida do filho no centro
// do casal). Os testes checam PROPRIEDADES do desenho, não a própria saída.

double xOf(GDiagram d, String id) => d.nodes.firstWhere((n) => n.id == id).x;

List<String> leftToRight(GDiagram d, Iterable<String> ids) {
  final n = d.nodes.where((x) => ids.contains(x.id)).toList()
    ..sort((a, b) => a.x.compareTo(b.x));
  return [for (final x in n) x.id];
}

String snapshot(GDiagram d) {
  final ns = [...d.nodes]..sort((a, b) {
      final c = a.y.compareTo(b.y);
      return c != 0 ? c : a.x.compareTo(b.x);
    });
  return ns.map((n) => '${n.generation}:${n.id}@${n.x.round()}').join(',');
}

const _pc = GEdgeType.parentChild;

/// Família de várias gerações: avós dos dois lados, tio com cônjuge, irmãos do
/// foco (um com ex e cônjuge atual), cônjuge e filhos do foco.
GLayout fixture([Map<String, int> y = const {}]) {
  GPerson p(String id, [GSex s = GSex.unknown]) =>
      GPerson(id, sex: s, birthYear: y[id]);
  return buildGenogramStructure(
    focusId: 'F',
    people: [
      p('GF', GSex.male), p('GM', GSex.female), p('MGF', GSex.male),
      p('MGM', GSex.female), p('Fa', GSex.male), p('Un'), p('UnW'),
      p('Mo', GSex.female), p('Au'), p('F'), p('Sb1'), p('Sb2'),
      p('Sb1X'), p('Sb1Y'), p('FW'), p('K1'), p('K2'),
    ],
    edges: const [
      GEdge('GF', 'GM', GEdgeType.spouse),
      GEdge('GF', 'Fa', _pc), GEdge('GM', 'Fa', _pc),
      GEdge('GF', 'Un', _pc), GEdge('GM', 'Un', _pc),
      GEdge('Un', 'UnW', GEdgeType.spouse),
      GEdge('MGF', 'MGM', GEdgeType.spouse),
      GEdge('MGF', 'Mo', _pc), GEdge('MGM', 'Mo', _pc),
      GEdge('MGF', 'Au', _pc), GEdge('MGM', 'Au', _pc),
      GEdge('Fa', 'Mo', GEdgeType.spouse),
      GEdge('Fa', 'F', _pc), GEdge('Mo', 'F', _pc),
      GEdge('Fa', 'Sb1', _pc), GEdge('Mo', 'Sb1', _pc),
      GEdge('Fa', 'Sb2', _pc), GEdge('Mo', 'Sb2', _pc),
      GEdge('Sb1X', 'Sb1', GEdgeType.exSpouse),
      GEdge('Sb1', 'Sb1Y', GEdgeType.spouse),
      GEdge('F', 'FW', GEdgeType.spouse),
      GEdge('F', 'K1', _pc), GEdge('FW', 'K1', _pc),
      GEdge('F', 'K2', _pc), GEdge('FW', 'K2', _pc),
    ],
  );
}

/// Componentes conexos de casamentos de uma faixa devem ser contíguos e em
/// linha: cada casal adjacente e nenhuma pessoa de fora no meio.
void expectBlocksContiguous(GLayout layout, GDiagram d, String why) {
  for (final c in layout.couples) {
    expect((xOf(d, c.a) - xOf(d, c.b)).abs(), d.colWidth,
        reason: '${c.a}–${c.b} adjacentes ($why)');
  }
}

void main() {
  group('#37 — irmãos por idade', () {
    GDiagram build(List<GPerson> kids) {
      final layout = buildGenogramStructure(
        focusId: 'k1',
        people: [
          const GPerson('Fa', sex: GSex.male),
          const GPerson('Mo', sex: GSex.female),
          ...kids,
        ],
        edges: [
          const GEdge('Fa', 'Mo', GEdgeType.spouse),
          for (final k in kids) ...[
            GEdge('Fa', k.id, _pc),
            GEdge('Mo', k.id, _pc),
          ],
        ],
      );
      return positionGenogram(layout);
    }

    test('mais velho à esquerda; sem ano vai ao fim; empate pela ordem atual',
        () {
      final d = build(const [
        GPerson('k1', birthYear: 1995),
        GPerson('k2', birthYear: 1985),
        GPerson('k3'),
        GPerson('k4', birthYear: 1990),
        GPerson('k5', birthYear: 1990),
      ]);
      expect(leftToRight(d, {'k1', 'k2', 'k3', 'k4', 'k5'}),
          ['k2', 'k4', 'k5', 'k1', 'k3']);
    });

    test('sem nenhum ano mantém a ordem de antes (por id)', () {
      final d = build(const [GPerson('k3'), GPerson('k1'), GPerson('k2')]);
      expect(leftToRight(d, {'k1', 'k2', 'k3'}), ['k1', 'k2', 'k3']);
    });

    GLayout m1(int? yB, int? y0) => buildGenogramStructure(
          focusId: 'B',
          people: [
            const GPerson('Fa', sex: GSex.male),
            const GPerson('Mo', sex: GSex.female),
            GPerson('B', birthYear: yB),
            GPerson('0Z', birthYear: y0),
            const GPerson('A'),
            const GPerson('C'),
          ],
          edges: const [
            GEdge('Fa', 'Mo', GEdgeType.spouse),
            GEdge('Fa', 'B', _pc),
            GEdge('Mo', 'B', _pc),
            GEdge('Fa', '0Z', _pc),
            GEdge('Mo', '0Z', _pc),
            GEdge('A', 'B', GEdgeType.exSpouse),
            GEdge('A', 'C', GEdgeType.spouse),
          ],
        );

    test('M1 com idades invertidas: bloco inteiro de B (B, A, C) antes de 0Z',
        () {
      final l = m1(1980, 1990);
      final d = positionGenogram(l);
      expect((xOf(d, 'A') - xOf(d, 'B')).abs(), d.colWidth);
      expect((xOf(d, 'A') - xOf(d, 'C')).abs(), d.colWidth);
      for (final id in ['B', 'A', 'C']) {
        expect(xOf(d, id) < xOf(d, '0Z'), isTrue, reason: id);
      }
    });

    test('M1 com a idade do outro lado: 0Z (mais velha) antes do bloco de B',
        () {
      final l = m1(1990, 1980);
      final d = positionGenogram(l);
      expect((xOf(d, 'A') - xOf(d, 'B')).abs(), d.colWidth);
      expect((xOf(d, 'A') - xOf(d, 'C')).abs(), d.colWidth);
      for (final id in ['B', 'A', 'C']) {
        expect(xOf(d, '0Z') < xOf(d, id), isTrue, reason: id);
      }
    });

    test('M4: foco 1995 casado, irmão 1985: irmão à esquerda; foco ao lado '
        'do cônjuge', () {
      final layout = buildGenogramStructure(
        focusId: 'F',
        people: const [
          GPerson('Fa', sex: GSex.male),
          GPerson('Mo', sex: GSex.female),
          GPerson('F', birthYear: 1995),
          GPerson('FW'),
          GPerson('A', birthYear: 1985),
        ],
        edges: const [
          GEdge('Fa', 'Mo', GEdgeType.spouse),
          GEdge('Fa', 'F', _pc),
          GEdge('Mo', 'F', _pc),
          GEdge('Fa', 'A', _pc),
          GEdge('Mo', 'A', _pc),
          GEdge('F', 'FW', GEdgeType.spouse),
        ],
      );
      final d = positionGenogram(layout);
      expect(xOf(d, 'A') < xOf(d, 'F'), isTrue);
      expect((xOf(d, 'F') - xOf(d, 'FW')).abs(), d.colWidth);
    });

    test('família de várias gerações SEM anos = saída de antes (capturada em '
        'HEAD 4423c60)', () {
      expect(
        snapshot(positionGenogram(fixture())),
        '-2:GF@180,-2:GM@300,-2:MGF@480,-2:MGM@600,-1:Un@120,-1:UnW@240,'
        '-1:Fa@360,-1:Mo@480,-1:Au@600,0:F@100,0:FW@220,0:Sb1X@340,'
        '0:Sb1@460,0:Sb1Y@580,0:Sb2@700,1:K1@100,1:K2@220',
      );
    });

    test('todo casal adjacente, com e sem anos (sem exclusões)', () {
      for (final years in <Map<String, int>>[
        const {},
        const {'F': 1995, 'Sb1': 1990, 'Sb2': 1980, 'Fa': 1960, 'Un': 1950},
        const {'Sb2': 1970, 'Sb1': 1985, 'F': 1990, 'Un': 1965, 'Fa': 1960},
        const {'Au': 1950, 'Mo': 1960, 'Un': 1970, 'Fa': 1955},
      ]) {
        final layout = fixture(years);
        expectBlocksContiguous(layout, positionGenogram(layout), '$years');
      }
    });

    test('irmãos do foco por idade na fixture: Sb2 (1970) < Sb1 (1985) < F '
        '(1990), cada um com seu bloco', () {
      final layout = fixture(const {'Sb2': 1970, 'Sb1': 1985, 'F': 1990});
      final d = positionGenogram(layout);
      expect(
          leftToRight(d, {'F', 'FW', 'Sb1X', 'Sb1', 'Sb1Y', 'Sb2'}),
          ['Sb2', 'Sb1X', 'Sb1', 'Sb1Y', 'F', 'FW']);
    });

    test('M6: o bloco Fa–Mo é comparado na fratria materna pela Mo (filha de '
        'MGF/MGM): a ancestral fica no lado interno, antes de Au, qualquer '
        'que seja a idade', () {
      for (final years in <Map<String, int>>[
        const {'Au': 1950, 'Mo': 1960, 'Un': 1970, 'Fa': 1955}, // Au mais velha
        const {'Au': 1970, 'Mo': 1960, 'Un': 1940, 'Fa': 1955}, // Au mais nova
        const {}, // sem anos
      ]) {
        final layout = fixture(years);
        final d = positionGenogram(layout);
        expectBlocksContiguous(layout, d, '$years');
        // Ordem inteira da faixa: paterno (tio, pai) | materno (mãe, tia).
        expect(leftToRight(d, {'Un', 'UnW', 'Fa', 'Mo', 'Au'}),
            ['Un', 'UnW', 'Fa', 'Mo', 'Au'],
            reason: '$years');
      }
    });

    test('M6: o bloco do irmão é ordenado pelo ano do IRMÃO mesmo quando o '
        'cônjuge (id menor) abre o bloco', () {
      GLayout fam(int yU1, int yU2) => buildGenogramStructure(
            focusId: 'F',
            people: [
              const GPerson('GF', sex: GSex.male),
              const GPerson('GM', sex: GSex.female),
              const GPerson('Fa', sex: GSex.male),
              const GPerson('Mo', sex: GSex.female),
              const GPerson('F'),
              GPerson('Un1', birthYear: yU1),
              const GPerson('A_conj1'), // id menor que o de Un1
              GPerson('Un2', birthYear: yU2),
            ],
            edges: const [
              GEdge('GF', 'GM', GEdgeType.spouse),
              GEdge('GF', 'Fa', _pc), GEdge('GM', 'Fa', _pc),
              GEdge('GF', 'Un1', _pc), GEdge('GM', 'Un1', _pc),
              GEdge('GF', 'Un2', _pc), GEdge('GM', 'Un2', _pc),
              GEdge('Un1', 'A_conj1', GEdgeType.spouse),
              GEdge('Fa', 'Mo', GEdgeType.spouse),
              GEdge('Fa', 'F', _pc), GEdge('Mo', 'F', _pc),
            ],
          );
      // Un2 mais velho: o bloco dele vem antes do de Un1 (que tem o cônjuge).
      var l = fam(1960, 1950);
      var d = positionGenogram(l);
      expect(leftToRight(d, {'Un1', 'A_conj1', 'Un2'}),
          ['Un2', 'Un1', 'A_conj1']);
      expectBlocksContiguous(l, d, 'Un2 mais velho');
      // Un1 mais velho: ordem invertida.
      l = fam(1950, 1960);
      d = positionGenogram(l);
      expect(leftToRight(d, {'Un1', 'A_conj1', 'Un2'}),
          ['Un1', 'A_conj1', 'Un2']);
      expectBlocksContiguous(l, d, 'Un1 mais velho');
    });

    test('M2: ancestral segue no lado interno, mesmo mais velho que o tio', () {
      final layout = buildGenogramStructure(
        focusId: 'F',
        people: const [
          GPerson('F'),
          GPerson('Fa', sex: GSex.male, birthYear: 1940),
          GPerson('Mo', sex: GSex.female),
          GPerson('Un', birthYear: 1950),
          GPerson('GF', sex: GSex.male),
          GPerson('GM', sex: GSex.female),
        ],
        edges: const [
          GEdge('GF', 'GM', GEdgeType.spouse),
          GEdge('GF', 'Fa', _pc),
          GEdge('GM', 'Fa', _pc),
          GEdge('GF', 'Un', _pc),
          GEdge('GM', 'Un', _pc),
          GEdge('Fa', 'Mo', GEdgeType.spouse),
          GEdge('Fa', 'F', _pc),
          GEdge('Mo', 'F', _pc),
        ],
      );
      final d = positionGenogram(layout);
      expect(xOf(d, 'Un') < xOf(d, 'Fa'), isTrue);
    });
  });

  group('#41 — cônjuge à direita e descida do filho', () {
    // Ids escolhidos para a esposa vir ANTES do paciente na ordem por id.
    GLayout casal({bool filhaComOsDois = false}) => buildGenogramStructure(
          focusId: 'Z_pac',
          people: const [
            GPerson('Z_pac', sex: GSex.male),
            GPerson('A_esposa', sex: GSex.female),
            GPerson('M_filha', sex: GSex.female),
          ],
          edges: [
            const GEdge('Z_pac', 'A_esposa', GEdgeType.spouse),
            const GEdge('Z_pac', 'M_filha', _pc),
            if (filhaComOsDois) const GEdge('A_esposa', 'M_filha', _pc),
          ],
        );

    test('paciente com pais: a esposa fica à DIREITA, ao lado dele', () {
      final layout = buildGenogramStructure(
        focusId: 'Z_pac',
        people: const [
          GPerson('Fa', sex: GSex.male),
          GPerson('Mo', sex: GSex.female),
          GPerson('Z_pac', sex: GSex.male),
          GPerson('A_esposa', sex: GSex.female),
          GPerson('Irmao', sex: GSex.male),
        ],
        edges: const [
          GEdge('Fa', 'Mo', GEdgeType.spouse),
          GEdge('Fa', 'Z_pac', _pc),
          GEdge('Mo', 'Z_pac', _pc),
          GEdge('Fa', 'Irmao', _pc),
          GEdge('Mo', 'Irmao', _pc),
          GEdge('Z_pac', 'A_esposa', GEdgeType.spouse),
        ],
      );
      final d = positionGenogram(layout);
      expect(xOf(d, 'A_esposa') - xOf(d, 'Z_pac'), d.colWidth);
    });

    test('cônjuge de um irmão fica à direita dele, nunca entre os irmãos', () {
      final layout = buildGenogramStructure(
        focusId: 'F',
        people: const [
          GPerson('Fa', sex: GSex.male),
          GPerson('Mo', sex: GSex.female),
          GPerson('F'),
          GPerson('Irmao', birthYear: 1980),
          GPerson('A_cunhada', sex: GSex.female),
        ],
        edges: const [
          GEdge('Fa', 'Mo', GEdgeType.spouse),
          GEdge('Fa', 'F', _pc),
          GEdge('Mo', 'F', _pc),
          GEdge('Fa', 'Irmao', _pc),
          GEdge('Mo', 'Irmao', _pc),
          GEdge('Irmao', 'A_cunhada', GEdgeType.spouse),
        ],
      );
      final d = positionGenogram(layout);
      expect(xOf(d, 'A_cunhada') - xOf(d, 'Irmao'), d.colWidth);
    });

    test('filha ligada só ao paciente: a descida parte do centro da linha do '
        'casal', () {
      final layout = casal();
      final d = positionGenogram(layout);
      final g = layout.sibGroups.single;
      final drop = sibGroupDropX(layout, d, g)!;
      expect(drop, (xOf(d, 'Z_pac') + xOf(d, 'A_esposa')) / 2);
      // e não do centro do próprio paciente
      expect(drop, isNot(xOf(d, 'Z_pac')));
      // a filha fica sob o centro do casal
      expect(xOf(d, 'M_filha'), drop);
    });

    test('filha ligada aos dois: a descida também é o centro do casal', () {
      final layout = casal(filhaComOsDois: true);
      final d = positionGenogram(layout);
      expect(sibGroupDropX(layout, d, layout.sibGroups.single),
          (xOf(d, 'Z_pac') + xOf(d, 'A_esposa')) / 2);
    });

    test('sem cônjuge, ou com ex apenas: a descida segue do próprio pai/mãe',
        () {
      final layout = buildGenogramStructure(
        focusId: 'P',
        people: const [GPerson('P'), GPerson('K'), GPerson('Ex')],
        edges: const [
          GEdge('P', 'K', _pc),
          GEdge('P', 'Ex', GEdgeType.exSpouse),
        ],
      );
      final d = positionGenogram(layout);
      expect(sibGroupDropX(layout, d, layout.sibGroups.single), xOf(d, 'P'));
    });
  });
}
