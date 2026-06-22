import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/therapy_goal.dart';
import '../domain/therapy_goal_status.dart';
import '../providers/therapy_goals_providers.dart';
import 'therapy_goal_routes.dart';
import 'widgets/therapy_goal_widgets.dart';

class TherapyGoalDetailPage extends ConsumerWidget {
  const TherapyGoalDetailPage({
    super.key,
    required this.role,
    required this.goalId,
    this.patientId,
  });

  final ProfileRole role;
  final String goalId;
  final String? patientId;

  bool get _isPatient => role == ProfileRole.patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(therapyGoalDetailProvider(goalId));

    return AppScaffold(
      title: 'Objetivo',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(therapyGoalDetailProvider(goalId)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: goalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erro ao carregar objetivo.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(therapyGoalDetailProvider(goalId)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (goal) {
          if (goal == null) {
            return const Center(child: Text('Objetivo não encontrado.'));
          }

          return _TherapyGoalDetailBody(
            goal: goal,
            role: role,
            patientId: patientId,
            onChanged: () {
              ref.invalidate(therapyGoalDetailProvider(goalId));
              if (_isPatient) {
                ref.read(myTherapyGoalsProvider.notifier).refresh();
              } else if (patientId != null) {
                ref.invalidate(
                  staffPatientTherapyGoalsProvider(
                    StaffTherapyGoalsContext(role: role, patientId: patientId!),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}

class _TherapyGoalDetailBody extends ConsumerStatefulWidget {
  const _TherapyGoalDetailBody({
    required this.goal,
    required this.role,
    required this.patientId,
    required this.onChanged,
  });

  final TherapyGoal goal;
  final ProfileRole role;
  final String? patientId;
  final VoidCallback onChanged;

  @override
  ConsumerState<_TherapyGoalDetailBody> createState() =>
      _TherapyGoalDetailBodyState();
}

class _TherapyGoalDetailBodyState
    extends ConsumerState<_TherapyGoalDetailBody> {
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      widget.onChanged();
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _openEdit() {
    final g = widget.goal;
    if (widget.role == ProfileRole.patient) {
      context.push(TherapyGoalRoutes.patientEdit(g.id));
    } else {
      context.push(
        TherapyGoalRoutes.staffEdit(
          role: widget.role,
          patientId: widget.patientId!,
          goalId: g.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final goal =
        ref.watch(therapyGoalDetailProvider(widget.goal.id)).valueOrNull ??
            widget.goal;
    final loc = MaterialLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: MotionReveal(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        style: theme.textTheme.headlineSmall,
                      ),
                    ),
                    TherapyGoalStatusChip(status: goal.status),
                  ],
                ),
                if (goal.description != null &&
                    goal.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Text(goal.description!),
                ],
                const SizedBox(height: 24),
                if (goal.targetDate != null)
                  _InfoRow(
                    label: 'Data alvo',
                    value: loc.formatFullDate(goal.targetDate!),
                  ),
                if (goal.completedAt != null)
                  _InfoRow(
                    label: 'Concluído em',
                    value: loc.formatFullDate(goal.completedAt!),
                  ),
                _InfoRow(
                  label: 'Atualizado',
                  value: loc.formatFullDate(goal.updatedAt),
                ),
              ],
            ),
          ),
        ),
        if (_busy) const LinearProgressIndicator(),
        const Divider(height: 1),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (goal.status == TherapyGoalStatus.active) ...[
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await ref
                                .read(therapyGoalsRepositoryProvider)
                                .updateStatus(
                                  id: goal.id,
                                  status: TherapyGoalStatus.completed,
                                );
                          }),
                  icon: const Icon(Icons.check),
                  label: const Text('Marcar como concluído'),
                ),
                const SizedBox(height: 8),
              ],
              if (goal.status != TherapyGoalStatus.archived)
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await ref
                                .read(therapyGoalsRepositoryProvider)
                                .updateStatus(
                                  id: goal.id,
                                  status: TherapyGoalStatus.archived,
                                );
                          }),
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Arquivar'),
                ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: _busy ? null : _openEdit,
                icon: const Icon(Icons.edit_outlined),
                label: Text(
                  widget.role == ProfileRole.patient
                      ? 'Editar título e descrição'
                      : 'Editar objetivo',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
