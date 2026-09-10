import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
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
            : GenogramRoutes.staffRelationshipEdit(
                role: widget.role,
                patientId: widget.patientId!,
                relationshipId: widget.relationshipId,
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

    return AppScaffold(
      title: 'Relação',
      accent: AppColors.blue,
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
            return const Center(child: Text('Relação não encontrada.'));
          }

          return genogramAsync.when(
            loading: () => const BrandLoader(),
            error: (_, __) =>
                const Center(child: Text('Erro ao carregar nomes.')),
            data: (data) {
              final aName = data.personNameById(relationship.personAId);
              final bName = data.personNameById(relationship.personBId);

              return MotionReveal(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.md,
                          AppSpacing.xxxl,
                        ),
                        children: [
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
                          AppPageHeader(
                            title: relationship.relationshipType.label,
                            subtitle: 'Natureza da relação registrada.',
                            icon: relationship.isSensitive
                                ? Icons.lock_outline
                                : Icons.account_tree_outlined,
                            metadata: [
                              Chip(label: Text(aName)),
                              Chip(label: Text(bName)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xl),
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
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: FilledButton.icon(
                        onPressed: _navigating ? null : _openEdit,
                        icon: const Icon(Icons.edit_outlined),
                        label: const Text('Editar relação'),
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
