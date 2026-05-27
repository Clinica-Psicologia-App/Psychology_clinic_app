import 'package:flutter/material.dart';

import '../../domain/patient.dart';

class PatientListTile extends StatelessWidget {
  const PatientListTile({
    super.key,
    required this.patient,
    required this.onTap,
  });

  final Patient patient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final psychologist =
        patient.responsiblePsychologistName ?? 'Não informado';
    final status = patient.accessStatus?.label;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: ListTile(
        onTap: onTap,
        title: Text(patient.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (patient.email != null && patient.email!.isNotEmpty)
              Text(patient.email!),
            if (patient.phone != null && patient.phone!.isNotEmpty)
              Text(patient.phone!),
            Text('Psicólogo: $psychologist'),
            if (status != null)
              Text(
                status,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
          ],
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}
