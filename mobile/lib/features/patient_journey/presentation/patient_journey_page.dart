import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/journey_step.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/status_chip.dart';
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
            child: MotionReveal(
              child: _JourneyHeader(patientName: profile?.fullName),
            ),
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
    final greeting = patientName == null ? null : 'Olá, $patientName.';

    return AppPageHeader(
      icon: Icons.route_outlined,
      title: 'Sua trilha terapêutica',
      subtitle:
          '${greeting == null ? '' : '$greeting '}Siga os passos no seu ritmo e toque em cada etapa para continuar.',
      metadata: const [
        StatusChip(label: 'Disponível', tone: AppStatusTone.available),
        StatusChip(label: 'Em andamento', tone: AppStatusTone.inProgress),
        StatusChip(label: 'Concluído', tone: AppStatusTone.completed),
        StatusChip(
            label: 'Em desenvolvimento', tone: AppStatusTone.development),
        StatusChip(label: 'Bloqueado', tone: AppStatusTone.blocked),
      ],
    );
  }
}
