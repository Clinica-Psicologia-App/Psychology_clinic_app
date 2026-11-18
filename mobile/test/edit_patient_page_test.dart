import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:terapia_esquema/core/errors/app_exception.dart';
import 'package:terapia_esquema/features/patients/data/patients_repository.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/domain/update_patient_credentials_request.dart';
import 'package:terapia_esquema/features/patients/domain/psychologist_option.dart';
import 'package:terapia_esquema/features/patients/presentation/edit_patient_page.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

Widget _wrap(Patient patient) {
  return ProviderScope(
    overrides: [
      psychologistsOptionsProvider.overrideWith(
        (ref) async => const <PsychologistOption>[],
      ),
    ],
    child: MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
      home: EditPatientPage(
        patient: patient,
        role: ProfileRole.psychologist,
      ),
    ),
  );
}

void main() {
  testWidgets(
      'abre com valores em português salvos sem lançar exceção de dropdown',
      (tester) async {
    const patient = Patient(
      id: 'p1',
      fullName: 'Maria Silva',
      gender: 'Feminino',
      relationshipStatus: 'Solteiro(a)',
      educationLevel: 'Ensino médio completo',
      sexualOrientation: 'Heterossexual',
      hasChildren: false,
    );

    await tester.pumpWidget(_wrap(patient));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(find.text('Editar paciente'), findsOneWidget);
    // Valor em português é exibido no dropdown (antes quebrava aqui).
    expect(find.text('Feminino'), findsWidgets);
  });

  testWidgets('tolera valor legado fora da lista de opções', (tester) async {
    const patient = Patient(
      id: 'p2',
      fullName: 'João Souza',
      gender: 'valor_legado_desconhecido',
      educationLevel: 'formato antigo qualquer',
    );

    await tester.pumpWidget(_wrap(patient));
    await tester.pump();

    // Não pode quebrar mesmo com valor que não existe entre as opções.
    expect(tester.takeException(), isNull);
    expect(find.text('valor_legado_desconhecido'), findsWidgets);
  });

  group('Acesso do paciente', () {
    const withAccount = Patient(
      id: 'p1',
      fullName: 'Maria Silva',
      email: 'maria@exemplo.com',
      profileId: 'prof1',
    );
    late _FakeRepo repo;

    Future<void> open(
      WidgetTester tester,
      Patient patient, {
      ProfileRole role = ProfileRole.psychologist,
    }) async {
      tester.view.physicalSize = const Size(900, 4000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      repo = _FakeRepo();
      await tester.pumpWidget(_wrapWith(patient, role, repo));
      await tester.pumpAndSettle();
    }

    Finder field(String label) => find.widgetWithText(TextFormField, label);

    testWidgets('psicólogo vê a seção com aviso e campos', (tester) async {
      await open(tester, withAccount);
      expect(find.text('Acesso do paciente'), findsOneWidget);
      expect(find.textContaining('passará a entrar com o novo e-mail'),
          findsOneWidget);
      expect(find.textContaining('continua até sair do app'), findsOneWidget);
      expect(field('E-mail de acesso'), findsOneWidget);
      expect(field('Nova senha'), findsOneWidget);
      expect(field('Confirmar nova senha'), findsOneWidget);
    });

    testWidgets('admin da plataforma também vê; paciente nunca vê',
        (tester) async {
      await open(tester, withAccount, role: ProfileRole.platformAdmin);
      expect(find.text('Acesso do paciente'), findsOneWidget);
      await open(tester, withAccount, role: ProfileRole.patient);
      expect(find.text('Acesso do paciente'), findsNothing);
    });

    testWidgets('sem conta: só o texto do convite, sem campos', (tester) async {
      await open(
          tester, const Patient(id: 'p2', fullName: 'Ana', email: 'a@b.com'));
      expect(
          find.text('Este paciente ainda não aceitou o convite. '
              'Reenvie o convite com o e-mail correto.'),
          findsOneWidget);
      expect(field('E-mail de acesso'), findsNothing);
      expect(field('Nova senha'), findsNothing);
      expect(find.text('Atualizar acesso'), findsNothing);
    });

    testWidgets('exige ao menos um campo', (tester) async {
      await open(tester, withAccount);
      await tester.tap(find.text('Atualizar acesso'));
      await tester.pumpAndSettle();
      expect(find.text('Informe um novo e-mail ou uma nova senha.'),
          findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    testWidgets('valida tamanho e confirmação da senha', (tester) async {
      await open(tester, withAccount);
      await tester.enterText(field('Nova senha'), 'curta');
      await tester.enterText(field('Confirmar nova senha'), 'curta');
      await tester.tap(find.text('Atualizar acesso'));
      await tester.pumpAndSettle();
      expect(
          find.text('A senha deve ter de 8 a 72 caracteres'), findsOneWidget);

      await tester.enterText(field('Nova senha'), 'senha-segura-1');
      await tester.enterText(field('Confirmar nova senha'), 'senha-diferente');
      await tester.tap(find.text('Atualizar acesso'));
      await tester.pumpAndSettle();
      expect(find.text('As senhas não são iguais'), findsOneWidget);
      expect(repo.calls, isEmpty);
    });

    testWidgets('sucesso: envia e-mail novo e senha, limpa as senhas',
        (tester) async {
      await open(tester, withAccount);
      await tester.enterText(field('E-mail de acesso'), '  Novo@Exemplo.com ');
      await tester.enterText(field('Nova senha'), 'senha-segura-1');
      await tester.enterText(field('Confirmar nova senha'), 'senha-segura-1');
      await tester.tap(find.text('Atualizar acesso'));
      await tester.pumpAndSettle();
      expect(repo.calls, hasLength(1));
      expect(repo.calls.single.patientId, 'p1');
      expect(repo.calls.single.email, 'novo@exemplo.com');
      expect(repo.calls.single.password, 'senha-segura-1');
      expect(find.text('Acesso do paciente atualizado.'), findsOneWidget);
      final pass = tester.widget<TextFormField>(field('Nova senha'));
      expect(pass.controller!.text, isEmpty);
      final conf = tester.widget<TextFormField>(field('Confirmar nova senha'));
      expect(conf.controller!.text, isEmpty);
    });

    testWidgets('e-mail igual ao atual não é reenviado', (tester) async {
      await open(tester, withAccount);
      await tester.enterText(field('Nova senha'), 'senha-segura-1');
      await tester.enterText(field('Confirmar nova senha'), 'senha-segura-1');
      await tester.tap(find.text('Atualizar acesso'));
      await tester.pumpAndSettle();
      expect(repo.calls.single.email, isNull);
      expect(repo.calls.single.password, 'senha-segura-1');
    });

    testWidgets('erro 409 aparece como veio e a senha não aparece na tela',
        (tester) async {
      await open(tester, withAccount);
      repo.error = AppException(
          code: AppExceptionCodes.conflict,
          message: 'Este e-mail não pode ser usado.');
      await tester.enterText(field('E-mail de acesso'), 'outro@exemplo.com');
      await tester.enterText(field('Nova senha'), 'senha-segura-1');
      await tester.enterText(field('Confirmar nova senha'), 'senha-segura-1');
      await tester.tap(find.text('Atualizar acesso'));
      await tester.pumpAndSettle();
      expect(find.text('Este e-mail não pode ser usado.'), findsOneWidget);
      expect(find.text('Acesso do paciente atualizado.'), findsNothing);
      expect(
          find.byWidgetPredicate(
              (w) => w is Text && (w.data ?? '').contains('senha-segura-1')),
          findsNothing);
    });
    testWidgets('duas trocas seguidas: A→B e depois B→A', (tester) async {
      await open(tester, withAccount);
      Future<void> troca(String email) async {
        await tester.enterText(field('E-mail de acesso'), email);
        await tester.tap(find.text('Atualizar acesso'));
        await tester.pumpAndSettle();
      }

      await troca('b@exemplo.com');
      await troca('maria@exemplo.com');
      expect(repo.calls.map((c) => c.email),
          ['b@exemplo.com', 'maria@exemplo.com']);
      expect(
          find.text('Informe um novo e-mail ou uma nova senha.'), findsNothing);
    });

    testWidgets('repetição após estado parcial conclui', (tester) async {
      await open(tester, withAccount);
      repo.queue.add(AppException(
          code: AppExceptionCodes.unknown,
          message: 'O login já foi alterado, mas a ficha do paciente não foi '
              'atualizada. Repita o pedido para concluir.'));
      await tester.enterText(field('E-mail de acesso'), 'b@exemplo.com');
      await tester.tap(find.text('Atualizar acesso'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Repita o pedido'), findsOneWidget);

      await tester.tap(find.text('Atualizar acesso'));
      await tester.pumpAndSettle();
      expect(
          repo.calls.map((c) => c.email), ['b@exemplo.com', 'b@exemplo.com']);
      expect(find.text('Acesso do paciente atualizado.'), findsOneWidget);
      expect(find.textContaining('Repita o pedido'), findsNothing);
    });

    testWidgets('sessão expirada (401) mostra a mensagem de sessão',
        (tester) async {
      await open(tester, withAccount);
      repo.error = AppException(
          code: AppExceptionCodes.sessionExpired,
          message: 'Sua sessão expirou. Entre novamente para continuar.');
      await tester.enterText(field('Nova senha'), 'senha-segura-1');
      await tester.enterText(field('Confirmar nova senha'), 'senha-segura-1');
      await tester.tap(find.text('Atualizar acesso'));
      await tester.pumpAndSettle();
      expect(find.text('Sua sessão expirou. Entre novamente para continuar.'),
          findsOneWidget);
    });

    testWidgets('fechar a tela durante o envio não quebra', (tester) async {
      await open(tester, withAccount);
      repo.gate = Completer<void>();
      await tester.enterText(field('Nova senha'), 'senha-segura-1');
      await tester.enterText(field('Confirmar nova senha'), 'senha-segura-1');
      await tester.tap(find.text('Atualizar acesso'));
      await tester.pump();
      expect(repo.calls, hasLength(1));

      // Desmonta a tela enquanto o pedido está em andamento.
      await tester.pumpWidget(const SizedBox());
      repo.gate!.complete();
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}

class _FakeRepo implements PatientsRepository {
  final calls = <UpdatePatientCredentialsRequest>[];

  /// Erros consumidos um a um nas próximas chamadas (null = sucesso).
  final queue = <Object?>[];
  Object? get error => queue.isEmpty ? null : queue.first;
  set error(Object? v) => queue
    ..clear()
    ..add(v);

  /// Se definido, a chamada espera este Completer (envio "em andamento").
  Completer<void>? gate;

  @override
  Future<void> updatePatientCredentials(
      UpdatePatientCredentialsRequest request) async {
    calls.add(request);
    if (gate != null) await gate!.future;
    if (queue.isNotEmpty) {
      final e = queue.removeAt(0);
      if (e != null) throw e;
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Widget _wrapWith(Patient patient, ProfileRole role, PatientsRepository repo) {
  return ProviderScope(
    overrides: [
      patientsRepositoryProvider.overrideWithValue(repo),
      psychologistsOptionsProvider.overrideWith(
        (ref) async => const <PsychologistOption>[],
      ),
    ],
    child: MaterialApp(
      locale: const Locale('pt', 'BR'),
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [Locale('pt', 'BR'), Locale('en')],
      home: EditPatientPage(patient: patient, role: role),
    ),
  );
}
