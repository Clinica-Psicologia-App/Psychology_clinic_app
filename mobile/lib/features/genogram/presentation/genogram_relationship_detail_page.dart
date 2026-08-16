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

class GenogramRelationshipDetailPage extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
    final relAsync =
        ref.watch(genogramRelationshipDetailProvider(relationshipId));

    final genogramAsync = role == ProfileRole.patient
        ? ref.watch(myGenogramProvider)
        : ref.watch(
            staffGenogramProvider(
              StaffGenogramContext(
                role: role,
                patientId: patientId!,
              ),
            ),
          );

    return AppScaffold(
      title: 'Relação',
      accent: AppColors.blue,
      body: relAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: FilledButton(
            onPressed: () => ref.invalidate(
              genogramRelationshipDetailProvider(relationshipId),
            ),
            child: const Text('Tentar novamente'),
          ),
        ),
        data: (relationship) {
          if (relationship == null) {
            return const Center(child: Text('Relação não encontrada.'));
          }

          return genogramAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
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
                        onPressed: () async {
                          final updated = await context.push<bool>(
                            role == ProfileRole.patient
                                ? GenogramRoutes.patientRelationshipEdit(
                                    relationshipId,
                                  )
                                : GenogramRoutes.staffRelationshipEdit(
                                    role: role,
                                    patientId: patientId!,
                                    relationshipId: relationshipId,
                                  ),
                          );
                          if (updated == true) {
                            ref.invalidate(
                              genogramRelationshipDetailProvider(
                                relationshipId,
                              ),
                            );
                            if (role == ProfileRole.patient) {
                              ref.read(myGenogramProvider.notifier).refresh();
                            } else {
                              ref.invalidate(
                                staffGenogramProvider(
                                  StaffGenogramContext(
                                    role: role,
                                    patientId: patientId!,
                                  ),
                                ),
                              );
                            }
                          }
                        },
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
