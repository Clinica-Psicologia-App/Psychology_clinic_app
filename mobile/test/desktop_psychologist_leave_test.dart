// Sair de uma tela pelo menu lateral da psicóloga (>= 768 px). Formulário sem
// confirmação hoje continua sem; numa tela com confirmação de descarte o menu
// pergunta e, aceita a saída, vai ao destino num toque só.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terapia_esquema/features/mental_map/data/case_conceptualization_repository.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/mental_map/domain/demands_text_history.dart';
import 'package:terapia_esquema/features/mental_map/providers/case_conceptualization_providers.dart';
import 'package:terapia_esquema/features/patient_invitations/presentation/create_patient_invitation_page.dart';
import 'package:terapia_esquema/features/patient_problems/domain/patient_problem.dart';
import 'package:terapia_esquema/features/patient_problems/providers/patient_problems_providers.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/domain/psychologist_option.dart';
import 'package:terapia_esquema/features/patients/presentation/create_patient_page.dart';
import 'package:terapia_esquema/features/patients/presentation/edit_patient_page.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/questionnaires/domain/question_answer_type.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_question.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_session.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/questionnaire_answer_page.dart';
import 'package:terapia_esquema/features/therapy_demands/presentation/therapy_demands_page.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_shell.dart';
import 'package:terapia_esquema/shared/widgets/desktop_psychologist/desktop_psychologist_menu.dart';

import 'psychologist_desktop_fixtures.dart';

const desk = Size(1366, 768);
const tablet = Size(834, 1112);
const phone = Size(390, 844);

class _Repo implements CaseConceptualizationRepository {
  @override
  Future<CaseConceptualization> load(String patientId) async =>
      CaseConceptualization(
        unmetNeeds: const [],
        modeSequences: const [],
        relationship: const TherapeuticRelationship(),
        motivoInitial: 'motivo fictício',
        updatedAt: DateTime(2026, 10, 22, 10, 30),
      );

  @override
  Future<DemandsTextHistory> loadDemandsHistory(String patientId) async =>
      DemandsTextHistory.empty;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _marina = Patient(
    id: 'p3', fullName: 'Marina Exemplo', email: 'usuario3@example.com');

const _session = QuestionnaireSession(
  responseId: 'resposta-ficticia',
  patientId: 'p3',
  questionnaire: Questionnaire(
      id: 'q1', code: 'Q1', name: 'Instrumento fictício', isActive: true),
  questions: [
    QuestionnaireQuestion(
      id: 'pergunta-1',
      code: 'P1',
      text: 'Pergunta fictícia',
      orderIndex: 0,
      answerType: QuestionAnswerType.likertScale,
      scaleMin: 1,
      scaleMax: 5,
    ),
  ],
);

late GoRouter _router;

Future<void> _pump(WidgetTester tester, Size size, String location) async {
  SharedPreferences.setMockInitialValues(
      {'coach_seen_tour_home_psicologo': true});
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  desktopAdminMenuCollapsed.value = false;
  _router = psiRouter(
    '/psychologist',
    newPatient: (_, __) =>
        const CreatePatientPage(role: ProfileRole.psychologist),
    newInvitation: (_, __) =>
        const CreatePatientInvitationPage(role: ProfileRole.psychologist),
    patientRoutes: [
      GoRoute(
          path: 'edit',
          builder: (_, __) => const EditPatientPage(
              patient: _marina, role: ProfileRole.psychologist)),
      GoRoute(
          path: 'therapy-demands',
          builder: (_, __) => const TherapyDemandsPage(
              role: ProfileRole.psychologist, patientId: 'p3')),
      GoRoute(
          path: 'questionnaires/answer',
          builder: (_, __) => const QuestionnaireAnswerPage(
              session: _session,
              role: ProfileRole.psychologist,
              patientId: 'p3')),
      // Tela que trava o voltar sem dizer como perguntar.
      GoRoute(
          path: 'locked',
          builder: (_, __) => const PopScope(
              canPop: false, child: Scaffold(body: Text('Tela travada')))),
    ],
  );
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(psiApp(_router, overrides: [
    psychologistsOptionsProvider
        .overrideWith((ref) async => <PsychologistOption>[]),
    patientDetailProvider.overrideWith((ref, id) async => null),
    caseConceptualizationRepositoryProvider.overrideWithValue(_Repo()),
    staffPatientProblemsProvider
        .overrideWith((ref, ctx) async => <PatientProblem>[]),
    therapyDemandsAuthorNameProvider.overrideWithValue('Dra. Helena Exemplo'),
  ]));
  await _settle(tester, 12);
  _router.push(location);
  await _settle(tester, 12);
}

Future<void> _settle(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _location() =>
    _router.routerDelegate.currentConfiguration.last.matchedLocation;

Finder _menuItem(String label) {
  Finder inMenu(Finder f) => find.descendant(
      of: find.byType(DesktopPsychologistMenu), matching: f);
  // No trilho do tablet a ação principal é só o ícone, com dica.
  final text = inMenu(find.text(label));
  return text.evaluate().isEmpty ? inMenu(find.byTooltip(label)) : text;
}

/// Escreve no primeiro campo da tela aberta.
Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField).hitTestable().first, text);
  await _settle(tester, 3);
}

void main() {
  setUpAll(() async {
    for (final f in ['Poppins-Regular.ttf', 'Poppins-Bold.ttf']) {
      final file = File('assets/fonts/$f');
      if (file.existsSync()) {
        await ui.loadFontFromList(file.readAsBytesSync(),
            fontFamily: 'Poppins');
      }
    }
  });

  // ── Os três formulários: hoje não há confirmação de descarte ─────────────
  for (final (name, route) in const [
    ('cadastrar paciente', '/psychologist/patients/new'),
    ('editar paciente', '/psychologist/patients/p3/edit'),
    ('novo convite', '/psychologist/patient-invitations/new'),
  ]) {
    testWidgets('$name: no celular o voltar sai sem confirmação (hoje)',
        (tester) async {
      await _pump(tester, phone, route);
      await _type(tester, 'Texto Fictício');
      await tester.binding.handlePopRoute();
      await _settle(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.text('Texto Fictício'), findsNothing);
      expect(_location(), isNot(route));
    });

    testWidgets('$name: no desktop o menu também sai sem confirmação',
        (tester) async {
      await _pump(tester, desk, route);
      await _type(tester, 'Texto Fictício');
      await tester.tap(_menuItem('Questionários'));
      await _settle(tester);
      expect(find.byType(AlertDialog), findsNothing);
      expect(_location(), '/psychologist/questionnaires');
      expect(tester.takeException(), isNull);
    });
  }

  // ── Tela com confirmação de descarte (Demandas Terapêuticas) ─────────────
  const demands = '/psychologist/patients/p3/therapy-demands';

  testWidgets('demandas: no celular o voltar pede confirmação (hoje)',
      (tester) async {
    await _pump(tester, phone, demands);
    await _type(tester, 'rascunho fictício');
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.byKey(const Key('demands_discard')), findsOneWidget);
    expect(_location(), demands);
  });

  for (final size in const [desk, tablet]) {
    testWidgets(
        'demandas: cancelar fica; confirmar vai ao destino num toque '
        '(${size.width.toInt()})', (tester) async {
      await _pump(tester, size, demands);
      await _type(tester, 'rascunho fictício');

      await tester.tap(_menuItem('Convites'));
      await _settle(tester);
      expect(find.byKey(const Key('demands_discard')), findsOneWidget);
      expect(_location(), demands);

      // Continuar editando: nada se perde e nada navega depois.
      await tester.tap(find.text('Continuar editando'));
      await _settle(tester);
      expect(_location(), demands);
      expect(find.text('rascunho fictício'), findsOneWidget);

      await tester.tap(_menuItem('Convites'));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('demands_discard')));
      await _settle(tester);
      expect(_location(), '/psychologist/patient-invitations');
      expect(find.byType(TherapyDemandsPage, skipOffstage: false),
          findsNothing);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('demandas: Início e "Novo paciente" também vão num toque',
      (tester) async {
    for (final (label, destination) in const [
      ('Início', '/psychologist'),
      ('Novo paciente', '/psychologist/patients/new'),
    ]) {
      await _pump(tester, desk, demands);
      await _type(tester, 'rascunho fictício');
      await tester.tap(_menuItem(label));
      await _settle(tester);
      await tester.tap(find.text('Continuar editando'));
      await _settle(tester);
      expect(_location(), demands, reason: label);
      await tester.tap(_menuItem(label));
      await _settle(tester);
      await tester.tap(find.byKey(const Key('demands_discard')));
      await _settle(tester);
      expect(_location(), destination, reason: label);
      // Saiu de verdade: a tela descartada não fica por baixo.
      expect(find.byType(TherapyDemandsPage, skipOffstage: false),
          findsNothing,
          reason: label);
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  // ── Responder questionário (trava o voltar mesmo sem resposta) ───────────
  const answer = '/psychologist/patients/p3/questionnaires/answer';
  const leaveTitle = 'Sair do questionário?';

  Future<void> choose(WidgetTester tester) async {
    await tester.tap(find.descendant(
        of: find.byType(QuestionnaireAnswerPage), matching: find.text('4')));
    await _settle(tester, 3);
  }

  testWidgets('questionário: voltar do celular como hoje', (tester) async {
    await _pump(tester, phone, answer);
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.text(leaveTitle), findsNothing);
    expect(find.byType(QuestionnaireAnswerPage), findsNothing);
    expect(_location(), '/psychologist');

    await _pump(tester, phone, answer);
    await choose(tester);
    await tester.binding.handlePopRoute();
    await _settle(tester);
    expect(find.text(leaveTitle), findsOneWidget);
    await tester.tap(find.text('Continuar'));
    await _settle(tester);
    expect(_location(), answer);
    await tester.binding.handlePopRoute();
    await _settle(tester);
    await tester.tap(find.text('Sair'));
    await _settle(tester);
    expect(_location(), '/psychologist');
  });

  for (final size in const [desk, tablet]) {
    testWidgets(
        'questionário sem resposta pendente: um toque chega ao destino '
        '(${size.width.toInt()})', (tester) async {
      for (final (label, destination) in const [
        ('Convites', '/psychologist/patient-invitations'),
        ('Pacientes', '/psychologist/patients'),
        ('Novo paciente', '/psychologist/patients/new'),
      ]) {
        await _pump(tester, size, answer);
        await tester.tap(_menuItem(label));
        await _settle(tester);
        expect(find.byType(AlertDialog), findsNothing, reason: label);
        expect(_location(), destination, reason: label);
        expect(find.byType(QuestionnaireAnswerPage, skipOffstage: false),
            findsNothing,
            reason: label);
        expect(tester.takeException(), isNull, reason: label);
      }
    });
  }

  testWidgets('questionário com resposta: cancelar fica; confirmar vai',
      (tester) async {
    for (final (label, destination) in const [
      ('Questionários', '/psychologist/questionnaires'),
      ('Novo paciente', '/psychologist/patients/new'),
    ]) {
      await _pump(tester, desk, answer);
      await choose(tester);
      await tester.tap(_menuItem(label));
      await _settle(tester);
      expect(find.text(leaveTitle), findsOneWidget, reason: label);
      await tester.tap(find.text('Continuar'));
      await _settle(tester);
      expect(_location(), answer, reason: label);
      // A resposta continua pendente: pergunta de novo.
      await tester.tap(_menuItem(label));
      await _settle(tester);
      expect(find.text(leaveTitle), findsOneWidget, reason: label);
      await tester.tap(find.text('Sair'));
      await _settle(tester);
      expect(_location(), destination, reason: label);
      expect(find.byType(QuestionnaireAnswerPage, skipOffstage: false),
          findsNothing,
          reason: label);
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('tela que trava o voltar sem pergunta: o menu não descarta',
      (tester) async {
    await _pump(tester, desk, '/psychologist/patients/p3/locked');
    await tester.tap(_menuItem('Convites'));
    await _settle(tester);
    expect(find.text('Tela travada'), findsOneWidget);
    expect(_location(), '/psychologist/patients/p3/locked');
  });

  testWidgets('demandas sem alteração: o menu navega direto', (tester) async {
    await _pump(tester, desk, demands);
    await tester.tap(_menuItem('Convites'));
    await _settle(tester);
    expect(find.byType(AlertDialog), findsNothing);
    expect(_location(), '/psychologist/patient-invitations');
  });
}
