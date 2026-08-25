import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import '../../questionnaires/providers/questionnaires_providers.dart';
import 'patient_result_details_page.dart';
import 'patient_results_page.dart';
import '../../../shared/widgets/brand_loading.dart';

List<RouteBase> resultsRoutesFor({required ProfileRole role}) {
  return [
    GoRoute(
      path: 'results',
      builder: (context, state) => PatientResultsPage(
        role: role,
        patientId: state.pathParameters['patientId']!,
      ),
      routes: [
        GoRoute(
          path: ':responseId',
          builder: (context, state) => PatientResultDetailsPage(
            role: role,
            patientId: state.pathParameters['patientId']!,
            responseId: state.pathParameters['responseId']!,
          ),
        ),
      ],
    ),
  ];
}

/// Rotas de resultados para o próprio paciente (montadas sob /patient).
/// O patientId é resolvido a partir do perfil autenticado.
List<RouteBase> patientResultsRoutes() {
  return [
    GoRoute(
      path: 'results',
      builder: (context, state) => const _PatientOwnResultsPage(),
      routes: [
        GoRoute(
          path: ':responseId',
          builder: (context, state) => _PatientOwnResultDetailsPage(
            responseId: state.pathParameters['responseId']!,
          ),
        ),
      ],
    ),
  ];
}

const _patientCtx = QuestionnaireListContext(role: ProfileRole.patient);

class _PatientOwnResultsPage extends ConsumerWidget {
  const _PatientOwnResultsPage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientIdAsync =
        ref.watch(questionnairePatientIdProvider(_patientCtx));
    return patientIdAsync.when(
      loading: () =>
          const Scaffold(body: BrandLoader()),
      error: (e, _) => const Scaffold(
        body: Center(child: Text('Não foi possível identificar o paciente.')),
      ),
      data: (patientId) => PatientResultsPage(
        role: ProfileRole.patient,
        patientId: patientId,
      ),
    );
  }
}

class _PatientOwnResultDetailsPage extends ConsumerWidget {
  const _PatientOwnResultDetailsPage({required this.responseId});

  final String responseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientIdAsync =
        ref.watch(questionnairePatientIdProvider(_patientCtx));
    return patientIdAsync.when(
      loading: () =>
          const Scaffold(body: BrandLoader()),
      error: (e, _) => const Scaffold(
        body: Center(child: Text('Não foi possível identificar o paciente.')),
      ),
      data: (patientId) => PatientResultDetailsPage(
        role: ProfileRole.patient,
        patientId: patientId,
        responseId: responseId,
      ),
    );
  }
}
