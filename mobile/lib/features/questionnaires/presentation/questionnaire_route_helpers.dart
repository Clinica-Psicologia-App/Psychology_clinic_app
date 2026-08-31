import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../profile/domain/profile_role.dart';
import '../domain/finish_questionnaire_result.dart';
import '../domain/questionnaire_session.dart';
import '../domain/questionnaire.dart';
import 'patient_instrument_dashboard_page.dart';
import 'questionnaire_answer_page.dart';
import 'questionnaire_intro_page.dart';
import 'questionnaire_success_page.dart';
import 'questionnaires_page.dart';

List<RouteBase> questionnaireRoutesFor({
  required ProfileRole role,
  String? patientIdPathParam,
}) {
  final nestedPatient = patientIdPathParam != null;

  return [
    GoRoute(
      path: 'questionnaires',
      builder: (context, state) => QuestionnairesPage(
        role: role,
        patientId:
            nestedPatient ? state.pathParameters[patientIdPathParam] : null,
        attachmentOnly: state.extra == 'attachment',
      ),
      routes: [
        GoRoute(
          path: 'intro',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is! QuestionnaireIntroArgs) {
              return const _InvalidSessionPage(
                message: 'Questionário indisponível.',
              );
            }
            return QuestionnaireIntroPage(
              questionnaire: extra.questionnaire,
              patientId: extra.patientId,
              role: role,
              staffPatientId: nestedPatient
                  ? state.pathParameters[patientIdPathParam]
                  : null,
            );
          },
        ),
        GoRoute(
          path: 'dashboard',
          builder: (context, state) {
            final extra = state.extra;
            final pid = nestedPatient
                ? state.pathParameters[patientIdPathParam]
                : null;
            if (extra is! Questionnaire || pid == null) {
              return const _InvalidSessionPage(
                  message: 'Instrumento indisponível.');
            }
            return PatientInstrumentDashboardPage(
              role: role,
              patientId: pid,
              questionnaire: extra,
            );
          },
        ),
        GoRoute(
          path: 'answer',
          builder: (context, state) {
            final session = state.extra;
            if (session is! QuestionnaireSession) {
              return const _InvalidSessionPage();
            }
            return QuestionnaireAnswerPage(
              session: session,
              role: role,
              patientId: nestedPatient
                  ? state.pathParameters[patientIdPathParam]
                  : null,
            );
          },
        ),
        GoRoute(
          path: 'success',
          builder: (context, state) {
            final result = state.extra;
            if (result is! FinishQuestionnaireResult) {
              return const _InvalidSessionPage(
                  message: 'Resultado indisponível.');
            }
            return QuestionnaireSuccessPage(
              result: result,
              role: role,
              patientId: nestedPatient
                  ? state.pathParameters[patientIdPathParam]
                  : null,
            );
          },
        ),
      ],
    ),
  ];
}

class QuestionnaireIntroArgs {
  const QuestionnaireIntroArgs({
    required this.questionnaire,
    required this.patientId,
  });

  final Questionnaire questionnaire;
  final String patientId;
}

class _InvalidSessionPage extends StatelessWidget {
  const _InvalidSessionPage({this.message = 'Sessão inválida.'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(child: Text(message)),
    );
  }
}
