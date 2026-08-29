import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/genogram_data.dart';
import '../../domain/genogram_gender.dart';
import '../../domain/genogram_layout.dart';
import '../../domain/genogram_layout_adapter.dart';
import '../../domain/genogram_person.dart';

/// Desenho do genograma pelo MOTOR: monta a topologia + posições a partir dos
/// vínculos estruturais explícitos e desenha a árvore bilateral (linhagem
/// paterna à esquerda, materna à direita, gerações em faixas). Só faz sentido
/// quando há vínculos; a página decide entre este e o desenho por inferência.
class MotorGenogramDiagram extends StatelessWidget {
  const MotorGenogramDiagram({super.key, required this.data});

  final GenogramData data;

  /// `true` se há estrutura suficiente para o motor desenhar (ao menos um
  /// vínculo estrutural e um paciente).
  static bool hasStructure(GenogramData data) {
    final input = buildLayoutInput(
      people: data.people,
      relationships: data.relationships,
    );
    return input != null && input.edges.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final input = buildLayoutInput(
      people: data.people,
      relationships: data.relationships,
    );
    if (input == null) {
      return const Center(child: Text('Sem paciente identificado.'));
    }
    final layout = buildGenogramStructure(
      people: input.people,
      edges: input.edges,
      focusId: input.focusId,
    );
    final diagram = positionGenogram(layout, colWidth: 116, rowHeight: 150);
    final byId = {for (final p in data.people) p.id: p};
    final fontFamily = DefaultTextStyle.of(context).style.fontFamily;

    return InteractiveViewer(
      constrained: false,
      minScale: 0.4,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(80),
      child: CustomPaint(
        size: Size(diagram.width, diagram.height),
        painter: _MotorGenogramPainter(
          layout: layout,
          diagram: diagram,
          byId: byId,
          focusId: input.focusId,
          fontFamily: fontFamily,
        ),
      ),
    );
  }
}

class _MotorGenogramPainter extends CustomPainter {
  _MotorGenogramPainter({
    required this.layout,
    required this.diagram,
    required this.byId,
    required this.focusId,
    this.fontFamily,
  });

  final GLayout layout;
  final GDiagram diagram;
  final Map<String, GenogramPerson> byId;
  final String focusId;
  final String? fontFamily;

  static const _r = 22.0;
  static const _navy = Color(0xFF0D1B3D);
  static const _line = Color(0xFF5B6B86);
  static const _teal = Color(0xFF0F9C90);
  static const _tealDeep = Color(0xFF0A5F59);
  static const _pat = Color(0xFF1F7A8C);
  static const _mat = Color(0xFF8A5CB0);
  static const _muted = Color(0xFF7B8798);

  GPositioned? _p(String id) => diagram.byId(id);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
        Offset.zero & size, Paint()..color = const Color(0xFFFBFCFE));
    _bands(canvas);
    _connectors(canvas);
    for (final n in diagram.nodes) {
      _node(canvas, n);
    }
  }

  void _bands(Canvas canvas) {
    void band(GLineage lin, Color c) {
      final xs = diagram.nodes.where((n) => n.lineage == lin).toList();
      if (xs.isEmpty) return;
      final minX = xs.map((n) => n.x).reduce(math.min) - _r - 14;
      final maxX = xs.map((n) => n.x).reduce(math.max) + _r + 14;
      final minY = xs.map((n) => n.y).reduce(math.min) - _r - 24;
      final maxY = xs.map((n) => n.y).reduce(math.max) + _r + 28;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTRB(minX, minY, maxX, maxY), const Radius.circular(16)),
        Paint()..color = c.withValues(alpha: 0.08),
      );
    }

    band(GLineage.paternal, _pat);
    band(GLineage.maternal, _mat);
  }

  void _connectors(Canvas canvas) {
    final paint = Paint()
      ..color = _line
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;

    for (final c in layout.couples) {
      final a = _p(c.a), b = _p(c.b);
      if (a == null || b == null) continue;
      final left = a.x < b.x ? a : b;
      final right = a.x < b.x ? b : a;
      canvas.drawLine(
          Offset(left.x + _r, left.y), Offset(right.x - _r, right.y), paint);
    }

    for (final g in layout.sibGroups) {
      final parents = g.parents.map(_p).whereType<GPositioned>().toList();
      final kids = g.members.map(_p).whereType<GPositioned>().toList();
      if (parents.isEmpty || kids.isEmpty) continue;
      final midX = parents.map((p) => p.x).reduce((a, b) => a + b) /
          parents.length;
      final parentY = parents.first.y;
      final childY = kids.first.y;
      final barY = (parentY + childY) / 2 + 20;
      canvas.drawLine(Offset(midX, parentY + _r), Offset(midX, barY), paint);
      final minX = kids.map((k) => k.x).reduce(math.min);
      final maxX = kids.map((k) => k.x).reduce(math.max);
      if (kids.length > 1) {
        canvas.drawLine(Offset(minX, barY), Offset(maxX, barY), paint);
      }
      for (final k in kids) {
        canvas.drawLine(Offset(k.x, barY), Offset(k.x, k.y - _r), paint);
      }
    }
  }

  int? _age(GenogramPerson p) {
    if (p.birthYear == null) return null;
    final end = p.deathYear ?? DateTime.now().year;
    final a = end - p.birthYear!;
    return a >= 0 && a < 130 ? a : null;
  }

  void _node(Canvas canvas, GPositioned n) {
    final c = Offset(n.x, n.y);
    final person = byId[n.id];
    final isIndex = n.id == focusId;
    final fill = Paint()
      ..color = isIndex ? const Color(0xFFEAFAF7) : Colors.white
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = isIndex ? _teal : _navy
      ..strokeWidth = isIndex ? 2.6 : 2.2
      ..style = PaintingStyle.stroke;

    if (isIndex) {
      final path = _diamond(c, _r);
      canvas.drawPath(path, fill);
      canvas.drawPath(path, stroke);
    } else if (person?.gender == GenogramGender.female) {
      canvas.drawCircle(c, _r, fill);
      canvas.drawCircle(c, _r, stroke);
    } else {
      final rect = Rect.fromCenter(center: c, width: _r * 2, height: _r * 2);
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, stroke);
    }

    // Idade dentro do símbolo.
    final age = person == null ? null : _age(person);
    if (age != null) {
      _text(canvas, '$age', c,
          size: 13, weight: FontWeight.w600, color: _navy, center: true);
    }

    // Falecimento: "X" sobre o símbolo.
    if (person?.isDeceased ?? false) {
      final x = Paint()
        ..color = _navy
        ..strokeWidth = 1.8
        ..style = PaintingStyle.stroke;
      canvas.drawLine(
          Offset(c.dx - _r, c.dy - _r), Offset(c.dx + _r, c.dy + _r), x);
      canvas.drawLine(
          Offset(c.dx + _r, c.dy - _r), Offset(c.dx - _r, c.dy + _r), x);
    }

    // Nome (+ papel) abaixo.
    final name = person == null
        ? n.id
        : (person.nickname != null && person.nickname!.trim().isNotEmpty
            ? person.nickname!.trim()
            : person.fullName);
    final nameColor = isIndex
        ? _tealDeep
        : n.lineage == GLineage.paternal
            ? _pat
            : n.lineage == GLineage.maternal
                ? _mat
                : _navy;
    _text(canvas, name, Offset(c.dx, c.dy + _r + 14),
        size: 12, weight: FontWeight.w700, color: nameColor, center: true);
    final role = person?.relationshipToPatient;
    if (role != null && role.trim().isNotEmpty && !isIndex) {
      _text(canvas, role.trim(), Offset(c.dx, c.dy + _r + 30),
          size: 10, weight: FontWeight.w400, color: _muted, center: true);
    }
  }

  void _text(Canvas canvas, String text, Offset at,
      {required double size,
      required FontWeight weight,
      required Color color,
      bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
            fontFamily: fontFamily,
            fontSize: size,
            fontWeight: weight,
            color: color),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 104);
    final dx = center ? at.dx - tp.width / 2 : at.dx;
    final dy = center && size >= 13 ? at.dy - tp.height / 2 : at.dy;
    tp.paint(canvas, Offset(dx, dy));
  }

  Path _diamond(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + r, c.dy)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - r, c.dy)
    ..close();

  @override
  bool shouldRepaint(_MotorGenogramPainter old) =>
      old.diagram != diagram || old.layout != layout;
}
