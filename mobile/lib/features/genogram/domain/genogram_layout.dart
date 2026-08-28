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

  GPlaced(
    this.id, {
    this.generation = 0,
    this.lineage = GLineage.unknown,
    this.connected = false,
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

  return GLayout(placed, couples, _siblingGroups(ids, parentsOf));
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
