import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient.dart';
import '../providers/patients_providers.dart';
import 'patient_routes.dart';
import 'widgets/patient_list_tile.dart';

class PatientsPage extends ConsumerWidget {
  const PatientsPage({super.key, required this.role});

  final ProfileRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listState = ref.watch(patientsListProvider);
    final profile = ref.watch(authControllerProvider).valueOrNull;

    return AppScaffold(
      title: 'Pacientes',
      actions: [
        if (profile != null && role.isStaff)
          IconButton(
            tooltip: 'Convidar paciente',
            onPressed: () => context.push(PatientRoutes.invitationCreate(role)),
            icon: const Icon(Icons.mark_email_unread_outlined),
          ),
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.read(patientsListProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<Patient>>(
        asyncValue: listState,
        onRetry: () => ref.read(patientsListProvider.notifier).refresh(),
        emptyMessage: 'Nenhum paciente encontrado.\n'
            'Toque em + para cadastrar o primeiro.',
        dataBuilder: (patients) => RefreshIndicator(
          onRefresh: () =>
              ref.read(patientsListProvider.notifier).refresh(),
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: patients.length,
            itemBuilder: (context, index) {
              final patient = patients[index];
              return PatientListTile(
                patient: patient,
                onTap: () => context.push(
                  PatientRoutes.detail(role, patient.id),
                ),
              );
            },
          ),
        ),
      ),
      floatingActionButton: profile != null && role.isStaff
          ? FloatingActionButton.extended(
              onPressed: () => context.push(PatientRoutes.create(role)),
              icon: const Icon(Icons.person_add),
              label: const Text('Novo paciente'),
            )
          : null,
    );
  }
}

extension on ProfileRole {
  bool get isStaff =>
      this == ProfileRole.admin || this == ProfileRole.psychologist;
}
