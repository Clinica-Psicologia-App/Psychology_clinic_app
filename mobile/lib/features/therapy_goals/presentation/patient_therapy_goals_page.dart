import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/therapy_goal.dart';
import '../domain/therapy_goal_status.dart';
import '../providers/therapy_goals_providers.dart';
import 'therapy_goal_routes.dart';
import 'widgets/therapy_goal_widgets.dart';

class PatientTherapyGoalsPage extends ConsumerWidget {
  const PatientTherapyGoalsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(myTherapyGoalsProvider);

    return AppScaffold(
      title: 'Objetivos da terapia',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created =
              await context.push<bool>(TherapyGoalRoutes.patientCreate);
          if (created == true) {
            ref.read(myTherapyGoalsProvider.notifier).refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo objetivo'),
      ),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.read(myTherapyGoalsProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<TherapyGoal>>(
        asyncValue: listAsync,
        onRetry: () => ref.read(myTherapyGoalsProvider.notifier).refresh(),
        emptyMessage:
            'Você ainda não registrou objetivos. Crie o primeiro com o botão abaixo.',
        emptyIcon: Icons.flag_outlined,
        dataBuilder: (items) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(myTherapyGoalsProvider.notifier).refresh();
          },
          child: _GoalsList(
            goals: items,
            onTap: (g) async {
              await context.push(TherapyGoalRoutes.patientDetail(g.id));
              ref.read(myTherapyGoalsProvider.notifier).refresh();
            },
          ),
        ),
      ),
    );
  }
}

class StaffPatientTherapyGoalsPage extends ConsumerWidget {
  const StaffPatientTherapyGoalsPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = StaffTherapyGoalsContext(role: role, patientId: patientId);
    final listAsync = ref.watch(staffPatientTherapyGoalsProvider(ctx));

    return AppScaffold(
      title: 'Objetivos da terapia',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>(
            TherapyGoalRoutes.staffCreate(role: role, patientId: patientId),
          );
          if (created == true) {
            ref.invalidate(staffPatientTherapyGoalsProvider(ctx));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo objetivo'),
      ),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.invalidate(staffPatientTherapyGoalsProvider(ctx)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<TherapyGoal>>(
        asyncValue: listAsync,
        onRetry: () => ref.invalidate(staffPatientTherapyGoalsProvider(ctx)),
        emptyMessage: 'Nenhum objetivo registrado para este paciente.',
        emptyIcon: Icons.flag_outlined,
        dataBuilder: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(staffPatientTherapyGoalsProvider(ctx));
            await ref.read(staffPatientTherapyGoalsProvider(ctx).future);
          },
          child: _GoalsList(
            goals: items,
            onTap: (g) async {
              await context.push(
                TherapyGoalRoutes.staffDetail(
                  role: role,
                  patientId: patientId,
                  goalId: g.id,
                ),
              );
              ref.invalidate(staffPatientTherapyGoalsProvider(ctx));
            },
          ),
        ),
      ),
    );
  }
}

class _GoalsList extends StatelessWidget {
  const _GoalsList({
    required this.goals,
    required this.onTap,
  });

  final List<TherapyGoal> goals;
  final void Function(TherapyGoal goal) onTap;

  @override
  Widget build(BuildContext context) {
    final visible =
        goals.where((g) => g.status != TherapyGoalStatus.archived).toList();
    final archived =
        goals.where((g) => g.status == TherapyGoalStatus.archived).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        Text(
          'Metas acordadas com seu psicólogo. Toque para ver detalhes ou atualizar o status.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        ...visible
            .map((g) => TherapyGoalListTile(goal: g, onTap: () => onTap(g))),
        if (archived.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            'Arquivados',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          ...archived.map(
            (g) => TherapyGoalListTile(goal: g, onTap: () => onTap(g)),
          ),
        ],
      ],
    );
  }
}
