import 'dart:math' as math;

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_severity.dart';
import '../../../../shared/widgets/esquema_core_logo.dart';
import '../../../../shared/widgets/homologation_ui.dart';
import '../../../../shared/widgets/icon_optics.dart';
import '../../../profile/domain/avatar_config.dart';
import '../../../profile/domain/avatar_type.dart';
import '../../../profile/domain/profile_role.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../domain/mental_case_map.dart';
import '../mental_map_node_state.dart';
import '../../domain/mental_map_case_summary.dart';
import '../../domain/mental_map_node_detail.dart';
import '../../domain/mental_map_validation_summary.dart';
import 'mental_map_art_icon.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Converte a severityColorKey do backend para uma cor concreta de UI.
Color _resolveSeverityDotColor(String? key, Color fallback) {
  final severity = AppSeverity.fromColorKey(key);
  return severity.hasSeverity ? severity.color : fallback;
}

class MentalMapDisclaimerBanner extends StatelessWidget {
  const MentalMapDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomologationInfoBanner(
      title: 'Visão integrada',
      icon: Icons.hub_outlined,
      message: 'Mapa mental em construção. Esta visão organiza informações '
          'registradas, mas não substitui avaliação clínica.',
    );
  }
}

class MentalMapSectionCard extends StatelessWidget {
  const MentalMapSectionCard({
    super.key,
    required this.title,
    required this.icon,
    required this.isEmpty,
    required this.emptyMessage,
    required this.child,
    this.emptyHint,
    this.onViewDetails,
  });

  final String title;
  final IconData icon;
  final bool isEmpty;
  final String emptyMessage;
  final String? emptyHint;
  final Widget child;
  final VoidCallback? onViewDetails;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            HomologationSectionHeader(icon: icon, title: title),
            const SizedBox(height: 16),
            if (isEmpty)
              HomologationEmptyPanel(
                icon: icon,
                title: 'Nada por aqui ainda',
                message: emptyMessage,
                hint: emptyHint,
              )
            else
              child,
            if (onViewDetails != null) ...[
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onViewDetails,
                  icon: const Icon(Icons.open_in_new, size: 18),
                  label: const Text('Ver detalhes'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class MentalMapScoreHighlightTile extends StatelessWidget {
  const MentalMapScoreHighlightTile({
    super.key,
    required this.name,
    required this.code,
    required this.kind,
    required this.displayScore,
  });

  final String name;
  final String code;
  final String kind;
  final String displayScore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '$kind · $code',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            displayScore,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class MentalMapCaseSummaryCard extends StatelessWidget {
  const MentalMapCaseSummaryCard({
    super.key,
    required this.summary,
  });

  final MentalMapCaseSummary summary;

  @override
  Widget build(BuildContext context) {
    return MentalMapSectionCard(
      title: 'Síntese clínica',
      icon: Icons.psychology_alt_outlined,
      isEmpty: !summary.hasContent,
      emptyMessage:
          'Ainda não há material suficiente para consolidar a síntese.',
      emptyHint: 'Preencha anamnese, demandas e instrumentos clínicos.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_hasText(summary.therapyDemands))
            _SummaryTextBlock(
              title: 'Demandas terapêuticas',
              body: summary.therapyDemands!,
            ),
          if (_hasText(summary.currentLifeContext))
            _SummaryTextBlock(
              title: 'Contexto de vida atual',
              body: summary.currentLifeContext!,
            ),
          if (_hasText(summary.intakeSummary))
            _SummaryTextBlock(
              title: 'Síntese inicial',
              body: summary.intakeSummary!,
            ),
          if (summary.centralHypotheses.isNotEmpty)
            _SummaryChipBlock(
              title: 'Hipóteses centrais',
              items: summary.centralHypotheses,
            ),
          if (summary.currentFocuses.isNotEmpty)
            _SummaryChipBlock(
              title: 'Focos atuais de acompanhamento',
              items: summary.currentFocuses,
            ),
        ],
      ),
    );
  }
}

class _SummaryTextBlock extends StatelessWidget {
  const _SummaryTextBlock({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 6),
          Text(body),
        ],
      ),
    );
  }
}

class _SummaryChipBlock extends StatelessWidget {
  const _SummaryChipBlock({
    required this.title,
    required this.items,
  });

  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final item in items)
                Chip(
                  label: Text(item),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

bool _hasText(String? value) {
  return value != null && value.trim().isNotEmpty;
}

class MentalMapValidationBanner extends StatelessWidget {
  const MentalMapValidationBanner({
    super.key,
    required this.summary,
  });

  final MentalMapValidationSummary summary;

  @override
  Widget build(BuildContext context) {
    return HomologationInfoBanner(
      title: summary.title,
      icon: Icons.verified_user_outlined,
      message: summary.message,
    );
  }
}

class MentalMapVisualHub extends StatelessWidget {
  const MentalMapVisualHub({
    super.key,
    required this.caseMap,
    required this.nodes,
  });

  final MentalCaseMap caseMap;
  final List<MentalMapHubNodeData> nodes;

  @override
  Widget build(BuildContext context) {
    final hubNodes = [
      ...nodes,
      if (!nodes.any((node) => node.id == 'personality'))
        const MentalMapHubNodeData(
          id: 'personality',
          title: 'Personalidade',
          subtitle: 'Versão futura',
          items: [],
          emptyLabel: 'Placeholder clínico',
          icon: Icons.psychology_alt_outlined,
          accentColor: AppColors.purple,
          isFilled: false,
          visualState: MentalMapNodeVisualState.blocked,
        ),
    ];

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomologationSectionHeader(
              icon: Icons.hub_outlined,
              title: 'Formulação visual do caso',
              subtitle: 'Núcleo clínico e contexto terapêutico',
            ),
            const SizedBox(height: 16),
            MentalMapRadialHub(
              center: caseMap.center,
              nodes: hubNodes,
            ),
          ],
        ),
      ),
    );
  }
}

class MentalMapRadialHub extends StatelessWidget {
  const MentalMapRadialHub({
    super.key,
    required this.center,
    required this.nodes,
  });

  final MentalCaseMapCenter center;
  final List<MentalMapHubNodeData> nodes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < 600) {
          return _MentalMapMobileOrbit(nodes: nodes, center: center);
        }

        final hubHeight = (width * 0.9).clamp(360.0, 520.0);
        final centerSize = (width * 0.34).clamp(124.0, 164.0);
        final nodeWidth = (width * 0.27).clamp(112.0, 144.0);
        final nodeHeight = (hubHeight * 0.22).clamp(90.0, 116.0);
        final centerX = (width - centerSize) / 2;
        final centerY = (hubHeight - centerSize) / 2;

        final topY = 8.0;
        final upperY = hubHeight * 0.18;
        final lowerY = hubHeight * 0.58;
        final bottomY = hubHeight - nodeHeight - 8;
        final leftX = 0.0;
        final centerNodeX = (width - nodeWidth) / 2;
        final rightX = width - nodeWidth;

        final nodeMap = <String, MentalMapHubNodeData>{
          for (final node in nodes) node.id: node,
        };

        // Posições compartilhadas entre o painter de conexões e os
        // Positioned dos nodos — a mesma fonte alimenta os dois.
        final slotPositions = <String, Rect>{
          'schemas': Rect.fromLTWH(centerNodeX, topY, nodeWidth, nodeHeight),
          'modes': Rect.fromLTWH(rightX, upperY, nodeWidth, nodeHeight),
          'problems': Rect.fromLTWH(rightX, lowerY, nodeWidth, nodeHeight),
          'goals': Rect.fromLTWH(centerNodeX, bottomY, nodeWidth, nodeHeight),
          'attachment': Rect.fromLTWH(leftX, upperY, nodeWidth, nodeHeight),
          'coping':
              Rect.fromLTWH(leftX, hubHeight * 0.36, nodeWidth, nodeHeight),
          'parental': Rect.fromLTWH(leftX, lowerY, nodeWidth, nodeHeight),
          'history': Rect.fromLTWH(leftX, bottomY, nodeWidth, nodeHeight),
        };

        return SizedBox(
          key: const ValueKey('mental-map-radial-layout'),
          width: width,
          height: hubHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: _HubConnections(
                  hubCenter: Offset(
                    centerX + centerSize / 2,
                    centerY + centerSize / 2,
                  ),
                  hubRadius: centerSize / 2,
                  targets: [
                    for (final entry in slotPositions.entries)
                      if (nodeMap[entry.key] case final node?)
                        _hubTarget(entry.value, node),
                  ],
                ),
              ),
              Positioned(
                left: centerX,
                top: centerY,
                width: centerSize,
                height: centerSize,
                child: _MentalMapHubCenter(center: center),
              ),
              for (final entry in slotPositions.entries)
                if (nodeMap[entry.key] case final node?)
                  Positioned(
                    left: entry.value.left,
                    top: entry.value.top,
                    width: entry.value.width,
                    height: entry.value.height,
                    child: _MentalMapOrbitNode(data: node, large: true),
                  ),
            ],
          ),
        );
      },
    );
  }
}

/// Distância que o fluxo percorre a cada ciclo do controller. Todos os
/// espaçamentos de [flowSpacingFor] dividem este valor — condição para o
/// laço não dar salto quando o controller volta de 1 para 0.
const double _flowCycleDistance = 60;

/// Espaçamento entre as partículas da fibra. A velocidade é a mesma em
/// todas as conexões; o que muda é a distância entre as partículas, então a
/// densidade do fluxo lê como quantidade de registros sem precisar de número.
///
/// Todo valor devolvido aqui precisa dividir [flowCycleDistance] — é o que
/// impede o laço de dar um salto quando o controller volta de 1 para 0.
@visibleForTesting
double flowSpacingFor(int itemCount) {
  if (itemCount >= 3) return 12;
  if (itemCount == 2) return 15;
  if (itemCount == 1) return 20;
  return 30;
}

/// Exposto para o teste conferir a divisibilidade citada acima.
@visibleForTesting
const double flowCycleDistance = _flowCycleDistance;

/// Anchor do nodo para o painter de conexões: o círculo do nodo fica
/// centralizado horizontalmente e um pouco acima do centro vertical da sua
/// caixa (a Column reserva espaço abaixo para o rótulo).
_HubConnectionTarget _hubTarget(
  Rect box,
  MentalMapHubNodeData node, {
  Offset? center,
  double radius = 32,
}) {
  return _HubConnectionTarget(
    center: center ?? Offset(box.center.dx, box.top + box.height * 0.42),
    radius: radius,
    isFilled: node.isFilled,
    color: node.severityColor ?? node.accentColor,
    // Só quem tem registro conduz fluxo: área vazia fica com a fibra
    // tênue e parada, e o contraste vira a informação.
    flowSpacing: node.isFilled ? flowSpacingFor(node.items.length) : null,
  );
}

/// Desenha as linhas do núcleo até cada nodo, parando na borda do círculo —
/// nunca atravessando o ícone ou o rótulo. Nodos preenchidos ganham conexão
/// mais presente com um micro-nodo no ponto médio; vazios ficam tênues.
class _HubConnectionsPainter extends CustomPainter {
  const _HubConnectionsPainter({
    required this.hubCenter,
    required this.hubRadius,
    required this.targets,
    this.flowPhase = 0,
  });

  final Offset hubCenter;
  final double hubRadius;
  final List<_HubConnectionTarget> targets;

  /// Avanço do fluxo, de 0 a 1 por ciclo do controller.
  final double flowPhase;

  @override
  void paint(Canvas canvas, Size size) {
    for (final target in targets) {
      final direction = target.center - hubCenter;
      final distance = direction.distance;
      // Só pula em caso degenerado (nodo praticamente sobre o centro do
      // hub) — nunca por estarem "próximos": alguns nodos deste layout
      // ficam a menos de hubRadius+targetRadius de distância, e ainda
      // assim precisam de uma linha (curta) até a borda do círculo.
      if (distance < 1) continue;
      final unit = direction / distance;
      final start = hubCenter + unit * hubRadius;
      // Garante que o fim da linha nunca fique mais perto do centro do
      // que o início — quando o nodo está muito próximo, a linha encolhe
      // até um ponto, mas nunca "volta" para dentro do círculo do hub.
      final endDistance = (distance - target.radius).clamp(hubRadius, distance);
      final end = hubCenter + unit * endDistance;

      // Curva suave em vez de linha reta — mesma organicidade da
      // constelação da marca. O ponto de controle é deslocado
      // perpendicularmente à linha direta.
      final normal = Offset(-unit.dy, unit.dx);
      final mid = Offset.lerp(start, end, 0.5)!;
      final control = mid + normal * (distance * 0.07);

      final color = target.isFilled ? target.color : AppColors.turquoise;
      final alpha = target.isFilled ? 0.45 : 0.24;

      final linePaint = Paint()
        ..color = color.withValues(alpha: alpha)
        ..strokeWidth = target.isFilled ? 1.8 : 1.2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final path = Path()
        ..moveTo(start.dx, start.dy)
        ..quadraticBezierTo(control.dx, control.dy, end.dx, end.dy);
      canvas.drawPath(path, linePaint);

      final dotPaint = Paint()..color = color.withValues(alpha: alpha + 0.2);
      canvas.drawCircle(start, 2.2, dotPaint);

      if (target.flowSpacing case final spacing?) {
        _paintFlow(canvas, path, spacing, color);
      } else {
        // Sem fluxo, o micro-nodo do meio dá alguma presença à fibra
        // apagada. Com fluxo ele só competiria com as partículas.
        canvas.drawCircle(control, 2.4, dotPaint);
      }
    }
  }

  /// Distribui partículas ao longo da fibra e as desloca em direção ao
  /// núcleo. As posições são `i * spacing - phase`: quando `phase` completa
  /// um `spacing`, o conjunto coincide com o do início, então o laço fecha
  /// sem salto visível.
  void _paintFlow(Canvas canvas, Path path, double spacing, Color color) {
    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;
    final metric = metrics.first;
    final length = metric.length;
    // Fibra curta demais não mostra fluxo — vira um borrão piscando.
    if (length < 12) return;

    final phase = (flowPhase * _flowCycleDistance) % spacing;
    final dot = Paint()..style = PaintingStyle.fill;

    for (var i = 0;; i++) {
      final distance = i * spacing - phase;
      if (distance > length) break;
      if (distance < 0) continue;
      final tangent = metric.getTangentForOffset(distance);
      if (tangent == null) continue;
      // Sem o esmaecimento nas pontas a partícula aparece e some de
      // estalo, o que denuncia o truque.
      final edge = math.min(distance, length - distance);
      final fade = (edge / 8).clamp(0.0, 1.0);
      dot.color = color.withValues(alpha: 0.9 * fade);
      canvas.drawCircle(tangent.position, 1.9, dot);
    }
  }

  @override
  bool shouldRepaint(_HubConnectionsPainter oldDelegate) =>
      oldDelegate.hubCenter != hubCenter ||
      oldDelegate.hubRadius != hubRadius ||
      oldDelegate.flowPhase != flowPhase ||
      !listEquals(oldDelegate.targets, targets);
}

class _HubConnectionTarget {
  const _HubConnectionTarget({
    required this.center,
    required this.radius,
    required this.isFilled,
    required this.color,
    this.flowSpacing,
  });

  final Offset center;
  final double radius;
  final bool isFilled;
  final Color color;

  /// Distância entre as partículas do fluxo. `null` = fibra sem fluxo.
  final double? flowSpacing;

  @override
  bool operator ==(Object other) =>
      other is _HubConnectionTarget &&
      other.center == center &&
      other.radius == radius &&
      other.isFilled == isFilled &&
      other.color == color &&
      other.flowSpacing == flowSpacing;

  @override
  int get hashCode => Object.hash(center, radius, isFilled, color, flowSpacing);
}

/// Envolve o painter das conexões com o controller do fluxo. Existe como
/// widget próprio porque os dois layouts (mobile e largo) precisam da mesma
/// animação, e o layout largo é stateless.
class _HubConnections extends StatefulWidget {
  const _HubConnections({
    required this.hubCenter,
    required this.hubRadius,
    required this.targets,
  });

  final Offset hubCenter;
  final double hubRadius;
  final List<_HubConnectionTarget> targets;

  @override
  State<_HubConnections> createState() => _HubConnectionsState();
}

class _HubConnectionsState extends State<_HubConnections>
    with SingleTickerProviderStateMixin {
  late final AnimationController _flow;

  @override
  void initState() {
    super.initState();
    _flow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Com "reduzir movimento" o fluxo congela, mas as partículas continuam
    // desenhadas: a densidade segue informando a quantidade de registros,
    // que é o dado — só o movimento é supérfluo.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _flow
        ..stop()
        ..value = 0;
    } else if (!_flow.isAnimating) {
      _flow.repeat();
    }
  }

  @override
  void dispose() {
    _flow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RepaintBoundary(
        child: AnimatedBuilder(
          animation: _flow,
          builder: (context, _) => CustomPaint(
            size: Size.infinite,
            painter: _HubConnectionsPainter(
              hubCenter: widget.hubCenter,
              hubRadius: widget.hubRadius,
              targets: widget.targets,
              flowPhase: _flow.value,
            ),
          ),
        ),
      ),
    );
  }
}

class _MentalMapMobileOrbit extends StatefulWidget {
  const _MentalMapMobileOrbit({
    required this.nodes,
    required this.center,
  });

  final List<MentalMapHubNodeData> nodes;
  final MentalCaseMapCenter center;

  @override
  State<_MentalMapMobileOrbit> createState() => _MentalMapMobileOrbitState();
}

class _MentalMapMobileOrbitState extends State<_MentalMapMobileOrbit>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3600),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // A flutuação ambiente dos nodos também obedece a "reduzir movimento".
    // Ela é puramente decorativa — diferente do fluxo, onde as partículas
    // seguem desenhadas porque a densidade é o dado.
    final reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduceMotion) {
      _controller
        ..stop()
        ..value = 0;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nodeMap = <String, MentalMapHubNodeData>{
      for (final node in widget.nodes) node.id: node,
    };

    // Layout polar: todos os nodos à mesma distância do núcleo. O Alignment
    // que havia antes deixava os de cima e os de baixo a distâncias
    // diferentes (o rótulo sob o círculo desloca a âncora para cima), e as
    // fibras acabavam com 0 a 8px — sem percurso para o fluxo correr.
    const slots = <({String id, double angleDeg})>[
      (id: 'schemas', angleDeg: -90),
      (id: 'modes', angleDeg: -30),
      (id: 'problems', angleDeg: 30),
      (id: 'attachment', angleDeg: 90),
      (id: 'goals', angleDeg: 150),
      (id: 'coping', angleDeg: 210),
    ];

    const boxHeight = 300.0;
    const nodeWidth = 84.0;
    const nodeHeight = 72.0;
    const nodeDiameter = 44.0;
    const hubDiameter = 88.0;
    // Onde o círculo cai dentro da caixa do nodo: a Column centraliza
    // [círculo, espaço, rótulo], então o círculo fica acima do meio.
    const circleAnchor =
        (nodeHeight - (nodeDiameter + 6 + 15)) / 2 + nodeDiameter / 2;

    final activeCount = widget.nodes.where((node) => node.isFilled).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final hubCenter = Offset(width / 2, boxHeight / 2);
        // Raio limitado pelo que cabe embaixo (rótulo do nodo inferior) e
        // pelas laterais (nodos a ±30° da horizontal).
        final radius = math.min(
          103.0,
          math.min(
            boxHeight / 2 - (nodeHeight - circleAnchor),
            (width / 2 - nodeWidth / 2) / math.cos(30 * math.pi / 180),
          ),
        );

        final circleCenters = <String, Offset>{
          for (final slot in slots)
            slot.id: hubCenter +
                Offset(
                  radius * math.cos(slot.angleDeg * math.pi / 180),
                  radius * math.sin(slot.angleDeg * math.pi / 180),
                ),
        };

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              key: const ValueKey('mental-map-connected-list'),
              height: boxHeight,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned.fill(
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: AppColors.navy.withValues(alpha: 0.06),
                          ),
                        ),
                        child: SizedBox.square(dimension: radius * 2),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: _HubConnections(
                      hubCenter: hubCenter,
                      hubRadius: hubDiameter / 2,
                      targets: [
                        for (final slot in slots)
                          if (nodeMap[slot.id] case final node?)
                            _hubTarget(
                              Rect.zero,
                              node,
                              center: circleCenters[slot.id],
                              radius: nodeDiameter / 2 + 2,
                            ),
                      ],
                    ),
                  ),
                  Positioned(
                    left: hubCenter.dx - hubDiameter / 2,
                    top: hubCenter.dy - hubDiameter / 2,
                    width: hubDiameter,
                    height: hubDiameter,
                    child: _MentalMapHubCenter(
                      center: widget.center,
                      compactSummary: activeCount == 1
                          ? '1 área ativa'
                          : '$activeCount áreas ativas',
                    ),
                  ),
                  for (var i = 0; i < slots.length; i++)
                    if (nodeMap[slots[i].id] case final node?)
                      () {
                        // O rótulo vai para o lado oposto ao núcleo. Só o
                        // nodo do topo precisa disso: nele a fibra desce
                        // reta e passaria exatamente por cima do texto.
                        final labelAbove =
                            math.sin(slots[i].angleDeg * math.pi / 180) < -0.7;
                        final anchor = labelAbove
                            ? nodeHeight - circleAnchor
                            : circleAnchor;
                        return Positioned(
                          left: circleCenters[slots[i].id]!.dx - nodeWidth / 2,
                          top: circleCenters[slots[i].id]!.dy - anchor,
                          width: nodeWidth,
                          height: nodeHeight,
                          child: AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) => Transform.translate(
                              offset: Offset(
                                0,
                                math.sin((_controller.value * math.pi) + i) * 4,
                              ),
                              child: child,
                            ),
                            child: _MentalMapOrbitNode(
                              data: node,
                              diameter: nodeDiameter,
                              labelAbove: labelAbove,
                            ),
                          ),
                        );
                      }(),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // O núcleo encolheu para abrir percurso para o fluxo, então
            // estas três leituras saíram de dentro dele para cá — mudaram
            // de lugar, não foram removidas.
            Text(
              [
                widget.center.activeProblemsLabel,
                widget.center.activeGoalsLabel,
                widget.center.lastCheckInLabel,
              ].join(' · '),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      },
    );
  }
}

// Correção de centramento óptico dos glifos — fonte única em icon_optics.dart,
// compartilhada com os estados vazios (HomologationEmptyPanel). Ver a medição
// em test/tools/measure_icon_drift.dart.
Offset _opticalNudgeFor(IconData icon, double size) =>
    opticalIconNudge(icon, size);

class _MentalMapOrbitNode extends StatelessWidget {
  const _MentalMapOrbitNode({
    required this.data,
    this.diameter = 56,
    this.large = false,
    this.labelAbove = false,
  });

  final MentalMapHubNodeData data;
  final double diameter;
  final bool large;

  /// Coloca o rótulo acima do círculo. No nodo do topo a fibra desce reta
  /// do círculo até o núcleo e passaria por baixo do texto — o rótulo tem
  /// de ficar do lado oposto ao centro.
  final bool labelAbove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Severity overrides the border/fill when available; icon/text keep
    // accentColor to preserve the node's visual identity.
    final effectiveRingColor = data.isFilled
        ? (data.severityColor ?? data.accentColor)
        : theme.colorScheme.outlineVariant;
    final textColor =
        data.isFilled ? data.accentColor : theme.colorScheme.onSurfaceVariant;

    final iconSize = large ? 26.0 : 22.0;

    // Nodo com registro ganha o ícone multicolor desenhado; vazio continua
    // com o glifo Material esmaecido, mantendo intacta a leitura de
    // "adormecido" que o fluxo apagado já reforça.
    final art = data.isFilled ? MentalMapArt.forNodeId(data.id) : null;
    final Widget iconChild = art != null
        ? MentalMapArtIcon(art: art, size: iconSize)
        : Transform.translate(
            offset: _opticalNudgeFor(data.icon, iconSize),
            child: Icon(
              data.icon,
              color: data.isFilled ? data.accentColor : effectiveRingColor,
              size: iconSize,
            ),
          );

    final circle = AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: data.isFilled
            ? effectiveRingColor.withValues(alpha: 0.14)
            : Colors.transparent,
        border: Border.all(
          color: effectiveRingColor,
          width: data.isFilled ? 2 : 1.5,
        ),
        boxShadow: data.isFilled
            ? [
                BoxShadow(
                  color: effectiveRingColor.withValues(alpha: 0.22),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : const [],
      ),
      child: Center(child: iconChild),
    );

    final label = Text(
      data.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      textAlign: TextAlign.center,
      style: theme.textTheme.labelSmall?.copyWith(
        color: textColor,
        fontWeight: data.isFilled ? FontWeight.w700 : FontWeight.w600,
      ),
    );

    return InkWell(
      onTap: data.onTap,
      borderRadius: BorderRadius.circular(22),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: labelAbove
            ? [label, const SizedBox(height: 6), circle]
            : [circle, const SizedBox(height: 6), label],
      ),
    );
  }
}

class MentalMapHubNodeData {
  const MentalMapHubNodeData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.items,
    required this.emptyLabel,
    required this.icon,
    required this.accentColor,
    required this.isFilled,
    required this.visualState,
    this.severityColor,
    this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> items;
  final String emptyLabel;
  final IconData icon;
  final Color accentColor;

  /// Cor clínica de severidade resolvida (null = sem dados ou vazio).
  final Color? severityColor;
  final bool isFilled;
  final MentalMapNodeVisualState visualState;
  final VoidCallback? onTap;

  bool get isEmpty => items.isEmpty;
}

class MentalMapHubNode extends StatelessWidget {
  const MentalMapHubNode({
    super.key,
    required this.data,
  });

  final MentalMapHubNodeData data;

  Color _stateColor(
    MentalMapNodeVisualState state,
    Color accent,
    ThemeData theme,
  ) {
    return switch (state) {
      MentalMapNodeVisualState.filled => accent,
      MentalMapNodeVisualState.partial => AppColors.warning,
      MentalMapNodeVisualState.pending => theme.colorScheme.onSurfaceVariant,
      MentalMapNodeVisualState.blocked => theme.colorScheme.error,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxHeight = constraints.maxHeight;
        final visibleItems = maxHeight < 104
            ? 1
            : maxHeight < 128
                ? 2
                : 3;

        return Material(
          color: data.accentColor.withValues(alpha: data.isFilled ? 0.1 : 0.05),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(
              color: data.isFilled
                  ? data.accentColor
                  : data.accentColor.withValues(alpha: 0.45),
              width: data.isFilled ? 1.6 : 1,
              strokeAlign: BorderSide.strokeAlignOutside,
            ),
          ),
          child: InkWell(
            onTap: data.onTap,
            borderRadius: BorderRadius.circular(22),
            child: Stack(
              children: [
                if (!data.isFilled)
                  Positioned.fill(
                    child: CustomPaint(
                      painter: _DashedBorderPainter(
                        color: data.accentColor.withValues(alpha: 0.35),
                        borderRadius: 22,
                      ),
                    ),
                  ),
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(data.icon, color: data.accentColor, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              data.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                          ),
                          Icon(
                            mentalMapNodeStateIcon(data.visualState),
                            size: 14,
                            semanticLabel:
                                mentalMapNodeStateLabel(data.visualState),
                            color: _stateColor(
                                data.visualState, data.accentColor, theme),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        mentalMapNodeStateLabel(data.visualState),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: _stateColor(
                              data.visualState, data.accentColor, theme),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Expanded(
                        child: data.isEmpty
                            ? Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  data.emptyLabel,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              )
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  for (final item
                                      in data.items.take(visibleItems))
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 2),
                                      child: Text(
                                        item,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: theme.textTheme.bodySmall,
                                      ),
                                    ),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MentalMapHubCenter extends StatelessWidget {
  const _MentalMapHubCenter({
    required this.center,
    this.compactSummary,
  });

  final MentalCaseMapCenter center;

  /// Quando presente, o núcleo entra em modo compacto: só o nome e este
  /// resumo. Usado no layout mobile, onde o círculo encolheu para abrir
  /// percurso de fibra — as três leituras longas vão para fora do círculo.
  final String? compactSummary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      // No modo compacto o círculo é só a foto — sem texto, a pedido da
      // clínica. O nome e a contagem de áreas seguem aqui para não sumirem
      // de quem navega por leitor de tela.
      label: compactSummary == null
          ? 'Paciente ${center.patientName}'
          : 'Paciente ${center.patientName}, $compactSummary',
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              AppColors.turquoise.withValues(alpha: 0.18),
              theme.colorScheme.surfaceContainerHighest,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border:
              Border.all(color: AppColors.turquoise.withValues(alpha: 0.35)),
          boxShadow: [
            BoxShadow(
              color: AppColors.turquoise.withValues(alpha: 0.15),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(compactSummary == null ? 12 : 0),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (compactSummary != null) ...[
                  UserAvatar.parts(
                    fullName: center.patientName,
                    initials: center.initials,
                    role: ProfileRole.patient,
                    avatarType: _toAvatarType(center.avatarType),
                    photoUrl: center.photoUrl,
                    avatarConfig: AvatarConfig.fromJson(center.avatarConfig),
                    size: 88,
                  ),
                ] else ...[
                  const EsquemaCoreLogo.icon(size: 28),
                  const SizedBox(height: 6),
                  Text(
                    center.patientName,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    center.activeProblemsLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    center.activeGoalsLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    center.lastCheckInLabel,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

AvatarType _toAvatarType(MentalCaseMapAvatarType t) => switch (t) {
      MentalCaseMapAvatarType.photo => AvatarType.photo,
      MentalCaseMapAvatarType.custom => AvatarType.custom,
      MentalCaseMapAvatarType.initials => AvatarType.initials,
    };

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter({
    required this.color,
    required this.borderRadius,
  });

  final Color color;
  final double borderRadius;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final rect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );

    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final path = Path()..addRRect(rect);
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        final next = distance + dashWidth;
        canvas.drawPath(
          metric.extractPath(distance, next.clamp(0, metric.length)),
          paint,
        );
        distance = next + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.borderRadius != borderRadius;
  }
}

Future<void> showMentalMapNodeDetailSheet({
  required BuildContext context,
  required MentalMapNodeDetail detail,
  required VoidCallback? onPrimaryTap,
  VoidCallback? onSecondaryTap,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => MentalMapNodeDetailSheet(
      detail: detail,
      onPrimaryTap: onPrimaryTap,
      onSecondaryTap: onSecondaryTap,
    ),
  );
}

class MentalMapNodeDetailSheet extends StatelessWidget {
  const MentalMapNodeDetailSheet({
    super.key,
    required this.detail,
    required this.onPrimaryTap,
    this.onSecondaryTap,
  });

  final MentalMapNodeDetail detail;
  final VoidCallback? onPrimaryTap;
  final VoidCallback? onSecondaryTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final loc = MaterialLocalizations.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              detail.title,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: Icon(
                detail.isFilled ? Icons.check_circle : Icons.schedule,
                size: 18,
              ),
              label: Text(detail.isFilled ? 'Preenchido' : 'Pendente'),
            ),
            const SizedBox(height: 12),
            Text(
              'Origem dos dados',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              detail.dataSource,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (detail.lastUpdatedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'Última atualização',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(loc.formatFullDate(detail.lastUpdatedAt!.toLocal())),
            ],
            const SizedBox(height: 16),
            Text(
              'Itens principais',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            if (detail.items.isEmpty)
              Text(
                'Nenhum dado registrado neste nó ainda.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ...detail.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 8,
                        color: _resolveSeverityDotColor(
                          detail.severityColorKey,
                          theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(item)),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 16),
            if (onPrimaryTap != null)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onPrimaryTap!();
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(detail.ctaLabel),
                ),
              ),
            if (onSecondaryTap != null && detail.secondaryCtaLabel != null) ...[
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onSecondaryTap!();
                  },
                  icon: const Icon(Icons.open_in_new),
                  label: Text(detail.secondaryCtaLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
