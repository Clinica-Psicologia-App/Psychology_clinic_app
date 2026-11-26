// E4 da psicóloga em desktop: cadastrar, editar e dados cadastrais a partir de
// 768 px. Validação e salvamento são comparados com o celular.
import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:terapia_esquema/core/errors/app_exception.dart';
import 'package:terapia_esquema/features/patients/data/patients_repository.dart';
import 'package:terapia_esquema/features/patients/domain/create_patient_request.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/domain/psychologist_option.dart';
import 'package:terapia_esquema/features/patients/domain/update_patient_credentials_request.dart';
import 'package:terapia_esquema/features/patients/domain/update_patient_request.dart';
import 'package:terapia_esquema/features/patients/presentation/edit_patient_page.dart';
import 'package:terapia_esquema/features/patients/presentation/patient_registration_page.dart';
import 'package:terapia_esquema/features/patients/presentation/widgets/patient_registration_widgets.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_kit.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_shell.dart';
import 'package:terapia_esquema/shared/widgets/desktop_psychologist/desktop_form.dart';
import 'package:terapia_esquema/shared/widgets/desktop_psychologist/desktop_psychologist_menu.dart';

import 'psychologist_desktop_fixtures.dart';

const desk = Size(1366, 768);
const wide = Size(1920, 1080);
const tablet = Size(834, 1112);
/// Celular alto: o formulário inteiro fica montado.
const phone = Size(390, 5000);

const create = '/psychologist/patients/new';
const edit = '/psychologist/patients/p3/edit';
const registration = '/psychologist/patients/p3/registration';

class _Repo implements PatientsRepository {
  final created = <CreatePatientRequest>[];
  final updated = <UpdatePatientRequest>[];
  final credentials = <UpdatePatientCredentialsRequest>[];
  final status = <(String, bool)>[];
  Object? fail;
  Completer<void>? hold;

  Future<void> _gate() async {
    if (hold != null) await hold!.future;
    if (fail != null) throw fail!;
  }

  @override
  Future<Patient> createPatient(CreatePatientRequest request) async {
    created.add(request);
    await _gate();
    return Patient(id: 'p9', fullName: request.fullName.trim());
  }

  @override
  Future<Patient> updatePatient(UpdatePatientRequest request) async {
    updated.add(request);
    await _gate();
    return psiMarinaCompleta();
  }

  @override
  Future<void> updatePatientCredentials(
      UpdatePatientCredentialsRequest request) async {
    credentials.add(request);
    await _gate();
  }

  @override
  Future<Patient> setPatientActiveStatus({
    required String patientId,
    required bool isActive,
  }) async {
    status.add((patientId, isActive));
    await _gate();
    return psiMarinaCompleta(active: isActive);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

late GoRouter _router;
late _Repo _repo;

Future<void> _pump(
  WidgetTester tester,
  Size size,
  String location, {
  Patient? patient,
  Patient? Function()? detail,
  Future<List<PsychologistOption>> Function()? psychologists,
  bool dark = false,
}) async {
  SharedPreferences.setMockInitialValues({
    'coach_seen_tour_home_psicologo': true,
    'coach_seen_tour_ficha_paciente': true,
  });
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  desktopAdminMenuCollapsed.value = false;
  _repo = _Repo();
  final marina = patient ?? psiMarinaCompleta();
  _router = psiRouter('/psychologist', patientRoutes: [
    GoRoute(
        path: 'edit',
        builder: (_, state) => EditPatientPage(
            patient: state.extra as Patient? ?? marina,
            role: ProfileRole.psychologist)),
    GoRoute(
        path: 'registration',
        builder: (_, __) => const PatientRegistrationPage(
            role: ProfileRole.psychologist, patientId: 'p3')),
  ]);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(psiApp(_router, dark: dark, overrides: [
    patientsRepositoryProvider.overrideWithValue(_repo),
    psychologistsOptionsProvider.overrideWith((ref) => psychologists == null
        ? Future.value(psiPsychologists)
        : psychologists()),
    patientDetailProvider.overrideWith(
        (ref, id) async => detail == null ? marina : detail()),
  ]));
  await _settle(tester, 12);
  // Empilhada, como no app: salvar e voltar têm para onde ir.
  _router.push(location);
  await _settle(tester, 15);
}

Future<void> _settle(WidgetTester tester, [int n = 8]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

String _location() =>
    _router.routerDelegate.currentConfiguration.last.matchedLocation;

bool _isDesktop() => find.byType(DesktopFormBody).evaluate().isNotEmpty;

/// O campo de [label], com rótulo dentro (celular) ou acima (desktop).
Finder _field(String label, [Type type = TextFormField]) {
  if (_isDesktop()) {
    return find.descendant(
        of: find.widgetWithText(DaLabeled, label), matching: find.byType(type));
  }
  return find.widgetWithText(type, label);
}

Finder _dropdown(String label, [bool boolean = false]) => _field(
    label,
    boolean
        ? DropdownButtonFormField<bool>
        : DropdownButtonFormField<String>);

Future<void> _type(WidgetTester tester, String label, String text) async {
  await tester.ensureVisible(_field(label));
  await tester.enterText(_field(label), text);
  await tester.pump();
}

Future<void> _choose(WidgetTester tester, String label, String option,
    {bool boolean = false}) async {
  final target = _dropdown(label, boolean);
  await tester.ensureVisible(target);
  await _settle(tester, 2);
  await tester.tap(target);
  await _settle(tester);
  await tester.tap(find.text(option).last);
  await _settle(tester);
}

Future<void> _tap(WidgetTester tester, Finder target) async {
  await tester.ensureVisible(target);
  await _settle(tester, 2);
  await tester.tap(target);
  await _settle(tester);
}

Future<void> _expand(WidgetTester tester) =>
    _tap(tester, find.textContaining('Expandir'));

const _createMessages = [
  'Informe o nome',
  'Informe o e-mail',
  'E-mail inválido',
  'Senha com pelo menos 8 caracteres',
  'As senhas não coincidem',
  'Telefone inválido',
  'CPF deve ter 11 dígitos',
];

Map<String, int> _errors(List<String> messages) => {
      for (final m in messages) m: find.text(m).evaluate().length,
    };

const _profile = [
  'Gênero',
  'Data de nascimento',
  'Telefone',
  'CPF',
  'Estado civil',
  'Escolaridade',
  'Ocupação',
  'Estado de nascimento',
  'País de nascimento',
  'Orientação religiosa',
  'Grupo étnico',
  'Orientação sexual',
  'Possui filhos?',
];

Future<Map<String, dynamic>> _fillAndCreate(WidgetTester tester) async {
  await _type(tester, 'Nome completo *', '  Paciente Fictícia  ');
  await _type(tester, 'E-mail de login *', 'Usuario9@Example.com');
  await _type(tester, 'Senha inicial *', 'senha-ficticia');
  await _type(tester, 'Confirmar senha *', 'senha-ficticia');
  await _expand(tester);
  await _choose(tester, 'Gênero', 'Feminino');
  await _tap(tester, find.byIcon(Icons.calendar_today_outlined));
  await _tap(tester, find.text('OK'));
  await _type(tester, 'Telefone', '11999990000');
  await _type(tester, 'CPF', '12345678909');
  await _choose(tester, 'Estado civil', 'Solteiro(a)');
  await _choose(tester, 'Escolaridade', 'Pós-graduação');
  for (final (label, value) in const [
    ('Ocupação', 'Designer'),
    ('Estado de nascimento', 'Estado Fictício'),
    ('País de nascimento', 'Brasil'),
    ('Orientação religiosa', 'Não informada'),
    ('Grupo étnico', 'Não informado'),
    ('Orientação sexual', 'Texto livre fictício'),
  ]) {
    await _type(tester, label, value);
  }
  await _choose(tester, 'Possui filhos?', 'Não');
  await _tap(tester, find.text('Cadastrar paciente'));
  expect(find.text('Paciente cadastrado'), findsOneWidget);
  expect(find.text('Paciente Fictícia foi criado com sucesso.'),
      findsOneWidget);
  await _tap(tester, find.text('OK'));
  return _repo.created.single.toJson();
}

const _editTexts = [
  'Nome completo *',
  'Telefone',
  'Ocupação',
  'Estado de nascimento',
  'País de nascimento',
  'Orientação religiosa',
  'Grupo étnico',
];

const _editChoices = [
  'Gênero',
  'Estado civil',
  'Escolaridade',
  'Orientação sexual',
];

/// O que o formulário de edição mostra.
Map<String, Object?> _editValues(WidgetTester tester) => {
      for (final label in _editTexts)
        label: tester
            .widget<EditableText>(find.descendant(
                of: _field(label), matching: find.byType(EditableText)))
            .controller
            .text,
      for (final label in _editChoices)
        label: tester
            .state<FormFieldState<String>>(_dropdown(label))
            .value,
      'Filhos':
          tester.state<FormFieldState<bool>>(_dropdown('Filhos', true)).value,
      'Psicólogo responsável': tester
          .state<FormFieldState<String>>(_dropdown('Psicólogo responsável'))
          .value,
      'nascimento':
          find.text('domingo, 12 de abril de 1992').evaluate().length,
    };

Future<Map<String, dynamic>> _changeAndSave(WidgetTester tester) async {
  await _type(tester, 'Nome completo *', '  Marina Alterada Fictícia ');
  await _type(tester, 'Telefone', '11888880000');
  await _tap(tester, find.byIcon(Icons.calendar_today_outlined));
  await _tap(tester, find.text('OK'));
  await _choose(tester, 'Gênero', 'Outro');
  await _choose(tester, 'Estado civil', 'Casado(a)');
  await _choose(tester, 'Escolaridade', 'Ensino médio');
  await _type(tester, 'Ocupação', '');
  await _type(tester, 'País de nascimento', 'País Fictício');
  await _choose(tester, 'Orientação sexual', 'Não informado');
  await _choose(tester, 'Filhos', 'Sim', boolean: true);
  await _choose(tester, 'Psicólogo responsável', 'Dr. Paulo Modelo');
  await _tap(tester, find.text('Salvar alterações'));
  return _repo.updated.single.toJson();
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

  group('Novo paciente', () {
    testWidgets('blocos, 2 colunas e ação parada no pé', (tester) async {
      await _pump(tester, desk, create);
      expect(_isDesktop(), isTrue);
      expect(find.byType(AppBar), findsNothing);
      for (final text in [
        'Essencial',
        'obrigatório',
        'Perfil clínico',
        'opcional',
        'Expandir',
        'Responsável',
        'Psicólogo responsável',
        'Mínimo 8 caracteres',
        'Cadastrar paciente',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      final name = tester.getTopLeft(find.text('Nome completo *'));
      final email = tester.getTopLeft(find.text('E-mail de login *'));
      expect(email.dy, name.dy);
      expect(email.dx, greaterThan(name.dx + 300));
      // Rótulo acima do campo.
      expect(tester.getTopLeft(_field('Nome completo *')).dy,
          greaterThan(name.dy));
      for (final label in _profile) {
        expect(find.text(label), findsNothing, reason: label);
      }

      final button = tester.getRect(find.text('Cadastrar paciente'));
      expect(button.bottom, greaterThan(desk.height - 40));
      await _expand(tester);
      final positions = [
        for (final label in _profile) tester.getTopLeft(find.text(label)),
      ];
      // Mesma ordem do celular, dois por linha.
      for (var i = 1; i < positions.length; i++) {
        if (i.isOdd) {
          expect(positions[i].dx, greaterThan(positions[i - 1].dx),
              reason: _profile[i]);
        } else {
          expect(positions[i].dy, greaterThan(positions[i - 1].dy),
              reason: _profile[i]);
        }
      }
      // Rolar não move a ação.
      await tester.drag(
          find.text('Essencial'), const Offset(0, -2000));
      await _settle(tester);
      expect(tester.getRect(find.text('Cadastrar paciente')), button);
      await _tap(tester, find.text('Recolher'));
      expect(find.text('CPF'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet: uma coluna', (tester) async {
      await _pump(tester, tablet, create);
      expect(tester.getTopLeft(find.text('E-mail de login *')).dy,
          greaterThan(tester.getTopLeft(find.text('Nome completo *')).dy));
    });

    testWidgets('olhos mostram e escondem as senhas', (tester) async {
      await _pump(tester, desk, create);
      bool hidden(String label) => tester
          .widget<EditableText>(find.descendant(
              of: _field(label), matching: find.byType(EditableText)))
          .obscureText;
      expect(hidden('Senha inicial *'), isTrue);
      await _tap(tester, find.byIcon(Icons.visibility_off_outlined).first);
      expect(hidden('Senha inicial *'), isFalse);
      expect(hidden('Confirmar senha *'), isTrue);
    });

    testWidgets('mesmas validações do celular', (tester) async {
      Future<List<Map<String, int>>> run(Size size) async {
        await _pump(tester, size, create);
        final result = <Map<String, int>>[];
        await _expand(tester);
        await _tap(tester, find.text('Cadastrar paciente'));
        result.add(_errors(_createMessages));
        await _type(tester, 'Nome completo *', 'Pessoa Fictícia');
        await _type(tester, 'E-mail de login *', 'sem-arroba');
        await _type(tester, 'Senha inicial *', '123');
        await _type(tester, 'Confirmar senha *', '1234');
        await _type(tester, 'Telefone', '123');
        await _type(tester, 'CPF', '123');
        await _tap(tester, find.text('Cadastrar paciente'));
        result.add(_errors(_createMessages));
        expect(_repo.created, isEmpty);
        return result;
      }

      final mobile = await run(phone);
      final desktop = await run(desk);
      expect(desktop, mobile);
      expect(mobile.first['Informe o nome'], 1);
      expect(mobile.last['CPF deve ter 11 dígitos'], 1);
      expect(mobile.last['Telefone inválido'], 1);
      expect(mobile.last['E-mail inválido'], 1);
    });

    testWidgets('perfil fechado não é validado, como no celular',
        (tester) async {
      for (final size in [phone, desk]) {
        await _pump(tester, size, create);
        await _expand(tester);
        await _type(tester, 'CPF', '1');
        // (o menu lateral tem "Recolher menu")
        await _tap(
            tester, find.textContaining(RegExp(r'^Recolher($| ↑)')));
        await _type(tester, 'Nome completo *', 'Pessoa Fictícia');
        await _type(tester, 'E-mail de login *', 'usuario9@example.com');
        await _type(tester, 'Senha inicial *', 'senha-ficticia');
        await _type(tester, 'Confirmar senha *', 'senha-ficticia');
        await _tap(tester, find.text('Cadastrar paciente'));
        expect(_repo.created, hasLength(1), reason: '$size');
      }
    });

    testWidgets('salva exatamente os mesmos dados do celular', (tester) async {
      await _pump(tester, phone, create);
      final mobile = await _fillAndCreate(tester);
      expect(_location(), '/psychologist/patients/p9');

      await _pump(tester, desk, create);
      final desktop = await _fillAndCreate(tester);
      expect(_location(), '/psychologist/patients/p9');
      expect(desktop, mobile);
      expect(desktop.keys, hasLength(17));
      expect(desktop['responsible_psychologist_id'], 'psi-1');
      expect(desktop['sexual_orientation'], 'Texto livre fictício');
      expect(tester.takeException(), isNull);
    });

    testWidgets('Enter em "Confirmar senha" cadastra; sem envio duplo',
        (tester) async {
      await _pump(tester, desk, create);
      _repo.hold = Completer<void>();
      await _type(tester, 'Nome completo *', 'Pessoa Fictícia');
      await _type(tester, 'E-mail de login *', 'usuario9@example.com');
      await _type(tester, 'Senha inicial *', 'senha-ficticia');
      await _type(tester, 'Confirmar senha *', 'senha-ficticia');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(_repo.created, hasLength(1));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.text('Cadastrar paciente'));
      await tester.pump();
      expect(_repo.created, hasLength(1));
      _repo.hold!.complete();
      await _settle(tester);
      expect(find.text('Paciente cadastrado'), findsOneWidget);
    });

    testWidgets('erro ao cadastrar: mesma faixa e continua na tela',
        (tester) async {
      await _pump(tester, desk, create);
      _repo.fail =
          AppException(code: 'ficticio', message: 'Falha fictícia.');
      await _type(tester, 'Nome completo *', 'Pessoa Fictícia');
      await _type(tester, 'E-mail de login *', 'usuario9@example.com');
      await _type(tester, 'Senha inicial *', 'senha-ficticia');
      await _type(tester, 'Confirmar senha *', 'senha-ficticia');
      await _tap(tester, find.text('Cadastrar paciente'));
      expect(find.byType(MaterialBanner), findsOneWidget);
      expect(_location(), create);
      await tester.pump(const Duration(seconds: 6));
      await _settle(tester);
      await _tap(tester, find.text('Cadastrar paciente'));
      expect(_repo.created, hasLength(2));
      await tester.pump(const Duration(seconds: 6));
    });
  });

  group('Editar paciente', () {
    testWidgets('barra, selos, índice, seções e ação no pé', (tester) async {
      await _pump(tester, desk, edit);
      expect(_isDesktop(), isTrue);
      for (final text in [
        'Editar paciente',
        'Atualize dados pessoais, contexto de origem, diversidade e responsabilidade clínica.',
        'Ativo',
        'Salvar alterações',
      ]) {
        expect(find.text(text), findsOneWidget, reason: text);
      }
      // Cada seção no índice e no conteúdo.
      for (final section in const [
        'Dados pessoais',
        'Origem',
        'Diversidade',
        'Responsabilidade',
        'Acesso do paciente',
      ]) {
        expect(find.text(section), findsNWidgets(2), reason: section);
        expect(find.widgetWithText(DaIndexItem, section), findsOneWidget);
      }
      expect(
          tester.getTopLeft(find.text('Telefone')).dy,
          tester.getTopLeft(find.text('Nome completo *')).dy);
      expect(tester.getRect(find.text('Salvar alterações')).bottom,
          greaterThan(desk.height - 40));

      await _pump(tester, tablet, edit);
      expect(find.byType(DaIndexItem), findsNothing);
      expect(find.text('Origem'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('índice leva à seção e marca o item', (tester) async {
      await _pump(tester, desk, edit);
      final title = find.text('Acesso do paciente').last;
      expect(tester.getTopLeft(title).dy, greaterThan(desk.height));
      await tester.tap(find.widgetWithText(DaIndexItem, 'Acesso do paciente'));
      await _settle(tester);
      expect(tester.getTopLeft(title).dy, lessThan(desk.height - 80));
      expect(
          tester
              .widget<DaIndexItem>(
                  find.widgetWithText(DaIndexItem, 'Acesso do paciente'))
              .active,
          isTrue);
    });

    testWidgets('abre com os mesmos valores do celular', (tester) async {
      await _pump(tester, phone, edit);
      final mobile = _editValues(tester);
      await _pump(tester, desk, edit);
      expect(_editValues(tester), mobile);
      expect(mobile['Gênero'], 'female');
      expect(mobile['nascimento'], 1);
    });

    testWidgets('salva exatamente os mesmos dados do celular', (tester) async {
      await _pump(tester, phone, edit);
      final mobile = await _changeAndSave(tester);
      expect(_location(), '/psychologist');

      await _pump(tester, desk, edit);
      final desktop = await _changeAndSave(tester);
      expect(_location(), '/psychologist');
      expect(desktop, mobile);
      expect(desktop['full_name'], 'Marina Alterada Fictícia');
      expect(desktop['occupation'], isNull);
      expect(desktop['responsible_psychologist_id'], 'psi-2');
      expect(desktop['has_children'], isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('nome vazio: "Obrigatório", mesmo com a tela rolada',
        (tester) async {
      await _pump(tester, desk, edit);
      await _type(tester, 'Nome completo *', '   ');
      await tester.tap(find.widgetWithText(DaIndexItem, 'Acesso do paciente'));
      await _settle(tester);
      await tester.tap(find.text('Salvar alterações'));
      await _settle(tester);
      expect(_repo.updated, isEmpty);
      expect(find.text('Obrigatório', skipOffstage: false), findsOneWidget);
      expect(_location(), edit);
    });

    testWidgets('valor antigo fora das opções continua visível',
        (tester) async {
      await _pump(tester, desk, edit,
          patient: const Patient(
              id: 'p3',
              fullName: 'Marina Exemplo',
              gender: 'Feminino',
              educationLevel: 'formato antigo qualquer'));
      expect(find.text('formato antigo qualquer'), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('erro ao salvar: mesmo texto e "OK" limpa', (tester) async {
      await _pump(tester, desk, edit);
      _repo.fail = Exception('falha fictícia');
      await _tap(tester, find.text('Salvar alterações'));
      expect(find.text('Erro ao salvar. Tente novamente.'), findsOneWidget);
      expect(_location(), edit);
      await _tap(tester, find.text('OK'));
      expect(find.text('Erro ao salvar. Tente novamente.'), findsNothing);
    });

    testWidgets('psicólogos carregando ou com erro, como no celular',
        (tester) async {
      await _pump(tester, desk, edit,
          psychologists: () async => throw Exception('falha fictícia'));
      expect(find.text('Não foi possível carregar os psicólogos.'),
          findsOneWidget);
      await _pump(tester, desk, edit,
          psychologists: () => Completer<List<PsychologistOption>>().future);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);
    });

    testWidgets('paciente inativo', (tester) async {
      await _pump(tester, desk, edit,
          patient: psiMarinaCompleta(active: false));
      expect(find.text('Inativo'), findsOneWidget);
      expect(find.text('Ativo'), findsNothing);
    });

    testWidgets('acesso sem conta: só o texto', (tester) async {
      await _pump(tester, desk, edit);
      expect(
          find.text('Este paciente ainda não aceitou o convite. '
              'Reenvie o convite com o e-mail correto.'),
          findsOneWidget);
      expect(find.text('Atualizar acesso'), findsNothing);
    });

    testWidgets('acesso: mesmas validações e mesmo envio do celular',
        (tester) async {
      const messages = [
        'E-mail inválido',
        'A senha deve ter de 8 a 72 caracteres',
        'As senhas não são iguais',
        'Informe um novo e-mail ou uma nova senha.',
        'Acesso do paciente atualizado.',
      ];
      Future<(List<Map<String, int>>, List<Map<String, dynamic>>)> run(
          Size size) async {
        await _pump(tester, size, edit,
            patient: psiMarinaCompleta(profileId: 'prof-p3'));
        final seen = <Map<String, int>>[];
        final button = find.text('Atualizar acesso');
        await _tap(tester, button);
        seen.add(_errors(messages));
        await _type(tester, 'E-mail de acesso', 'ruim@');
        await _type(tester, 'Nova senha', '123');
        await _type(tester, 'Confirmar nova senha', '1234');
        await _tap(tester, button);
        seen.add(_errors(messages));
        await _type(tester, 'E-mail de acesso', 'Novo9@Example.com');
        await _type(tester, 'Nova senha', 'senha-ficticia');
        await _type(tester, 'Confirmar nova senha', 'senha-ficticia');
        await _tap(tester, button);
        seen.add(_errors(messages));
        // O "Salvar alterações" é outro formulário.
        expect(_repo.updated, isEmpty);
        return (seen, [for (final c in _repo.credentials) c.toJson()]);
      }

      final mobile = await run(phone);
      final desktop = await run(desk);
      expect(desktop.$1, mobile.$1);
      expect(desktop.$2, mobile.$2);
      expect(desktop.$2.single['email'], 'novo9@example.com');
      expect(mobile.$1.last['Acesso do paciente atualizado.'], 1);
    });
  });

  group('Dados cadastrais', () {
    List<String> rows(WidgetTester tester) => [
          for (final text in tester.widgetList<Text>(find.descendant(
              of: find.byType(PatientInfoRowLayout),
              matching: find.byType(Text))))
            text.data!,
        ];

    testWidgets('mesmos dados do celular, em 2 colunas, e ações',
        (tester) async {
      await _pump(tester, phone, registration);
      final mobile = rows(tester);
      await _pump(tester, desk, registration);
      expect(_isDesktop(), isTrue);
      expect(rows(tester), mobile);
      expect(find.text('Dados cadastrais'), findsOneWidget);
      expect(find.byType(PatientInfoRowLayout), findsNWidgets(13));
      for (final text in [
        'Dados do paciente',
        'Informações principais para identificação, contato e contexto clínico.',
        'PACIENTE ATIVO',
        'App ativo',
        'Dra. Helena Exemplo',
        'Paciente ativo',
        'Inativar acesso',
        'Editar paciente',
      ]) {
        // O nome da psicóloga também está no rodapé do menu.
        expect(
            find.descendant(
                of: find.byType(DesktopFormBody), matching: find.text(text)),
            findsOneWidget,
            reason: text);
      }
      final first = tester.getTopLeft(find.text('E-mail'));
      final second = tester.getTopLeft(find.text('Telefone'));
      expect(second.dy, closeTo(first.dy, 8));
      expect(second.dx, greaterThan(first.dx + 300));
      expect(tester.getRect(find.text('Editar paciente')).bottom,
          greaterThan(desk.height - 40));
      expect(tester.takeException(), isNull);
    });

    testWidgets('dado vazio não ocupa lugar', (tester) async {
      await _pump(tester, desk, registration,
          patient: const Patient(
              id: 'p3',
              fullName: 'Marina Exemplo',
              email: 'usuario3@example.com',
              occupation: 'Designer'));
      expect(find.byType(PatientInfoRowLayout), findsNWidgets(2));
      final a = tester.getTopLeft(find.text('E-mail'));
      final b = tester.getTopLeft(find.text('Ocupação'));
      expect(b.dy, closeTo(a.dy, 8));
    });

    testWidgets('telefone e CPF mascarados; mostrar e copiar', (tester) async {
      final copied = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
      addTearDown(() => tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null));
      await _pump(tester, desk, registration);
      expect(find.text('•••••••0000'), findsOneWidget);
      expect(find.text('***.***.789-**'), findsOneWidget);
      await _tap(tester, find.byTooltip('Mostrar CPF'));
      expect(find.text('12345678909'), findsOneWidget);
      await _tap(tester, find.byTooltip('Copiar Telefone'));
      expect(copied, ['11999990000']);
      expect(find.text('Telefone copiado.'), findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('"Editar paciente" abre o formulário; trilha volta à ficha',
        (tester) async {
      await _pump(tester, desk, registration);
      await _tap(tester, find.text('Editar paciente'));
      expect(_location(), edit);
      expect(find.text('Salvar alterações'), findsOneWidget);
      await _tap(tester, find.text('Marina Exemplo').first);
      expect(_location(), '/psychologist/patients/p3');
    });

    testWidgets('inativar pede a mesma confirmação', (tester) async {
      await _pump(tester, desk, registration);
      await _tap(tester, find.text('Inativar acesso'));
      expect(find.text('Inativar acesso?'), findsOneWidget);
      await _tap(tester, find.text('Cancelar'));
      expect(_repo.status, isEmpty);
      await _tap(tester, find.text('Inativar acesso'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Inativar'));
      expect(_repo.status, [('p3', false)]);
      expect(find.text('Acesso do paciente inativado com sucesso.'),
          findsOneWidget);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('inativo: reativar', (tester) async {
      await _pump(tester, desk, registration,
          patient: psiMarinaCompleta(
              active: false, access: PatientAccessStatus.inactive));
      expect(find.text('PACIENTE INATIVO'), findsOneWidget);
      expect(find.text('Inativo'), findsOneWidget);
      await _tap(tester, find.text('Reativar acesso'));
      await _tap(tester, find.widgetWithText(FilledButton, 'Reativar'));
      expect(_repo.status, [('p3', true)]);
      await tester.pump(const Duration(seconds: 5));
    });

    testWidgets('erro e não encontrado, com a trilha', (tester) async {
      var fail = true;
      await _pump(tester, desk, registration, detail: () {
        if (fail) throw Exception('falha fictícia');
        return psiMarinaCompleta();
      });
      expect(
          find.text('Não foi possível carregar o paciente.'), findsOneWidget);
      expect(find.byType(DesktopTopBar), findsOneWidget);
      fail = false;
      await _tap(tester, find.text('Tentar novamente'));
      await _settle(tester);
      expect(find.text('Dados do paciente'), findsOneWidget);
      await _pump(tester, desk, registration, detail: () => null);
      expect(find.text('Paciente não encontrado.'), findsOneWidget);
    });
  });

  testWidgets('larguras e tema escuro: três telas sem overflow',
      (tester) async {
    for (final size in const [
      Size(768, 1024),
      tablet,
      Size(1024, 768),
      desk,
      wide,
      Size(1366, 560),
    ]) {
      for (final location in [create, edit, registration]) {
        for (final dark in [false, true]) {
          await _pump(tester, size, location,
              dark: dark,
              patient: psiMarinaCompleta(profileId: 'prof-p3'));
          if (location == create) {
            await _expand(tester);
            await _tap(tester, find.text('Cadastrar paciente'));
          }
          expect(find.byType(DesktopPsychologistMenu), findsOneWidget);
          expect(_isDesktop(), isTrue, reason: '$location $size');
          expect(tester.takeException(), isNull,
              reason: '$location $size $dark');
        }
      }
    }
  });

  testWidgets('celular não usa o desktop; digitado sobrevive à largura',
      (tester) async {
    for (final location in [create, edit, registration]) {
      await _pump(tester, phone, location);
      expect(_isDesktop(), isFalse, reason: location);
    }
    await _pump(tester, desk, create);
    await _type(tester, 'Nome completo *', 'Texto Fictício');
    tester.view.physicalSize = phone;
    await _settle(tester);
    expect(_isDesktop(), isFalse);
    expect(find.text('Texto Fictício'), findsOneWidget);
    tester.view.physicalSize = desk;
    await _settle(tester);
    expect(find.text('Texto Fictício'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
