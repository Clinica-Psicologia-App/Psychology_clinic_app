/// Motor de layout do genograma — **Dart puro** (sem Flutter/Supabase).
///
/// Recebe pessoas + vínculos ESTRUTURAIS explícitos (casamento e pai/mãe–filho)
/// e calcula, para cada pessoa: a **geração**, a **linhagem** (paterna, materna
/// ou própria), os **casais** e os **grupos de irmãos**. Pessoas sem nenhum
/// vínculo estrutural são marcadas como **não-conectadas** (o desenho as trata
/// pelo fallback antigo).
///
/// É o núcleo que a Etapa 2 (desenho das duas linhagens) consome. Não faz
/// posicionamento em pixels ainda — só a topologia; o posicionamento estético
/// (bandas, faixas) vem depois, sobre esta base.
library;

/// Sexo usado para decidir o lado da linhagem (pai → paterna, mãe → materna).
enum GSex { male, female, unknown }

/// Tipos de vínculo ESTRUTURAL (os que definem a árvore). Os vínculos
/// emocionais (conflito, próxima…) são outra camada e não entram aqui.
enum GEdgeType { spouse, exSpouse, parentChild }

/// Linhagem de uma pessoa em relação ao paciente (foco).
enum GLineage { paternal, maternal, self, unknown }

/// Uma pessoa, para o motor (só o que o layout precisa).
class GPerson {
  final String id;
  final GSex sex;
  const GPerson(this.id, {this.sex = GSex.unknown});
}

/// Um vínculo estrutural.
/// - `parentChild`: [a] é o pai/mãe, [b] é o filho(a).
/// - `spouse` / `exSpouse`: [a] e [b] são o casal (sem direção).
class GEdge {
  final String a;
  final String b;
  final GEdgeType type;
  const GEdge(this.a, this.b, this.type);
}

/// Resultado por pessoa.
class GPlaced {
  final String id;

  /// 0 = geração do paciente; negativo = ancestrais; positivo = descendentes.
  int generation;
  GLineage lineage;

  /// `false` quando a pessoa não tem vínculo estrutural que a ligue ao foco.
  bool connected;

  /// `true` se está na linha ancestral direta do foco (pai, avós…). Usado para
  /// posicionar: ancestrais no lado interno, tios/tias no externo.
  bool ancestor;

  GPlaced(
    this.id, {
    this.generation = 0,
    this.lineage = GLineage.unknown,
    this.connected = false,
    this.ancestor = false,
  });
}

/// Um casal (para desenhar a linha de união).
class GCouple {
  final String a;
  final String b;

  /// `true` para casamento atual; `false` para ex (divórcio/separação).
  final bool current;
  const GCouple(this.a, this.b, {this.current = true});
}

/// Um grupo de irmãos (filhos do mesmo conjunto de pais).
class GSibGroup {
  final List<String> members;
  final Set<String> parents;
  const GSibGroup(this.members, this.parents);
}

/// A topologia calculada.
class GLayout {
  final Map<String, GPlaced> placed;
  final List<GCouple> couples;
  final List<GSibGroup> sibGroups;
  const GLayout(this.placed, this.couples, this.sibGroups);

  Iterable<GPlaced> get connected => placed.values.where((p) => p.connected);
  Iterable<GPlaced> get unconnected => placed.values.where((p) => !p.connected);
}

/// Calcula a topologia do genograma a partir dos vínculos explícitos.
GLayout buildGenogramStructure({
  required List<GPerson> people,
  required List<GEdge> edges,
  required String focusId,
}) {
  final ids = {for (final p in people) p.id};
  final sex = {for (final p in people) p.id: p.sex};

  // ── Adjacência ────────────────────────────────────────────────────────────
  final parentsOf = {for (final id in ids) id: <String>{}};
  final childrenOf = {for (final id in ids) id: <String>{}};
  final spouseOf = {for (final id in ids) id: <String>{}};
  final couples = <GCouple>[];

  for (final e in edges) {
    if (!ids.contains(e.a) || !ids.contains(e.b) || e.a == e.b) continue;
    switch (e.type) {
      case GEdgeType.parentChild:
        parentsOf[e.b]!.add(e.a);
        childrenOf[e.a]!.add(e.b);
      case GEdgeType.spouse:
      case GEdgeType.exSpouse:
        spouseOf[e.a]!.add(e.b);
        spouseOf[e.b]!.add(e.a);
        couples.add(GCouple(e.a, e.b, current: e.type == GEdgeType.spouse));
    }
  }

  final placed = {for (final id in ids) id: GPlaced(id)};

  if (!ids.contains(focusId)) {
    return GLayout(placed, couples, _siblingGroups(ids, parentsOf));
  }

  // ── Geração: BFS a partir do foco ─────────────────────────────────────────
  final gen = <String, int>{focusId: 0};
  final queue = <String>[focusId];
  placed[focusId]!
    ..generation = 0
    ..connected = true;

  while (queue.isNotEmpty) {
    final cur = queue.removeAt(0);
    final g = gen[cur]!;
    void visit(String other, int og) {
      if (!ids.contains(other) || gen.containsKey(other)) return;
      gen[other] = og;
      placed[other]!
        ..generation = og
        ..connected = true;
      queue.add(other);
    }

    for (final p in parentsOf[cur]!) {
      visit(p, g - 1);
    }
    for (final c in childrenOf[cur]!) {
      visit(c, g + 1);
    }
    for (final s in spouseOf[cur]!) {
      visit(s, g);
    }
  }

  // ── Linhagem ──────────────────────────────────────────────────────────────
  final focusParents = parentsOf[focusId]!.toList();
  String? paternalRoot;
  String? maternalRoot;
  for (final p in focusParents) {
    if (sex[p] == GSex.male && paternalRoot == null) {
      paternalRoot = p;
    } else if (sex[p] == GSex.female && maternalRoot == null) {
      maternalRoot = p;
    }
  }
  // Sexo não resolveu tudo: completa por ordem (1º livre = paterno).
  for (final p in focusParents) {
    if (p != paternalRoot && p != maternalRoot) {
      if (paternalRoot == null) {
        paternalRoot = p;
      } else {
        maternalRoot ??= p;
      }
    }
  }

    // O pai e a mãe são cônjuges e são as DUAS raízes de linhagens distintas;
    // por isso eles não podem propagar linhagem via casamento (um contaminaria
    // o outro). Só os ancestrais acima deles (e tios) propagam para o cônjuge.
    final rootParents = focusParents.toSet();

    void assignLine(String? root, GLineage lin) {
      if (root == null) return;
      final stack = <String>[root];
      final seen = <String>{};
      while (stack.isNotEmpty) {
        final x = stack.removeLast();
        if (!seen.add(x) || x == focusId) continue;
        placed[x]!.lineage = lin;
        // sobe aos pais (ancestrais)
        for (final pp in parentsOf[x]!) {
          stack.add(pp);
          // tios: irmãos de x (demais filhos dos pais de x)
          for (final sib in childrenOf[pp]!) {
            stack.add(sib);
          }
        }
        // cônjuge do ancestral entra na mesma linhagem — exceto os pais do
        // foco, que são as raízes opostas.
        if (!rootParents.contains(x)) {
          for (final sp in spouseOf[x]!) {
            stack.add(sp);
          }
        }
      }
    }

  assignLine(paternalRoot, GLineage.paternal);
  assignLine(maternalRoot, GLineage.maternal);

  // Foco, seu cônjuge, irmãos e descendentes = própria linhagem.
  placed[focusId]!.lineage = GLineage.self;
  for (final s in spouseOf[focusId]!) {
    placed[s]!.lineage = GLineage.self;
  }
  for (final p in focusParents) {
    for (final sib in childrenOf[p]!) {
      if (sib != focusId) placed[sib]!.lineage = GLineage.self;
    }
  }
  for (final pl in placed.values) {
    if (pl.generation > 0) pl.lineage = GLineage.self;
  }

  // Linha ancestral direta (spine): sobe do foco só pelos pais — NÃO inclui
  // irmãos dos ancestrais (tios). Serve para o posicionamento colocar os
  // ancestrais no lado interno e os tios/tias no externo.
  {
    final stack = <String>[...focusParents];
    final seen = <String>{};
    while (stack.isNotEmpty) {
      final x = stack.removeLast();
      if (!seen.add(x)) continue;
      placed[x]!.ancestor = true;
      stack.addAll(parentsOf[x]!);
    }
  }

  return GLayout(placed, couples, _siblingGroups(ids, parentsOf));
}

/// Uma pessoa já posicionada em coordenadas.
class GPositioned {
  final String id;
  final int generation;
  final GLineage lineage;
  final bool connected;
  final double x;
  final double y;
  const GPositioned(
    this.id, {
    required this.generation,
    required this.lineage,
    required this.connected,
    required this.x,
    required this.y,
  });
}

/// O diagrama posicionado, pronto para o desenho.
class GDiagram {
  final List<GPositioned> nodes;
  final double width;
  final double height;
  final double colWidth;
  final double rowHeight;
  const GDiagram(
    this.nodes, {
    required this.width,
    required this.height,
    required this.colWidth,
    required this.rowHeight,
  });

  GPositioned? byId(String id) {
    for (final n in nodes) {
      if (n.id == id) return n;
    }
    return null;
  }
}

/// Converte a topologia em coordenadas do desenho bilateral: cada geração numa
/// faixa horizontal (mais ancestral no topo), linhagem paterna à esquerda e
/// materna à direita, casais adjacentes. Pessoas não-conectadas vão para uma
/// faixa solta na base (fallback). Posicionamento v1: agrupa por linhagem e
/// centra cada faixa; o refino de centralizar pais sobre filhos vem depois.
GDiagram positionGenogram(
  GLayout layout, {
  double colWidth = 120,
  double rowHeight = 150,
  double margin = 40,
}) {
  final connected = layout.placed.values.where((p) => p.connected).toList();
  final unconnected = layout.placed.values.where((p) => !p.connected).toList();

  final spouse = <String, String>{};
  for (final c in layout.couples) {
    spouse[c.a] = c.b;
    spouse[c.b] = c.a;
  }

  final byGen = <int, List<GPlaced>>{};
  for (final p in connected) {
    byGen.putIfAbsent(p.generation, () => []).add(p);
  }
  final gens = byGen.keys.toList()..sort(); // ascendente: ancestral no topo

  // Ordena cada faixa: linhagem paterna | própria | materna, com os ancestrais
  // diretos no lado INTERNO (perto do centro) e os tios/tias no EXTERNO, e os
  // casais adjacentes.
  final rowOrders = <int, List<String>>{};
  for (final g in gens) {
    final people = byGen[g]!;
    List<GPlaced> cluster(GLineage l, {required bool ancestorRight}) {
      final list = people.where((p) => p.lineage == l).toList()
        ..sort((a, b) {
          final av = a.ancestor ? 1 : 0;
          final bv = b.ancestor ? 1 : 0;
          // paterna: ancestral por último (direita/interno).
          // materna: ancestral primeiro (esquerda/interno).
          final byAnc = ancestorRight ? av.compareTo(bv) : bv.compareTo(av);
          return byAnc != 0 ? byAnc : a.id.compareTo(b.id);
        });
      return list;
    }

    final base = <GPlaced>[
      ...cluster(GLineage.paternal, ancestorRight: true),
      ...cluster(GLineage.self, ancestorRight: true),
      ...cluster(GLineage.maternal, ancestorRight: false),
      ...cluster(GLineage.unknown, ancestorRight: true),
    ];

    final inGen = {for (final p in base) p.id};
    final order = <String>[];
    final done = <String>{};
    for (final p in base) {
      if (done.contains(p.id)) continue;
      order.add(p.id);
      done.add(p.id);
      final sp = spouse[p.id];
      if (sp != null && inGen.contains(sp) && !done.contains(sp)) {
        order.add(sp);
        done.add(sp);
      }
    }
    rowOrders[g] = order;
  }

  final maxCount = rowOrders.values
      .fold<int>(0, (m, l) => l.length > m ? l.length : m)
      .clamp(1, 1 << 30);
  final looseRow = unconnected.isNotEmpty ? 1 : 0;
  final width = maxCount * colWidth + 2 * margin;
  final height = (gens.length + looseRow) * rowHeight + 2 * margin;

  final nodes = <GPositioned>[];
  for (var r = 0; r < gens.length; r++) {
    final g = gens[r];
    final order = rowOrders[g]!;
    final rowWidth = order.length * colWidth;
    final startX = margin + (maxCount * colWidth - rowWidth) / 2 + colWidth / 2;
    final y = margin + r * rowHeight + rowHeight / 2;
    for (var i = 0; i < order.length; i++) {
      final pl = layout.placed[order[i]]!;
      nodes.add(GPositioned(
        pl.id,
        generation: g,
        lineage: pl.lineage,
        connected: true,
        x: startX + i * colWidth,
        y: y,
      ));
    }
  }

  if (unconnected.isNotEmpty) {
    final rowWidth = unconnected.length * colWidth;
    final startX = margin + (maxCount * colWidth - rowWidth) / 2 + colWidth / 2;
    final y = margin + gens.length * rowHeight + rowHeight / 2;
    for (var i = 0; i < unconnected.length; i++) {
      final pl = unconnected[i];
      nodes.add(GPositioned(
        pl.id,
        generation: pl.generation,
        lineage: pl.lineage,
        connected: false,
        x: startX + i * colWidth,
        y: y,
      ));
    }
  }

  return GDiagram(
    nodes,
    width: width,
    height: height,
    colWidth: colWidth,
    rowHeight: rowHeight,
  );
}

/// Agrupa pessoas que compartilham exatamente o mesmo conjunto de pais.
List<GSibGroup> _siblingGroups(
  Set<String> ids,
  Map<String, Set<String>> parentsOf,
) {
  final byParents = <String, List<String>>{};
  for (final id in ids) {
    final ps = parentsOf[id]!;
    if (ps.isEmpty) continue;
    final key = (ps.toList()..sort()).join('|');
    byParents.putIfAbsent(key, () => []).add(id);
  }
  return [
    for (final e in byParents.entries)
      GSibGroup(e.value, e.key.split('|').toSet()),
  ];
}
