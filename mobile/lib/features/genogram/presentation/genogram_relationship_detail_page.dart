import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/genogram_relationship_type.dart';
import '../providers/genogram_providers.dart';
import 'genogram_routes.dart';
import '../../../shared/widgets/brand_loading.dart';

class GenogramRelationshipDetailPage extends ConsumerStatefulWidget {
  const GenogramRelationshipDetailPage({
    super.key,
    required this.role,
    required this.relationshipId,
    this.patientId,
  });

  final ProfileRole role;
  final String relationshipId;
  final String? patientId;

  @override
  ConsumerState<GenogramRelationshipDetailPage> createState() =>
      _GenogramRelationshipDetailPageState();
}

class _GenogramRelationshipDetailPageState
    extends ConsumerState<GenogramRelationshipDetailPage> {
  bool _navigating = false;

  Future<void> _openEdit() async {
    if (_navigating || !mounted) return;
    setState(() => _navigating = true);
    try {
      final updated = await context.push<bool>(
        widget.role == ProfileRole.patient
            ? GenogramRoutes.patientRelationshipEdit(widget.relationshipId)
            : GenogramRoutes.relationshipEditFor(
                widget.patientId!,
                widget.relationshipId,
              ),
      );
      if (!mounted) return;
      if (updated == true) {
        ref.invalidate(
          genogramRelationshipDetailProvider(widget.relationshipId),
        );
        if (widget.role == ProfileRole.patient) {
          ref.read(myGenogramProvider.notifier).refresh();
        } else {
          ref.invalidate(
            staffGenogramProvider(
              StaffGenogramContext(
                role: widget.role,
                patientId: widget.patientId!,
              ),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final relAsync =
        ref.watch(genogramRelationshipDetailProvider(widget.relationshipId));

    final genogramAsync = widget.role == ProfileRole.patient
        ? ref.watch(myGenogramProvider)
        : ref.watch(
            staffGenogramProvider(
              StaffGenogramContext(
                role: widget.role,
                patientId: widget.patientId!,
              ),
            ),
          );

    return AppCanopyScaffold(
      body: relAsync.when(
        loading: () => const BrandLoader(),
        error: (_, __) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(
              genogramRelationshipDetailProvider(widget.relationshipId),
            ),
            child: const Text('Tentar novamente'),
          ),
        ),
        data: (relationship) {
          if (relationship == null) {
            return const Column(
              children: [
                _RelationshipHeroHeader(
                  typeName: 'Relação',
                  typeIcon: Icons.account_tree_outlined,
                  onEdit: null,
                ),
                Expanded(
                  child: Center(child: Text('Relação não encontrada.')),
                ),
              ],
            );
          }

          return genogramAsync.when(
            loading: () => const BrandLoader(),
            error: (_, __) =>
                const Center(child: Text('Erro ao carregar nomes.')),
            data: (data) {
              final aName = data.personNameById(relationship.personAId);
              final bName = data.personNameById(relationship.personBId);

              return MotionReveal(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: _RelationshipHeroHeader(
                        typeName: relationship.relationshipType.label,
                        typeIcon: Icons.account_tree_outlined,
                        isSensitive: relationship.isSensitive,
                        personA: aName,
                        personB: bName,
                        onEdit: _navigating ? null : _openEdit,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.xxxl,
                      ),
                      sliver: SliverList(
                        delegate: SliverChildListDelegate([
                          if (relationship.isSensitive)
                            const Padding(
                              padding: EdgeInsets.only(bottom: AppSpacing.md),
                              child: AppInfoCard(
                                title: 'Conteúdo sensível',
                                body:
                                    'As informações foram ocultadas na visualização principal.',
                                icon: Icons.lock_outline,
                                tone: AppInfoCardTone.error,
                              ),
                            ),
                          AppInfoCard(
                            title: 'Pessoas envolvidas',
                            icon: Icons.group_outlined,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _InfoLine(label: 'Pessoa A', value: aName),
                                _InfoLine(label: 'Pessoa B', value: bName),
                              ],
                            ),
                          ),
                          if (relationship.notes != null &&
                              relationship.notes!.trim().isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.xl),
                            AppInfoCard(
                              title: 'Observações',
                              body: relationship.notes!.trim(),
                              icon: Icons.notes_outlined,
                            ),
                          ],
                          const SizedBox(height: AppSpacing.xl),
                          FilledButton.icon(
                            onPressed: _navigating ? null : _openEdit,
                            icon: const Icon(Icons.edit_outlined),
                            label: const Text('Editar relação'),
                          ),
                        ]),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Hero header ────────────────────────────────────────────────────────────────

class _RelationshipHeroHeader extends StatelessWidget {
  const _RelationshipHeroHeader({
    required this.typeName,
    required this.typeIcon,
    this.isSensitive = false,
    this.personA,
    this.personB,
    this.onEdit,
  });

  final String typeName;
  final IconData typeIcon;
  final bool isSensitive;
  final String? personA;
  final String? personB;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF063530), Color(0xFF1D9E75)],
        ),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
      ),
      child: Padding(
        padding: EdgeInsets.only(top: top),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top bar
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.sm,
                vertical: AppSpacing.xs,
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white70, size: 20),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Genograma',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Colors.white70,
                          letterSpacing: 0.5,
                        ),
                  ),
                  const Spacer(),
                  if (onEdit != null)
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit_outlined,
                          size: 16, color: Colors.white70),
                      label: const Text('Editar',
                          style: TextStyle(color: Colors.white70)),
                    ),
                ],
              ),
            ),
            // Icon + title
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
              child: Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isSensitive ? Icons.lock_outline : typeIcon,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          typeName,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        Text(
                          'Relação do genograma',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            // Person chips
            if (personA != null || personB != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, AppSpacing.sm, AppSpacing.lg, 0),
                child: Wrap(
                  spacing: AppSpacing.xs,
                  children: [
                    if (personA != null) _PersonChip(name: personA!),
                    if (personB != null) _PersonChip(name: personB!),
                    if (isSensitive)
                      const _PersonChip(
                          name: 'Sensível', icon: Icons.lock_outline),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.lg),
          ],
        ),
      ),
    );
  }
}

class _PersonChip extends StatelessWidget {
  const _PersonChip({required this.name, this.icon});
  final String name;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Text(
            name,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info line ─────────────────────────────────────────────────────────────────

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 92,
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
