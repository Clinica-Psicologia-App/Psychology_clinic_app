import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient_problem.dart';
import '../domain/patient_problem_status.dart';
import '../providers/patient_problems_providers.dart';
import 'patient_problem_routes.dart';
import 'widgets/patient_problem_widgets.dart';

class PatientProblemDetailPage extends ConsumerWidget {
  const PatientProblemDetailPage({
    super.key,
    required this.role,
    required this.problemId,
    this.patientId,
  });

  final ProfileRole role;
  final String problemId;
  final String? patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final problemAsync = ref.watch(patientProblemDetailProvider(problemId));

    return AppScaffold(
      title: 'Problema',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.invalidate(patientProblemDetailProvider(problemId)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: problemAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erro ao carregar problema.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(patientProblemDetailProvider(problemId)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (problem) {
          if (problem == null) {
            return const Center(child: Text('Problema não encontrado.'));
          }

          return _PatientProblemDetailBody(
            problem: problem,
            role: role,
            patientId: patientId,
            onChanged: () {
              ref.invalidate(patientProblemDetailProvider(problemId));
              if (role == ProfileRole.patient) {
                ref.read(myPatientProblemsProvider.notifier).refresh();
              } else if (patientId != null) {
                ref.invalidate(
                  staffPatientProblemsProvider(
                    StaffPatientProblemsContext(
                      role: role,
                      patientId: patientId!,
                    ),
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

class _PatientProblemDetailBody extends ConsumerStatefulWidget {
  const _PatientProblemDetailBody({
    required this.problem,
    required this.role,
    required this.patientId,
    required this.onChanged,
  });

  final PatientProblem problem;
  final ProfileRole role;
  final String? patientId;
  final VoidCallback onChanged;

  @override
  ConsumerState<_PatientProblemDetailBody> createState() =>
      _PatientProblemDetailBodyState();
}

class _PatientProblemDetailBodyState
    extends ConsumerState<_PatientProblemDetailBody> {
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
    final p = widget.problem;
    if (widget.role == ProfileRole.patient) {
      context.push(PatientProblemRoutes.patientEdit(p.id));
    } else {
      context.push(
        PatientProblemRoutes.staffEdit(
          role: widget.role,
          patientId: widget.patientId!,
          problemId: p.id,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final goal = ref
            .watch(patientProblemDetailProvider(widget.problem.id))
            .valueOrNull ??
        widget.problem;
    final loc = MaterialLocalizations.of(context);

    return Column(
      children: [
        Expanded(
          child: MotionReveal(
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                AppPageHeader(
                  title: goal.title,
                  subtitle:
                      'Registro do foco clínico acompanhado no processo terapêutico.',
                  icon: Icons.psychology_alt_outlined,
                  metadata: [
                    PatientProblemStatusChip(status: goal.status),
                  ],
                ),
                if (goal.intensity != null) ...[
                  const SizedBox(height: AppSpacing.lg),
                  PatientProblemIntensityBadge(intensity: goal.intensity!),
                ],
                if (goal.category != null &&
                    goal.category!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.lg),
                  _InfoRow(label: 'Categoria', value: goal.category!),
                ],
                if (goal.description != null &&
                    goal.description!.trim().isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xl),
                  AppInfoCard(
                    title: 'Descrição',
                    body: goal.description!,
                    icon: Icons.notes_outlined,
                  ),
                ],
                const SizedBox(height: AppSpacing.xl),
                const AppSectionHeader(
                  title: 'Dados do foco',
                  subtitle: 'Datas e histórico de atualização.',
                ),
                const SizedBox(height: AppSpacing.sm),
                if (goal.identifiedAt != null)
                  _InfoRow(
                    label: 'Identificado em',
                    value: loc.formatFullDate(goal.identifiedAt!),
                  ),
                if (goal.resolvedAt != null)
                  _InfoRow(
                    label: 'Resolvido em',
                    value: loc.formatFullDate(goal.resolvedAt!),
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
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (goal.status == PatientProblemStatus.active) ...[
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await ref
                                .read(patientProblemsRepositoryProvider)
                                .updateStatus(
                                  id: goal.id,
                                  status: PatientProblemStatus.improved,
                                );
                          }),
                  icon: const Icon(Icons.trending_up),
                  label: const Text('Marcar como melhorou'),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (goal.status == PatientProblemStatus.active ||
                  goal.status == PatientProblemStatus.improved) ...[
                FilledButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await ref
                                .read(patientProblemsRepositoryProvider)
                                .updateStatus(
                                  id: goal.id,
                                  status: PatientProblemStatus.resolved,
                                );
                          }),
                  icon: const Icon(Icons.check),
                  label: const Text('Marcar como resolvido'),
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
              if (goal.status != PatientProblemStatus.archived)
                OutlinedButton.icon(
                  onPressed: _busy
                      ? null
                      : () => _run(() async {
                            await ref
                                .read(patientProblemsRepositoryProvider)
                                .updateStatus(
                                  id: goal.id,
                                  status: PatientProblemStatus.archived,
                                );
                          }),
                  icon: const Icon(Icons.archive_outlined),
                  label: const Text('Arquivar'),
                ),
              const SizedBox(height: AppSpacing.xs),
              TextButton.icon(
                onPressed: _busy ? null : _openEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Editar'),
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
