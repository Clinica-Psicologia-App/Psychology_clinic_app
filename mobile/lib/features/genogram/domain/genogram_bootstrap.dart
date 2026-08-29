/// Bootstrap do genograma — **Dart puro**. A partir dos papéis em texto livre
/// (`relationshipToPatient`: "Mãe", "Pai", "Avó paterna"…), PROPÕE os vínculos
/// estruturais (`spouse`/`parent_child`) que faltam, para o terapeuta apenas
/// confirmar em vez de cadastrar do zero.
///
/// É heurístico e conservador: só propõe o que dá para inferir com alta
/// confiança (pais, irmãos, filhos e avós com o lado explícito). Nunca duplica
/// um vínculo que já existe. A camada de UI/gravação consome estas propostas.
library;

import 'genogram_layout.dart' show GEdge, GEdgeType, GSex;

/// Uma pessoa para o bootstrap: id, papel em texto livre, sexo e nome.
class GBootstrapPerson {
  final String id;
  final String? role;
  final GSex sex;
  final String name;
  const GBootstrapPerson(this.id,
      {this.role, this.sex = GSex.unknown, this.name = ''});
}

/// Uma proposta de vínculo, com um rótulo legível para a confirmação.
class GEdgeProposal {
  final GEdge edge;
  final String reason;
  const GEdgeProposal(this.edge, this.reason);
}

/// Normaliza texto livre: minúsculas, sem acento, sem espaços nas bordas.
String normalizeRole(String? s) {
  final t = (s ?? '').toLowerCase().trim();
  const from = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const to = 'aaaaaeeeeiiiiooooouuuuc';
  final sb = StringBuffer();
  for (final ch in t.split('')) {
    final i = from.indexOf(ch);
    sb.write(i >= 0 ? to[i] : ch);
  }
  return sb.toString();
}

enum _Kind { patient, mother, father, sibling, grandparent, child, unknown }
enum _Side { paternal, maternal, none }

({_Kind kind, _Side side}) _classify(String? role) {
  final r = normalizeRole(role);
  final side = r.contains('patern')
      ? _Side.paternal
      : r.contains('matern')
          ? _Side.maternal
          : _Side.none;
  if (r.contains('paciente')) return (kind: _Kind.patient, side: _Side.none);
  if (r.contains('avo') || r.contains('avob')) {
    return (kind: _Kind.grandparent, side: side);
  }
  if (r.contains('mae')) return (kind: _Kind.mother, side: _Side.none);
  if (r.contains('irma')) return (kind: _Kind.sibling, side: _Side.none);
  if (r.contains('filh')) return (kind: _Kind.child, side: _Side.none);
  // "pai" por último para não colidir com "paciente"/"patern".
  if (r == 'pai' || r.startsWith('pai ') || r.contains('pai/')) {
    return (kind: _Kind.father, side: _Side.none);
  }
  return (kind: _Kind.unknown, side: side);
}

/// Chave não-direcionada para deduplicar casais.
String _coupleKey(String a, String b) {
  final s = [a, b]..sort();
  return '${s[0]}|${s[1]}';
}

/// Propõe os vínculos estruturais que faltam a partir dos papéis.
List<GEdgeProposal> proposeStructure({
  required List<GBootstrapPerson> people,
  required List<GEdge> existing,
}) {
  // Vínculos já existentes, para não duplicar.
  final existingParentChild = <String>{}; // "parent>child"
  final existingCouples = <String>{}; // chave não-direcionada
  for (final e in existing) {
    switch (e.type) {
      case GEdgeType.parentChild:
        existingParentChild.add('${e.a}>${e.b}');
      case GEdgeType.spouse:
      case GEdgeType.exSpouse:
        existingCouples.add(_coupleKey(e.a, e.b));
    }
  }

  final byId = {for (final p in people) p.id: p};
  String name(String id) => byId[id]?.name ?? id;

  String? patient;
  final fathers = <String>[];
  final mothers = <String>[];
  final siblings = <String>[];
  final children = <String>[];
  final gpPat = <String>[];
  final gpMat = <String>[];

  for (final p in people) {
    final c = _classify(p.role);
    switch (c.kind) {
      case _Kind.patient:
        patient ??= p.id;
      case _Kind.father:
        fathers.add(p.id);
      case _Kind.mother:
        mothers.add(p.id);
      case _Kind.sibling:
        siblings.add(p.id);
      case _Kind.child:
        children.add(p.id);
      case _Kind.grandparent:
        if (c.side == _Side.paternal) gpPat.add(p.id);
        if (c.side == _Side.maternal) gpMat.add(p.id);
      case _Kind.unknown:
        break;
    }
  }

  final out = <GEdgeProposal>[];
  void proposePC(String parent, String child, String reason) {
    if (parent == child) return;
    if (existingParentChild.contains('$parent>$child')) return;
    out.add(GEdgeProposal(GEdge(parent, child, GEdgeType.parentChild), reason));
    existingParentChild.add('$parent>$child');
  }

  void proposeSpouse(String a, String b, String reason) {
    if (a == b) return;
    if (existingCouples.contains(_coupleKey(a, b))) return;
    out.add(GEdgeProposal(GEdge(a, b, GEdgeType.spouse), reason));
    existingCouples.add(_coupleKey(a, b));
  }

  if (patient == null) return out;

  final father = fathers.isNotEmpty ? fathers.first : null;
  final mother = mothers.isNotEmpty ? mothers.first : null;

  if (father != null && mother != null) {
    proposeSpouse(father, mother, '${name(father)} e ${name(mother)} — casal');
  }

  for (final parent in [father, mother]) {
    if (parent == null) continue;
    proposePC(parent, patient, '${name(patient)} é filho(a) de ${name(parent)}');
    for (final sib in siblings) {
      proposePC(parent, sib, '${name(sib)} é filho(a) de ${name(parent)}');
    }
  }

  for (final child in children) {
    proposePC(patient, child, '${name(child)} é filho(a) de ${name(patient)}');
  }

  // Avós: só quando o lado é explícito e o pai/mãe correspondente existe.
  void grandparents(List<String> gps, String? parent, String sideLabel) {
    if (parent == null) return;
    for (final gp in gps) {
      proposePC(gp, parent,
          '${name(parent)} é filho(a) de ${name(gp)} (avô/avó $sideLabel)');
    }
    if (gps.length == 2) {
      proposeSpouse(gps[0], gps[1],
          '${name(gps[0])} e ${name(gps[1])} — avós $sideLabel (casal)');
    }
  }

  grandparents(gpPat, father, 'paterno(a)');
  grandparents(gpMat, mother, 'materno(a)');

  return out;
}
