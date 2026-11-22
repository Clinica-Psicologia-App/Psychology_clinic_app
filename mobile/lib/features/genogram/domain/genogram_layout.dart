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
enum GEdgeType { spouse, exSpouse, separation, parentChild }

/// Linhagem de uma pessoa em relação ao paciente (foco).
enum GLineage { paternal, maternal, self, unknown }

/// Tipos de relação EMOCIONAL (camada 2), separados da estrutura.
enum GEmotion { close, distant, conflict, broken, closeAndConflict }

/// Uma relação emocional entre duas pessoas (para o overlay do desenho).
class GEmotionalRel {
  final String a;
  final String b;
  final GEmotion kind;
  const GEmotionalRel(this.a, this.b, this.kind);
}

/// Uma pessoa, para o motor (só o que o layout precisa).
class GPerson {
  final String id;
  final GSex sex;

  /// Ano de nascimento (opcional). Só ordena irmãos do mesmo grupo (mais velho
  /// à esquerda); sem ano a pessoa fica onde já ficaria (e vai após quem tem).
  final int? birthYear;
  const GPerson(this.id, {this.sex = GSex.unknown, this.birthYear});
}

/// Um vínculo estrutural.
/// - `parentChild`: [a] é o pai/mãe, [b] é o filho(a).
/// - `spouse` / `exSpouse`: [a] e [b] são o casal (sem direção).
class GEdge {
  final String a;
  final String b;
  final GEdgeType type;

  /// Só em `parentChild`: filiação adotiva (descida tracejada no desenho).
  final bool adopted;
  const GEdge(this.a, this.b, this.type, {this.adopted = false});
}

/// Um par de gêmeos (irmãos ligados por um ponto único na barra de irmãos).
class GTwin {
  final String a;
  final String b;
  const GTwin(this.a, this.b);
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

  /// Cópia de [GPerson.birthYear] (ordenação de irmãos).
  final int? birthYear;

  GPlaced(
    this.id, {
    this.generation = 0,
    this.lineage = GLineage.unknown,
    this.connected = false,
    this.ancestor = false,
    this.birthYear,
  });
}

/// Um casal (para desenhar a linha de união).
class GCouple {
  final String a;
  final String b;

  /// `true` para casamento atual; `false` para ex (divórcio ou separação).
  final bool current;

  /// `true` para separação (1 barra "/"); `false` para divórcio (2 barras "//").
  /// Só relevante quando [current] é `false`.
  final bool separated;
  const GCouple(this.a, this.b,
      {this.current = true, this.separated = false});
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

  /// Grupos de gêmeos (cada conjunto liga-se por um único ponto na barra).
  final List<Set<String>> twinGroups;

  /// Filhos com filiação adotiva (descida tracejada).
  final Set<String> adoptedChildren;
  const GLayout(
    this.placed,
    this.couples,
    this.sibGroups, {
    this.twinGroups = const [],
    this.adoptedChildren = const {},
  });

  Iterable<GPlaced> get connected => placed.values.where((p) => p.connected);
  Iterable<GPlaced> get unconnected => placed.values.where((p) => !p.connected);
}

/// Calcula a topologia do genograma a partir dos vínculos explícitos.
GLayout buildGenogramStructure({
  required List<GPerson> people,
  required List<GEdge> edges,
  required String focusId,
  List<GTwin> twins = const [],
}) {
  final ids = {for (final p in people) p.id};
  final sex = {for (final p in people) p.id: p.sex};

  // Filhos adotivos (aresta parentChild marcada) e grupos de gêmeos — camadas
  // de desenho, independentes da geração/linhagem.
  final adoptedChildren = <String>{
    for (final e in edges)
      if (e.type == GEdgeType.parentChild && e.adopted) e.b,
  };
  final twinGroups = _twinGroups(twins, ids);

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
      case GEdgeType.separation:
        spouseOf[e.a]!.add(e.b);
        spouseOf[e.b]!.add(e.a);
        couples.add(GCouple(e.a, e.b,
            current: e.type == GEdgeType.spouse,
            separated: e.type == GEdgeType.separation));
    }
  }

  final placed = {
    for (final p in people) p.id: GPlaced(p.id, birthYear: p.birthYear),
  };

  if (!ids.contains(focusId)) {
    return GLayout(
      placed,
      couples,
      _siblingGroups(ids, parentsOf),
      twinGroups: twinGroups,
      adoptedChildren: adoptedChildren,
    );
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

  return GLayout(
    placed,
    couples,
    _siblingGroups(ids, parentsOf),
    twinGroups: twinGroups,
    adoptedChildren: adoptedChildren,
  );
}

/// Une os pares de gêmeos em grupos (union-find simples), só ids existentes.
List<Set<String>> _twinGroups(List<GTwin> twins, Set<String> ids) {
  final groups = <Set<String>>[];
  for (final t in twins) {
    if (!ids.contains(t.a) || !ids.contains(t.b) || t.a == t.b) continue;
    Set<String>? ga, gb;
    for (final g in groups) {
      if (g.contains(t.a)) ga = g;
      if (g.contains(t.b)) gb = g;
    }
    if (ga == null && gb == null) {
      groups.add({t.a, t.b});
    } else if (ga != null && gb == null) {
      ga.add(t.b);
    } else if (ga == null && gb != null) {
      gb.add(t.a);
    } else if (ga != null && gb != null && !identical(ga, gb)) {
      ga.addAll(gb);
      groups.remove(gb);
    }
  }
  return groups;
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
/// faixa solta na base (fallback). O posicionamento horizontal parte da geração
/// mais NOVA (âncora) para a mais velha, centralizando cada pai/casal sobre a
/// média dos filhos já posicionados — assim as linhas de descida saem retas.
GDiagram positionGenogram(
  GLayout layout, {
  double colWidth = 120,
  double rowHeight = 150,
  double margin = 40,
}) {
  final connected = layout.placed.values.where((p) => p.connected).toList();
  final unconnected = layout.placed.values.where((p) => !p.connected).toList();

  // ── Lookup de casais ───────────────────────────────────────────────────────
  // Suporta recasamentos: uma pessoa pode ter múltiplos cônjuges na mesma
  // geração. A chave "a|b" (IDs ordenados) identifica cada par de forma única.
  String ck(String a, String b) => ([a, b]..sort()).join('|');
  final coupleMap = <String, GCouple>{
    for (final c in layout.couples) ck(c.a, c.b): c,
  };
  // Todos os cônjuges por pessoa (pode ser mais de um).
  final spousesOf = <String, List<String>>{};
  for (final c in layout.couples) {
    (spousesOf[c.a] ??= []).add(c.b);
    (spousesOf[c.b] ??= []).add(c.a);
  }
  // Filhos específicos de cada casal (a partir dos grupos de irmãos com
  // exatamente 2 pais). Essencial para centrar cada casal sobre seus filhos
  // sem confundir filhos de uniões diferentes.
  final coupleKids = <String, Set<String>>{};
  for (final sg in layout.sibGroups) {
    if (sg.parents.length == 2) {
      final sorted = sg.parents.toList()..sort();
      coupleKids[ck(sorted[0], sorted[1])] = sg.members.toSet();
    }
  }

  // Quem é FILHO(A) de alguém na árvore (tem grupo de irmãos).
  final sibGroupOf = <String, int>{
    for (var i = 0; i < layout.sibGroups.length; i++)
      for (final m in layout.sibGroups[i].members) m: i,
  };

  final byGen = <int, List<GPlaced>>{};
  for (final p in connected) {
    byGen.putIfAbsent(p.generation, () => []).add(p);
  }
  final gens = byGen.keys.toList()..sort();

  // Ordena cada faixa: linhagem paterna | própria | materna, ancestrais no
  // lado INTERNO. Recasamentos formam cadeias: [ex... | pessoa | atual...].
  // Ex-cônjuges vão à ESQUERDA da pessoa; cônjuge atual vai à DIREITA.
  final rowOrders = <int, List<String>>{};
  for (final g in gens) {
    final people = byGen[g]!;
    List<GPlaced> cluster(GLineage l, {required bool ancestorRight}) {
      final list = people.where((p) => p.lineage == l).toList()
        ..sort((a, b) {
          final av = a.ancestor ? 1 : 0;
          final bv = b.ancestor ? 1 : 0;
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
    final baseIndex = {
      for (var i = 0; i < base.length; i++) base[i].id: i,
    };

    // BLOCO = cadeia CONEXA inteira de casamentos (e ex) da faixa, em linha
    // reta: [ex… | pessoa | atual…]. A pessoa-âncora é quem é FILHA de alguém na
    // árvore (o cônjuge de fora fica sempre ao lado dela, o atual à direita);
    // sem filha na cadeia, vale a primeira da faixa.
    final done = <String>{};
    List<String> expand(String x, int side) {
      // side 0: livre (ex à esquerda, atual à direita); -1: x tem de ficar
      // primeiro; 1: x tem de ficar por último (para tocar a âncora).
      done.add(x);
      final sp = (spousesOf[x] ?? [])
          .where((s) => inGen.contains(s) && !done.contains(s))
          .toList();
      done.addAll(sp);
      final exes = sp
          .where((s) => coupleMap[ck(x, s)]?.current == false)
          .toList();
      final curs = sp
          .where((s) => coupleMap[ck(x, s)]?.current != false)
          .toList();
      final left = <String>[];
      final right = <String>[];
      if (side == 0) {
        for (final ex in exes.reversed) {
          left.addAll(expand(ex, 1));
        }
        for (final cur in curs) {
          right.addAll(expand(cur, -1));
        }
      } else if (side == 1) {
        for (final s in [...exes.reversed, ...curs]) {
          left.addAll(expand(s, 1));
        }
      } else {
        for (final s in [...curs, ...exes]) {
          right.addAll(expand(s, -1));
        }
      }
      return [...left, x, ...right];
    }

    // Quem começou o bloco decide o lugar dele na faixa (linhagem/ancestral).
    final blocks = <({List<String> ids, GPlaced head})>[];
    for (final p in base) {
      if (done.contains(p.id)) continue;
      final comp = <String>{p.id};
      final stack = [p.id];
      while (stack.isNotEmpty) {
        final x = stack.removeLast();
        for (final s in spousesOf[x] ?? const <String>[]) {
          if (inGen.contains(s) && comp.add(s)) stack.add(s);
        }
      }
      final sorted = comp.toList()
        ..sort((a, b) => baseIndex[a]!.compareTo(baseIndex[b]!));
      final root = sorted.firstWhere(sibGroupOf.containsKey, orElse: () => p.id);
      blocks.add((ids: expand(root, 0), head: p));
    }

    // IDADE: dentro de cada grupo de irmãos (mesmos pais), os blocos dos irmãos
    // trocam de lugar entre si — mais velho primeiro, sem ano no fim, empate =
    // ordem atual. Só trocam blocos que ocupam a mesma região da faixa
    // (mesma linhagem e mesmo lado ancestral): linhagem e ancestralidade
    // continuam vindo antes da idade. O irmão é sempre a pessoa FILHA daqueles
    // pais; o ano do bloco é o dele. Um bloco só participa de um grupo (o
    // primeiro que o alcança) — assim dois grupos nunca se desfazem. Sem anos
    // a ordem não muda.
    final claimed = <int>{};
    for (var gi = 0; gi < layout.sibGroups.length; gi++) {
      final members = layout.sibGroups[gi].members.toSet();
      final byRegion = <String, List<int>>{};
      for (var i = 0; i < blocks.length; i++) {
        if (claimed.contains(i)) continue;
        if (!blocks[i].ids.any(members.contains)) continue;
        // Região de ordenação = a da pessoa FILHA daqueles pais (o membro da
        // fratria dentro do bloco), não a de quem abriu o bloco. Só troca
        // de lugar quem também ocupa o mesmo trecho da faixa (mesma região do
        // início do bloco), para nunca mover um bloco de linhagem.
        final m = blocks[i].ids.firstWhere(members.contains);
        final pm = layout.placed[m]!;
        final h = blocks[i].head;
        (byRegion['${pm.lineage.index}|${pm.ancestor}/'
                '${h.lineage.index}|${h.ancestor}'] ??= [])
            .add(i);
      }
      for (final slots in byRegion.values) {
        if (slots.length < 2) continue;
        int? yearOf(int i) {
          int? best;
          for (final id in blocks[i].ids) {
            if (!members.contains(id)) continue;
            final y = layout.placed[id]!.birthYear;
            if (y != null && (best == null || y < best)) best = y;
          }
          return best;
        }

        final order = [...slots]..sort((x, y) {
            final yx = yearOf(x), yy = yearOf(y);
            if (yx == yy) return x.compareTo(y);
            if (yx == null) return 1;
            if (yy == null) return -1;
            return yx.compareTo(yy);
          });
        final copy = [for (final i in order) blocks[i]];
        for (var k = 0; k < slots.length; k++) {
          blocks[slots[k]] = copy[k];
        }
        claimed.addAll(slots);
      }
    }
    rowOrders[g] = [for (final b in blocks) ...b.ids];
  }

  // childrenOf reconstruído dos grupos de irmãos.
  final childrenOf = <String, Set<String>>{};
  for (final sg in layout.sibGroups) {
    for (final par in sg.parents) {
      childrenOf.putIfAbsent(par, () => <String>{}).addAll(sg.members);
    }
  }

  // Posiciona da geração mais NOVA para a mais velha. Detecta cadeias de
  // recasamento [B, A, C] e posiciona cada par de casal sobre seus filhos.
  final xById = <String, double>{};
  for (var r = gens.length - 1; r >= 0; r--) {
    final order = rowOrders[gens[r]]!;
    final n = order.length;
    if (r == gens.length - 1) {
      for (var i = 0; i < n; i++) {
        xById[order[i]] = i * colWidth;
      }
      continue;
    }

    bool areCouple(int i, int j) =>
        i >= 0 && j >= 0 && i < n && j < n &&
        coupleMap.containsKey(ck(order[i], order[j]));

    double? kidsCenter(Iterable<String> kids) {
      final placed = kids.where(xById.containsKey).toList();
      if (placed.isEmpty) return null;
      return placed.map((k) => xById[k]!).reduce((a, b) => a + b) /
          placed.length;
    }

    final desired = List<double?>.filled(n, null);
    var i = 0;
    while (i < n) {
      if (areCouple(i, i + 1) && areCouple(i + 1, i + 2)) {
        // Cadeia de recasamento: [B=i, A=i+1, C=i+2]
        final meanBA = kidsCenter(coupleKids[ck(order[i], order[i + 1])] ?? {});
        final meanAC = kidsCenter(coupleKids[ck(order[i + 1], order[i + 2])] ?? {});
        if (meanBA != null) {
          desired[i] = meanBA - colWidth / 2;
          desired[i + 1] = meanBA + colWidth / 2;
        }
        if (meanAC != null) {
          final demA = meanAC - colWidth / 2;
          desired[i + 1] = desired[i + 1] == null
              ? demA
              : (desired[i + 1]! + demA) / 2;
          desired[i + 2] = meanAC + colWidth / 2;
        } else if (desired[i + 1] != null) {
          desired[i + 2] = desired[i + 1]! + colWidth;
        }
        i += 3;
      } else if (areCouple(i, i + 1)) {
        // Par de casal simples — usa filhos específicos do casal, com
        // fallback para todos os filhos de ambos.
        final specKids = coupleKids[ck(order[i], order[i + 1])] ?? {};
        final allKids = specKids.isNotEmpty
            ? specKids
            : <String>{
                ...?childrenOf[order[i]],
                ...?childrenOf[order[i + 1]],
              };
        final mean = kidsCenter(allKids);
        if (mean != null) {
          desired[i] = mean - colWidth / 2;
          desired[i + 1] = mean + colWidth / 2;
        }
        i += 2;
      } else {
        // Pessoa sem casal nesta faixa — centra sobre seus filhos.
        final mean = kidsCenter(childrenOf[order[i]] ?? {});
        if (mean != null) desired[i] = mean;
        i++;
      }
    }

    // Preenche nulos, resolve sobreposições e re-centra.
    final prov = List<double>.filled(n, 0);
    for (var k = 0; k < n; k++) {
      prov[k] = desired[k] ?? (k > 0 ? prov[k - 1] + colWidth : 0.0);
    }
    for (var k = n - 2; k >= 0; k--) {
      if (desired[k] == null) prov[k] = prov[k + 1] - colWidth;
    }
    for (var k = 0; k < n; k++) {
      final lb = k > 0 ? xById[order[k - 1]]! + colWidth : prov[k];
      xById[order[k]] = prov[k] < lb ? lb : prov[k];
    }
    var sumD = 0.0, sumA = 0.0, cnt = 0;
    for (var k = 0; k < n; k++) {
      if (desired[k] != null) {
        sumD += desired[k]!;
        sumA += xById[order[k]]!;
        cnt++;
      }
    }
    if (cnt > 0) {
      final shift = (sumD - sumA) / cnt;
      for (final id in order) {
        xById[id] = xById[id]! + shift;
      }
    }
  }

  // ── Normalização ──────────────────────────────────────────────────────────
  var minX = double.infinity, maxX = -double.infinity;
  for (final v in xById.values) {
    if (v < minX) minX = v;
    if (v > maxX) maxX = v;
  }
  if (xById.isEmpty) {
    minX = 0;
    maxX = 0;
  }
  final connectedRowWidth = (maxX - minX) + colWidth;
  final looseRowWidth = unconnected.length * colWidth;
  final innerWidth =
      connectedRowWidth > looseRowWidth ? connectedRowWidth : looseRowWidth;
  final looseRow = unconnected.isNotEmpty ? 1 : 0;
  final width = innerWidth + 2 * margin;
  final height = (gens.length + looseRow) * rowHeight + 2 * margin;
  final connShift =
      margin + (innerWidth - connectedRowWidth) / 2 + colWidth / 2 - minX;

  final nodes = <GPositioned>[];
  for (var r = 0; r < gens.length; r++) {
    final g = gens[r];
    final y = margin + r * rowHeight + rowHeight / 2;
    for (final id in rowOrders[g]!) {
      final pl = layout.placed[id]!;
      nodes.add(GPositioned(
        pl.id,
        generation: g,
        lineage: pl.lineage,
        connected: true,
        x: xById[id]! + connShift,
        y: y,
      ));
    }
  }

  if (unconnected.isNotEmpty) {
    final startX = margin + (innerWidth - looseRowWidth) / 2 + colWidth / 2;
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

/// X de onde sai a descida dos filhos de [g] no desenho.
///
/// - Dois pais: o meio entre eles (centro da linha do casal).
/// - Um só pai/mãe que tem UM cônjuge atual na faixa (o cadastro costuma ligar
///   o filho só ao paciente): o meio da linha desse casal, não o centro do
///   próprio pai/mãe — assim a descida parte do casal, como no desenho clássico.
/// - Caso contrário, o centro dos pais.
double? sibGroupDropX(GLayout layout, GDiagram diagram, GSibGroup g) {
  double? xOf(String id) => diagram.byId(id)?.x;
  final xs = [for (final p in g.parents) xOf(p)].whereType<double>().toList();
  if (xs.isEmpty) return null;
  if (xs.length == 1 && g.parents.length == 1) {
    final only = g.parents.first;
    final me = diagram.byId(only)!;
    final partners = <String>{
      for (final c in layout.couples)
        if (c.current && (c.a == only || c.b == only))
          c.a == only ? c.b : c.a,
    }.where((o) {
      final n = diagram.byId(o);
      return n != null && n.y == me.y;
    }).toList();
    if (partners.length == 1) {
      return (me.x + diagram.byId(partners.first)!.x) / 2;
    }
  }
  return xs.reduce((a, b) => a + b) / xs.length;
}
