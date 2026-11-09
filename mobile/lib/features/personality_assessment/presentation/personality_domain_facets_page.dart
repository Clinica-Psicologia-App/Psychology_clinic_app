import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../patients/presentation/widgets/patient_context_header.dart';
import '../../personality_reference/presentation/personality_reference_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/personality_assessment.dart';
import '../domain/personality_domain_highlights.dart';
import '../domain/personality_instrument.dart';
import '../providers/personality_assessment_providers.dart';
import 'personality_dashboard_page.dart';
import 'personality_domain_colors.dart';

/// Facetas que se destacaram em um domínio (altas e baixas), aberta a partir
/// do Mapa Mental. As de nível médio ficam atrás de "Ver todas as facetas".
/// Cada faceta leva ao cartão dela no guia clínico (só staff).
class PersonalityDomainFacetsPage extends ConsumerWidget {
  const PersonalityDomainFacetsPage({
    super.key,
    required this.role,
    required this.patientId,
    required this.assessmentId,
    required this.domainCode,
  });

  final ProfileRole role;
  final String patientId;
  final String assessmentId;
  final String domainCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(personalityAssessmentByIdProvider(assessmentId));
    return AppCanopyScaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PatientContextHeader(
              patientId: patientId,
              pageTitle: 'FACETAS DO DOMÍNIO',
              role: role,
              accentColor: AppColors.blue,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: AsyncStateBody<PersonalityAssessment?>(
              asyncValue: async,
              onRetry: () =>
                  ref.invalidate(personalityAssessmentByIdProvider(assessmentId)),
              emptyMessage: 'Avaliação não encontrada.',
              dataBuilder: (a) {
                if (a == null) {
                  return const Center(child: Text('Avaliação não encontrada.'));
                }
                final domainIndex = a.instrumentDef.domains
                    .indexWhere((d) => d.code == domainCode);
                if (domainIndex < 0) {
                  return const Center(child: Text('Domínio não encontrado.'));
                }
                return PersonalityDomainFacetsBody(
                  role: role,
                  patientId: patientId,
                  domainIndex: domainIndex,
                  domain: a.instrumentDef.domains[domainIndex],
                  result: a.results.forDomain(domainCode),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class PersonalityDomainFacetsBody extends StatefulWidget {
  const PersonalityDomainFacetsBody({
    required this.role,
    required this.patientId,
    required this.domainIndex,
    required this.domain,
    required this.result,
  });

  final ProfileRole role;
  final String patientId;
  final int domainIndex;
  final PersonalityDomain domain;
  final DomainResult result;

  @override
  State<PersonalityDomainFacetsBody> createState() => PersonalityDomainFacetsBodyState();
}

class PersonalityDomainFacetsBodyState extends State<PersonalityDomainFacetsBody> {
  bool _showAll = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = personalityDomainColor(widget.domain.code);
    final overall = widget.result.overall;
    final highlights =
        PersonalityDomainHighlights.from(widget.domain, widget.result);

    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                widget.domain.label,
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
            ),
            Text(
              overall.level?.label ?? 'Sem registro',
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                color: overall.level == null ? AppColors.textMuted : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        LevelFaixa(level: overall.level, color: color),
        const SizedBox(height: 18),
        if (!highlights.hasHighlights)
          Text(
            'Nenhuma faceta ficou alta ou baixa neste domínio.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: AppColors.textSecondary),
          )
        else ...[
          if (highlights.highs.isNotEmpty)
            _Group(
              title: 'Altas',
              items: highlights.highs,
              color: color,
              onGuide: _openGuide,
            ),
          if (highlights.lows.isNotEmpty)
            _Group(
              title: 'Baixas',
              items: highlights.lows,
              color: color,
              onGuide: _openGuide,
            ),
        ],
        if (highlights.others.isNotEmpty) ...[
          const SizedBox(height: 4),
          OutlinedButton(
            onPressed: () => setState(() => _showAll = !_showAll),
            child: Text(_showAll
                ? 'Ocultar as demais facetas'
                : 'Ver todas as ${highlights.total} facetas'),
          ),
          if (_showAll)
            _Group(
              title: 'Demais facetas',
              items: highlights.others,
              color: color,
              onGuide: _openGuide,
            ),
        ],
      ],
    );
  }

  void _openGuide(PersonalityFacetResult item) {
    context.push(
      PersonalityReferenceRoutes.staffFacet(
        role: widget.role,
        patientId: widget.patientId,
        factorIndex: widget.domainIndex,
        facetIndex: item.indexInDomain,
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group({
    required this.title,
    required this.items,
    required this.color,
    required this.onGuide,
  });

  final String title;
  final List<PersonalityFacetResult> items;
  final Color color;
  final void Function(PersonalityFacetResult item) onGuide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          for (final item in items)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.fromLTRB(14, 10, 8, 6),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(
                  color: theme.colorScheme.outline.withValues(alpha: 0.5),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.facet.label,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Text(
                          item.entry.level?.label ?? '—',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: item.entry.level == null
                                ? AppColors.textMuted
                                : color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: LevelFaixa(level: item.entry.level, color: color),
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => onGuide(item),
                      icon: const Icon(Icons.menu_book_outlined, size: 16),
                      label: const Text('Ver no guia clínico'),
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
