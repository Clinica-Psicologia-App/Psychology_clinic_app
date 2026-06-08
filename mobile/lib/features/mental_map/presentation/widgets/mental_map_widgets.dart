import 'package:flutter/material.dart';

import '../../../../shared/widgets/homologation_ui.dart';
import '../../domain/mental_case_map.dart';
import '../../domain/mental_map_case_summary.dart';
import '../../domain/mental_map_node_detail.dart';
import '../../domain/mental_map_validation_summary.dart';

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
    return Card(
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
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomologationSectionHeader(
              icon: Icons.hub_outlined,
              title: 'Formulação visual do caso',
              subtitle: 'Centro clínico + camadas principais e contextuais',
            ),
            const SizedBox(height: 16),
            MentalMapRadialHub(
              center: caseMap.center,
              nodes: nodes,
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
        if (width < 560) {
          return _MentalMapHubGridFallback(nodes: nodes, center: center);
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

        return SizedBox(
          key: const ValueKey('mental-map-radial-layout'),
          width: width,
          height: hubHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned(
                left: centerX,
                top: centerY,
                width: centerSize,
                height: centerSize,
                child: _MentalMapHubCenter(center: center),
              ),
              if (nodeMap['schemas'] case final node?)
                Positioned(
                  left: centerNodeX,
                  top: topY,
                  width: nodeWidth,
                  height: nodeHeight,
                  child: MentalMapHubNode(data: node),
                ),
              if (nodeMap['modes'] case final node?)
                Positioned(
                  left: rightX,
                  top: upperY,
                  width: nodeWidth,
                  height: nodeHeight,
                  child: MentalMapHubNode(data: node),
                ),
              if (nodeMap['problems'] case final node?)
                Positioned(
                  left: rightX,
                  top: lowerY,
                  width: nodeWidth,
                  height: nodeHeight,
                  child: MentalMapHubNode(data: node),
                ),
              if (nodeMap['goals'] case final node?)
                Positioned(
                  left: centerNodeX,
                  top: bottomY,
                  width: nodeWidth,
                  height: nodeHeight,
                  child: MentalMapHubNode(data: node),
                ),
              if (nodeMap['attachment'] case final node?)
                Positioned(
                  left: leftX,
                  top: upperY,
                  width: nodeWidth,
                  height: nodeHeight,
                  child: MentalMapHubNode(data: node),
                ),
              if (nodeMap['coping'] case final node?)
                Positioned(
                  left: leftX,
                  top: hubHeight * 0.36,
                  width: nodeWidth,
                  height: nodeHeight,
                  child: MentalMapHubNode(data: node),
                ),
              if (nodeMap['parental'] case final node?)
                Positioned(
                  left: leftX,
                  top: lowerY,
                  width: nodeWidth,
                  height: nodeHeight,
                  child: MentalMapHubNode(data: node),
                ),
              if (nodeMap['history'] case final node?)
                Positioned(
                  left: leftX,
                  top: bottomY,
                  width: nodeWidth,
                  height: nodeHeight,
                  child: MentalMapHubNode(data: node),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _MentalMapHubGridFallback extends StatelessWidget {
  const _MentalMapHubGridFallback({
    required this.nodes,
    required this.center,
  });

  final List<MentalMapHubNodeData> nodes;
  final MentalCaseMapCenter center;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MentalMapHubCenter(center: center),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              const spacing = 10.0;
              final itemWidth = (width - spacing) / 2;

              return Wrap(
                key: const ValueKey('mental-map-grid-layout'),
                spacing: spacing,
                runSpacing: spacing,
                children: [
                  for (final node in nodes)
                    SizedBox(
                      width: itemWidth,
                      height: 112,
                      child: MentalMapHubNode(data: node),
                    ),
                ],
              );
            },
          ),
        ],
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
    this.onTap,
  });

  final String id;
  final String title;
  final String subtitle;
  final List<String> items;
  final String emptyLabel;
  final IconData icon;
  final Color accentColor;
  final bool isFilled;
  final VoidCallback? onTap;

  bool get isEmpty => items.isEmpty;
}

class MentalMapHubNode extends StatelessWidget {
  const MentalMapHubNode({
    super.key,
    required this.data,
  });

  final MentalMapHubNodeData data;

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
                            data.isFilled
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 14,
                            color: data.isFilled
                                ? data.accentColor
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        data.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
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
  });

  final MentalCaseMapCenter center;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            colors.primaryContainer,
            colors.surfaceContainerHighest,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colors.primary.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                center.patientName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
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
          ),
        ),
      ),
    );
  }
}

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
                fontWeight: FontWeight.w800,
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
                        color: theme.colorScheme.primary,
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
