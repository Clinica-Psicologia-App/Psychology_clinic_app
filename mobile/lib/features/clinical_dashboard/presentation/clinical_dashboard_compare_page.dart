import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../../results/presentation/result_routes.dart';
import '../providers/clinical_dashboard_providers.dart';

class ClinicalDashboardComparePage extends ConsumerWidget {
  const ClinicalDashboardComparePage({
    super.key,
    required this.role,
    required this.patientId,
    required this.questionnaireCode,
  });

  final ProfileRole role;
  final String patientId;
  final String questionnaireCode;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = StaffClinicalDashboardContext(role: role, patientId: patientId);
    final dataAsync = ref.watch(staffClinicalDashboardProvider(ctx));

    return AppScaffold(
      title: 'Histórico comparativo',
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Não foi possível carregar o histórico.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(staffClinicalDashboardProvider(ctx)),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (data) {
          final entries = data.history
              .where(
                (e) =>
                    e.questionnaireCode.toUpperCase() ==
                    questionnaireCode.toUpperCase(),
              )
              .toList();

          final loc = MaterialLocalizations.of(context);
          final theme = Theme.of(context);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (entries.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Nenhuma aplicação concluída encontrada para '
                      '$questionnaireCode.',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entries.first.questionnaireName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          questionnaireCode,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${entries.length} '
                          'aplicação${entries.length == 1 ? '' : 'ões'} '
                          'concluída${entries.length == 1 ? '' : 's'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ...entries.asMap().entries.map((indexedEntry) {
                  final index = indexedEntry.key;
                  final entry = indexedEntry.value;
                  final dateLabel = entry.completedAt != null
                      ? loc.formatFullDate(entry.completedAt!.toLocal())
                      : 'Data desconhecida';
                  final isMostRecent = index == 0;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isMostRecent
                            ? theme.colorScheme.primaryContainer
                            : theme.colorScheme.surfaceContainerHighest,
                        child: Text(
                          '${entries.length - index}',
                          style: TextStyle(
                            color: isMostRecent
                                ? theme.colorScheme.onPrimaryContainer
                                : theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      title: Text(
                        dateLabel,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: isMostRecent
                              ? FontWeight.w700
                              : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        [
                          if (isMostRecent) 'Mais recente',
                          entry.hasResults
                              ? 'Com resultados'
                              : 'Sem resultados',
                        ].join(' · '),
                      ),
                      trailing: entry.hasResults
                          ? IconButton(
                              icon: const Icon(Icons.open_in_new_outlined),
                              tooltip: 'Ver resultado',
                              onPressed: () => context.push(
                                ResultRoutes.detail(
                                  role: role,
                                  patientId: patientId,
                                  responseId: entry.responseId,
                                ),
                              ),
                            )
                          : null,
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }
}
