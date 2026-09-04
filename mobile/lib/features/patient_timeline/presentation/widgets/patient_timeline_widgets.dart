import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/status_chip.dart';
import '../../../life_story/domain/life_story_deepen_enums.dart';
import '../../domain/patient_timeline_event.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class PatientTimelineEventTile extends StatelessWidget {
  const PatientTimelineEventTile({
    super.key,
    required this.event,
    required this.onTap,
    this.isFirst = false,
    this.isLast = false,
  });

  final PatientTimelineEvent event;
  final VoidCallback onTap;
  final bool isFirst;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sensitive = event.isSensitive;
    final hasPresentInfluence = event.presentInfluence != null;
    // Evento sensível recebe tratamento de confidencialidade (discreto),
    // não de alarme: cadeado + roxo clínico, nunca vermelho de erro.
    final accent = sensitive
        ? AppColors.purple
        : hasPresentInfluence
            ? AppColors.warning
            : AppColors.moduleTimeline;
    final lineColor = accent.withValues(alpha: 0.22);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 48,
            child: Column(
              children: [
                if (!isFirst)
                  Expanded(
                    child: Container(width: 2, color: lineColor),
                  ),
                _TimelineNode(accent: accent),
                if (!isLast)
                  Expanded(
                    child: Container(width: 2, color: lineColor),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(
                top: isFirst ? 0 : 4,
                bottom: isLast ? 0 : AppSpacing.md,
              ),
              child: ClayCard(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: accent.withValues(alpha: 0.18)),
                ),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    event.dateLabel,
                                    style:
                                        theme.textTheme.labelMedium?.copyWith(
                                      color: accent,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xxs),
                                  Text(
                                    event.title,
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onSurface,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xs,
                          children: [
                            if (event.periodLabel != null &&
                                event.periodLabel!.trim().isNotEmpty)
                              StatusChip(
                                label: event.periodLabel!.trim(),
                                tone: AppStatusTone.info,
                                icon: Icons.auto_stories_outlined,
                              ),
                            if (event.presentInfluence != null)
                              StatusChip(
                                label:
                                    'Influência ${event.presentInfluence}/10',
                                tone: AppStatusTone.warning,
                                icon: Icons.insights_outlined,
                              ),
                            if (sensitive)
                              const StatusChip(
                                label: 'Conteúdo sensível',
                                tone: AppStatusTone.neutral,
                                icon: Icons.lock_outline,
                              ),
                          ],
                        ),
                        if (event.subtitleLine != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            event.subtitleLine!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (event.description != null &&
                            event.description!.trim().isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            event.description!.trim(),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              height: 1.45,
                            ),
                          ),
                        ],
                        if (event.emotionalNeedKeys.isNotEmpty ||
                            event.copingKeys.isNotEmpty) ...[
                          const SizedBox(height: AppSpacing.sm),
                          Text(
                            _compactClinicalSummary(event),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _compactClinicalSummary(PatientTimelineEvent event) {
    final parts = <String>[];
    if (event.emotionalNeedKeys.isNotEmpty ||
        _hasText(event.emotionalNeedOther)) {
      parts.add(
        'Necessidade: ${_labelsFor(
          event.emotionalNeedKeys,
          _emotionalNeedLabels,
          otherText: event.emotionalNeedOther,
        ).join(', ')}',
      );
    }
    if (event.copingKeys.isNotEmpty || _hasText(event.copingOther)) {
      parts.add(
        'Lidou: ${_labelsFor(
          event.copingKeys,
          _copingLabels,
          otherText: event.copingOther,
        ).join(', ')}',
      );
    }
    return parts.join(' · ');
  }
}

/// Nodo em anel com ponto central e halo suave — mesma linguagem do mapa
/// mental aplicada à linha do tempo.
class _TimelineNode extends StatelessWidget {
  const _TimelineNode({required this.accent});

  final Color accent;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
            ),
          ),
          Container(
            width: 15,
            height: 15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: accent, width: 1.4),
            ),
          ),
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
          ),
        ],
      ),
    );
  }
}

class TimelineEventDetailBody extends StatelessWidget {
  const TimelineEventDetailBody({super.key, required this.event});

  final PatientTimelineEvent event;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        if (event.isSensitive)
          const Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.md),
            child: AppInfoCard(
              icon: Icons.lock_outline,
              title: 'Evento marcado como sensível',
              body:
                  'Este conteúdo deve ser acessado com atenção ao contexto clínico.',
              tone: AppInfoCardTone.error,
            ),
          ),
        _EventHero(event: event),
        const SizedBox(height: AppSpacing.md),
        _ClinicalDetailSection(
          title: 'O que aconteceu',
          icon: Icons.chat_bubble_outline,
          accent: AppColors.cyan,
          children: [
            if (event.description != null &&
                event.description!.trim().isNotEmpty)
              _NarrativeText(event.description!.trim()),
            if (event.category != null && event.category!.trim().isNotEmpty)
              _TextBlock(
                label: 'Observações',
                value: event.category!.trim(),
              ),
            if (event.periodLabel != null &&
                event.periodLabel!.trim().isNotEmpty)
              _TextBlock(
                label: 'Etapa da vida',
                value: event.periodLabel!.trim(),
              ),
          ],
        ),
        if (event.emotionalNeedKeys.isNotEmpty ||
            _hasText(event.emotionalNeedOther) ||
            _hasText(event.emotionsFelt) ||
            event.emotionalImpact != null) ...[
          const SizedBox(height: AppSpacing.md),
          _ClinicalDetailSection(
            title: 'Impacto emocional',
            icon: Icons.favorite_outline,
            accent: AppColors.error,
            children: [
              if (event.emotionalImpact != null)
                _Gauge(
                  label: 'Intensidade sentida',
                  value: event.emotionalImpact!,
                  accent: AppColors.error,
                ),
              if (event.emotionalNeedKeys.isNotEmpty ||
                  _hasText(event.emotionalNeedOther))
                _ChipsBlock(
                  label: 'Necessidade em jogo',
                  items: _labelsFor(
                    event.emotionalNeedKeys,
                    _emotionalNeedLabels,
                    otherText: event.emotionalNeedOther,
                  ),
                  accent: AppColors.error,
                ),
              if (_hasText(event.emotionsFelt))
                _TextBlock(
                  label: 'Emoções',
                  value: event.emotionsFelt!.trim(),
                ),
            ],
          ),
        ],
        if (_hasText(event.selfMeaning) ||
            _hasText(event.othersMeaning) ||
            _hasText(event.worldMeaning)) ...[
          const SizedBox(height: AppSpacing.md),
          _ClinicalDetailSection(
            title: 'Significado que ficou',
            icon: Icons.psychology_outlined,
            accent: AppColors.purple,
            children: [
              if (_hasText(event.selfMeaning))
                _MeaningBlock(
                  icon: Icons.person_outline,
                  label: 'Sobre si',
                  value: event.selfMeaning!.trim(),
                ),
              if (_hasText(event.othersMeaning))
                _MeaningBlock(
                  icon: Icons.groups_outlined,
                  label: 'Sobre os outros',
                  value: event.othersMeaning!.trim(),
                ),
              if (_hasText(event.worldMeaning))
                _MeaningBlock(
                  icon: Icons.public_outlined,
                  label: 'Sobre o mundo',
                  value: event.worldMeaning!.trim(),
                ),
            ],
          ),
        ],
        if (event.copingKeys.isNotEmpty || _hasText(event.copingOther)) ...[
          const SizedBox(height: AppSpacing.md),
          _ClinicalDetailSection(
            title: 'Como lidou com isso',
            icon: Icons.shield_outlined,
            accent: AppColors.turquoise,
            children: [
              _ChipsBlock(
                items: _labelsFor(
                  event.copingKeys,
                  _copingLabels,
                  otherText: event.copingOther,
                ),
                accent: AppColors.turquoise,
              ),
            ],
          ),
        ],
        if (event.presentInfluence != null ||
            event.presentAreaKeys.isNotEmpty ||
            _hasText(event.presentReaction)) ...[
          const SizedBox(height: AppSpacing.md),
          _ClinicalDetailSection(
            title: 'Ponte com o presente',
            icon: Icons.insights_outlined,
            accent: AppColors.warning,
            children: [
              if (event.presentInfluence != null)
                _Gauge(
                  label: 'Influência hoje',
                  value: event.presentInfluence!,
                  accent: AppColors.warning,
                ),
              if (event.presentAreaKeys.isNotEmpty)
                _ChipsBlock(
                  label: 'Áreas afetadas',
                  items: _labelsFor(
                    event.presentAreaKeys,
                    _presentAreaLabels,
                  ),
                  accent: AppColors.warning,
                ),
              if (_hasText(event.presentReaction))
                _TextBlock(
                  label: 'Como reage hoje',
                  value: event.presentReaction!.trim(),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Cabeçalho do evento: cartão com gradiente, título, data e marcadores.
class _EventHero extends StatelessWidget {
  const _EventHero({required this.event});

  final PatientTimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Sem data, o próprio dateLabel já mostra o período — não repetir no selo.
    final period = event.eventDate == null ? null : event.periodLabel?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.cyan, AppColors.navy],
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  event.isSensitive
                      ? Icons.lock_outline
                      : Icons.event_note_outlined,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.schedule,
                            size: 13, color: Color(0xFFCFE6F2)),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            event.dateLabel,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: const Color(0xFFCFE6F2)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if ((period != null && period.isNotEmpty) || event.isSensitive) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (period != null && period.isNotEmpty)
                  _HeroBadge(icon: Icons.auto_stories_outlined, label: period),
                if (event.isSensitive)
                  const _HeroBadge(icon: Icons.lock_outline, label: 'Sensível'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _HeroBadge extends StatelessWidget {
  const _HeroBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }
}

/// Medidor 0–10 (intensidade emocional, influência atual).
class _Gauge extends StatelessWidget {
  const _Gauge({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final int value;
  final Color accent;

  static const max = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$value/$max',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: accent,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / max).clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: accent.withValues(alpha: 0.14),
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

/// Lista de rótulos como chips (necessidades, enfrentamento, áreas).
class _ChipsBlock extends StatelessWidget {
  const _ChipsBlock({required this.items, required this.accent, this.label});

  final List<String> items;
  final Color accent;
  final String? label;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (label != null) ...[
            Text(
              label!.toUpperCase(),
              style: theme.textTheme.labelSmall?.copyWith(
                fontSize: 9,
                letterSpacing: 0.4,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 6),
          ],
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final item in items)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    item,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Texto narrativo em destaque (o relato do acontecimento).
class _NarrativeText extends StatelessWidget {
  const _NarrativeText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        text,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.textPrimary,
              height: 1.55,
            ),
      ),
    );
  }
}

/// Rótulo pequeno + texto.
class _TextBlock extends StatelessWidget {
  const _TextBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 9,
              letterSpacing: 0.4,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textPrimary, height: 1.5),
          ),
        ],
      ),
    );
  }
}

/// Bloco de significado com ícone (sobre si / os outros / o mundo).
class _MeaningBlock extends StatelessWidget {
  const _MeaningBlock({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.purple),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.purple,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ClinicalDetailSection extends StatelessWidget {
  const _ClinicalDetailSection({
    required this.title,
    required this.children,
    this.icon,
    this.accent,
  });

  final String title;
  final List<Widget> children;
  final IconData? icon;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final visible = children.where((child) => child is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final tone = accent ?? AppColors.cyan;

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 17, color: tone),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;

List<String> _labelsFor(
  List<String> keys,
  Map<String, String> labels, {
  String? otherText,
}) {
  final values = keys.map((key) {
    if (key == 'other' && _hasText(otherText)) return otherText!.trim();
    return labels[key] ?? key;
  }).toList();
  if (keys.contains('other') && !_hasText(otherText)) {
    values.add('Outro');
  }
  return values;
}

// Rótulos derivados dos enums canônicos do fluxo Conhecer — as chaves antigas
// daqui não batiam com as gravadas no banco, e apareciam cruas na tela.
final _emotionalNeedLabels = {
  for (final need in EmotionalNeed.values) need.key: need.label,
};

const _copingLabels = {
  'avoidance': 'Me afastei / evitei sentir',
  'surrender_adaptation': 'Aceitei e busquei me adaptar',
  'overcompensation_reaction': 'Explodi / reagi',
  'emotional_shutdown': 'Desliguei emocionalmente',
  'help_protection': 'Procurei ajuda / proteção',
  'perfectionism': 'Tentei "ser perfeito"',
  'other': 'Outro',
};

final _presentAreaLabels = {
  for (final area in PresentArea.values) area.key: area.label,
};

