import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
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
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        88,
      ),
      children: [
        AppPageHeader(
          title: 'Objetivos da terapia',
          subtitle:
              'Metas acordadas para acompanhar progresso, próximos passos e mudanças importantes ao longo do processo terapêutico.',
          icon: Icons.flag_outlined,
          metadata: [
            Chip(label: Text('${visible.length} em andamento')),
            if (archived.isNotEmpty)
              Chip(label: Text('${archived.length} arquivados')),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        const AppSectionHeader(
          title: 'Em acompanhamento',
          subtitle: 'Toque em uma meta para ver detalhes ou atualizar status.',
        ),
        const SizedBox(height: AppSpacing.sm),
        MotionStaggered(
          children: [
            for (final g in visible)
              TherapyGoalListTile(goal: g, onTap: () => onTap(g)),
          ],
        ),
        if (archived.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          const AppSectionHeader(
            title: 'Arquivados',
            subtitle: 'Metas mantidas como histórico do processo.',
          ),
          const SizedBox(height: AppSpacing.sm),
          MotionStaggered(
            children: [
              for (final g in archived)
                TherapyGoalListTile(goal: g, onTap: () => onTap(g)),
            ],
          ),
        ],
      ],
    );
  }
}
