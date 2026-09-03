import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/personality_assessment.dart';
import '../domain/personality_instrument.dart';
import '../providers/personality_assessment_providers.dart';
import 'personality_assessment_routes.dart';

/// Dashboard de uma avaliação: visão geral (5 domínios) e facetas por domínio.
class PersonalityDashboardPage extends ConsumerWidget {
  const PersonalityDashboardPage({
    super.key,
    required this.role,
    required this.patientId,
    required this.assessmentId,
  });

  final ProfileRole role;
  final String patientId;
  final String assessmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(personalityAssessmentByIdProvider(assessmentId));
    return AppScaffold(
      title: 'Perfil de personalidade',
      accent: AppColors.purple,
      actions: [
        IconButton(
          tooltip: 'Editar',
          onPressed: () async {
            await context.push(
              PersonalityAssessmentRoutes.staffEdit(
                role: role,
                patientId: patientId,
                assessmentId: assessmentId,
              ),
            );
            ref.invalidate(personalityAssessmentByIdProvider(assessmentId));
          },
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      body: AsyncStateBody<PersonalityAssessment?>(
        asyncValue: async,
        onRetry: () =>
            ref.invalidate(personalityAssessmentByIdProvider(assessmentId)),
        emptyMessage: 'Avaliação não encontrada.',
        dataBuilder: (a) {
          if (a == null) {
            return const Center(child: Text('Avaliação não encontrada.'));
          }
          return _Body(assessment: a);
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({required this.assessment});

  final PersonalityAssessment assessment;

  @override
  Widget build(BuildContext context) {
    final def = assessment.instrumentDef;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      children: [
        _header(context),
        const SizedBox(height: 12),
        for (final d in def.domains)
          _DomainCard(
            domain: d,
            result: assessment.results.forDomain(d.code),
          ),
      ],
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    String dateLabel() {
      final d = assessment.appliedOn;
      if (d == null) return 'Data não informada';
      String two(int x) => x.toString().padLeft(2, '0');
      return '${two(d.day)}/${two(d.month)}/${d.year}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.purple, Color(0xFF5B3A8E)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AVALIAÇÃO · PERSONALIDADE',
              style: theme.textTheme.labelSmall?.copyWith(
                color: const Color(0xFFE0D4F5),
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
                fontSize: 9,
              )),
          const SizedBox(height: 3),
          Text(assessment.instrumentDef.name,
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              )),
          const SizedBox(height: 6),
          Text('Aplicado em ${dateLabel()}',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: const Color(0xFFE0D4F5))),
          if (assessment.protocolValidity != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                assessment.protocolValidity!.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Faixa de 5 níveis (Muito baixo → Muito alto), marcando a classificação.
class LevelFaixa extends StatelessWidget {
  const LevelFaixa({super.key, required this.level});

  final PersonalityLevel? level;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < PersonalityLevel.values.length; i++)
          Expanded(
            child: Container(
              height: 8,
              margin: EdgeInsets.only(
                  right: i == PersonalityLevel.values.length - 1 ? 0 : 3),
              decoration: BoxDecoration(
                color: (level != null && i == level!.position)
                    ? AppColors.purple
                    : AppColors.purple.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
      ],
    );
  }
}

class _DomainCard extends StatefulWidget {
  const _DomainCard({required this.domain, required this.result});

  final PersonalityDomain domain;
  final DomainResult result;

  @override
  State<_DomainCard> createState() => _DomainCardState();
}

class _DomainCardState extends State<_DomainCard> {
  bool _open = false;

  String _scoreText(num? s) => s == null ? '' : '  ·  $s';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final overall = widget.result.overall;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          widget.domain.label,
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w800),
                        ),
                      ),
                      Text(
                        (overall.level?.label ?? 'Sem registro') +
                            _scoreText(overall.score),
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: overall.level == null
                              ? AppColors.textMuted
                              : AppColors.purple,
                        ),
                      ),
                      Icon(_open ? Icons.expand_less : Icons.expand_more,
                          color: AppColors.textMuted),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LevelFaixa(level: overall.level),
                ],
              ),
            ),
          ),
          if (_open) ...[
            Divider(
                height: 1,
                color: theme.colorScheme.outline.withValues(alpha: 0.4)),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: Column(
                children: [
                  for (final f in widget.domain.facets)
                    _facetRow(theme, f, widget.result.facet(f.code)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _facetRow(ThemeData theme, PersonalityFacet f, ScoreEntry e) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(f.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600)),
              ),
              Text(
                (e.level?.label ?? '—') + _scoreText(e.score),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color:
                      e.level == null ? AppColors.textMuted : AppColors.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LevelFaixa(level: e.level),
        ],
      ),
    );
  }
}
