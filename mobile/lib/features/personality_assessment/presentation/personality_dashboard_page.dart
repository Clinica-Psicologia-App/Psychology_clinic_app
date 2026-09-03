import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
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

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir avaliação?'),
        content: const Text(
            'Esta ação remove permanentemente o registro desta avaliação de '
            'personalidade (resultados, síntese e integração). Não pode ser '
            'desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ref
          .read(personalityAssessmentRepositoryProvider)
          .delete(assessmentId);
      ref.invalidate(personalityAssessmentsProvider(patientId));
      if (context.mounted) context.pop(true);
    } catch (e) {
      if (context.mounted) showErrorBanner(context, e);
    }
  }

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
        IconButton(
          tooltip: 'Excluir avaliação',
          onPressed: () => _confirmDelete(context, ref),
          icon: const Icon(Icons.delete_outline),
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
          return _Body(
            assessment: a,
            role: role,
            patientId: patientId,
            assessmentId: assessmentId,
          );
        },
      ),
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.assessment,
    required this.role,
    required this.patientId,
    required this.assessmentId,
  });

  final PersonalityAssessment assessment;
  final ProfileRole role;
  final String patientId;
  final String assessmentId;

  @override
  Widget build(BuildContext context) {
    final def = assessment.instrumentDef;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
      children: [
        _header(context),
        const SizedBox(height: 12),
        ProfilePanel(assessment: assessment),
        const SizedBox(height: 4),
        for (final d in def.domains)
          DomainCard(
            domain: d,
            result: assessment.results.forDomain(d.code),
          ),
        const SizedBox(height: 6),
        _synthesisSection(context),
        _integrationSection(context),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.purple,
            side: const BorderSide(color: AppColors.purple),
            minimumSize: const Size.fromHeight(44),
          ),
          onPressed: () => context.push(
            PersonalityAssessmentRoutes.staffSynthesis(
              role: role,
              patientId: patientId,
              assessmentId: assessmentId,
            ),
          ),
          icon: const Icon(Icons.edit_note_outlined),
          label: Text(
            assessment.hasSynthesis || assessment.hasIntegration
                ? 'Editar síntese e integração'
                : 'Adicionar síntese clínica',
          ),
        ),
        const SizedBox(height: 10),
        _ShareToggle(
          assessmentId: assessmentId,
          shared: assessment.sharedWithPatient,
        ),
      ],
    );
  }

  Widget _sectionCard(BuildContext context,
      {required IconData icon, required String title, required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }

  Widget _synthesisSection(BuildContext context) {
    final theme = Theme.of(context);
    final s = assessment.synthesis;
    Widget block(String label, String? value) {
      if ((value ?? '').trim().isEmpty) return const SizedBox.shrink();
      return Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 9,
                  letterSpacing: 0.3,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                )),
            const SizedBox(height: 2),
            Text(value!.trim(),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: AppColors.textPrimary, height: 1.45)),
          ],
        ),
      );
    }

    return _sectionCard(
      context,
      icon: Icons.psychology_outlined,
      title: 'Síntese clínica',
      child: assessment.hasSynthesis
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                block('O que o perfil ajuda a compreender', s.understanding),
                block('Aspectos clinicamente relevantes', s.relevant),
                block('Recursos identificados', s.resources),
                block('Vulnerabilidades identificadas', s.vulnerabilities),
                block('Hipóteses a explorar em sessão', s.hypotheses),
              ],
            )
          : Text('Ainda não preenchida.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              )),
    );
  }

  Widget _integrationSection(BuildContext context) {
    final theme = Theme.of(context);
    final i = assessment.integration;
    return _sectionCard(
      context,
      icon: Icons.hub_outlined,
      title: 'Integração à conceitualização',
      child: assessment.hasIntegration
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (i.status != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceTintBlue,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(i.status!.label,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.blue,
                        )),
                  ),
                if (i.links.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 5,
                    runSpacing: 5,
                    children: [
                      for (final l in i.links)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.purple.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(l.label,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.purple,
                              )),
                        ),
                    ],
                  ),
                ],
                if ((i.note ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(i.note!.trim(),
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textPrimary, height: 1.45)),
                ],
              ],
            )
          : Text('Ainda não avaliada.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textMuted,
                fontStyle: FontStyle.italic,
              )),
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

/// Toggle de compartilhamento do perfil com o paciente (opt-in do terapeuta).
class _ShareToggle extends ConsumerStatefulWidget {
  const _ShareToggle({required this.assessmentId, required this.shared});

  final String assessmentId;
  final bool shared;

  @override
  ConsumerState<_ShareToggle> createState() => _ShareToggleState();
}

class _ShareToggleState extends ConsumerState<_ShareToggle> {
  bool _busy = false;

  Future<void> _toggle(bool value) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref
          .read(personalityAssessmentRepositoryProvider)
          .setShared(id: widget.assessmentId, shared: value);
      ref.invalidate(personalityAssessmentByIdProvider(widget.assessmentId));
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: SwitchListTile(
        value: widget.shared,
        onChanged: _busy ? null : _toggle,
        activeThumbColor: AppColors.purple,
        secondary: const Icon(Icons.visibility_outlined, color: AppColors.purple),
        title: const Text('Compartilhar perfil com o paciente'),
        subtitle: Text(
          widget.shared
              ? 'Visível ao paciente (só as faixas, sem números nem sua síntese).'
              : 'Não visível ao paciente. Ative para liberar o perfil.',
          style: theme.textTheme.labelSmall?.copyWith(color: AppColors.textMuted),
        ),
      ),
    );
  }
}

/// Painel consolidado do perfil: os 5 domínios numa escala compartilhada de
/// 5 faixas (Muito baixo → Muito alto), com um marcador por domínio. É apenas
/// uma representação dos dados informados — não uma nova interpretação.
class ProfilePanel extends StatelessWidget {
  const ProfilePanel({super.key, required this.assessment});

  final PersonalityAssessment assessment;

  static const _bands = ['Mto baixo', 'Baixo', 'Médio', 'Alto', 'Mto alto'];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final def = assessment.instrumentDef;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Perfil nos Cinco Grandes Fatores',
              style:
                  theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          // Cabeçalho das faixas alinhado à área do gráfico (rótulo = flex 4).
          Row(
            children: [
              const Expanded(flex: 4, child: SizedBox()),
              Expanded(
                flex: 8,
                child: Row(
                  children: [
                    for (final b in _bands)
                      Expanded(
                        child: Text(
                          b,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 7.5,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          for (final d in def.domains)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 4,
                    child: Text(
                      d.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 8,
                    child: _ProfileTrack(
                      level: assessment.results.forDomain(d.code).overall.level,
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

/// Trilha de 5 faixas com um marcador (ponto) na faixa da classificação.
class _ProfileTrack extends StatelessWidget {
  const _ProfileTrack({required this.level});

  final PersonalityLevel? level;

  @override
  Widget build(BuildContext context) {
    const n = 5;
    return SizedBox(
      height: 16,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Row(
            children: [
              for (var i = 0; i < n; i++)
                Expanded(
                  child: Container(
                    height: 6,
                    margin: EdgeInsets.only(right: i == n - 1 ? 0 : 2),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          if (level != null)
            Row(
              children: [
                for (var i = 0; i < n; i++)
                  Expanded(
                    child: Center(
                      child: i == level!.position
                          ? Container(
                              width: 14,
                              height: 14,
                              decoration: const BoxDecoration(
                                color: AppColors.purple,
                                shape: BoxShape.circle,
                              ),
                            )
                          : const SizedBox(height: 14),
                    ),
                  ),
              ],
            ),
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

class DomainCard extends StatefulWidget {
  const DomainCard({super.key, required this.domain, required this.result});

  final PersonalityDomain domain;
  final DomainResult result;

  @override
  State<DomainCard> createState() => DomainCardState();
}

class DomainCardState extends State<DomainCard> {
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
