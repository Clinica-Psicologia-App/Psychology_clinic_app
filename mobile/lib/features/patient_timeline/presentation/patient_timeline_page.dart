import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/status_chip.dart';
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
            title: 'Sua linha do tempo',
            subtitle:
                'Organize marcos por etapa da vida e registre como eles ainda aparecem no presente.',
            onCreate: () async {
              final created =
                  await context.push<bool>(PatientTimelineRoutes.patientCreate);
              if (created == true) {
                ref.read(myPatientTimelineProvider.notifier).refresh();
              }
            },
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
            title: 'Linha do tempo clínica',
            subtitle:
                'Visualize eventos-chave, etapas da vida e pontes com o presente.',
            onCreate: () async {
              final created = await context.push<bool>(
                PatientTimelineRoutes.staffCreate(
                  role: role,
                  patientId: patientId,
                ),
              );
              if (created == true) {
                ref.invalidate(staffPatientTimelineProvider(ctx));
              }
            },
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
    required this.title,
    required this.subtitle,
    required this.onCreate,
    required this.onTap,
  });

  final List<PatientTimelineEvent> events;
  final String title;
  final String subtitle;
  final Future<void> Function() onCreate;
  final void Function(PatientTimelineEvent event) onTap;

  @override
  Widget build(BuildContext context) {
    final sensitiveCount = events.where((event) => event.isSensitive).length;
    final presentCount =
        events.where((event) => event.presentInfluence != null).length;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xxl,
      ),
      itemCount: events.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.lg),
            child: AppPageHeader(
              icon: Icons.timeline_outlined,
              title: title,
              subtitle: subtitle,
              metadata: [
                StatusChip(
                  label: '${events.length} evento(s)',
                  tone: AppStatusTone.info,
                  icon: Icons.event_note_outlined,
                ),
                if (presentCount > 0)
                  StatusChip(
                    label: '$presentCount com influência atual',
                    tone: AppStatusTone.warning,
                    icon: Icons.insights_outlined,
                  ),
                if (sensitiveCount > 0)
                  StatusChip(
                    label: '$sensitiveCount sensível(is)',
                    tone: AppStatusTone.error,
                    icon: Icons.lock_outline,
                  ),
              ],
              primaryAction: FilledButton.icon(
                onPressed: onCreate,
                icon: const Icon(Icons.add),
                label: const Text('Novo evento'),
              ),
            ),
          );
        }
        final eventIndex = index - 1;
        final event = events[eventIndex];
        return MotionReveal(
          delay: staggerDelay(eventIndex),
          child: PatientTimelineEventTile(
            event: event,
            onTap: () => onTap(event),
            isFirst: eventIndex == 0,
            isLast: eventIndex == events.length - 1,
          ),
        );
      },
    );
  }
}
