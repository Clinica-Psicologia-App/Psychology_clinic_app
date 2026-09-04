import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../genogram/presentation/genogram_routes.dart';
import '../../genogram/providers/genogram_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/patient_timeline_providers.dart';
import 'patient_timeline_routes.dart';
import 'widgets/patient_timeline_widgets.dart';
import '../../../shared/widgets/brand_loading.dart';

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
      accent: AppColors.cyan,
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.invalidate(patientTimelineEventDetailProvider(eventId)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: eventAsync.when(
        loading: () => const BrandLoader(),
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
              Expanded(
                child: MotionReveal(
                  child: TimelineEventDetailBody(event: event),
                ),
              ),
              if (event.relatedPersonIds.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: _RelatedPersonLink(
                    role: role,
                    patientId: patientId,
                    personId: event.relatedPersonIds.first,
                  ),
                ),
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

/// Atalho para a pessoa do genograma vinculada a este evento.
class _RelatedPersonLink extends ConsumerWidget {
  const _RelatedPersonLink({
    required this.role,
    required this.patientId,
    required this.personId,
  });

  final ProfileRole role;
  final String? patientId;
  final String personId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(genogramPersonDetailProvider(personId));

    return personAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (person) {
        if (person == null) return const SizedBox.shrink();
        return OutlinedButton.icon(
          onPressed: () => context.push(
            role == ProfileRole.patient
                ? GenogramRoutes.patientPersonDetail(person.id)
                // Rota STANDALONE pelo mesmo motivo do caminho de ida: evita
                // reentrar no shell e duplicar a página dele na pilha.
                : GenogramRoutes.personDetailFor(
                    patientId ?? person.patientId,
                    person.id,
                  ),
          ),
          icon: const Icon(Icons.account_tree_outlined),
          label: Text('Ver no genograma: ${person.displayName}'),
        );
      },
    );
  }
}
