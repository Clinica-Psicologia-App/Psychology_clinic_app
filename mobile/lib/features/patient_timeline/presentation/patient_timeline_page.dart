import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient_timeline_event.dart';
import '../providers/patient_timeline_providers.dart';
import 'patient_timeline_routes.dart';
import 'widgets/patient_timeline_widgets.dart';

class PatientTimelinePage extends ConsumerWidget {
  const PatientTimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(myPatientTimelineProvider);

    return AppScaffold(
      title: 'Linha do tempo',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created =
              await context.push<bool>(PatientTimelineRoutes.patientCreate);
          if (created == true) {
            ref.read(myPatientTimelineProvider.notifier).refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo evento'),
      ),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.read(myPatientTimelineProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<PatientTimelineEvent>>(
        asyncValue: listAsync,
        onRetry: () => ref.read(myPatientTimelineProvider.notifier).refresh(),
        emptyMessage:
            'Nenhum evento na linha do tempo. Registre marcos da sua história ou do processo terapêutico.',
        emptyIcon: Icons.timeline_outlined,
        dataBuilder: (items) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(myPatientTimelineProvider.notifier).refresh();
          },
          child: _TimelineList(
            events: items,
            onTap: (event) async {
              await context.push(PatientTimelineRoutes.patientDetail(event.id));
              ref.read(myPatientTimelineProvider.notifier).refresh();
            },
          ),
        ),
      ),
    );
  }
}

class StaffPatientTimelinePage extends ConsumerWidget {
  const StaffPatientTimelinePage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = StaffPatientTimelineContext(role: role, patientId: patientId);
    final listAsync = ref.watch(staffPatientTimelineProvider(ctx));

    return AppScaffold(
      title: 'Linha do tempo',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>(
            PatientTimelineRoutes.staffCreate(role: role, patientId: patientId),
          );
          if (created == true) {
            ref.invalidate(staffPatientTimelineProvider(ctx));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo evento'),
      ),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(staffPatientTimelineProvider(ctx)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<PatientTimelineEvent>>(
        asyncValue: listAsync,
        onRetry: () => ref.invalidate(staffPatientTimelineProvider(ctx)),
        emptyMessage: 'Nenhum evento registrado para este paciente.',
        emptyIcon: Icons.timeline_outlined,
        dataBuilder: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(staffPatientTimelineProvider(ctx));
            await ref.read(staffPatientTimelineProvider(ctx).future);
          },
          child: _TimelineList(
            events: items,
            onTap: (event) async {
              await context.push(
                PatientTimelineRoutes.staffDetail(
                  role: role,
                  patientId: patientId,
                  eventId: event.id,
                ),
              );
              ref.invalidate(staffPatientTimelineProvider(ctx));
            },
          ),
        ),
      ),
    );
  }
}

class _TimelineList extends StatelessWidget {
  const _TimelineList({
    required this.events,
    required this.onTap,
  });

  final List<PatientTimelineEvent> events;
  final void Function(PatientTimelineEvent event) onTap;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        return PatientTimelineEventTile(
          event: event,
          onTap: () => onTap(event),
          isFirst: index == 0,
          isLast: index == events.length - 1,
        );
      },
    );
  }
}
