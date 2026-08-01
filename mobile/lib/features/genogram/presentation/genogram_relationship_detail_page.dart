import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/genogram_relationship_type.dart';
import '../providers/genogram_providers.dart';
import 'genogram_routes.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

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
              final theme = Theme.of(context);
              final aName = data.personNameById(relationship.personAId);
              final bName = data.personNameById(relationship.personBId);

              return MotionReveal(
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.all(16),
                        children: [
                          if (relationship.isSensitive)
                            ClayCard(
                              color: theme.colorScheme.errorContainer
                                  .withValues(alpha: 0.35),
                              child: const ListTile(
                                leading: Icon(Icons.lock_outline),
                                title: Text('Conteúdo sensível'),
                              ),
                            ),
                          ClayCard(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    relationship.relationshipType.label,
                                    style: theme.textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Pessoa A: $aName'),
                                  const SizedBox(height: 4),
                                  Text('Pessoa B: $bName'),
                                  if (relationship.notes != null &&
                                      relationship.notes!
                                          .trim()
                                          .isNotEmpty) ...[
                                    const SizedBox(height: 16),
                                    Text(
                                      'Observações',
                                      style: theme.textTheme.labelLarge,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(relationship.notes!.trim()),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(16),
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
