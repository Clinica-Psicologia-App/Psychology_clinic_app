import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../shared/widgets/app_page_header.dart';
import '../../../../shared/widgets/status_chip.dart';
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
                                      color: AppColors.navy,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            const Icon(
                              Icons.arrow_forward_rounded,
                              size: 20,
                              color: AppColors.textMuted,
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
                              color: AppColors.textSecondary,
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
                              color: AppColors.textSecondary,
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
        AppPageHeader(
          icon: event.isSensitive
              ? Icons.lock_outline
              : Icons.event_note_outlined,
          title: event.title,
          subtitle: event.dateLabel,
          metadata: [
            if (event.periodLabel != null &&
                event.periodLabel!.trim().isNotEmpty)
              StatusChip(
                label: event.periodLabel!.trim(),
                tone: AppStatusTone.info,
                icon: Icons.auto_stories_outlined,
              ),
            if (event.presentInfluence != null)
              StatusChip(
                label: 'Influência atual ${event.presentInfluence}/10',
                tone: AppStatusTone.warning,
                icon: Icons.insights_outlined,
              ),
            if (event.isSensitive)
              const StatusChip(
                label: 'Sensível',
                tone: AppStatusTone.error,
                icon: Icons.lock_outline,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _ClinicalDetailSection(
          title: 'O que aconteceu',
          children: [
            if (event.category != null && event.category!.trim().isNotEmpty)
              _DetailRow(
                label: 'Observações',
                value: event.category!.trim(),
              ),
            if (event.periodLabel != null &&
                event.periodLabel!.trim().isNotEmpty)
              _DetailRow(
                label: 'Etapa da vida',
                value: event.periodLabel!.trim(),
              ),
            if (event.description != null &&
                event.description!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(event.description!.trim()),
            ],
          ],
        ),
        if (event.emotionalNeedKeys.isNotEmpty ||
            _hasText(event.emotionalNeedOther) ||
            _hasText(event.emotionsFelt) ||
            event.emotionalImpact != null) ...[
          const SizedBox(height: AppSpacing.md),
          _ClinicalDetailSection(
            title: 'Impacto emocional',
            children: [
              if (event.emotionalImpact != null)
                _DetailRow(
                  label: 'Impacto',
                  value: '${event.emotionalImpact}/10',
                ),
              if (event.emotionalNeedKeys.isNotEmpty ||
                  _hasText(event.emotionalNeedOther))
                _DetailRow(
                  label: 'Necessidade',
                  value: _labelsFor(
                    event.emotionalNeedKeys,
                    _emotionalNeedLabels,
                    otherText: event.emotionalNeedOther,
                  ).join(', '),
                ),
              if (_hasText(event.emotionsFelt))
                _DetailRow(
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
            title: 'Significado',
            children: [
              if (_hasText(event.selfMeaning))
                _DetailRow(
                  label: 'Sobre si',
                  value: event.selfMeaning!.trim(),
                ),
              if (_hasText(event.othersMeaning))
                _DetailRow(
                  label: 'Sobre os outros',
                  value: event.othersMeaning!.trim(),
                ),
              if (_hasText(event.worldMeaning))
                _DetailRow(
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
            children: [
              Text(
                _labelsFor(
                  event.copingKeys,
                  _copingLabels,
                  otherText: event.copingOther,
                ).join(', '),
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
            children: [
              if (event.presentInfluence != null)
                _DetailRow(
                  label: 'Influência',
                  value: '${event.presentInfluence}/10',
                ),
              if (event.presentAreaKeys.isNotEmpty)
                _DetailRow(
                  label: 'Áreas',
                  value: _labelsFor(
                    event.presentAreaKeys,
                    _presentAreaLabels,
                  ).join(', '),
                ),
              if (_hasText(event.presentReaction)) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(event.presentReaction!.trim()),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

class _ClinicalDetailSection extends StatelessWidget {
  const _ClinicalDetailSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final visible = children.where((child) => child is! SizedBox).toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            ...children,
          ],
        ),
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

const _emotionalNeedLabels = {
  'connection_acceptance': 'Conexão e Aceitação',
  'autonomy_competence_identity': 'Autonomia, competência e identidade',
  'limits_self_control': 'Limites e autocontrole',
  'expression_freedom': 'Liberdade de Expressão',
  'recognition_value': 'Valorização e reconhecimento',
  'spontaneity_leisure': 'Espontaneidade e Lazer',
  'other': 'Outra',
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

const _presentAreaLabels = {
  'relationships': 'Relações',
  'self_esteem': 'Autoestima',
  'work': 'Trabalho',
  'emotions': 'Emoções',
  'decisions': 'Decisões',
  'body': 'Corpo',
};

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
