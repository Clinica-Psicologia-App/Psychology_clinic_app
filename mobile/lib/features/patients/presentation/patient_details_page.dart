import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient.dart';
import '../providers/patients_providers.dart';
import 'widgets/future_modules_section.dart';

class PatientDetailsPage extends ConsumerWidget {
  const PatientDetailsPage({
    super.key,
    required this.patientId,
    required this.role,
  });

  final String patientId;
  final ProfileRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPatient = ref.watch(patientDetailProvider(patientId));

    return AppScaffold(
      title: 'Paciente',
      body: asyncPatient.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Não foi possível carregar o paciente.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.invalidate(patientDetailProvider(patientId)),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (patient) {
          if (patient == null) {
            return const Center(child: Text('Paciente não encontrado.'));
          }
          return _PatientDetailsBody(patient: patient);
        },
      ),
    );
  }
}

class _PatientDetailsBody extends StatelessWidget {
  const _PatientDetailsBody({required this.patient});

  final Patient patient;

  @override
  Widget build(BuildContext context) {
    final dateFormat = MaterialLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patient.fullName,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                _InfoRow(label: 'E-mail', value: patient.email),
                _InfoRow(label: 'Telefone', value: patient.phone),
                _InfoRow(label: 'CPF', value: patient.cpf),
                _InfoRow(
                  label: 'Data de nascimento',
                  value: patient.birthDate != null
                      ? dateFormat.formatFullDate(patient.birthDate!)
                      : null,
                ),
                _InfoRow(
                  label: 'Psicólogo responsável',
                  value: patient.responsiblePsychologistName,
                ),
                _InfoRow(
                  label: 'Status',
                  value: patient.accessStatus?.label,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
        const FutureModulesSection(),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String? value;

  @override
  Widget build(BuildContext context) {
    if (value == null || value!.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(child: Text(value!)),
        ],
      ),
    );
  }
}
