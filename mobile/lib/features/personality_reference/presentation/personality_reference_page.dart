import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/personality_reference_content.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class StaffPersonalityReferencePage extends StatefulWidget {
  const StaffPersonalityReferencePage({
    super.key,
    required this.role,
    required this.patientId,
    this.focusFactor,
    this.focusFacet,
  });

  final ProfileRole role;
  final String patientId;

  /// Fator e faceta (índices na ordem do guia) a destacar ao abrir. Vêm da
  /// tela de facetas do Mapa Mental.
  final int? focusFactor;
  final int? focusFacet;

  @override
  State<StaffPersonalityReferencePage> createState() =>
      _StaffPersonalityReferencePageState();
}

class _StaffPersonalityReferencePageState
    extends State<StaffPersonalityReferencePage> {
  final _focusKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.focusFactor == null || widget.focusFacet == null) return;
    // A lista entra com animação escalonada; espera ela assentar antes de rolar.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Dois passes: o segundo corrige o deslocamento deixado pela animação.
      for (final wait in const [600, 900]) {
        await Future<void>.delayed(Duration(milliseconds: wait));
        final target = _focusKey.currentContext;
        if (!mounted || target == null || !target.mounted) return;
        await Scrollable.ensureVisible(
          target,
          alignment: 0.02,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

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
              for (var i = 0; i < personalityReferenceFactors.length; i++) ...[
                _FactorCard(
                  factor: personalityReferenceFactors[i],
                  focusFacet: widget.focusFactor == i ? widget.focusFacet : null,
                  focusKey: _focusKey,
                ),
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
  const _FactorCard({
    required this.factor,
    this.focusFacet,
    this.focusKey,
  });

  final PersonalityReferenceFactor factor;

  /// Índice da faceta destacada neste fator (nulo se nenhuma).
  final int? focusFacet;
  final GlobalKey? focusKey;

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
                    for (var i = 0; i < factor.facets.length; i++) ...[
                      _FacetTile(
                        key: focusFacet == i ? focusKey : null,
                        facet: factor.facets[i],
                        highlighted: focusFacet == i,
                      ),
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
  const _FacetTile({super.key, required this.facet, this.highlighted = false});

  final PersonalityReferenceFacet facet;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: highlighted ? AppColors.purple : colors.outlineVariant,
          width: highlighted ? 2 : 1,
        ),
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
