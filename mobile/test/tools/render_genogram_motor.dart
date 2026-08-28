// Prova visual do motor de layout do genograma: monta uma família de exemplo,
// roda buildGenogramStructure + positionGenogram e desenha o resultado.
//
//   flutter test test/tools/render_genogram_motor.dart
//
// Saída em build/genograma_motor.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_layout.dart';

// Família de exemplo: 3 gerações, 2 linhagens, com uma tia paterna e um irmão.
const _people = [
  GPerson('F'),
  GPerson('Fa', sex: GSex.male),
  GPerson('Mo', sex: GSex.female),
  GPerson('Si'),
  GPerson('GpP', sex: GSex.male),
  GPerson('GmP', sex: GSex.female),
  GPerson('GpM', sex: GSex.male),
  GPerson('GmM', sex: GSex.female),
  GPerson('Tia', sex: GSex.female),
];
const _edges = [
  GEdge('Fa', 'F', GEdgeType.parentChild),
  GEdge('Mo', 'F', GEdgeType.parentChild),
  GEdge('Fa', 'Si', GEdgeType.parentChild),
  GEdge('Mo', 'Si', GEdgeType.parentChild),
  GEdge('Fa', 'Mo', GEdgeType.spouse),
  GEdge('GpP', 'Fa', GEdgeType.parentChild),
  GEdge('GmP', 'Fa', GEdgeType.parentChild),
  GEdge('GpP', 'Tia', GEdgeType.parentChild),
  GEdge('GmP', 'Tia', GEdgeType.parentChild),
  GEdge('GpP', 'GmP', GEdgeType.spouse),
  GEdge('GpM', 'Mo', GEdgeType.parentChild),
  GEdge('GmM', 'Mo', GEdgeType.parentChild),
  GEdge('GpM', 'GmM', GEdgeType.spouse),
];
const _labels = {
  'F': 'Paciente', 'Fa': 'João', 'Mo': 'Carla', 'Si': 'Pedro',
  'GpP': 'Antônio', 'GmP': 'Cecília', 'GpM': 'Jorge', 'GmM': 'Rosa',
  'Tia': 'Sofia',
};

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    for (final f in ['roboto-regular.ttf', 'roboto-medium.ttf', 'roboto-bold.ttf']) {
      await ui.loadFontFromList(File('$dir\\$f').readAsBytesSync(),
          fontFamily: 'Roboto');
    }
  });

  testWidgets('motor → desenho da árvore bilateral', (tester) async {
    final layout = buildGenogramStructure(
      focusId: 'F', people: _people, edges: _edges,
    );
    final diagram = positionGenogram(layout, colWidth: 110, rowHeight: 150);

    tester.view.physicalSize = Size(diagram.width, diagram.height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      home: RepaintBoundary(
        child: CustomPaint(
          size: Size(diagram.width, diagram.height),
          painter: _MotorPainter(layout: layout, diagram: diagram),
        ),
      ),
    ));
    await tester.pump(const Duration(milliseconds: 200));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first);
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/genograma_motor.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/genograma_motor.png');
  });
}

class _MotorPainter extends CustomPainter {
  _MotorPainter({required this.layout, required this.diagram});
  final GLayout layout;
  final GDiagram diagram;

  static const _r = 22.0;
  static const _navy = Color(0xFF0D1B3D);
  static const _line = Color(0xFF5B6B86);
  static const _teal = Color(0xFF0F9C90);
  static const _pat = Color(0xFF1F7A8C);
  static const _mat = Color(0xFF8A5CB0);

  GPositioned? _p(String id) => diagram.byId(id);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFBFCFE));
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
      final minX = xs.map((n) => n.x).reduce((a, b) => a < b ? a : b) - _r - 14;
      final maxX = xs.map((n) => n.x).reduce((a, b) => a > b ? a : b) + _r + 14;
      final minY = xs.map((n) => n.y).reduce((a, b) => a < b ? a : b) - _r - 22;
      final maxY = xs.map((n) => n.y).reduce((a, b) => a > b ? a : b) + _r + 26;
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

    // casais
    for (final c in layout.couples) {
      final a = _p(c.a), b = _p(c.b);
      if (a == null || b == null) continue;
      final left = a.x < b.x ? a : b;
      final right = a.x < b.x ? b : a;
      canvas.drawLine(
          Offset(left.x + _r, left.y), Offset(right.x - _r, right.y), paint);
    }

    // descendência por grupo de irmãos
    for (final g in layout.sibGroups) {
      final parents = g.parents.map(_p).whereType<GPositioned>().toList();
      final kids = g.members.map(_p).whereType<GPositioned>().toList();
      if (parents.isEmpty || kids.isEmpty) continue;
      final midX =
          parents.map((p) => p.x).reduce((a, b) => a + b) / parents.length;
      final parentY = parents.first.y;
      final childY = kids.first.y;
      final barY = (parentY + childY) / 2 + 20;
      canvas.drawLine(Offset(midX, parentY + _r), Offset(midX, barY), paint);
      final minX = kids.map((k) => k.x).reduce((a, b) => a < b ? a : b);
      final maxX = kids.map((k) => k.x).reduce((a, b) => a > b ? a : b);
      if (kids.length > 1) {
        canvas.drawLine(Offset(minX, barY), Offset(maxX, barY), paint);
      }
      for (final k in kids) {
        canvas.drawLine(Offset(k.x, barY), Offset(k.x, k.y - _r), paint);
      }
    }
  }

  void _node(Canvas canvas, GPositioned n) {
    final c = Offset(n.x, n.y);
    final isIndex = n.id == 'F';
    final person = _people.firstWhere((p) => p.id == n.id);
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
    } else if (person.sex == GSex.female) {
      canvas.drawCircle(c, _r, fill);
      canvas.drawCircle(c, _r, stroke);
    } else {
      final rect = Rect.fromCenter(center: c, width: _r * 2, height: _r * 2);
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, stroke);
    }
    _label(canvas, n, _labels[n.id] ?? n.id, isIndex);
  }

  Path _diamond(Offset c, double r) => Path()
    ..moveTo(c.dx, c.dy - r)
    ..lineTo(c.dx + r, c.dy)
    ..lineTo(c.dx, c.dy + r)
    ..lineTo(c.dx - r, c.dy)
    ..close();

  void _label(Canvas canvas, GPositioned n, String text, bool isIndex) {
    final color = n.lineage == GLineage.paternal
        ? _pat
        : n.lineage == GLineage.maternal
            ? _mat
            : (isIndex ? const Color(0xFF0A5F59) : _navy);
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: 100);
    tp.paint(canvas, Offset(n.x - tp.width / 2, n.y + _r + 5));
  }

  @override
  bool shouldRepaint(_MotorPainter old) => false;
}
