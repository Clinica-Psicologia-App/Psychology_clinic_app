import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient_check_in.dart';
import '../providers/patient_check_ins_providers.dart';
import 'patient_check_in_routes.dart';
import 'widgets/patient_check_in_widgets.dart';

class PatientCheckInsPage extends ConsumerWidget {
  const PatientCheckInsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(myPatientCheckInsProvider);
    final todayAsync = ref.watch(todayCheckInProvider);

    return AppScaffold(
      title: 'Check-in',
      floatingActionButton: todayAsync.when(
        data: (today) {
          if (today != null) {
            return FloatingActionButton.extended(
              onPressed: () => context.push(
                PatientCheckInRoutes.patientEdit(today.id),
              ),
              icon: const Icon(Icons.edit),
              label: const Text('Editar check-in de hoje'),
            );
          }
          return FloatingActionButton.extended(
            onPressed: () => _openCreate(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Check-in de hoje'),
          );
        },
        loading: () => const FloatingActionButton.extended(
          onPressed: null,
          icon: Icon(Icons.add),
          label: Text('Check-in de hoje'),
        ),
        error: (_, __) => FloatingActionButton.extended(
          onPressed: () => _openCreate(context, ref),
          icon: const Icon(Icons.add),
          label: const Text('Check-in de hoje'),
        ),
      ),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () {
            ref.read(myPatientCheckInsProvider.notifier).refresh();
            ref.invalidate(todayCheckInProvider);
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<PatientCheckIn>>(
        asyncValue: listAsync,
        onRetry: () {
          ref.read(myPatientCheckInsProvider.notifier).refresh();
          ref.invalidate(todayCheckInProvider);
        },
        emptyMessage:
            'Nenhum check-in ainda. Registre como está se sentindo hoje.',
        emptyIcon: Icons.fact_check_outlined,
        dataBuilder: (items) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(myPatientCheckInsProvider.notifier).refresh();
            ref.invalidate(todayCheckInProvider);
          },
          child: _CheckInsList(
            items: items,
            onTap: (c) async {
              await context.push(PatientCheckInRoutes.patientDetail(c.id));
              ref.read(myPatientCheckInsProvider.notifier).refresh();
              ref.invalidate(todayCheckInProvider);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final created =
        await context.push<bool>(PatientCheckInRoutes.patientCreate);
    if (created == true) {
      ref.read(myPatientCheckInsProvider.notifier).refresh();
      ref.invalidate(todayCheckInProvider);
    }
  }
}

class StaffPatientCheckInsPage extends ConsumerWidget {
  const StaffPatientCheckInsPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = StaffCheckInsContext(role: role, patientId: patientId);
    final listAsync = ref.watch(staffPatientCheckInsProvider(ctx));

    return AppScaffold(
      title: 'Check-ins',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(staffPatientCheckInsProvider(ctx)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<PatientCheckIn>>(
        asyncValue: listAsync,
        onRetry: () => ref.invalidate(staffPatientCheckInsProvider(ctx)),
        emptyMessage: 'Nenhum check-in registrado pelo paciente.',
        emptyIcon: Icons.fact_check_outlined,
        dataBuilder: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(staffPatientCheckInsProvider(ctx));
            await ref.read(staffPatientCheckInsProvider(ctx).future);
          },
          child: _CheckInsList(
            items: items,
            readOnly: true,
            onTap: (c) => context.push(
              PatientCheckInRoutes.staffDetail(
                role: role,
                patientId: patientId,
                checkInId: c.id,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CheckInsList extends StatelessWidget {
  const _CheckInsList({
    required this.items,
    required this.onTap,
    this.readOnly = false,
  });

  final List<PatientCheckIn> items;
  final void Function(PatientCheckIn checkIn) onTap;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    final today = items.where((c) => c.isToday).toList();
    final history = items.where((c) => !c.isToday).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        if (readOnly)
          Text(
            'Histórico de check-ins do paciente (somente leitura).',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          )
        else
          Text(
            'Registros rápidos entre as sessões. O check-in de hoje aparece em destaque.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        const SizedBox(height: 16),
        MotionStaggered(
          children: [
            for (final c in today)
              PatientCheckInListTile(
                checkIn: c,
                highlightToday: true,
                onTap: () => onTap(c),
              ),
          ],
        ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text('Anteriores', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          MotionStaggered(
            children: [
              for (final c in history)
                PatientCheckInListTile(
                  checkIn: c,
                  onTap: () => onTap(c),
                ),
            ],
          ),
        ],
      ],
    );
  }
}
