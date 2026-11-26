// E5 da psicóloga em desktop: Convites a partir de 768 px, com o formulário em
// painel lateral. Validação e envio são comparados com o celular.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terapia_esquema/core/errors/app_exception.dart';
import 'package:terapia_esquema/features/patient_invitations/data/patient_invitations_repository.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/create_patient_invitation_request.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/created_patient_invitation.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation_draft.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation_status.dart';
import 'package:terapia_esquema/features/patient_invitations/presentation/invitation_link.dart';
import 'package:terapia_esquema/features/patient_invitations/presentation/widgets/desktop_invitations_view.dart';
import 'package:terapia_esquema/features/patient_invitations/providers/patient_invitations_providers.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/presentation/patient_details_page.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/shared/widgets/async_state_body.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_kit.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_shell.dart';
import 'package:terapia_esquema/shared/widgets/desktop_psychologist/desktop_form.dart';
import 'package:terapia_esquema/shared/widgets/loading_skeleton.dart';

import 'psychologist_desktop_fixtures.dart';

const desk = Size(1366, 768);
const wide = Size(1920, 1080);
const tablet = Size(834, 1112);
const phone = Size(390, 1400);

const list = '/psychologist/patient-invitations';
const create = '/psychologist/patient-invitations/new';
const patients = '/psychologist/patients';
const file = '/psychologist/patients/p3';
const url = 'https://exemplo.invalid/accept-invitation?token=ficticio';

class _Repo implements PatientInvitationsRepository {
  final created = <CreatePatientInvitationRequest>[];
  Object? fail;
  Completer<void>? hold;
  String link = url;

  @override
  Future<CreatedPatientInvitation> createInvitation(
      CreatePatientInvitationRequest request) async {
    created.add(request);
    if (hold != null) await hold!.future;
    if (fail != null) throw fail!;
    return CreatedPatientInvitation(
      invitation: psiInvitation(id: 'inv-9', email: 'lucia@example.com'),
      inviteUrl: link,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

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
  String location = list,
  Object? extra,
  Future<List<PatientInvitation>> Function()? invitations,
  bool dark = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'coach_seen_tour_home_psicologo': true,
    'coach_seen_tour_pacientes': true,
    'coach_seen_tour_ficha_paciente': true,
  });
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  desktopAdminMenuCollapsed.value = false;
  _repo = _Repo();
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
  _router = psiRouter('/psychologist',
      ficha: (_, __) => const PatientDetailsPage(
          role: ProfileRole.psychologist, patientId: 'p3'));
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(psiApp(_router,
      dark: dark,
      loads: _loads,
      invitations: invitations,
      overrides: [
        patientInvitationsRepositoryProvider.overrideWithValue(_repo),
        patientDetailProvider.overrideWith((ref, id) async =>
            psiMarina(access: PatientAccessStatus.noAppAccess)),
        patientVitalsProvider.overrideWith((ref, id) async => psiVitals),
      ]));
  await _settle(tester, 12);
  _router.push(location, extra: extra);
  await _settle(tester, 15);
}

String _location() =>
    _router.routerDelegate.currentConfiguration.last.matchedLocation;

bool _isDesktop() => find.byType(DaLabeled).evaluate().isNotEmpty;

Finder _field(String label) => _isDesktop()
    ? find.descendant(
        of: find.widgetWithText(DaLabeled, label),
        matching: find.byType(TextFormField))
    : find.widgetWithText(TextFormField, label);

Finder get _panel => find.byWidgetPredicate((w) =>
    w is Container &&
    w.decoration is BoxDecoration &&
    (w.decoration! as BoxDecoration).boxShadow != null &&
    w.constraints?.maxWidth != null &&
    (w.constraints!.maxWidth == 440 || w.constraints!.maxWidth == 500));

Finder get _generate => find.text('Gerar convite');

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await _settle(tester, 2);
  await tester.tap(target);
  await _settle(tester);
}

Future<void> _open(WidgetTester tester) =>
    _tap(tester, find.text('Novo convite'));

Future<void> _fill(WidgetTester tester,
    {String name = '', String email = '', String phoneNumber = ''}) async {
  await tester.enterText(_field('Nome'), name);
  await tester.enterText(_field('E-mail *'), email);
  await tester.enterText(_field('Telefone'), phoneNumber);
  await tester.pump();
}

const _messages = ['Informe o e-mail', 'E-mail inválido', 'Telefone inválido'];

Map<String, int> _errors() => {
      for (final m in _messages) m: find.text(m).evaluate().length,
    };

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

  testWidgets('abaixo de 768 segue a tela do celular; de 768 em diante, tabela',
      (tester) async {
    for (final w in [390.0, 767.0]) {
      await _pump(tester, Size(w, 1400));
      expect(find.byType(DesktopInvitationsView), findsNothing);
      expect(find.text('CONVITES DE PACIENTES'), findsOneWidget);
    }
    for (final size in const [Size(768, 1024), tablet, desk, wide]) {
      await _pump(tester, size);
      expect(find.byType(DesktopInvitationsView), findsOneWidget);
      expect(find.text('CONVITES DE PACIENTES'), findsNothing);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('barra, histórico, colunas, números e linha do convite',
      (tester) async {
    await _pump(tester, desk);
    for (final text in [
      'Convites de pacientes',
      'Novo convite',
      'Histórico de convites',
      'Status dos links enviados pela clínica.',
      'Destinatário',
      'Expira em',
      'Status',
      'Pendentes',
      'Aceitos',
      'Total',
      'Convidada Fictícia',
      'usuario7@example.com',
      '01/01/2030',
      'Pendente',
    ]) {
      expect(find.text(text), findsOneWidget, reason: text);
    }
    expect(find.byTooltip('Atualizar'), findsOneWidget);
    expect(find.textContaining('Responsavel:'), findsNothing);
  });

  testWidgets('cada situação mantém o que o celular informa', (tester) async {
    Future<List<PatientInvitation>> all() async => [
          psiInvitation(responsible: 'Dra. Helena Exemplo'),
          psiInvitation(
              id: 'b',
              email: 'usuario8@example.com',
              status: PatientInvitationStatus.accepted,
              acceptedAt: DateTime(2026, 1, 5, 12)),
          psiInvitation(
              id: 'c',
              email: 'usuario9@example.com',
              fullName: null,
              status: PatientInvitationStatus.expired),
          psiInvitation(
              id: 'd',
              email: 'usuario10@example.com',
              status: PatientInvitationStatus.revoked),
        ];
    const shown = [
      'Responsavel: Dra. Helena Exemplo',
      'Aceito em 05/01/2026',
      'Expirou em 01/01/2030',
      'Convite revogado',
      'Pendente',
      'Aceito',
      'Expirado',
      'Revogado',
    ];
    for (final size in [phone, tablet, desk]) {
      await _pump(tester, size, invitations: all);
      for (final text in shown) {
        expect(find.text(text), findsOneWidget, reason: '$size $text');
      }
      // Sem nome, o e-mail vira o título (e se repete embaixo).
      expect(find.text('usuario9@example.com'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('vazio usa o texto aprovado', (tester) async {
    await _pump(tester, desk, invitations: () async => []);
    expect(find.text('Nenhum convite'), findsOneWidget);
    expect(find.text('Nenhum convite encontrado.'), findsOneWidget);
    expect(find.text('Use "Novo convite" para enviar o primeiro.'),
        findsOneWidget);
    expect(find.textContaining('Toque em'), findsNothing);
  });

  testWidgets('carregando mostra esqueleto; sem números ainda', (tester) async {
    final never = Completer<List<PatientInvitation>>();
    await _pump(tester, desk, invitations: () => never.future);
    expect(find.byType(LoadingSkeleton), findsWidgets);
    expect(find.text('Pendentes'), findsNothing);
    expect(find.text('Destinatário'), findsOneWidget);
  });

  testWidgets('erro mostra a mensagem de hoje e tentar de novo recarrega',
      (tester) async {
    var fail = true;
    await _pump(tester, desk, invitations: () async {
      if (fail) throw StateError('x');
      return [psiInvitation()];
    });
    expect(find.text('Não conseguimos carregar os convites. Tente novamente.'),
        findsOneWidget);
    fail = false;
    await _tap(
        tester,
        find.descendant(
            of: find.byType(ErrorStatePanel),
            matching: find.byWidgetPredicate((w) => w is ButtonStyleButton)));
    expect(find.text('Convidada Fictícia'), findsOneWidget);
  });

  testWidgets('Atualizar recarrega a lista', (tester) async {
    await _pump(tester, desk);
    final before = _loads.invitations;
    await _tap(tester, find.byTooltip('Atualizar'));
    expect(_loads.invitations, before + 1);
  });

  testWidgets('linha sem ação: realce suave, sem mexer e sem cursor de clique',
      (tester) async {
    await _pump(tester, desk);
    final cell = find.text('Convidada Fictícia');
    final row =
        find.ancestor(of: cell, matching: find.byType(AnimatedContainer)).first;
    final box =
        find.descendant(of: row, matching: find.byType(DecoratedBox)).first;
    Color fill() =>
        (tester.widget<DecoratedBox>(box).decoration as BoxDecoration).color!;
    final rest = tester.getRect(cell);
    expect(fill().a, 0);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    addTearDown(mouse.removePointer);
    for (final (to, rising) in [
      (tester.getCenter(row), true),
      (Offset.zero, false)
    ]) {
      await mouse.moveTo(to);
      await tester.pump();
      var last = fill().a;
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(fill().a,
            rising ? greaterThanOrEqualTo(last) : lessThanOrEqualTo(last));
        last = fill().a;
        expect(tester.getRect(cell), rest);
      }
      expect(fill().a, rising ? greaterThan(0) : 0);
      expect(RendererBinding.instance.mouseTracker.debugDeviceActiveCursor(1),
          SystemMouseCursors.basic);
    }
    await tester.tap(cell);
    await _settle(tester);
    expect(_location(), list);
    expect(find.text('Gerar convite'), findsNothing);
  });

  testWidgets('Novo convite abre o painel, sem trocar de tela', (tester) async {
    for (final (size, width) in const [
      (tablet, 440.0),
      (desk, 440.0),
      (wide, 500.0),
    ]) {
      await _pump(tester, size);
      await _open(tester);
      expect(_location(), list);
      expect(tester.getSize(_panel).width, width);
      expect(tester.getTopRight(_panel), Offset(size.width, 0));
      for (final text in [
        'Convidar paciente',
        'Envie um convite para o paciente criar a senha e completar os dados no primeiro acesso.',
        'Senha pelo paciente',
        'Cadastro assistido',
        'Dados do convite',
        'O e-mail é obrigatório. Nome e telefone ajudam na identificação antes do aceite.',
        'Nome',
        'E-mail *',
        'Telefone',
        'Responsável clínico',
        'O convite será vinculado ao psicólogo responsável pelo acompanhamento.',
        'Psicólogo responsável',
        'Gerar convite',
      ]) {
        expect(find.descendant(of: _panel, matching: find.text(text)),
            findsOneWidget,
            reason: '$size $text');
      }
      expect(
          find.descendant(
              of: _panel, matching: find.text('Dra. Helena Exemplo')),
          findsOneWidget);
      // Foco no primeiro campo.
      expect(
          tester
              .widget<EditableText>(find.descendant(
                  of: _field('Nome'), matching: find.byType(EditableText)))
              .focusNode
              .hasFocus,
          isTrue);
      // Botão fixo no pé do painel.
      expect(tester.getBottomRight(_panel).dy - tester.getCenter(_generate).dy,
          lessThan(48));
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });

  testWidgets('Esc, X e clique fora fecham sem enviar', (tester) async {
    await _pump(tester, desk);
    for (final close in <Future<void> Function()>[
      () => tester.sendKeyEvent(LogicalKeyboardKey.escape),
      () => tester.tap(find.byTooltip('Fechar')),
      () => tester.tapAt(const Offset(400, 400)),
    ]) {
      await _open(tester);
      await _fill(tester, email: 'lucia@example.com');
      await close();
      await _settle(tester);
      expect(find.text('Gerar convite'), findsNothing);
      expect(find.byType(DesktopInvitationsView), findsOneWidget);
      expect(_location(), list);
    }
    expect(_repo.created, isEmpty);
    // Reaberto, o formulário vem limpo.
    await _open(tester);
    expect(find.text('lucia@example.com'), findsNothing);
  });

  testWidgets('mesma validação do celular', (tester) async {
    const cases = [
      ('', '', ''),
      ('Lúcia', 'sem-arroba', ''),
      ('', 'lucia@example.com', '123'),
    ];
    for (final (name, email, number) in cases) {
      final results = <Map<String, int>>[];
      for (final size in [phone, desk]) {
        await _pump(tester, size);
        await _open(tester);
        await _fill(tester, name: name, email: email, phoneNumber: number);
        await _tap(tester, _generate);
        results.add(_errors());
        expect(_repo.created, isEmpty);
      }
      expect(results[1], results[0], reason: '$name/$email/$number');
      expect(results[0].values.fold(0, (a, b) => a + b), greaterThan(0));
    }
    await _pump(tester, desk);
    await _open(tester);
    await _tap(tester, _generate);
    expect(find.text('Informe o e-mail'), findsOneWidget);
  });

  testWidgets('envio idêntico ao do celular; mostra e copia o link',
      (tester) async {
    final payloads = <Map<String, dynamic>>[];
    for (final size in [phone, tablet, desk]) {
      await _pump(tester, size);
      await _open(tester);
      await _fill(tester,
          name: '  Lúcia Amostra ',
          email: 'Lucia@Example.com',
          phoneNumber: '11977776666');
      final before = _loads.invitations;
      await _tap(tester, _generate);
      expect(_repo.created, hasLength(1));
      payloads.add(_repo.created.single.toJson());
      expect(_location(), list);
      expect(_generate, findsNothing);
      expect(find.text('Convite gerado'), findsOneWidget, reason: '$size');
      expect(find.text(url), findsOneWidget);
      expect(_clipboard, [url]);
      expect(find.text('Link do convite copiado.'), findsOneWidget);
      expect(_loads.invitations, greaterThan(before));
      await _tap(tester, find.text('Copiar link'));
      expect(_clipboard, [url, url]);
      await _tap(tester, find.byTooltip('Fechar'));
      expect(find.text('Convite gerado'), findsNothing);
      expect(tester.takeException(), isNull, reason: '$size');
    }
    expect(payloads[1], payloads[0]);
    expect(payloads[2], payloads[0]);
    expect(payloads[0], {
      'email': 'lucia@example.com',
      'responsible_psychologist_id': 'psi-1',
      'full_name': 'Lúcia Amostra',
      'phone': '(11) 97777-6666',
    });
  });

  testWidgets('erro do envio: mesma mensagem do celular e nada se perde',
      (tester) async {
    for (final error in <Object>[
      AppException(
          code: AppExceptionCodes.unknown,
          message: 'Convite criado, mas link não retornado.'),
      StateError('x'),
    ]) {
      final texts = <List<String>>[];
      for (final size in [phone, desk]) {
        await _pump(tester, size);
        // O estado de erro do provider não vaza de um aparelho para o outro.
        await _open(tester);
        _repo.fail = error;
        await _fill(tester, email: 'lucia@example.com');
        await _tap(tester, _generate);
        final banner = find.byType(MaterialBanner);
        expect(banner, findsOneWidget, reason: '$size $error');
        texts.add(tester
            .widgetList<Text>(
                find.descendant(of: banner, matching: find.byType(Text)))
            .map((t) => t.data ?? '')
            .toList());
        expect(find.text('lucia@example.com'), findsOneWidget);
        expect(_generate, findsOneWidget);
        // Dá para tentar de novo.
        _repo.fail = null;
        await _tap(tester, _generate);
        expect(find.text('Convite gerado'), findsOneWidget);
      }
      expect(texts[1], texts[0]);
    }
  });

  testWidgets('gerando: botão travado, painel não fecha e o link chega',
      (tester) async {
    await _pump(tester, desk);
    await _open(tester);
    _repo.hold = Completer<void>();
    await _fill(tester, email: 'lucia@example.com');
    await tester.tap(_generate);
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.tap(_generate);
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await _settle(tester);
    await tester.tap(find.byTooltip('Fechar'));
    await _settle(tester);
    await tester.tapAt(const Offset(400, 400));
    await _settle(tester);
    expect(_generate, findsOneWidget);
    expect(_repo.created, hasLength(1));
    _repo.hold!.complete();
    await _settle(tester);
    expect(_generate, findsNothing);
    expect(find.text('Convite gerado'), findsOneWidget);
    expect(find.byType(DesktopInvitationsView), findsOneWidget);
  });

  testWidgets(
      'endereço próprio (Convidar de Pacientes e da ficha): página de desktop',
      (tester) async {
    const draft = PatientInvitationDraft(
      fullName: 'Marina Fictícia',
      email: 'usuario3@example.com',
      phone: '(11) 90000-0000',
      responsiblePsychologistId: 'psi-1',
    );
    final payloads = <Map<String, dynamic>>[];
    for (final size in [phone, desk]) {
      await _pump(tester, size, location: create, extra: draft);
      expect(find.byType(DesktopFormBody),
          size == desk ? findsOneWidget : findsNothing);
      expect(find.text('Marina Fictícia'), findsOneWidget);
      expect(find.text('usuario3@example.com'), findsOneWidget);
      await _tap(tester, _generate);
      payloads.add(_repo.created.single.toJson());
      // Salvou e voltou para quem abriu, como no celular.
      expect(_location(), '/psychologist');
      expect(tester.takeException(), isNull);
    }
    expect(payloads[1], payloads[0]);
  });

  group('convite aberto por Pacientes e pela ficha', () {
    for (final (origin, location, button) in <(String, String, Finder)>[
      ('Pacientes', patients, find.text('Convidar')),
      ('ficha', file, find.byTooltip('Convidar paciente')),
    ]) {
      for (final size in const [Size(390, 1400), desk]) {
        testWidgets('$origin em ${size.width.toInt()}: o link aparece e copia',
            (tester) async {
          await _pump(tester, size, location: location);
          await _tap(tester, button);
          expect(_location(), create);
          if (origin == 'ficha') {
            expect(find.text('usuario3@example.com'), findsOneWidget);
          }
          await tester.enterText(_field('E-mail *'), 'lucia@example.com');
          await _tap(tester, _generate);

          expect(_location(), location);
          expect(_repo.created, hasLength(1));
          expect(find.byType(Dialog), findsOneWidget);
          expect(find.byType(DesktopRecentInvitation),
              size == desk ? findsOneWidget : findsNothing);
          expect(find.byType(RecentInvitationCard),
              size == desk ? findsNothing : findsOneWidget);
          for (final text in [
            'Convite gerado',
            'lucia@example.com',
            url,
            'Copiar link',
            'Link do convite copiado.',
          ]) {
            expect(find.text(text), findsOneWidget, reason: text);
          }
          expect(_clipboard, [url]);
          await _tap(tester, find.text('Copiar link'));
          expect(_clipboard, [url, url]);
          // Um toque fora não perde o link.
          await tester.tapAt(const Offset(4, 4));
          await _settle(tester);
          expect(find.text(url), findsOneWidget);
          await _tap(tester, find.byTooltip('Fechar'));
          expect(find.byType(Dialog), findsNothing);
          expect(_location(), location);
          expect(tester.takeException(), isNull);
        });

        testWidgets(
            '$origin em ${size.width.toInt()}: voltar sem gerar não mostra nada',
            (tester) async {
          await _pump(tester, size, location: location);
          await _tap(tester, button);
          _router.pop();
          await _settle(tester, 12);
          expect(_location(), location);
          expect(find.byType(Dialog), findsNothing);
          expect(_clipboard, isEmpty);
          expect(_repo.created, isEmpty);
          // Dá para abrir de novo.
          await _tap(tester, button);
          expect(_location(), create);
        });
      }
    }

    testWidgets('cartão cabe em celular pequeno e com link comprido',
        (tester) async {
      await _pump(tester, const Size(360, 1400), location: patients);
      _repo.link =
          'https://exemplo.invalid/accept-invitation?token=${'a' * 400}';
      await _tap(tester, find.text('Convidar'));
      await tester.enterText(_field('E-mail *'), 'lucia@example.com');
      await _tap(tester, _generate);
      // Tela baixa, como com o teclado aberto.
      tester.view.physicalSize = const Size(360, 420);
      await _settle(tester);
      expect(find.text('Convite gerado'), findsOneWidget);
      await _tap(tester, find.text('Copiar link'));
      await _tap(tester, find.byTooltip('Fechar'));
      expect(find.byType(Dialog), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('trilha da página leva a Convites', (tester) async {
    await _pump(tester, desk, location: create);
    await tester.tap(find.descendant(
        of: find.byType(DesktopTopBar), matching: find.text('Convites')));
    await _settle(tester, 12);
    expect(_location(), list);
    expect(find.byType(DesktopInvitationsView), findsOneWidget);
  });

  testWidgets('escuro e nomes longos sem estouro', (tester) async {
    for (final size in const [Size(768, 600), Size(1024, 640), desk]) {
      await _pump(tester, size,
          dark: true,
          invitations: () async => [
                psiInvitation(
                    fullName: 'Nome Fictício Muito Comprido ' * 5,
                    email: '${'usuario' * 12}@example.com',
                    responsible: 'Responsável Fictício Comprido ' * 4,
                    status: PatientInvitationStatus.accepted,
                    acceptedAt: DateTime(2026, 1, 5)),
                for (var i = 0; i < 30; i++)
                  psiInvitation(id: 'i$i', email: 'u$i@example.com'),
              ]);
      await _open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await _settle(tester);
      expect(tester.takeException(), isNull, reason: '$size');
    }
  });
}
