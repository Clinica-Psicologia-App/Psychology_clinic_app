import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient_problem.dart';
import '../domain/patient_problem_status.dart';
import '../providers/patient_problems_providers.dart';
import 'patient_problem_routes.dart';
import 'widgets/patient_problem_widgets.dart';

class PatientProblemsPage extends ConsumerWidget {
  const PatientProblemsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(myPatientProblemsProvider);

    return AppScaffold(
      title: 'Problemas',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created =
              await context.push<bool>(PatientProblemRoutes.patientCreate);
          if (created == true) {
            ref.read(myPatientProblemsProvider.notifier).refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo problema'),
      ),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.read(myPatientProblemsProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<PatientProblem>>(
        asyncValue: listAsync,
        onRetry: () => ref.read(myPatientProblemsProvider.notifier).refresh(),
        emptyMessage:
            'Nenhum problema registrado. Use o botão abaixo para adicionar uma queixa ou foco de trabalho.',
        emptyIcon: Icons.report_problem_outlined,
        dataBuilder: (items) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(myPatientProblemsProvider.notifier).refresh();
          },
          child: _ProblemsList(
            problems: items,
            onTap: (p) async {
              await context.push(PatientProblemRoutes.patientDetail(p.id));
              ref.read(myPatientProblemsProvider.notifier).refresh();
            },
          ),
        ),
      ),
    );
  }
}

class StaffPatientProblemsPage extends ConsumerWidget {
  const StaffPatientProblemsPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = StaffPatientProblemsContext(role: role, patientId: patientId);
    final listAsync = ref.watch(staffPatientProblemsProvider(ctx));

    return AppScaffold(
      title: 'Problemas',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await context.push<bool>(
            PatientProblemRoutes.staffCreate(role: role, patientId: patientId),
          );
          if (created == true) {
            ref.invalidate(staffPatientProblemsProvider(ctx));
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Novo problema'),
      ),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(staffPatientProblemsProvider(ctx)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<PatientProblem>>(
        asyncValue: listAsync,
        onRetry: () => ref.invalidate(staffPatientProblemsProvider(ctx)),
        emptyMessage: 'Nenhum problema registrado para este paciente.',
        emptyIcon: Icons.report_problem_outlined,
        dataBuilder: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(staffPatientProblemsProvider(ctx));
            await ref.read(staffPatientProblemsProvider(ctx).future);
          },
          child: _ProblemsList(
            problems: items,
            onTap: (p) async {
              await context.push(
                PatientProblemRoutes.staffDetail(
                  role: role,
                  patientId: patientId,
                  problemId: p.id,
                ),
              );
              ref.invalidate(staffPatientProblemsProvider(ctx));
            },
          ),
        ),
      ),
    );
  }
}

class _ProblemsList extends StatelessWidget {
  const _ProblemsList({
    required this.problems,
    required this.onTap,
  });

  final List<PatientProblem> problems;
  final void Function(PatientProblem problem) onTap;

  @override
  Widget build(BuildContext context) {
    final open = problems.where((p) => p.isOpen).toList();
    final closed = problems
        .where(
          (p) =>
              p.status == PatientProblemStatus.resolved ||
              p.status == PatientProblemStatus.archived,
        )
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      children: [
        Text(
          'Queixas e focos de trabalho em acompanhamento.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        if (open.isNotEmpty) ...[
          Text('Em acompanhamento',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...open.map(
              (p) => PatientProblemListTile(problem: p, onTap: () => onTap(p))),
        ],
        if (closed.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('Resolvidos / arquivados',
              style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 8),
          ...closed.map(
            (p) => PatientProblemListTile(problem: p, onTap: () => onTap(p)),
          ),
        ],
      ],
    );
  }
}
