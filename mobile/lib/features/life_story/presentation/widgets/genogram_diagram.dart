import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../genogram/domain/genogram_relationship.dart';
import '../../../genogram/domain/genogram_relationship_type.dart';
import '../../domain/family_person.dart';
import '../../domain/genogram_relationship_enums.dart';
import '../../domain/life_story_enums.dart';

/// Genograma gráfico (spec §36–38). Desenha as pessoas em quatro gerações
/// (§37), com a simbologia padrão do genograma (§36): quadrado = masculino,
/// círculo = feminino, losango = outro/não informado; o paciente é a pessoa
/// focal (traço duplo). Falecimento = "X" sobre o símbolo.
///
/// IMPORTANTE — topologia estrutural inferida: os conectores de parentesco
/// (união dos pais, descendência, irmãos) são inferidos do papel de cada
/// pessoa em relação ao paciente, pois o modelo não guarda os laços
/// estruturais explícitos (quem é casado com quem, filho de quem).
///
/// As relações emocionais tipadas (próxima, distante, conflito, rompida),
/// porém, quando cadastradas em [relationships], são desenhadas entre as duas
/// pessoas que elas ligam — inclusive entre familiares (ex.: mãe × pai), o que
/// a camada de vínculos radiais do paciente não representa.
///
/// Camadas (§38): a Estrutura é sempre exibida; [showBonds] liga os marcadores
/// de relação emocional (camada 2 — vínculos do paciente + [relationships]);
/// [highlightCaregivers] destaca figuras de cuidado (camada 3, visão do
/// terapeuta).
class GenogramDiagram extends StatelessWidget {
  const GenogramDiagram({
    super.key,
    required this.people,
    this.relationships = const [],
    this.showBonds = false,
    this.highlightCaregivers = false,
  });

  final List<FamilyPerson> people;

  /// Relações tipadas explícitas entre familiares (camada emocional). Quando
  /// vazias, o diagrama cai no comportamento antigo (só estrutura inferida).
  final List<GenogramRelationship> relationships;
  final bool showBonds;
  final bool highlightCaregivers;

  static const _rowGap = 128.0;
  static const _colGap = 82.0;
  static const _symbolR = 22.0;
  static const _padding = 32.0;

  @override
  Widget build(BuildContext context) {
    final layout = _buildLayout();
    final size = Size(layout.width, layout.height);
    // Fonte do tema — TextPainter não herda o DefaultTextStyle sozinho.
    final fontFamily = DefaultTextStyle.of(context).style.fontFamily;
    return InteractiveViewer(
      constrained: false,
      minScale: 0.4,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(80),
      child: CustomPaint(
        size: size,
        painter: _GenogramPainter(
          layout: layout,
          relationships: relationships,
          showBonds: showBonds,
          highlightCaregivers: highlightCaregivers,
          fontFamily: fontFamily,
        ),
      ),
    );
  }

  _Layout _buildLayout() {
    // Distribui as pessoas nas quatro gerações (§37) a partir do parentesco.
    final grandparents = <FamilyPerson>[];
    final parents = <FamilyPerson>[];
    final peers = <FamilyPerson>[]; // geração do paciente
    final children = <FamilyPerson>[];
    final others = <FamilyPerson>[];

    for (final p in people) {
      switch (p.role) {
        case RelationshipRole.grandmother:
        case RelationshipRole.grandfather:
          grandparents.add(p);
        case RelationshipRole.mother:
        case RelationshipRole.father:
        case RelationshipRole.stepmother:
        case RelationshipRole.stepfather:
        case RelationshipRole.aunt:
        case RelationshipRole.uncle:
          parents.add(p);
        case RelationshipRole.sister:
        case RelationshipRole.brother:
        case RelationshipRole.partner:
        case RelationshipRole.exPartner:
        case RelationshipRole.cousinF:
        case RelationshipRole.cousinM:
          peers.add(p);
        case RelationshipRole.daughter:
        case RelationshipRole.son:
          children.add(p);
        case RelationshipRole.caregiver:
        case RelationshipRole.other:
        case null:
          others.add(p);
      }
    }

    // A pessoa focal (paciente) entra na geração do paciente, ao centro.
    final rows = <List<_Node>>[];

    List<_Node> toNodes(List<FamilyPerson> list) =>
        [for (final p in list) _Node(person: p)];

    final row0 = toNodes(grandparents);
    final row1 = toNodes([...parents, ...others]);
    final patientNode = _Node(person: null, isPatient: true);
    // Paciente ao centro da própria geração, entre os pares.
    final peerNodes = toNodes(peers);
    final mid = peerNodes.length ~/ 2;
    final row2 = [...peerNodes.take(mid), patientNode, ...peerNodes.skip(mid)];
    final row3 = toNodes(children);

    for (final r in [row0, row1, row2, row3]) {
      if (r.isNotEmpty) rows.add(r);
    }

    final maxCount =
        rows.fold<int>(1, (m, r) => math.max(m, r.length));
    final width = _padding * 2 + maxCount * _colGap;

    // Posiciona cada nó. Guarda o índice de geração para os conectores.
    var genIndex = 0;
    final placed = <List<_Node>>[];
    final rowSources = <List<FamilyPerson>>[]; // paralelo, para referência
    for (final r in [row0, row1, row2, row3]) {
      if (r.isEmpty) continue;
      final rowWidth = r.length * _colGap;
      final startX = (width - rowWidth) / 2 + _colGap / 2;
      final y = _padding + _symbolR + genIndex * _rowGap;
      for (var i = 0; i < r.length; i++) {
        r[i].center = Offset(startX + i * _colGap, y);
        r[i].generation = genIndex;
      }
      placed.add(r);
      rowSources.add(const []);
      genIndex++;
    }

    final height = _padding * 2 + _symbolR + (genIndex - 1) * _rowGap + 44;

    return _Layout(
      width: math.max(width, 320),
      height: height,
      rows: placed,
      patient: patientNode,
      symbolR: _symbolR,
      rowGap: _rowGap,
    );
  }
}

class _Node {
  _Node({required this.person, this.isPatient = false});

  final FamilyPerson? person; // null = paciente (pessoa focal)
  final bool isPatient;
  Offset center = Offset.zero;
  int generation = 0;

  String get label => isPatient ? 'Paciente' : (person?.fullName ?? '');
  String? get sub => isPatient ? null : person?.role?.label;
  bool get deceased => person?.isDeceased ?? false;

  /// masculino / feminino / outro(losango).
  _Sex get sex {
    final g = person?.gender;
    if (g == PersonGender.male) return _Sex.male;
    if (g == PersonGender.female) return _Sex.female;
    if (g == PersonGender.other) return _Sex.other;
    // Infere do parentesco quando o gênero não foi informado.
    switch (person?.role) {
      case RelationshipRole.mother:
      case RelationshipRole.stepmother:
      case RelationshipRole.sister:
      case RelationshipRole.grandmother:
      case RelationshipRole.aunt:
      case RelationshipRole.cousinF:
      case RelationshipRole.daughter:
        return _Sex.female;
      case RelationshipRole.father:
      case RelationshipRole.stepfather:
      case RelationshipRole.brother:
      case RelationshipRole.grandfather:
      case RelationshipRole.uncle:
      case RelationshipRole.cousinM:
      case RelationshipRole.son:
        return _Sex.male;
      default:
        return _Sex.other;
    }
  }

  bool get isCaregiver =>
      person?.caregiverRole == CaregiverRole.important ||
      person?.caregiverRole == CaregiverRole.partial;
}

enum _Sex { male, female, other }

class _Layout {
  _Layout({
    required this.width,
    required this.height,
    required this.rows,
    required this.patient,
    required this.symbolR,
    required this.rowGap,
  });

  final double width;
  final double height;
  final List<List<_Node>> rows;
  final _Node patient;
  final double symbolR;
  final double rowGap;
}

class _GenogramPainter extends CustomPainter {
  _GenogramPainter({
    required this.layout,
    required this.relationships,
    required this.showBonds,
    required this.highlightCaregivers,
    this.fontFamily,
  });

  final _Layout layout;
  final List<GenogramRelationship> relationships;
  final bool showBonds;
  final bool highlightCaregivers;
  final String? fontFamily;

  static const _line = Color(0xFF6B7A90);
  static const _symbolStroke = AppColors.navy;

  @override
  void paint(Canvas canvas, Size size) {
    _drawStructuralConnectors(canvas);
    if (showBonds) {
      _drawRelationships(canvas);
      _drawBonds(canvas);
    }
    for (final row in layout.rows) {
      for (final node in row) {
        _drawNode(canvas, node);
      }
    }
  }

  // ── Conectores estruturais (camada 1) ────────────────────────────────────
  void _drawStructuralConnectors(Canvas canvas) {
    final paint = Paint()
      ..color = _line
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final r = layout.symbolR;

    // Geração dos pais → geração do paciente.
    final parentRow = layout.rows.length > 1 ? layout.rows[1] : const <_Node>[];
    final peerRow = _peerRow();

    final father = _firstWhere(parentRow, _Sex.male);
    final mother = _firstWhere(parentRow, _Sex.female);
    Offset? unionMid;
    if (father != null && mother != null) {
      final y = father.center.dy;
      canvas.drawLine(Offset(father.center.dx + r, y),
          Offset(mother.center.dx - r, y), paint);
      unionMid = Offset((father.center.dx + mother.center.dx) / 2, y);
    } else {
      final only = father ?? mother;
      if (only != null) unionMid = Offset(only.center.dx, only.center.dy);
    }

    // Barra de irmãos (paciente + irmãos) e descendência dos pais.
    if (peerRow.isNotEmpty) {
      final siblings = peerRow
          .where((n) =>
              n.isPatient ||
              n.person?.role == RelationshipRole.sister ||
              n.person?.role == RelationshipRole.brother)
          .toList();
      if (siblings.isNotEmpty) {
        final barY = siblings.first.center.dy - r - 22;
        final left = siblings.first.center.dx;
        final right = siblings.last.center.dx;
        if (siblings.length > 1) {
          canvas.drawLine(Offset(left, barY), Offset(right, barY), paint);
        }
        for (final s in siblings) {
          canvas.drawLine(
              Offset(s.center.dx, barY), Offset(s.center.dx, s.center.dy - r),
              paint);
        }
        if (unionMid != null) {
          final barCenter = (left + right) / 2;
          canvas.drawLine(unionMid, Offset(unionMid.dx, barY - 0), paint);
          canvas.drawLine(
              Offset(unionMid.dx, barY), Offset(barCenter, barY), paint);
        }
      }
    }

    // Avós → pais (união dos avós, descendência leve).
    if (layout.rows.length > 1 && layout.rows[0].isNotEmpty) {
      final gp = layout.rows[0];
      final gm = _firstWhere(gp, _Sex.female);
      final gf = _firstWhere(gp, _Sex.male);
      if (gm != null && gf != null) {
        final y = gf.center.dy;
        canvas.drawLine(Offset(gf.center.dx + r, y),
            Offset(gm.center.dx - r, y), paint);
        final gmid = Offset((gf.center.dx + gm.center.dx) / 2, y);
        // Descendência aproximada até a faixa dos pais.
        final targetY = parentRow.isNotEmpty
            ? parentRow.first.center.dy - r
            : y + layout.rowGap;
        canvas.drawLine(gmid, Offset(gmid.dx, targetY), paint);
      }
    }

    // Paciente (+ companheiro) → filhos.
    if (layout.rows.length > 2 && layout.rows.last != peerRow) {
      final childRow = layout.rows.last;
      final partner = peerRow.firstWhere(
        (n) =>
            n.person?.role == RelationshipRole.partner ||
            n.person?.role == RelationshipRole.exPartner,
        orElse: () => layout.patient,
      );
      final start = layout.patient.center;
      final coupleMid = partner == layout.patient
          ? start
          : Offset((start.dx + partner.center.dx) / 2, start.dy);
      if (partner != layout.patient) {
        canvas.drawLine(Offset(start.dx + r, start.dy),
            Offset(partner.center.dx - r, partner.center.dy), paint);
      }
      final barY = childRow.first.center.dy - r - 22;
      final left = childRow.first.center.dx;
      final right = childRow.last.center.dx;
      if (childRow.length > 1) {
        canvas.drawLine(Offset(left, barY), Offset(right, barY), paint);
      }
      for (final c in childRow) {
        canvas.drawLine(
            Offset(c.center.dx, barY), Offset(c.center.dx, c.center.dy - r),
            paint);
      }
      canvas.drawLine(coupleMid, Offset(coupleMid.dx, barY), paint);
      canvas.drawLine(Offset(coupleMid.dx, barY),
          Offset((left + right) / 2, barY), paint);
    }
  }

  List<_Node> _peerRow() {
    for (final row in layout.rows) {
      if (row.any((n) => n.isPatient)) return row;
    }
    return const [];
  }

  _Node? _firstWhere(List<_Node> row, _Sex sex) {
    for (final n in row) {
      if (!n.isPatient && n.sex == sex) return n;
    }
    return null;
  }

  // ── Vínculos emocionais (camada 2) ───────────────────────────────────────
  void _drawBonds(Canvas canvas) {
    final patient = layout.patient.center;
    for (final row in layout.rows) {
      for (final node in row) {
        final p = node.person;
        if (p == null || !p.hasRelationshipData) continue;
        _drawBond(canvas, patient, node.center, p);
      }
    }
  }

  void _drawBond(Canvas canvas, Offset a, Offset b, FamilyPerson p) {
    final style = _bondStyle(p);
    _drawStyledLine(canvas, a, b, style.kind, style.color);
  }

  // ── Relações explícitas entre familiares (camada emocional cadastrada) ─────
  // Diferente dos vínculos do paciente (radiais), estas ligam quaisquer duas
  // pessoas — ex.: mãe × pai conflituoso — usando os dados tipados que antes
  // não apareciam no desenho.
  void _drawRelationships(Canvas canvas) {
    if (relationships.isEmpty) return;
    final byId = <String, _Node>{};
    for (final row in layout.rows) {
      for (final node in row) {
        final id = node.person?.id;
        if (id != null) byId[id] = node;
      }
    }
    for (final rel in relationships) {
      final style = _relationshipStyle(rel.relationshipType);
      if (style == null) continue; // só a camada emocional (a estrutural é inferida)
      final a = byId[rel.personAId];
      final b = byId[rel.personBId];
      if (a == null || b == null) continue;
      _drawStyledLine(canvas, a.center, b.center, style.kind, style.color);
    }
  }

  /// Mapeia o tipo de relação para o vocabulário visual do genograma. Retorna
  /// `null` para os tipos estruturais (cônjuge, irmão, pai/mãe–filho), que já
  /// são representados pelos conectores inferidos e não devem duplicar linha.
  _BondStyle? _relationshipStyle(GenogramRelationshipType type) {
    switch (type) {
      case GenogramRelationshipType.close:
        return const _BondStyle(_BondKind.close, Color(0xFF2E7D6B));
      case GenogramRelationshipType.distant:
        return const _BondStyle(_BondKind.distant, Color(0xFF6B7A90));
      case GenogramRelationshipType.conflict:
        return const _BondStyle(_BondKind.conflict, Color(0xFFB5651D));
      case GenogramRelationshipType.ruptured:
        return const _BondStyle(_BondKind.broken, Color(0xFFB03A3A));
      case GenogramRelationshipType.spouse:
      case GenogramRelationshipType.exSpouse:
      case GenogramRelationshipType.sibling:
      case GenogramRelationshipType.twin:
      case GenogramRelationshipType.parentChild:
      case GenogramRelationshipType.neutral:
      case GenogramRelationshipType.other:
        return null;
    }
  }

  /// Desenha uma linha entre dois pontos no estilo do vínculo, encolhendo as
  /// pontas para não invadir os símbolos. Compartilhado entre a camada de
  /// vínculos do paciente e a de relações cadastradas.
  void _drawStyledLine(
      Canvas canvas, Offset a, Offset b, _BondKind kind, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke;
    final dir = b - a;
    final len = dir.distance;
    if (len < 1) return;
    final unit = dir / len;
    final start = a + unit * (layout.symbolR + 6);
    final end = b - unit * (layout.symbolR + 6);
    switch (kind) {
      case _BondKind.close:
        final normal = Offset(-unit.dy, unit.dx) * 2.2;
        canvas.drawLine(start + normal, end + normal, paint);
        canvas.drawLine(start - normal, end - normal, paint);
      case _BondKind.distant:
        _dashed(canvas, start, end, paint);
      case _BondKind.conflict:
        _zigzag(canvas, start, end, paint);
      case _BondKind.broken:
        canvas.drawLine(start, end, paint);
        _slashes(canvas, start, end, paint);
      case _BondKind.plain:
        canvas.drawLine(start, end, paint);
    }
  }

  _BondStyle _bondStyle(FamilyPerson p) {
    switch (p.bondType) {
      case BondType.closeAffectionate:
        return const _BondStyle(_BondKind.close, Color(0xFF2E7D6B));
      case BondType.distant:
        return const _BondStyle(_BondKind.distant, Color(0xFF6B7A90));
      case BondType.conflictual:
        return const _BondStyle(_BondKind.conflict, Color(0xFFB5651D));
      case BondType.broken:
        return const _BondStyle(_BondKind.broken, Color(0xFFB03A3A));
      case BondType.ambivalent:
        return const _BondStyle(_BondKind.conflict, Color(0xFFB5651D));
      default:
        // Fallback pelas escalas.
        if ((p.conflict ?? 0) >= 6) {
          return const _BondStyle(_BondKind.conflict, Color(0xFFB5651D));
        }
        if ((p.closeness ?? 0) >= 7) {
          return const _BondStyle(_BondKind.close, Color(0xFF2E7D6B));
        }
        if ((p.closeness ?? 10) <= 3) {
          return const _BondStyle(_BondKind.distant, Color(0xFF6B7A90));
        }
        return const _BondStyle(_BondKind.plain, Color(0xFF6B7A90));
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 6.0, gap = 4.0;
    final total = (b - a).distance;
    final unit = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      final s = a + unit * d;
      final e = a + unit * math.min(d + dash, total);
      canvas.drawLine(s, e, paint);
      d += dash + gap;
    }
  }

  void _zigzag(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    final unit = (b - a) / total;
    final normal = Offset(-unit.dy, unit.dx);
    const step = 8.0, amp = 4.0;
    final path = Path()..moveTo(a.dx, a.dy);
    var d = 0.0, s = 1.0;
    while (d < total) {
      final next = math.min(d + step, total);
      final mid = a + unit * ((d + next) / 2) + normal * (amp * s);
      final end = a + unit * next;
      path.lineTo(mid.dx, mid.dy);
      path.lineTo(end.dx, end.dy);
      s = -s;
      d = next;
    }
    canvas.drawPath(path, paint);
  }

  void _slashes(Canvas canvas, Offset a, Offset b, Paint paint) {
    final mid = (a + b) / 2;
    final unit = (b - a) / (b - a).distance;
    final normal = Offset(-unit.dy, unit.dx) * 5;
    for (final off in [-3.0, 3.0]) {
      final c = mid + unit * off;
      canvas.drawLine(c + normal, c - normal, paint);
    }
  }

  // ── Símbolo da pessoa ─────────────────────────────────────────────────────
  void _drawNode(Canvas canvas, _Node node) {
    final c = node.center;
    final r = layout.symbolR;
    final caregiverGlow = highlightCaregivers && node.isCaregiver;

    if (caregiverGlow) {
      final glow = Paint()
        ..color = AppColors.turquoise.withValues(alpha: 0.22)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(c, r + 8, glow);
    }

    final fill = Paint()
      ..color = node.isPatient ? const Color(0xFFEAF3F2) : Colors.white
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = _symbolStroke
      ..strokeWidth = node.isPatient ? 2.6 : 1.8
      ..style = PaintingStyle.stroke;

    _symbolPath(canvas, node, c, r, fill, stroke);

    // Pessoa focal: traço duplo (anel externo).
    if (node.isPatient) {
      final outer = Paint()
        ..color = _symbolStroke
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      _symbolPathShapeOnly(canvas, node, c, r + 4, outer);
    }

    // Falecimento: "X" sobre o símbolo.
    if (node.deceased) {
      final x = Paint()
        ..color = _symbolStroke
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(c.dx - r, c.dy - r), Offset(c.dx + r, c.dy + r), x);
      canvas.drawLine(Offset(c.dx + r, c.dy - r), Offset(c.dx - r, c.dy + r), x);
    }

    _drawLabel(canvas, node);
  }

  void _symbolPath(Canvas canvas, _Node node, Offset c, double r, Paint fill,
      Paint stroke) {
    switch (node.isPatient ? _Sex.other : node.sex) {
      case _Sex.male:
        final rect = Rect.fromCenter(center: c, width: r * 2, height: r * 2);
        canvas.drawRect(rect, fill);
        canvas.drawRect(rect, stroke);
      case _Sex.female:
        canvas.drawCircle(c, r, fill);
        canvas.drawCircle(c, r, stroke);
      case _Sex.other:
        final path = _diamond(c, r);
        canvas.drawPath(path, fill);
        canvas.drawPath(path, stroke);
    }
  }

  void _symbolPathShapeOnly(
      Canvas canvas, _Node node, Offset c, double r, Paint stroke) {
    // Paciente é desenhado como losango neutro; anel externo do mesmo formato.
    canvas.drawPath(_diamond(c, r), stroke);
  }

  Path _diamond(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + r, c.dy)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - r, c.dy)
    ..close();

  void _drawLabel(Canvas canvas, _Node node) {
    final c = node.center;
    final r = layout.symbolR;
    final name = TextPainter(
      text: TextSpan(
        text: node.label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          fontFamily: fontFamily,
          color: node.isPatient ? AppColors.turquoise : AppColors.navy,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 78);
    name.paint(canvas, Offset(c.dx - name.width / 2, c.dy + r + 4));

    if (node.sub != null) {
      final sub = TextPainter(
        text: TextSpan(
          text: node.sub,
          style: TextStyle(
              fontSize: 10,
              fontFamily: fontFamily,
              color: AppColors.textSecondary),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: 78);
      sub.paint(canvas, Offset(c.dx - sub.width / 2, c.dy + r + 4 + name.height));
    }
  }

  @override
  bool shouldRepaint(_GenogramPainter old) =>
      old.showBonds != showBonds ||
      old.highlightCaregivers != highlightCaregivers ||
      old.relationships != relationships ||
      old.layout != layout;
}

enum _BondKind { close, distant, conflict, broken, plain }

class _BondStyle {
  const _BondStyle(this.kind, this.color);
  final _BondKind kind;
  final Color color;
}
