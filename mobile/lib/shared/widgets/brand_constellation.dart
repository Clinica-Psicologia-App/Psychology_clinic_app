import 'package:flutter/material.dart';

/// Linguagem visual de nodos e conexões da marca (Living Clinical Map).
///
/// Desenha uma pequena constelação abstrata: nós circulares (alguns em anel,
/// alguns preenchidos) ligados por linhas finas. Usada como camada decorativa
/// em heros, splash, login e estados vazios — nunca como informação.
///
/// `progress` (0..1) revela a constelação gradualmente: primeiro as linhas
/// crescem a partir do primeiro nó de cada par, depois os nós aparecem.
/// Com `progress: 1` a pintura é estática (sem custo de animação).
class BrandConstellation extends StatelessWidget {
  const BrandConstellation({
    super.key,
    required this.size,
    this.color = Colors.white,
    this.opacity = 0.30,
    this.progress = 1.0,
    this.preset = BrandConstellationPreset.scatter,
  });

  final Size size;
  final Color color;
  final double opacity;
  final double progress;
  final BrandConstellationPreset preset;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: RepaintBoundary(
        child: CustomPaint(
          size: size,
          painter: _ConstellationPainter(
            color: color.withValues(alpha: opacity),
            progress: progress.clamp(0.0, 1.0),
            preset: preset,
          ),
        ),
      ),
    );
  }
}

enum BrandConstellationPreset {
  /// Nós espalhados organicamente — heros e painéis de marca.
  scatter,

  /// Caminho ascendente conectado — progresso/jornada.
  path,

  /// Nós orbitando um núcleo central — splash e estados vazios.
  orbit,
}

class _Node {
  const _Node(this.x, this.y, this.radius, {this.ring = false});

  /// Posições normalizadas 0..1.
  final double x;
  final double y;
  final double radius;
  final bool ring;
}

class _ConstellationPainter extends CustomPainter {
  const _ConstellationPainter({
    required this.color,
    required this.progress,
    required this.preset,
  });

  final Color color;
  final double progress;
  final BrandConstellationPreset preset;

  static const _scatterNodes = [
    _Node(0.12, 0.30, 4, ring: true),
    _Node(0.30, 0.12, 3),
    _Node(0.52, 0.26, 5, ring: true),
    _Node(0.74, 0.10, 3),
    _Node(0.90, 0.34, 4, ring: true),
    _Node(0.68, 0.52, 3),
    _Node(0.22, 0.62, 3),
    _Node(0.44, 0.80, 4, ring: true),
    _Node(0.82, 0.78, 3),
  ];
  static const _scatterLinks = [
    (0, 1),
    (1, 2),
    (2, 3),
    (3, 4),
    (2, 5),
    (5, 8),
    (0, 6),
    (6, 7),
    (7, 5),
  ];

  static const _pathNodes = [
    _Node(0.10, 0.85, 5, ring: true),
    _Node(0.32, 0.62, 4),
    _Node(0.55, 0.48, 5, ring: true),
    _Node(0.75, 0.28, 4),
    _Node(0.92, 0.12, 6, ring: true),
  ];
  static const _pathLinks = [(0, 1), (1, 2), (2, 3), (3, 4)];

  static const _orbitNodes = [
    _Node(0.50, 0.50, 6, ring: true),
    _Node(0.50, 0.12, 4),
    _Node(0.85, 0.32, 4, ring: true),
    _Node(0.82, 0.74, 3),
    _Node(0.50, 0.90, 4, ring: true),
    _Node(0.16, 0.72, 3),
    _Node(0.14, 0.28, 4, ring: true),
  ];
  static const _orbitLinks = [(0, 1), (0, 2), (0, 3), (0, 4), (0, 5), (0, 6)];

  (List<_Node>, List<(int, int)>) get _layout => switch (preset) {
        BrandConstellationPreset.scatter => (_scatterNodes, _scatterLinks),
        BrandConstellationPreset.path => (_pathNodes, _pathLinks),
        BrandConstellationPreset.orbit => (_orbitNodes, _orbitLinks),
      };

  @override
  void paint(Canvas canvas, Size size) {
    final (nodes, links) = _layout;

    Offset pos(_Node n) => Offset(n.x * size.width, n.y * size.height);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Linhas crescem primeiro (0..0.7 do progresso)
    final lineProgress = (progress / 0.7).clamp(0.0, 1.0);
    for (var i = 0; i < links.length; i++) {
      final revealEnd = (i + 1) / links.length;
      final t = (lineProgress / revealEnd).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final (a, b) = links[i];
      final start = pos(nodes[a]);
      final end = pos(nodes[b]);
      canvas.drawLine(start, Offset.lerp(start, end, t)!, linePaint);
    }

    // Nós aparecem em seguida (0.3..1 do progresso)
    final nodeProgress = ((progress - 0.3) / 0.7).clamp(0.0, 1.0);
    final fill = Paint()..color = color;
    final ring = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < nodes.length; i++) {
      final revealEnd = (i + 1) / nodes.length;
      final t = (nodeProgress / revealEnd).clamp(0.0, 1.0);
      if (t <= 0) continue;
      final node = nodes[i];
      final radius = node.radius * t;
      canvas.drawCircle(pos(node), radius, node.ring ? ring : fill);
    }
  }

  @override
  bool shouldRepaint(_ConstellationPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.preset != preset;
}
