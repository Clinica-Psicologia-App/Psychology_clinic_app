// Cancelar e reenviar convite pendente, no celular e no desktop. Sem rede: o
// repositório (ou o cliente das funções) é falso.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:terapia_esquema/core/errors/app_exception.dart';
import 'package:terapia_esquema/core/errors/error_mapper.dart';
import 'package:terapia_esquema/features/patient_invitations/data/patient_invitations_repository.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/create_patient_invitation_request.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/created_patient_invitation.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation_status.dart';
import 'package:terapia_esquema/features/patient_invitations/presentation/widgets/invitation_actions.dart';
import 'package:terapia_esquema/features/patient_invitations/providers/patient_invitations_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_shell.dart';

import 'psychologist_desktop_fixtures.dart';

const phone = Size(390, 1400);
const tablet = Size(834, 1112);
const desk = Size(1366, 768);
const sizes = [phone, tablet, desk];

const list = '/psychologist/patient-invitations';
const url = 'https://exemplo.invalid/accept-invitation?token=novo';
const email = 'usuario7@example.com';
const notPending = 'Este convite já foi aceito, expirou ou foi cancelado.';
const cancelQuestion =
    'Cancelar este convite? O link enviado para $email deixa de funcionar.';
const resendQuestion =
    'Reenviar o convite? O link anterior deixa de funcionar e um novo e-mail é enviado para $email.';

class _Repo implements PatientInvitationsRepository {
  _Repo(this.items);

  List<PatientInvitation> items;
  final calls = <String>[];
  final created = <CreatePatientInvitationRequest>[];
  Object? failRevoke;
  Object? failCreate;
  Completer<void>? hold;

  @override
  Future<void> revokeInvitation(String invitationId) async {
    calls.add('revoke $invitationId');
    if (hold != null) await hold!.future;
    if (failRevoke != null) throw failRevoke!;
    items = [
      for (final i in items)
        i.id == invitationId
            ? psiInvitation(
                id: i.id,
                email: i.email,
                fullName: i.fullName,
                status: PatientInvitationStatus.revoked)
            : i,
    ];
  }

  @override
  Future<CreatedPatientInvitation> createInvitation(
      CreatePatientInvitationRequest request) async {
    calls.add('create ${request.email}');
    created.add(request);
    if (failCreate != null) throw failCreate!;
    final invitation = psiInvitation(
        id: 'novo-${created.length}',
        email: request.email,
        fullName: request.fullName);
    items = [invitation, ...items];
    return CreatedPatientInvitation(invitation: invitation, inviteUrl: url);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Pendente completo (nome, telefone e responsável).
PatientInvitation _pending({String id = 'inv-1', String mail = email}) =>
    PatientInvitation(
      id: id,
      email: mail,
      fullName: 'Convidada Fictícia',
      phone: '(11) 90000-0000',
      status: PatientInvitationStatus.pending,
      expiresAt: DateTime(2030, 1, 1),
      createdAt: DateTime(2026, 1, 1),
      invitedById: 'psi-1',
      responsiblePsychologistId: 'psi-1',
    );

List<PatientInvitation> _mixed() => [
      _pending(),
      psiInvitation(
          id: 'a',
          email: 'usuario8@example.com',
          status: PatientInvitationStatus.accepted),
      psiInvitation(
          id: 'e',
          email: 'usuario9@example.com',
          status: PatientInvitationStatus.expired),
      psiInvitation(
          id: 'r',
          email: 'usuario10@example.com',
          status: PatientInvitationStatus.revoked),
    ];

late GoRouter _router;
late _Repo _repo;
late PsiLoads _loads;
final _clipboard = <String>[];

Future<void> _settle(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _pump(
  WidgetTester tester,
  Size size, {
  List<PatientInvitation>? items,
  bool dark = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'coach_seen_tour_home_psicologo': true,
  });
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  desktopAdminMenuCollapsed.value = false;
  _repo = _Repo(items ?? _mixed());
  _loads = PsiLoads();
  _clipboard.clear();
  tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'Clipboard.setData') {
      _clipboard.add((call.arguments as Map)['text'] as String);
    }
    return null;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, null));
  _router = psiRouter('/psychologist');
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(psiApp(_router,
      dark: dark,
      loads: _loads,
      invitations: () async => _repo.items,
      overrides: [
        patientInvitationsRepositoryProvider.overrideWithValue(_repo),
      ]));
  await _settle(tester, 12);
  _router.push(list);
  await _settle(tester, 15);
}

final _menus = find.byType(InvitationMenu);
final _more = find.byIcon(Icons.more_horiz);

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await _settle(tester, 3);
  await tester.tap(target);
  await _settle(tester);
}

/// Abre o menu do primeiro pendente e escolhe [item].
Future<void> _choose(WidgetTester tester, String item) async {
  await _tap(tester, _more.first);
  await tester.tap(find.text(item));
  await _settle(tester);
}

Finder _dialogButton(String label) =>
    find.descendant(of: find.byType(AlertDialog), matching: find.text(label));

Future<void> _confirm(WidgetTester tester, String label) async {
  await tester.tap(_dialogButton(label));
  await _settle(tester, 12);
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

  group('repositório', () {
    late _Functions functions;
    late PatientInvitationsRepository repository;

    setUp(() {
      functions = _Functions();
      repository = PatientInvitationsRepository(client: _Client(functions));
    });

    Future<AppException> failure(
        int status, String code, String message) async {
      functions.failure = FunctionException(status: status, details: {
        'ok': false,
        'error': {'code': code, 'message': message}
      });
      try {
        await repository.revokeInvitation('id-1');
      } on AppException catch (e) {
        return e;
      }
      fail('deveria falhar');
    }

    test('chama revoke-patient-invitation só com o invitation_id', () async {
      functions.response = const FunctionResponse(status: 200, data: {
        'ok': true,
        'data': {'id': 'id-1', 'status': 'revoked'}
      });
      await repository.revokeInvitation('id-1');
      final (name, body, method) = functions.calls.single;
      expect(name, 'revoke-patient-invitation');
      expect(body, {'invitation_id': 'id-1'});
      expect(method, HttpMethod.post);
    });

    test('409 vira a mensagem aprovada, qualquer que seja o motivo', () async {
      for (final reason in [
        'Este convite já foi aceito.',
        'Este convite já expirou.',
        'Este convite já foi cancelado.',
      ]) {
        final e = await failure(409, 'CONFLICT', reason);
        expect(userMessageFor(e), notPending);
      }
    });

    test('404 e 500 seguem o tratamento de sempre', () async {
      final missing =
          await failure(404, 'NOT_FOUND', 'Convite não encontrado.');
      expect(userMessageFor(missing), 'Convite não encontrado.');
      final server = await failure(500, 'INTERNAL_ERROR', 'qualquer');
      expect(userMessageFor(server),
          'Tivemos um problema no servidor. Tente de novo em instantes.');
    });
  });

  test('reenviar só para quem pode criar convite', () {
    expect(canResendInvitation(ProfileRole.psychologist), isTrue);
    expect(canResendInvitation(ProfileRole.platformAdmin), isTrue);
    expect(canResendInvitation(ProfileRole.patient), isFalse);
  });

  testWidgets('sem poder criar, o menu só cancela', (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: InvitationMenu(
                canResend: false,
                busy: false,
                enabled: true,
                onSelected: (_) {}))));
    await tester.tap(_more);
    await tester.pumpAndSettle();
    expect(find.text('Cancelar convite'), findsOneWidget);
    expect(find.text('Reenviar convite'), findsNothing);
  });

  testWidgets('menu só no convite pendente, com as duas ações', (tester) async {
    for (final size in sizes) {
      await _pump(tester, size);
      expect(_menus, findsOneWidget, reason: '$size');
      await _tap(tester, _more);
      expect(find.text('Cancelar convite'), findsOneWidget);
      expect(find.text('Reenviar convite'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('celular: o menu fica sob a etiqueta, sem apertar o texto',
      (tester) async {
    for (final size in const [Size(360, 1400), phone]) {
      await _pump(tester, size, items: [
        _pending(),
        psiInvitation(
            id: 'a',
            email: 'usuario8@example.com',
            status: PatientInvitationStatus.accepted),
      ]);
      // A etiqueta não sai do lugar: o texto tem a largura de sempre.
      expect(tester.getRect(find.text('Pendente')).right,
          tester.getRect(find.text('Aceito')).right,
          reason: '$size');
      final icon = tester.getRect(_more);
      expect(
          icon.top, greaterThan(tester.getRect(find.text('Pendente')).bottom));
      for (final text in [email, 'Expira em 01/01/2030']) {
        expect(icon.overlaps(tester.getRect(find.text(text))), isFalse);
      }
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('Voltar e toque fora não fazem nada', (tester) async {
    for (final size in sizes) {
      await _pump(tester, size);
      for (final (item, question, button) in const [
        ('Cancelar convite', cancelQuestion, 'Cancelar convite'),
        ('Reenviar convite', resendQuestion, 'Reenviar'),
      ]) {
        for (final leave in <Future<void> Function()>[
          () => tester.tap(_dialogButton('Voltar')),
          () => tester.tapAt(const Offset(4, 4)),
        ]) {
          final loads = _loads.invitations;
          await _choose(tester, item);
          expect(find.text(question), findsOneWidget, reason: '$size $item');
          expect(_dialogButton(button), findsOneWidget);
          expect(_dialogButton('Voltar'), findsOneWidget);
          await leave();
          await _settle(tester);
          expect(find.byType(AlertDialog), findsNothing);
          expect(_repo.calls, isEmpty);
          expect(_loads.invitations, loads);
        }
      }
    }
  });

  testWidgets('cancelar: revoga, avisa e recarrega', (tester) async {
    for (final size in sizes) {
      await _pump(tester, size);
      final loads = _loads.invitations;
      await _choose(tester, 'Cancelar convite');
      await _confirm(tester, 'Cancelar convite');
      expect(_repo.calls, ['revoke inv-1']);
      expect(find.text('Convite cancelado.'), findsOneWidget, reason: '$size');
      expect(_loads.invitations, loads + 1);
      expect(find.text('Revogado'), findsNWidgets(2));
      expect(_menus, findsNothing);
      expect(find.text('Convite gerado'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('reenviar: revoga e cria com os mesmos dados; mostra o link',
      (tester) async {
    for (final size in sizes) {
      await _pump(tester, size);
      final loads = _loads.invitations;
      await _choose(tester, 'Reenviar convite');
      await _confirm(tester, 'Reenviar');
      expect(_repo.calls, ['revoke inv-1', 'create $email'], reason: '$size');
      expect(_repo.created.single.toJson(), {
        'email': email,
        'responsible_psychologist_id': 'psi-1',
        'full_name': 'Convidada Fictícia',
        'phone': '(11) 90000-0000',
      });
      expect(find.text('Novo convite enviado.'), findsOneWidget);
      expect(find.text('Convite gerado'), findsOneWidget);
      expect(find.text(url), findsOneWidget);
      expect(_loads.invitations, loads + 1);
      // O novo pendente tem menu; o antigo, não.
      expect(_menus, findsOneWidget);
      expect(_clipboard, isEmpty);
      await _tap(tester, find.text('Copiar link'));
      expect(_clipboard, [url]);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('409: mensagem aprovada, recarrega e não cria', (tester) async {
    for (final size in [phone, desk]) {
      for (final (item, button) in const [
        ('Cancelar convite', 'Cancelar convite'),
        ('Reenviar convite', 'Reenviar'),
      ]) {
        await _pump(tester, size);
        _repo.failRevoke =
            AppException(code: AppExceptionCodes.conflict, message: notPending);
        final loads = _loads.invitations;
        await _choose(tester, item);
        await _confirm(tester, button);
        expect(find.text(notPending), findsOneWidget, reason: '$size $item');
        expect(_repo.calls, ['revoke inv-1']);
        expect(_loads.invitations, loads + 1);
        expect(find.text('Convite gerado'), findsNothing);
      }
    }
  });

  testWidgets('falha de rede ao cancelar: avisa, recarrega e dá para repetir',
      (tester) async {
    await _pump(tester, desk);
    _repo.failRevoke = mapToAppException(Exception('network down'));
    final loads = _loads.invitations;
    await _choose(tester, 'Cancelar convite');
    await _confirm(tester, 'Cancelar convite');
    expect(find.textContaining('sem internet'), findsOneWidget);
    expect(_loads.invitations, loads + 1);
    expect(_menus, findsOneWidget);
    _repo.failRevoke = null;
    await _choose(tester, 'Cancelar convite');
    await _confirm(tester, 'Cancelar convite');
    expect(_menus, findsNothing);
  });

  testWidgets('reenvio que cancela mas não cria: diz as duas coisas',
      (tester) async {
    for (final size in [phone, desk]) {
      await _pump(tester, size);
      _repo.failCreate = AppException(
          code: AppExceptionCodes.conflict,
          message: 'Já existe um convite pendente para este e-mail.');
      final loads = _loads.invitations;
      await _choose(tester, 'Reenviar convite');
      await _confirm(tester, 'Reenviar');
      expect(
          find.text(
              'Convite cancelado. Já existe um convite pendente para este e-mail.'),
          findsOneWidget,
          reason: '$size');
      expect(find.text('Novo convite enviado.'), findsNothing);
      expect(find.text('Convite gerado'), findsNothing);
      expect(_loads.invitations, loads + 1);
      expect(find.text('Revogado'), findsNWidgets(2));
    }
  });

  testWidgets('cancelar o convite do cartão tira o link morto da tela',
      (tester) async {
    for (final size in [phone, desk]) {
      await _pump(tester, size);
      await _choose(tester, 'Reenviar convite');
      await _confirm(tester, 'Reenviar');
      expect(find.text(url), findsOneWidget);
      await _choose(tester, 'Cancelar convite');
      await _confirm(tester, 'Cancelar convite');
      expect(_repo.calls.last, 'revoke novo-1', reason: '$size');
      expect(find.text(url), findsNothing);
    }
  });

  testWidgets('durante a ação: indicador e nenhum outro menu abre',
      (tester) async {
    for (final size in [phone, desk]) {
      await _pump(tester, size, items: [
        _pending(),
        _pending(id: 'inv-2', mail: 'usuario8@example.com'),
      ]);
      _repo.hold = Completer<void>();
      await _choose(tester, 'Cancelar convite');
      await tester.tap(_dialogButton('Cancelar convite'));
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(_more, findsOneWidget);
      await tester.tap(_more, warnIfMissed: false);
      await _settle(tester);
      expect(find.text('Reenviar convite'), findsNothing);
      expect(_repo.calls, ['revoke inv-1']);
      _repo.hold!.complete();
      await _settle(tester, 12);
      await _tap(tester, _more);
      expect(find.text('Reenviar convite'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('sair da tela no meio não impede o reenvio nem a recarga',
      (tester) async {
    await _pump(tester, desk);
    _repo.hold = Completer<void>();
    await _choose(tester, 'Reenviar convite');
    await tester.tap(_dialogButton('Reenviar'));
    await tester.pump(const Duration(milliseconds: 500));
    _router.go('/psychologist');
    await _settle(tester, 12);
    final loads = _loads.invitations;
    _repo.hold!.complete();
    await _settle(tester, 12);
    expect(_repo.calls, ['revoke inv-1', 'create $email']);
    expect(find.text('Novo convite enviado.'), findsOneWidget);
    expect(_loads.invitations, greaterThan(loads));
    expect(tester.takeException(), isNull);
  });

  testWidgets('reenviar do fim de uma lista longa: o cartão aparece',
      (tester) async {
    await _pump(tester, const Size(390, 700), items: [
      for (var i = 0; i < 12; i++)
        psiInvitation(
            id: 'x$i',
            email: 'antigo$i@example.com',
            status: PatientInvitationStatus.accepted),
      _pending(),
    ]);
    await tester.scrollUntilVisible(_more, 300,
        scrollable: find.byType(Scrollable).first);
    await _choose(tester, 'Reenviar convite');
    await _confirm(tester, 'Reenviar');
    expect(find.text('Convite gerado').hitTestable(), findsOneWidget);
  });

  testWidgets('cabe em tela pequena, no escuro e com e-mail comprido',
      (tester) async {
    final long = '${'usuario' * 10}@example.com';
    for (final size in const [Size(320, 640), Size(768, 600), desk]) {
      await _pump(tester, size, dark: true, items: [_pending(mail: long)]);
      await tester.scrollUntilVisible(_more, 200,
          scrollable: find.byType(Scrollable).first);
      await _choose(tester, 'Reenviar convite');
      expect(find.textContaining(long), findsWidgets);
      await tester.tap(_dialogButton('Voltar'));
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('desktop: o menu não aumenta a linha', (tester) async {
    for (final size in [tablet, desk]) {
      await _pump(tester, size, items: [
        _pending(),
        psiInvitation(
            id: 'a',
            email: 'usuario8@example.com',
            status: PatientInvitationStatus.accepted),
      ]);
      double height(String mail) => tester
          .getSize(find
              .ancestor(
                  of: find.text(mail), matching: find.byType(AnimatedContainer))
              .first)
          .height;
      expect(height(email), height('usuario8@example.com'), reason: '$size');
      expect(tester.getRect(_more).right, lessThan(size.width));
    }
  });
}

class _Functions extends FunctionsClient {
  _Functions() : super('https://exemplo.invalid', const {});

  FunctionResponse? response;
  FunctionException? failure;
  final calls = <(String, Object?, HttpMethod)>[];

  @override
  Future<FunctionResponse> invoke(
    String functionName, {
    Map<String, String>? headers,
    Object? body,
    Iterable<MultipartFile>? files,
    Map<String, dynamic>? queryParameters,
    HttpMethod method = HttpMethod.post,
    String? region,
    Future<void>? abortSignal,
  }) async {
    calls.add((functionName, body, method));
    if (failure != null) throw failure!;
    return response!;
  }
}

class _Client implements SupabaseClient {
  _Client(this.functions);

  @override
  final _Functions functions;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
