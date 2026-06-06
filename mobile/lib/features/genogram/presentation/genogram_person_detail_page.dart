import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/genogram_data.dart';
import '../domain/genogram_gender.dart';
import '../domain/genogram_person.dart';
import '../providers/genogram_providers.dart';
import 'genogram_routes.dart';
import 'widgets/genogram_widgets.dart';

class GenogramPersonDetailPage extends ConsumerWidget {
  const GenogramPersonDetailPage({
    super.key,
    required this.role,
    required this.personId,
    this.patientId,
  });

  final ProfileRole role;
  final String personId;
  final String? patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(genogramPersonDetailProvider(personId));

    return AppScaffold(
      title: 'Pessoa',
      body: personAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: FilledButton(
            onPressed: () =>
                ref.invalidate(genogramPersonDetailProvider(personId)),
            child: const Text('Tentar novamente'),
          ),
        ),
        data: (person) {
          if (person == null) {
            return const Center(child: Text('Pessoa não encontrada.'));
          }

          return _PersonDetailBody(
            person: person,
            role: role,
            patientId: patientId,
            onChanged: () {
              ref.invalidate(genogramPersonDetailProvider(personId));
              _refreshLists(ref);
            },
          );
        },
      ),
    );
  }

  void _refreshLists(WidgetRef ref) {
    if (role == ProfileRole.patient) {
      ref.read(myGenogramProvider.notifier).refresh();
    } else if (patientId != null) {
      ref.invalidate(
        staffGenogramProvider(
          StaffGenogramContext(role: role, patientId: patientId!),
        ),
      );
    }
  }
}

class _PersonDetailBody extends ConsumerWidget {
  const _PersonDetailBody({
    required this.person,
    required this.role,
    required this.patientId,
    required this.onChanged,
  });

  final GenogramPerson person;
  final ProfileRole role;
  final String? patientId;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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

    return genogramAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Erro ao carregar relações.')),
      data: (data) => _buildContent(context, data),
    );
  }

  Widget _buildContent(BuildContext context, GenogramData data) {
    final theme = Theme.of(context);
    final linked = data.relationships
        .where((r) => r.involvesPerson(person.id))
        .toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (person.isSensitive)
                Card(
                  color: theme.colorScheme.errorContainer
                      .withValues(alpha: 0.35),
                  child: const ListTile(
                    leading: Icon(Icons.lock_outline),
                    title: Text('Dados sensíveis'),
                  ),
                ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.displayName,
                        style: theme.textTheme.titleLarge,
                      ),
                      if (person.relationshipToPatient != null &&
                          person.relationshipToPatient!.trim().isNotEmpty)
                        _Row(
                          'Relação',
                          person.relationshipToPatient!.trim(),
                        ),
                      if (person.gender != null)
                        _Row('Gênero', person.gender!.label),
                      if (person.lifeSpanLabel != null)
                        _Row('Período', person.lifeSpanLabel!),
                      if (person.isDeceased) const _Row('Status', 'Falecido'),
                      if (person.notes != null &&
                          person.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text('Observações', style: theme.textTheme.labelLarge),
                        const SizedBox(height: 4),
                        Text(person.notes!.trim()),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text('Relações vinculadas',
                  style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (linked.isEmpty)
                const Text('Nenhuma relação com esta pessoa ainda.')
              else
                ...linked.map(
                  (r) => GenogramRelationshipTile(
                    relationship: r,
                    data: data,
                    onTap: () => _openRelationship(context, r.id),
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
                    ? GenogramRoutes.patientPersonEdit(person.id)
                    : GenogramRoutes.staffPersonEdit(
                        role: role,
                        patientId: patientId!,
                        personId: person.id,
                      ),
              );
              if (updated == true) onChanged();
            },
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar pessoa'),
          ),
        ),
      ],
    );
  }

  Future<void> _openRelationship(BuildContext context, String id) async {
    await context.push(
      role == ProfileRole.patient
          ? GenogramRoutes.patientRelationshipDetail(id)
          : GenogramRoutes.staffRelationshipDetail(
              role: role,
              patientId: patientId!,
              relationshipId: id,
            ),
    );
    onChanged();
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
