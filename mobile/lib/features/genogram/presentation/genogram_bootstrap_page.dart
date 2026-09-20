import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import '../domain/genogram_bootstrap.dart';
import '../domain/genogram_layout.dart' show GEdge, GEdgeType;
import '../domain/genogram_relationship_input.dart';
import '../domain/genogram_relationship_type.dart';
import '../providers/genogram_providers.dart';

/// Tela do bootstrap: mostra os vínculos estruturais propostos a partir dos
/// papéis e deixa o terapeuta confirmar quais gravar. Escreve em
/// `genogram_relationships` via [GenogramRepository.createRelationship].
class GenogramBootstrapPage extends ConsumerStatefulWidget {
  const GenogramBootstrapPage({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<GenogramBootstrapPage> createState() =>
      _GenogramBootstrapPageState();
}

class _GenogramBootstrapPageState extends ConsumerState<GenogramBootstrapPage> {
  Set<int>? _accepted;
  // Escolha de lado dos avós: id → true (paterno) / false (materno).
  final Map<String, bool> _sides = {};
  bool _saving = false;

  static GenogramRelationshipType _mapType(GEdgeType t) => switch (t) {
        GEdgeType.spouse => GenogramRelationshipType.spouse,
        GEdgeType.exSpouse => GenogramRelationshipType.exSpouse,
        GEdgeType.separation => GenogramRelationshipType.separation,
        GEdgeType.parentChild => GenogramRelationshipType.parentChild,
      };

  static String _typeLabel(GEdgeType t) => switch (t) {
        GEdgeType.spouse => 'Casamento',
        GEdgeType.exSpouse => 'Ex-cônjuge (divórcio)',
        GEdgeType.separation => 'Separados',
        GEdgeType.parentChild => 'Pai/mãe → filho(a)',
      };

  static ({IconData icon, Color color}) _typeStyle(GEdgeType t) => switch (t) {
        GEdgeType.spouse => (
            icon: Icons.favorite_rounded,
            color: AppColors.error,
          ),
        GEdgeType.exSpouse => (
            icon: Icons.heart_broken_rounded,
            color: AppColors.textMuted,
          ),
        GEdgeType.separation => (
            icon: Icons.heart_broken_rounded,
            color: AppColors.warning,
          ),
        GEdgeType.parentChild => (
            icon: Icons.supervisor_account_rounded,
            color: AppColors.turquoise,
          ),
      };

  Future<void> _commit(GBootstrapData data) async {
    final accepted = _accepted ?? const {};
    final sideEdges = grandparentSideEdges(
      plan: data.sidePlan,
      paternalById: _sides,
    );
    final total = accepted.length + sideEdges.length;
    if (total == 0 || data.clinicId == null) return;
    setState(() => _saving = true);
    final repo = ref.read(genogramRepositoryProvider);

    Future<void> create(GEdge e) => repo.createRelationship(
          clinicId: data.clinicId!,
          patientId: data.patientId,
          input: GenogramRelationshipInput(
            personAId: e.a,
            personBId: e.b,
            relationshipType: _mapType(e.type),
          ),
        );

    try {
      for (final i in accepted) {
        await create(data.proposals[i].edge);
      }
      for (final e in sideEdges) {
        await create(e);
      }
      ref.invalidate(staffGenogramProvider);
      ref.invalidate(genogramBootstrapProvider(data.patientId));
      ref.invalidate(genogramDataForPatientProvider(data.patientId));
      ref.invalidate(genogramRelationshipsForPatientProvider(data.patientId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$total vínculo(s) criado(s).')),
      );
      context.pop();
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(genogramBootstrapProvider(widget.patientId));

    return AppScaffold(
      title: 'Sugerir vínculos',
      accent: AppColors.turquoise,
      body: AsyncStateBody<GBootstrapData>(
        asyncValue: async,
        onRetry: () =>
            ref.invalidate(genogramBootstrapProvider(widget.patientId)),
        dataBuilder: (data) {
          if (data.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.turquoise.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.account_tree_outlined,
                        size: 32,
                        color: AppColors.turquoise,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      'Nada a sugerir',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    const Text(
                      'Os vínculos estruturais já estão cadastrados, ou '
                      'não há papéis suficientes (mãe, pai, irmão, avós…) '
                      'para inferir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            );
          }
          final proposals = data.proposals;
          final accepted =
              _accepted ??= {for (var i = 0; i < proposals.length; i++) i};
          final gps = data.sidePlan.grandparents;
          final total = accepted.length +
              grandparentSideEdges(plan: data.sidePlan, paternalById: _sides)
                  .length;

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  children: [
                    // Cartão informativo
                    const _InfoBanner(
                      text:
                          'Vínculos inferidos a partir dos papéis cadastrados. '
                          'Revise e confirme — nada é gravado até você tocar em Confirmar.',
                    ),
                    if (proposals.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.lg),
                      _SectionHeader(
                        label: 'Vínculos propostos',
                        count: accepted.length,
                        total: proposals.length,
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      for (var i = 0; i < proposals.length; i++) ...[
                        if (i > 0) const SizedBox(height: AppSpacing.xs),
                        _ProposalCard(
                          reason: proposals[i].reason,
                          typeLabel: _typeLabel(proposals[i].edge.type),
                          style: _typeStyle(proposals[i].edge.type),
                          checked: accepted.contains(i),
                          enabled: !_saving,
                          onChanged: (v) => setState(() {
                            if (v == true) {
                              accepted.add(i);
                            } else {
                              accepted.remove(i);
                            }
                          }),
                        ),
                      ],
                    ],
                    if (data.sidePlan.isUsable && gps.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xl),
                      const _SectionHeader(label: 'Avós — de que lado?'),
                      const SizedBox(height: AppSpacing.xs),
                      for (final gp in gps) ...[
                        _GrandparentCard(
                          gp: gp,
                          selected: _sides[gp.id],
                          enabled: !_saving,
                          onChanged: (v) => setState(() {
                            if (v == null) {
                              _sides.remove(gp.id);
                            } else {
                              _sides[gp.id] = v;
                            }
                          }),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                      ],
                    ],
                    const SizedBox(height: AppSpacing.md),
                  ],
                ),
              ),
              _ConfirmBar(
                total: total,
                saving: _saving,
                onConfirm: total == 0 ? null : () => _commit(data),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _InfoBanner extends StatelessWidget {
  const _InfoBanner({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.turquoise.withValues(alpha: 0.08),
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: AppColors.turquoise.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.turquoise,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.75),
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.count, this.total});

  final String label;
  final int? count;
  final int? total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: AppColors.turquoise,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
            letterSpacing: 0.3,
          ),
        ),
        if (count != null && total != null) ...[
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              '$count de $total',
              style: theme.textTheme.labelSmall?.copyWith(
                color: AppColors.turquoise,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProposalCard extends StatelessWidget {
  const _ProposalCard({
    required this.reason,
    required this.typeLabel,
    required this.style,
    required this.checked,
    required this.enabled,
    required this.onChanged,
  });

  final String reason;
  final String typeLabel;
  final ({IconData icon, Color color}) style;
  final bool checked;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      decoration: BoxDecoration(
        color: checked
            ? style.color.withValues(alpha: 0.06)
            : theme.colorScheme.surfaceContainerLowest,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: checked
              ? style.color.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.35),
          width: checked ? 1.5 : 1,
        ),
      ),
      child: InkWell(
        onTap: enabled ? () => onChanged(!checked) : null,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              // Ícone do tipo de vínculo
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: style.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, size: 18, color: style.color),
              ),
              const SizedBox(width: AppSpacing.md),
              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reason,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      typeLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: style.color.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Checkbox customizado
              AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: checked ? style.color : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: checked
                        ? style.color
                        : theme.colorScheme.outline.withValues(alpha: 0.6),
                    width: checked ? 0 : 1.5,
                  ),
                ),
                child: checked
                    ? const Icon(Icons.check_rounded,
                        size: 14, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GrandparentCard extends StatelessWidget {
  const _GrandparentCard({
    required this.gp,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  final GGrandparentSideChoice gp;
  final bool? selected;
  final bool enabled;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLowest,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.elderly_rounded,
                  size: 17,
                  color: AppColors.purple,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  gp.name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (selected == null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    'Pendente',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _SidePill(
                label: 'Paterno',
                selected: selected == true,
                enabled: enabled,
                onTap: () => onChanged(selected == true ? null : true),
              ),
              const SizedBox(width: AppSpacing.xs),
              _SidePill(
                label: 'Materno',
                selected: selected == false,
                enabled: enabled,
                onTap: () => onChanged(selected == false ? null : false),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SidePill extends StatelessWidget {
  const _SidePill({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.purple
              : theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: selected
                ? AppColors.purple
                : theme.colorScheme.outline.withValues(alpha: 0.4),
          ),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ConfirmBar extends StatelessWidget {
  const _ConfirmBar({
    required this.total,
    required this.saving,
    required this.onConfirm,
  });

  final int total;
  final bool saving;
  final VoidCallback? onConfirm;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md,
          ),
          child: FilledButton.icon(
            onPressed: saving || onConfirm == null ? null : onConfirm,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.turquoise,
              minimumSize: const Size.fromHeight(52),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            icon: saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.check_rounded, size: 20),
            label: Text(
              saving ? 'Gravando…' : 'Confirmar ($total)',
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
