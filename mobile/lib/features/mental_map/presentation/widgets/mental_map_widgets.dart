import 'package:flutter/material.dart';

import '../../../../shared/widgets/homologation_ui.dart';
import '../../domain/mental_map_case_summary.dart';
import '../../domain/mental_map_validation_summary.dart';

class MentalMapDisclaimerBanner extends StatelessWidget {
  const MentalMapDisclaimerBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return const HomologationInfoBanner(
      title: 'Visão integrada',
      icon: Icons.hub_outlined,
      message: 'Mapa mental em construção. Esta visão organiza informações '
          'registradas nos módulos, mas não substitui avaliação clínica.',
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
    required this.patientName,
    required this.activeProblemsCount,
    required this.activeGoalsCount,
    required this.lastQuestionnaireLabel,
    required this.nodes,
  });

  final String patientName;
  final int activeProblemsCount;
  final int activeGoalsCount;
  final String lastQuestionnaireLabel;
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
              title: 'Conexões principais do caso',
              subtitle: 'Conexões principais do caso atual',
            ),
            const SizedBox(height: 16),
            MentalMapRadialHub(
              patientName: patientName,
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
    required this.patientName,
    required this.nodes,
  });

  final String patientName;
  final List<MentalMapHubNodeData> nodes;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        if (width < 340) {
          return _MentalMapHubGridFallback(nodes: nodes, patientName: patientName);
        }

        final hubHeight = (width * 0.95).clamp(280.0, 420.0);
        final centerSize = (width * 0.32).clamp(96.0, 128.0);
        final nodeSize = (width * 0.24).clamp(72.0, 96.0);
        final centerX = (width - centerSize) / 2;
        final centerY = (hubHeight - centerSize) / 2;

        final topY = 0.0;
        final upperY = hubHeight * 0.18;
        final lowerY = hubHeight * 0.58;
        final bottomY = hubHeight - nodeSize;
        final leftX = 0.0;
        final centerNodeX = (width - nodeSize) / 2;
        final rightX = width - nodeSize;

        final nodeMap = <String, MentalMapHubNodeData>{
          for (final node in nodes) node.title: node,
        };

        return SizedBox(
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
                child: _MentalMapHubCenter(patientName: patientName),
              ),
              if (nodeMap['Esquemas'] case final node?)
                Positioned(
                  left: centerNodeX,
                  top: topY,
                  width: nodeSize,
                  height: nodeSize,
                  child: MentalMapHubNode(data: node),
                ),
              if (nodeMap['Modos'] case final node?)
                Positioned(
                  left: rightX,
                  top: upperY,
                  width: nodeSize,
                  height: nodeSize,
                  child: MentalMapHubNode(data: node),
                ),
              if (nodeMap['Problemas'] case final node?)
                Positioned(
                  left: rightX,
                  top: lowerY,
                  width: nodeSize,
                  height: nodeSize,
                  child: MentalMapHubNode(data: node),
                ),
              if (nodeMap['Objetivos'] case final node?)
                Positioned(
                  left: centerNodeX,
                  top: bottomY,
                  width: nodeSize,
                  height: nodeSize,
                  child: MentalMapHubNode(data: node),
                ),
              if (nodeMap['Timeline'] case final node?)
                Positioned(
                  left: leftX,
                  top: lowerY,
                  width: nodeSize,
                  height: nodeSize,
                  child: MentalMapHubNode(data: node),
                ),
              if (nodeMap['Genograma'] case final node?)
                Positioned(
                  left: leftX,
                  top: upperY,
                  width: nodeSize,
                  height: nodeSize,
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
    required this.patientName,
  });

  final List<MentalMapHubNodeData> nodes;
  final String patientName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _MentalMapHubCenter(patientName: patientName),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            const spacing = 10.0;
            final itemWidth = (width - spacing) / 2;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: [
                for (final node in nodes)
                  SizedBox(
                    width: itemWidth,
                    height: 84,
                    child: MentalMapHubNode(data: node),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class MentalMapHubNodeData {
  const MentalMapHubNodeData({
    required this.title,
    required this.icon,
    required this.accentColor,
    this.onTap,
  });

  final String title;
  final IconData icon;
  final Color accentColor;
  final VoidCallback? onTap;
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

    return Material(
      color: data.accentColor.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: data.onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(data.icon, color: data.accentColor, size: 24),
                const SizedBox(height: 6),
                Text(
                  data.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MentalMapHubCenter extends StatelessWidget {
  const _MentalMapHubCenter({
    required this.patientName,
  });

  final String patientName;

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
                patientName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Paciente',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
