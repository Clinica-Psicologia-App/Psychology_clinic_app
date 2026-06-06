import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/journey_step.dart';
import '../../../shared/widgets/homologation_ui.dart';
import '../providers/patient_journey_providers.dart';
import 'patient_journey_navigation.dart';
import 'widgets/journey_trail.dart';

class PatientJourneyPage extends ConsumerWidget {
  const PatientJourneyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(patientJourneyStepsProvider);
    final profile = ref.watch(authControllerProvider).valueOrNull;

    return AppScaffold(
      title: 'Meu plano terapêutico',
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: _JourneyHeader(patientName: profile?.fullName),
          ),
          Expanded(
            child: AsyncStateBody<List<JourneyStep>>(
              asyncValue: stepsAsync,
              onRetry: () {
                ref.invalidate(patientJourneyProgressProvider);
                ref.invalidate(patientJourneyStepsProvider);
              },
              emptyMessage: 'Nenhum passo configurado na trilha.',
              emptyIcon: Icons.route_outlined,
              dataBuilder: (steps) => RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(patientJourneyProgressProvider);
                  ref.invalidate(patientJourneyStepsProvider);
                  await ref.read(patientJourneyStepsProvider.future);
                },
                child: JourneyTrail(
                  steps: steps,
                  onStepTap: (step) => navigateFromJourneyStep(context, step),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyHeader extends StatelessWidget {
  const _JourneyHeader({this.patientName});

  final String? patientName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const HomologationSectionHeader(
              icon: Icons.route_outlined,
              title: 'Sua trilha terapêutica',
              subtitle:
                  'Siga os passos na ordem sugerida. Toque em cada card para abrir o módulo.',
            ),
            if (patientName != null) ...[
              const SizedBox(height: 12),
              Text(
                'Olá, $patientName.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Legenda de status',
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            const Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _LegendDot(
                  label: 'Disponível',
                  availabilityKey: 'available',
                ),
                _LegendDot(
                  label: 'Em andamento',
                  availabilityKey: 'inProgress',
                ),
                _LegendDot(
                  label: 'Concluído',
                  availabilityKey: 'completed',
                ),
                _LegendDot(
                  label: 'Em desenvolvimento',
                  availabilityKey: 'dev',
                ),
                _LegendDot(
                  label: 'Bloqueado',
                  availabilityKey: 'blocked',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({
    required this.label,
    required this.availabilityKey,
  });

  final String label;
  final String availabilityKey;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dotColor = switch (availabilityKey) {
      'completed' => colors.tertiary,
      'inProgress' => colors.secondary,
      'dev' => colors.outline,
      'blocked' => colors.error,
      _ => colors.primary,
    };

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: dotColor,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: Theme.of(context).textTheme.labelSmall),
      ],
    );
  }
}
