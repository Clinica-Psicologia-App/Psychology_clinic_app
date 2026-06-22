import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/patient_check_ins_providers.dart';
import 'patient_check_in_routes.dart';
import 'widgets/patient_check_in_widgets.dart';

class PatientCheckInDetailPage extends ConsumerWidget {
  const PatientCheckInDetailPage({
    super.key,
    required this.role,
    required this.checkInId,
    this.patientId,
  });

  final ProfileRole role;
  final String checkInId;
  final String? patientId;

  bool get _isPatient => role == ProfileRole.patient;
  bool get _readOnly => !_isPatient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInAsync = ref.watch(patientCheckInDetailProvider(checkInId));

    return AppScaffold(
      title: 'Check-in',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.invalidate(patientCheckInDetailProvider(checkInId)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: checkInAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erro ao carregar check-in.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(patientCheckInDetailProvider(checkInId)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (checkIn) {
          if (checkIn == null) {
            return const Center(child: Text('Check-in não encontrado.'));
          }

          final loc = MaterialLocalizations.of(context);
          final theme = Theme.of(context);

          return Column(
            children: [
              Expanded(
                child: MotionReveal(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (checkIn.isToday)
                        Card(
                          color: theme.colorScheme.primaryContainer
                              .withValues(alpha: 0.4),
                          child: const ListTile(
                            leading: Icon(Icons.today),
                            title: Text('Check-in de hoje'),
                          ),
                        ),
                      const SizedBox(height: 16),
                      Text(
                        loc.formatFullDate(checkIn.checkedInAt.toLocal()),
                        style: theme.textTheme.headlineSmall,
                      ),
                      Text(
                        loc.formatTimeOfDay(
                          TimeOfDay.fromDateTime(checkIn.checkedInAt.toLocal()),
                        ),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 24),
                      CheckInScoresSummary(checkIn: checkIn),
                      if (checkIn.notes != null &&
                          checkIn.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Text('Observações', style: theme.textTheme.titleSmall),
                        const SizedBox(height: 8),
                        Text(checkIn.notes!),
                      ],
                    ],
                  ),
                ),
              ),
              if (_isPatient && checkIn.isEditableToday) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: FilledButton.icon(
                    onPressed: () => context.push(
                      PatientCheckInRoutes.patientEdit(checkInId),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar check-in de hoje'),
                  ),
                ),
              ],
              if (_readOnly)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Visualização somente leitura para a equipe.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
