import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_layout.dart';

void main() {
  group('buildGenogramStructure', () {
    test('família nuclear: gerações e linhagens do pai/mãe', () {
      final layout = buildGenogramStructure(
        focusId: 'F',
        people: const [
          GPerson('F'),
          GPerson('Fa', sex: GSex.male),
          GPerson('Mo', sex: GSex.female),
          GPerson('Si'),
        ],
        edges: const [
          GEdge('Fa', 'F', GEdgeType.parentChild),
          GEdge('Mo', 'F', GEdgeType.parentChild),
          GEdge('Fa', 'Si', GEdgeType.parentChild),
          GEdge('Mo', 'Si', GEdgeType.parentChild),
          GEdge('Fa', 'Mo', GEdgeType.spouse),
        ],
      );

      // Gerações
      expect(layout.placed['F']!.generation, 0);
      expect(layout.placed['Si']!.generation, 0);
      expect(layout.placed['Fa']!.generation, -1);
      expect(layout.placed['Mo']!.generation, -1);

      // Linhagens
      expect(layout.placed['F']!.lineage, GLineage.self);
      expect(layout.placed['Si']!.lineage, GLineage.self);
      expect(layout.placed['Fa']!.lineage, GLineage.paternal);
      expect(layout.placed['Mo']!.lineage, GLineage.maternal);

      // Todos conectados
      expect(layout.placed.values.every((p) => p.connected), isTrue);

      // Um casal
      expect(layout.couples.length, 1);

      // Um grupo de irmãos [F, Si]
      final sib = layout.sibGroups.firstWhere((g) => g.members.contains('F'));
      expect(sib.members.toSet(), {'F', 'Si'});
      expect(sib.parents, {'Fa', 'Mo'});
    });

    test('árvore bilateral: avós paternos e maternos na linhagem certa', () {
      final layout = buildGenogramStructure(
        focusId: 'F',
        people: const [
          GPerson('F'),
          GPerson('Fa', sex: GSex.male),
          GPerson('Mo', sex: GSex.female),
          GPerson('GpP', sex: GSex.male), // avô paterno
          GPerson('GmP', sex: GSex.female), // avó paterna
          GPerson('GpM', sex: GSex.male), // avô materno
          GPerson('GmM', sex: GSex.female), // avó materna
        ],
        edges: const [
          GEdge('Fa', 'F', GEdgeType.parentChild),
          GEdge('Mo', 'F', GEdgeType.parentChild),
          GEdge('Fa', 'Mo', GEdgeType.spouse),
          // linhagem paterna
          GEdge('GpP', 'Fa', GEdgeType.parentChild),
          GEdge('GmP', 'Fa', GEdgeType.parentChild),
          GEdge('GpP', 'GmP', GEdgeType.spouse),
          // linhagem materna
          GEdge('GpM', 'Mo', GEdgeType.parentChild),
          GEdge('GmM', 'Mo', GEdgeType.parentChild),
          GEdge('GpM', 'GmM', GEdgeType.spouse),
        ],
      );

      // Gerações dos avós
      for (final id in ['GpP', 'GmP', 'GpM', 'GmM']) {
        expect(layout.placed[id]!.generation, -2, reason: '$id deve ser -2');
      }

      // Linhagens
      expect(layout.placed['GpP']!.lineage, GLineage.paternal);
      expect(layout.placed['GmP']!.lineage, GLineage.paternal);
      expect(layout.placed['GpM']!.lineage, GLineage.maternal);
      expect(layout.placed['GmM']!.lineage, GLineage.maternal);
    });

    test('tia paterna herda a linhagem do pai', () {
      final layout = buildGenogramStructure(
        focusId: 'F',
        people: const [
          GPerson('F'),
          GPerson('Fa', sex: GSex.male),
          GPerson('Mo', sex: GSex.female),
          GPerson('GpP', sex: GSex.male),
          GPerson('GmP', sex: GSex.female),
          GPerson('Sofia', sex: GSex.female), // tia paterna
        ],
        edges: const [
          GEdge('Fa', 'F', GEdgeType.parentChild),
          GEdge('Mo', 'F', GEdgeType.parentChild),
          GEdge('Fa', 'Mo', GEdgeType.spouse),
          GEdge('GpP', 'Fa', GEdgeType.parentChild),
          GEdge('GmP', 'Fa', GEdgeType.parentChild),
          GEdge('GpP', 'Sofia', GEdgeType.parentChild),
          GEdge('GmP', 'Sofia', GEdgeType.parentChild),
        ],
      );

      expect(layout.placed['Sofia']!.generation, -1);
      expect(layout.placed['Sofia']!.lineage, GLineage.paternal);
      expect(layout.placed['Sofia']!.connected, isTrue);
    });

    test('pessoa sem vínculo estrutural fica não-conectada (fallback)', () {
      final layout = buildGenogramStructure(
        focusId: 'F',
        people: const [
          GPerson('F'),
          GPerson('Fa', sex: GSex.male),
          GPerson('X'), // solta, sem arestas
        ],
        edges: const [
          GEdge('Fa', 'F', GEdgeType.parentChild),
        ],
      );

      expect(layout.placed['X']!.connected, isFalse);
      expect(layout.placed['X']!.lineage, GLineage.unknown);
      expect(layout.placed['F']!.connected, isTrue);
      expect(layout.placed['Fa']!.connected, isTrue);
      expect(layout.unconnected.map((p) => p.id).toList(), ['X']);
    });

    test('descendentes do foco entram na própria linhagem', () {
      final layout = buildGenogramStructure(
        focusId: 'F',
        people: const [
          GPerson('F'),
          GPerson('Filho'),
        ],
        edges: const [
          GEdge('F', 'Filho', GEdgeType.parentChild),
        ],
      );

      expect(layout.placed['Filho']!.generation, 1);
      expect(layout.placed['Filho']!.lineage, GLineage.self);
    });
  });

  group('positionGenogram', () {
    GLayout bilateral() => buildGenogramStructure(
          focusId: 'F',
          people: const [
            GPerson('F'),
            GPerson('Fa', sex: GSex.male),
            GPerson('Mo', sex: GSex.female),
            GPerson('GpP', sex: GSex.male),
            GPerson('GmP', sex: GSex.female),
            GPerson('GpM', sex: GSex.male),
            GPerson('GmM', sex: GSex.female),
          ],
          edges: const [
            GEdge('Fa', 'F', GEdgeType.parentChild),
            GEdge('Mo', 'F', GEdgeType.parentChild),
            GEdge('Fa', 'Mo', GEdgeType.spouse),
            GEdge('GpP', 'Fa', GEdgeType.parentChild),
            GEdge('GmP', 'Fa', GEdgeType.parentChild),
            GEdge('GpP', 'GmP', GEdgeType.spouse),
            GEdge('GpM', 'Mo', GEdgeType.parentChild),
            GEdge('GmM', 'Mo', GEdgeType.parentChild),
            GEdge('GpM', 'GmM', GEdgeType.spouse),
          ],
        );

    test('mesma geração → mesmo y; gerações empilhadas do topo', () {
      final d = positionGenogram(bilateral());
      // avós na mesma faixa
      expect(d.byId('GpP')!.y, d.byId('GmM')!.y);
      // pais na mesma faixa
      expect(d.byId('Fa')!.y, d.byId('Mo')!.y);
      // ancestral mais alto tem y menor (mais no topo)
      expect(d.byId('GpP')!.y, lessThan(d.byId('Fa')!.y));
      expect(d.byId('Fa')!.y, lessThan(d.byId('F')!.y));
    });

    test('paterna à esquerda, materna à direita', () {
      final d = positionGenogram(bilateral());
      // na faixa dos pais: pai (paterna) à esquerda da mãe (materna)
      expect(d.byId('Fa')!.x, lessThan(d.byId('Mo')!.x));
      // na faixa dos avós: paternos à esquerda dos maternos
      final patX = [d.byId('GpP')!.x, d.byId('GmP')!.x].reduce((a, b) => a > b ? a : b);
      final matX = [d.byId('GpM')!.x, d.byId('GmM')!.x].reduce((a, b) => a < b ? a : b);
      expect(patX, lessThan(matX));
    });

    test('casais ficam adjacentes (uma coluna de distância)', () {
      final d = positionGenogram(bilateral(), colWidth: 100);
      expect((d.byId('Fa')!.x - d.byId('Mo')!.x).abs(), 100);
      expect((d.byId('GpP')!.x - d.byId('GmP')!.x).abs(), 100);
    });

    test('tia paterna fica no lado externo (à esquerda do pai)', () {
      final layout = buildGenogramStructure(
        focusId: 'F',
        people: const [
          GPerson('F'),
          GPerson('Fa', sex: GSex.male),
          GPerson('Mo', sex: GSex.female),
          GPerson('GpP', sex: GSex.male),
          GPerson('GmP', sex: GSex.female),
          GPerson('Tia', sex: GSex.female),
        ],
        edges: const [
          GEdge('Fa', 'F', GEdgeType.parentChild),
          GEdge('Mo', 'F', GEdgeType.parentChild),
          GEdge('Fa', 'Mo', GEdgeType.spouse),
          GEdge('GpP', 'Fa', GEdgeType.parentChild),
          GEdge('GmP', 'Fa', GEdgeType.parentChild),
          GEdge('GpP', 'Tia', GEdgeType.parentChild),
          GEdge('GmP', 'Tia', GEdgeType.parentChild),
        ],
      );
      final d = positionGenogram(layout);
      // Tia (externo) < Pai (interno) < Mãe
      expect(d.byId('Tia')!.x, lessThan(d.byId('Fa')!.x));
      expect(d.byId('Fa')!.x, lessThan(d.byId('Mo')!.x));
      // Tia é paterna, então fica à esquerda da mãe (materna)
      expect(d.byId('Tia')!.x, lessThan(d.byId('Mo')!.x));
    });

    test('não-conectados vão para a faixa solta na base', () {
      final layout = buildGenogramStructure(
        focusId: 'F',
        people: const [
          GPerson('F'),
          GPerson('Fa', sex: GSex.male),
          GPerson('X'),
        ],
        edges: const [GEdge('Fa', 'F', GEdgeType.parentChild)],
      );
      final d = positionGenogram(layout);
      // X está abaixo de todo mundo conectado
      final maxConnectedY = d.nodes
          .where((n) => n.connected)
          .map((n) => n.y)
          .reduce((a, b) => a > b ? a : b);
      expect(d.byId('X')!.y, greaterThan(maxConnectedY));
      expect(d.byId('X')!.connected, isFalse);
    });
  });
}
