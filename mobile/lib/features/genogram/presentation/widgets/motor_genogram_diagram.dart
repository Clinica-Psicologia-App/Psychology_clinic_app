import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_animations.dart';
import '../../domain/genogram_data.dart';
import '../../domain/genogram_gender.dart';
import '../../domain/genogram_layout.dart';
import '../../domain/genogram_layout_adapter.dart';
import '../../domain/genogram_person.dart';

/// Desenho do genograma pelo MOTOR: monta a topologia + posições a partir dos
/// vínculos estruturais explícitos e desenha a árvore bilateral (linhagem
/// paterna à esquerda, materna à direita, gerações em faixas). Só faz sentido
/// quando há vínculos; a página decide entre este e o desenho por inferência.
class MotorGenogramDiagram extends StatefulWidget {
  const MotorGenogramDiagram({
    super.key,
    required this.data,
    this.showEmotional = true,
    this.onTapPerson,
  });

  final GenogramData data;

  /// Liga/desliga o overlay das relações emocionais (conflito, próxima…).
  final bool showEmotional;

  /// Chamado ao tocar num símbolo (edição no próprio diagrama). Recebe o id da
  /// pessoa. Quando nulo, os toques não fazem nada.
  final void Function(String personId)? onTapPerson;

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
  State<MotorGenogramDiagram> createState() => _MotorGenogramDiagramState();
}

class _MotorGenogramDiagramState extends State<MotorGenogramDiagram>
    with TickerProviderStateMixin {
  /// Entrada: pessoas surgem em cascata e as ligações se desenham depois.
  late final AnimationController _entry = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// Halo do paciente "respirando" — sinaliza quem é o índice sem poluir.
  late final AnimationController _pulse = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2600),
  );

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    if (AppAnimations.shouldAnimate(context)) {
      _entry.forward();
      _pulse.repeat(reverse: true);
    } else {
      _entry.value = 1;
    }
  }

  @override
  void dispose() {
    _entry.dispose();
    _pulse.dispose();
    super.dispose();
  }

  GenogramData get data => widget.data;

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
      twins: input.twins,
    );
    final diagram = positionGenogram(layout, colWidth: 116, rowHeight: 150);
    final byId = {for (final p in data.people) p.id: p};
    final fontFamily = DefaultTextStyle.of(context).style.fontFamily;
    final emotional = widget.showEmotional
        ? emotionalRelations(data.relationships)
        : const <GEmotionalRel>[];
    final onTapPerson = widget.onTapPerson;

    final painter = AnimatedBuilder(
      animation: Listenable.merge([_entry, _pulse]),
      builder: (context, _) => CustomPaint(
        size: Size(diagram.width, diagram.height),
        painter: _MotorGenogramPainter(
          layout: layout,
          diagram: diagram,
          byId: byId,
          focusId: input.focusId,
          emotional: emotional,
          fontFamily: fontFamily,
          entry: _entry.value,
          pulse: _pulse.value,
        ),
      ),
    );

    final viewer = InteractiveViewer(
      constrained: false,
      minScale: 0.4,
      maxScale: 2.5,
      boundaryMargin: const EdgeInsets.all(80),
      child: onTapPerson == null
          ? painter
          : GestureDetector(
              behavior: HitTestBehavior.deferToChild,
              onTapUp: (d) {
                final id = _hitTest(diagram, d.localPosition);
                if (id != null) onTapPerson(id);
              },
              child: painter,
            ),
    );

    // Fundo fica FORA do InteractiveViewer: não acompanha o zoom/arraste, então
    // funciona como ambiente da tela em vez de parte do desenho.
    return Stack(
      children: [
        const Positioned.fill(child: _GenogramBackdrop()),
        Positioned.fill(child: viewer),
      ],
    );
  }

  /// Nó mais próximo do toque (dentro do raio do símbolo). `localPosition` está
  /// no espaço do diagrama porque o GestureDetector é filho do InteractiveViewer.
  static String? _hitTest(GDiagram diagram, Offset at) {
    const hitRadius = 26.0;
    String? best;
    var bestD = hitRadius;
    for (final n in diagram.nodes) {
      final d = (Offset(n.x, n.y) - at).distance;
      if (d <= bestD) {
        bestD = d;
        best = n.id;
      }
    }
    return best;
  }
}

class _MotorGenogramPainter extends CustomPainter {
  _MotorGenogramPainter({
    required this.layout,
    required this.diagram,
    required this.byId,
    required this.focusId,
    required this.emotional,
    this.fontFamily,
    this.entry = 1,
    this.pulse = 0,
  });

  final GLayout layout;
  final GDiagram diagram;
  final Map<String, GenogramPerson> byId;
  final String focusId;
  final List<GEmotionalRel> emotional;
  final String? fontFamily;

  /// 0→1: progresso da entrada (cascata das pessoas + traçado das ligações).
  final double entry;

  /// 0→1→0: respiração do halo do paciente.
  final double pulse;

  static const _green = Color(0xFF2E7D6B);
  static const _ochre = Color(0xFFB5651D);
  static const _red = Color(0xFFB03A3A);
  static const _care = Color(0xFFE0A400); // cuidador principal (destaque)

  static const _r = 22.0;

  /// Cor base do ambiente atrás do diagrama — usada no contorno dos rótulos.
  static const _canvasBg = Color(0xFFF7FBFA);
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
    // Sem fundo opaco: o ambiente atrás do InteractiveViewer aparece.
    final rect = Offset.zero & size;

    // Ligações entram depois das pessoas, "se desenhando".
    final linkT = Curves.easeOut.transform(
      ((entry - 0.30) / 0.55).clamp(0.0, 1.0),
    );
    if (linkT > 0) {
      canvas.saveLayer(rect, Paint()..color = Color.fromRGBO(0, 0, 0, linkT));
      _bands(canvas);
      _connectors(canvas);
      _emotionalLayer(canvas);
      canvas.restore();
    }

    // Pessoas surgem em cascata, com um leve "pop".
    for (var i = 0; i < diagram.nodes.length; i++) {
      final n = diagram.nodes[i];
      final t = Curves.easeOutBack.transform(
        ((entry - i * 0.05) / 0.45).clamp(0.0, 1.0),
      );
      if (t <= 0) continue;
      final fade = ((entry - i * 0.05) / 0.45).clamp(0.0, 1.0);
      final bounds = Rect.fromCircle(center: Offset(n.x, n.y), radius: 110);

      canvas.saveLayer(bounds, Paint()..color = Color.fromRGBO(0, 0, 0, fade));
      canvas.save();
      final s = 0.84 + 0.16 * t.clamp(0.0, 1.0);
      canvas.translate(n.x, n.y);
      canvas.scale(s);
      canvas.translate(-n.x, -n.y);
      if (n.id == focusId) _focusHalo(canvas, n);
      _node(canvas, n);
      canvas.restore();
      canvas.restore();
    }
  }

  /// Halo que "respira" no paciente — só aparece com a entrada concluída e
  /// segue a forma do símbolo (círculo no feminino, quadrado no restante).
  void _focusHalo(Canvas canvas, GPositioned n) {
    if (entry < 0.9) return;
    final c = Offset(n.x, n.y);
    final r = _r + 8 + 6 * pulse;
    final paint = Paint()
      ..color = _teal.withValues(alpha: 0.20 - 0.12 * pulse)
      ..style = PaintingStyle.fill;

    final isFemale = byId[n.id]?.gender == GenogramGender.female;
    if (isFemale) {
      canvas.drawCircle(c, r, paint);
    } else {
      canvas.drawRect(
        Rect.fromCenter(center: c, width: r * 2, height: r * 2),
        paint,
      );
    }
  }

  // ── Camada emocional (overlay) ─────────────────────────────────────────────
  void _emotionalLayer(Canvas canvas) {
    for (final e in emotional) {
      final a = _p(e.a), b = _p(e.b);
      if (a == null || b == null) continue;
      final (color, draw) = switch (e.kind) {
        GEmotion.close => (_green, _CurveKind.doubleLine),
        GEmotion.distant => (const Color(0xFF6B7A90), _CurveKind.dashed),
        GEmotion.conflict => (_ochre, _CurveKind.zigzag),
        GEmotion.broken => (_red, _CurveKind.slashed),
      };
      _styledLine(canvas, Offset(a.x, a.y), Offset(b.x, b.y), draw, color);
    }
  }

  void _styledLine(
      Canvas canvas, Offset a, Offset b, _CurveKind kind, Color color) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.8
      ..style = PaintingStyle.stroke;
    final dir = b - a;
    final len = dir.distance;
    if (len < 1) return;
    final unit = dir / len;
    final start = a + unit * (_r + 6);
    final end = b - unit * (_r + 6);
    switch (kind) {
      case _CurveKind.doubleLine:
        final n = Offset(-unit.dy, unit.dx) * 2.4;
        canvas.drawLine(start + n, end + n, paint);
        canvas.drawLine(start - n, end - n, paint);
      case _CurveKind.dashed:
        _dashed(canvas, start, end, paint);
      case _CurveKind.zigzag:
        _zigzag(canvas, start, end, paint);
      case _CurveKind.slashed:
        canvas.drawLine(start, end, paint);
        _slashes(canvas, start, end, paint);
    }
  }

  void _dashed(Canvas canvas, Offset a, Offset b, Paint paint) {
    const dash = 6.0, gap = 4.0;
    final total = (b - a).distance;
    final unit = (b - a) / total;
    var d = 0.0;
    while (d < total) {
      canvas.drawLine(
          a + unit * d, a + unit * math.min(d + dash, total), paint);
      d += dash + gap;
    }
  }

  void _zigzag(Canvas canvas, Offset a, Offset b, Paint paint) {
    final total = (b - a).distance;
    final unit = (b - a) / total;
    final normal = Offset(-unit.dy, unit.dx);
    const step = 9.0, amp = 4.0;
    final path = Path()..moveTo(a.dx, a.dy);
    var d = 0.0, s = 1.0;
    while (d < total) {
      final next = math.min(d + step, total);
      final mid = a + unit * ((d + next) / 2) + normal * (amp * s);
      final e = a + unit * next;
      path.lineTo(mid.dx, mid.dy);
      path.lineTo(e.dx, e.dy);
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
      // Divórcio/separação: duas barras "//" sobre a linha do casal.
      if (!c.current) {
        final mx = (left.x + right.x) / 2;
        final my = left.y;
        final dp = Paint()
          ..color = _red
          ..strokeWidth = 2
          ..style = PaintingStyle.stroke;
        for (final off in [-4.0, 4.0]) {
          canvas.drawLine(
              Offset(mx + off - 4, my + 7), Offset(mx + off + 4, my - 7), dp);
        }
      }
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
      canvas.drawLine(Offset(midX, parentY), Offset(midX, barY), paint);
      // A barra de irmãos cobre os filhos E o ponto de descida do casal, para
      // o traço nunca ficar solto quando o casal não fica exatamente em cima.
      final barLeft =
          math.min(midX, kids.map((k) => k.x).reduce(math.min));
      final barRight =
          math.max(midX, kids.map((k) => k.x).reduce(math.max));
      if (barRight > barLeft) {
        canvas.drawLine(Offset(barLeft, barY), Offset(barRight, barY), paint);
      }
      _descents(canvas, kids, barY, paint);
    }
  }

  /// Desce da barra de irmãos até cada filho. Gêmeos convergem num único ponto
  /// (Λ); filhos adotivos descem tracejado.
  void _descents(
      Canvas canvas, List<GPositioned> kids, double barY, Paint paint) {
    final kidIds = {for (final k in kids) k.id};
    // Grupos de gêmeos presentes neste conjunto de irmãos.
    final twinOf = <String, Set<String>>{};
    for (final tg in layout.twinGroups) {
      final here = tg.where(kidIds.contains).toSet();
      if (here.length >= 2) {
        for (final id in here) {
          twinOf[id] = here;
        }
      }
    }
    final dashed = Paint()
      ..color = _line
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    void drop(double fromX, GPositioned k) {
      final a = Offset(fromX, barY);
      final b = Offset(k.x, k.y - _r);
      if (layout.adoptedChildren.contains(k.id)) {
        _dashed(canvas, a, b, dashed);
      } else {
        canvas.drawLine(a, b, paint);
      }
    }

    final done = <String>{};
    for (final k in kids) {
      final group = twinOf[k.id];
      if (group == null) {
        drop(k.x, k); // filho comum: vertical
        continue;
      }
      if (done.contains(k.id)) continue;
      final members = kids.where((c) => group.contains(c.id)).toList();
      final apexX =
          members.map((c) => c.x).reduce((a, b) => a + b) / members.length;
      for (final m in members) {
        drop(apexX, m); // gêmeos: convergem no apex sobre a barra
        done.add(m.id);
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
    final isFemale = person?.gender == GenogramGender.female;

    final fill = Paint()
      ..color = isIndex ? const Color(0xFFEAFAF7) : Colors.white
      ..style = PaintingStyle.fill;
    final stroke = Paint()
      ..color = isIndex ? _teal : _navy
      ..strokeWidth = isIndex ? 2.6 : 2.2
      ..style = PaintingStyle.stroke;

    // Cuidador(a) principal: halo âmbar atrás do símbolo — segue a forma do símbolo.
    if (person?.isPrimaryCaregiver ?? false) {
      final haloPaint = Paint()
        ..color = _care.withValues(alpha: 0.18)
        ..style = PaintingStyle.fill;
      if (isFemale) {
        canvas.drawCircle(c, _r + 9, haloPaint);
      } else {
        canvas.drawRect(
            Rect.fromCenter(
                center: c, width: (_r + 9) * 2, height: (_r + 9) * 2),
            haloPaint);
      }
    }

    // Símbolo: círculo (feminino) ou quadrado (masculino/outro).
    // O paciente (isIndex) mantém a cor teal mas segue a mesma forma.
    if (isFemale) {
      canvas.drawCircle(c, _r, fill);
      canvas.drawCircle(c, _r, stroke);
    } else {
      final rect = Rect.fromCenter(center: c, width: _r * 2, height: _r * 2);
      canvas.drawRect(rect, fill);
      canvas.drawRect(rect, stroke);
    }

    // Anel de cuidador: forma acompanha o símbolo.
    if (person?.isPrimaryCaregiver ?? false) {
      final ringPaint = Paint()
        ..color = _care
        ..strokeWidth = 2.4
        ..style = PaintingStyle.stroke;
      if (isFemale) {
        canvas.drawCircle(c, _r + 6, ringPaint);
      } else {
        canvas.drawRect(
            Rect.fromCenter(
                center: c, width: (_r + 6) * 2, height: (_r + 6) * 2),
            ringPaint);
      }
    } else if (person?.isPartialCaregiver ?? false) {
      final ringPaint = Paint()
        ..color = _care.withValues(alpha: 0.55)
        ..strokeWidth = 1.6
        ..style = PaintingStyle.stroke;
      if (isFemale) {
        canvas.drawCircle(c, _r + 6, ringPaint);
      } else {
        canvas.drawRect(
            Rect.fromCenter(
                center: c, width: (_r + 6) * 2, height: (_r + 6) * 2),
            ringPaint);
      }
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
    TextPainter build(TextStyle style) => TextPainter(
          text: TextSpan(text: text, style: style),
          textAlign: TextAlign.center,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: 104);

    final tp = build(TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      color: color,
    ));
    final dx = center ? at.dx - tp.width / 2 : at.dx;
    final dy = center && size >= 13 ? at.dy - tp.height / 2 : at.dy;

    // Contorno na cor do fundo: as linhas de parentesco passam por trás do
    // nome sem cortá-lo (mesma técnica de rótulo sobre mapa).
    final outline = build(TextStyle(
      fontFamily: fontFamily,
      fontSize: size,
      fontWeight: weight,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeJoin = StrokeJoin.round
        ..color = _canvasBg,
    ));
    outline.paint(canvas, Offset(dx, dy));

    tp.paint(canvas, Offset(dx, dy));
  }


  @override
  bool shouldRepaint(_MotorGenogramPainter old) =>
      old.diagram != diagram ||
      old.layout != layout ||
      old.emotional != emotional ||
      old.entry != entry ||
      old.pulse != pulse;
}

/// Ambiente da tela do genograma: formas orgânicas discretas da paleta, para o
/// diagrama não flutuar num vazio branco. Fica atrás do zoom/arraste.
class _GenogramBackdrop extends StatelessWidget {
  const _GenogramBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          children: [
            Positioned.fill(child: Container(color: const Color(0xFFF7FBFA))),
            Positioned(
              top: -70,
              left: -60,
              child: _blob(210, const Color(0xFF0F9C90).withValues(alpha: 0.09)),
            ),
            Positioned(
              bottom: -80,
              right: -70,
              child: _blob(240, const Color(0xFF1F7A8C).withValues(alpha: 0.08)),
            ),
            Positioned(
              top: 120,
              right: -40,
              child: _blob(120, const Color(0xFF8A5CB0).withValues(alpha: 0.06)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

enum _CurveKind { doubleLine, dashed, zigzag, slashed }
