import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/initial_assessment_providers.dart';
import '../providers/patient_family_providers.dart';
import '../providers/patient_history_providers.dart';
import 'initial_assessment_family_page.dart';
import 'initial_assessment_family_therapist_page.dart';
import 'initial_assessment_history_page.dart';
import 'initial_assessment_history_therapist_page.dart';
import 'initial_assessment_patient_page.dart';
import 'initial_assessment_therapist_page.dart';

List<RouteBase> patientInitialAssessmentRoutes() {
  return [
    GoRoute(
      path: 'initial-assessment',
      builder: (_, __) => const _MyInitialAssessmentEntry(),
      routes: [
        GoRoute(
          path: 'history',
          builder: (_, __) => const _MyHistoryEntry(),
        ),
        GoRoute(
          path: 'family',
          builder: (_, __) => const _MyFamilyEntry(),
        ),
      ],
    ),
  ];
}

List<RouteBase> staffPatientInitialAssessmentRoutes({
  required ProfileRole role,
}) {
  return [
    GoRoute(
      path: 'initial-assessment',
      builder: (context, state) => InitialAssessmentTherapistPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
      routes: [
        GoRoute(
          path: 'history',
          builder: (context, state) => InitialAssessmentHistoryTherapistPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
          ),
        ),
        GoRoute(
          path: 'family',
          builder: (context, state) => InitialAssessmentFamilyTherapistPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
          ),
        ),
      ],
    ),
  ];
}

/// Resolve o `patientId` do paciente logado antes de abrir a Tela 1.
class _MyInitialAssessmentEntry extends ConsumerWidget {
  const _MyInitialAssessmentEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idAsync = ref.watch(myAssessmentPatientIdProvider);
    return idAsync.when(
      data: (patientId) => InitialAssessmentPatientPage(
        role: ProfileRole.patient,
        patientId: patientId,
      ),
      loading: () => const AppScaffold(
        title: 'Como você está hoje?',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const AppScaffold(
        title: 'Como você está hoje?',
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar sua avaliação. Tente novamente mais tarde.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Resolve o `patientId` do paciente logado antes de abrir a Tela 2.
class _MyHistoryEntry extends ConsumerWidget {
  const _MyHistoryEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idAsync = ref.watch(myHistoryPatientIdProvider);
    return idAsync.when(
      data: (patientId) => InitialAssessmentHistoryPage(
        role: ProfileRole.patient,
        patientId: patientId,
      ),
      loading: () => const AppScaffold(
        title: 'Minha História',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const AppScaffold(
        title: 'Minha História',
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar sua história. Tente novamente mais tarde.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}

/// Resolve o `patientId` do paciente logado antes de abrir a Tela 3.
class _MyFamilyEntry extends ConsumerWidget {
  const _MyFamilyEntry();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idAsync = ref.watch(myFamilyPatientIdProvider);
    return idAsync.when(
      data: (patientId) => InitialAssessmentFamilyPage(
        role: ProfileRole.patient,
        patientId: patientId,
      ),
      loading: () => const AppScaffold(
        title: 'Minha Família',
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const AppScaffold(
        title: 'Minha Família',
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Não foi possível carregar sua família. Tente novamente mais tarde.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
