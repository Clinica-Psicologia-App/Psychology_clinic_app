import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/personality_reference_content.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class StaffPersonalityReferencePage extends StatelessWidget {
  const StaffPersonalityReferencePage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Referência de personalidade',
      accent: AppColors.purple,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          MotionStaggered(
            children: [
              // Header com identidade do módulo: tint roxo + ícone em box
              // gradiente, no mesmo padrão dos demais módulos clínicos.
              ClayCard(
                color: AppColors.surfaceTintPurple,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.purple,
                              AppColors.purple.withValues(alpha: 0.78),
                            ],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.purple.withValues(alpha: 0.30),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.psychology_alt_outlined,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Matriz clínica de fatores e facetas',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleLarge
                                  ?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.navy,
                                  ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Psicoeducação genérica de apoio à leitura clínica da equipe — '
                              'não é o relatório nem a interpretação oficial de nenhum '
                              'instrumento. Não substitui a correção autorizada, cujos '
                              'resultados devem ser registrados em Avaliação → Personalidade.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              for (final factor in personalityReferenceFactors) ...[
                _FactorCard(factor: factor),
                const SizedBox(height: 16),
              ],
              ClayCard(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    personalityReferenceNote,
                    style: Theme.of(context).textTheme.bodyMedium,
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

class _FactorCard extends StatelessWidget {
  const _FactorCard({required this.factor});

  final PersonalityReferenceFactor factor;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Barra de acento — identifica o fator na varredura visual.
            Container(width: 5, color: AppColors.purple),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      factor.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      factor.description,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    for (final facet in factor.facets) ...[
                      _FacetTile(facet: facet),
                      const SizedBox(height: 12),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FacetTile extends StatelessWidget {
  const _FacetTile({required this.facet});

  final PersonalityReferenceFacet facet;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              facet.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              facet.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 12),
            _GuidanceBlock(
              title: 'Sugestão para baixo escore',
              body: facet.lowScoreGuidance,
              background: colors.secondaryContainer,
              foreground: colors.onSecondaryContainer,
            ),
            const SizedBox(height: 10),
            _GuidanceBlock(
              title: 'Sugestão para alto escore',
              body: facet.highScoreGuidance,
              background: colors.tertiaryContainer,
              foreground: colors.onTertiaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}

class _GuidanceBlock extends StatelessWidget {
  const _GuidanceBlock({
    required this.title,
    required this.body,
    required this.background,
    required this.foreground,
  });

  final String title;
  final String body;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              body,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: foreground,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
