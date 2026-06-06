import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/patient_timeline_providers.dart';
import 'patient_timeline_routes.dart';
import 'widgets/patient_timeline_widgets.dart';

class PatientTimelineEventDetailPage extends ConsumerWidget {
  const PatientTimelineEventDetailPage({
    super.key,
    required this.role,
    required this.eventId,
    this.patientId,
  });

  final ProfileRole role;
  final String eventId;
  final String? patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventAsync = ref.watch(patientTimelineEventDetailProvider(eventId));

    return AppScaffold(
      title: 'Evento',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.invalidate(patientTimelineEventDetailProvider(eventId)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: eventAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erro ao carregar evento.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(
                  patientTimelineEventDetailProvider(eventId),
                ),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (event) {
          if (event == null) {
            return const Center(child: Text('Evento não encontrado.'));
          }

          return Column(
            children: [
              Expanded(child: TimelineEventDetailBody(event: event)),
              Padding(
                padding: const EdgeInsets.all(16),
                child: FilledButton.icon(
                  onPressed: () async {
                    final updated = await context.push<bool>(
                      role == ProfileRole.patient
                          ? PatientTimelineRoutes.patientEdit(eventId)
                          : PatientTimelineRoutes.staffEdit(
                              role: role,
                              patientId: patientId!,
                              eventId: eventId,
                            ),
                    );
                    if (updated == true) {
                      ref.invalidate(
                        patientTimelineEventDetailProvider(eventId),
                      );
                      if (role == ProfileRole.patient) {
                        ref.read(myPatientTimelineProvider.notifier).refresh();
                      } else if (patientId != null) {
                        ref.invalidate(
                          staffPatientTimelineProvider(
                            StaffPatientTimelineContext(
                              role: role,
                              patientId: patientId!,
                            ),
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('Editar evento'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
