// Admin E3 (Questionários): abas, editor e prévia ≥768 px vs celular.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/auth/providers/auth_providers.dart';
import 'package:terapia_esquema/features/clinics/domain/clinic_summary.dart';
import 'package:terapia_esquema/features/clinics/providers/clinics_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';
import 'package:terapia_esquema/features/user_management/domain/clinic_user.dart';
import 'package:terapia_esquema/features/user_management/providers/user_management_providers.dart';
import 'package:terapia_esquema/shared/widgets/app_nav_shell.dart';
import 'package:terapia_esquema/features/questionnaires/data/questionnaire_catalog_admin_repository.dart';
import 'package:terapia_esquema/features/questionnaires/data/questionnaires_repository.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_shell.dart';


import 'package:terapia_esquema/features/platform_admin/presentation/platform_admin_home_page.dart';
import 'package:terapia_esquema/features/questionnaires/domain/question_answer_type.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_access_item.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_access_management_data.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_catalog_admin.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_professional_option.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_question.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_session.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/questionnaire_access_management_page.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/questionnaire_answer_page.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/questionnaire_catalog_admin_page.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/questionnaire_catalog_editor_page.dart';
import 'package:terapia_esquema/features/questionnaires/providers/questionnaire_catalog_admin_providers.dart';
import 'package:terapia_esquema/features/questionnaires/providers/questionnaires_providers.dart';
class _FakeAuth extends AuthController {
  _FakeAuth() : super(_DummyRef()) {
    state = const AsyncValue<UserProfile?>.data(UserProfile(
      id: 'a1',
      clinicId: 'c1',
      role: ProfileRole.platformAdmin,
      fullName: 'Admin Exemplo',
      email: 'admin@example.com',
      isActive: true,
    ));
  }
}

class _DummyRef implements Ref {
  @override
  ProviderSubscription<T> listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool? fireImmediately,
  }) =>
      _DummySub<T>();
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummySub<T> implements ProviderSubscription<T> {
  @override
  void close() {}
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ClinicUser _u(String id, String clinic, String type, String name,
        ProfileRole role, bool active,
        {int assigned = 0}) =>
    ClinicUser(
      id: id,
      clinicId: clinic,
      clinicName: clinic == 'c1' ? 'Clínica Exemplo' : 'Consultório Individual Modelo',
      clinicType: type,
      clinicIsActive: true,
      fullName: name,
      email: 'usuario$id@example.com',
      role: role,
      isActive: active,
      assignedPatientsCount: assigned,
    );

final _users = [
  _u('3', 'c1', 'clinic', 'Dr. Lucas Amostra', ProfileRole.platformAdmin, true),
  _u('6', 'c1', 'clinic', 'Dra. Carla Demonstrativa', ProfileRole.platformAdmin, true),
  _u('0', 'c1', 'clinic', 'Dra. Helena Exemplo', ProfileRole.platformAdmin, false),
  _u('1', 'c1', 'clinic', 'Dr. Paulo Modelo', ProfileRole.psychologist, true),
  _u('5', 'c1', 'clinic', 'Dr. Tiago Simulado', ProfileRole.psychologist, false),
  _u('4', 'c1', 'clinic', 'Dra. Beatriz Teste', ProfileRole.psychologist, true),
  _u('2', 'c1', 'clinic', 'Dra. Renata Fictícia', ProfileRole.psychologist, true),
  _u('9', 'c2', 'personal', 'Dr. Mateus Exemplar', ProfileRole.platformAdmin, true),
  _u('11', 'c2', 'personal', 'Dr. Bruno Protótipo', ProfileRole.psychologist, true),
  _u('7', 'c2', 'personal', 'Dr. Rafael Hipotético', ProfileRole.psychologist, true),
  _u('10', 'c2', 'personal', 'Dra. Ana Clara Sintética', ProfileRole.psychologist, false),
  _u('8', 'c2', 'personal', 'Dra. Juliana Fictícia', ProfileRole.psychologist, true),
];

class _FakeUsers extends ClinicUsersNotifier {
  @override
  Future<List<ClinicUser>> build() async => _users;
}

class _FakeClinics extends ClinicsNotifier {
  @override
  Future<List<ClinicSummary>> build() async => [
        ClinicSummary(
            id: 'c1',
            name: 'Clínica Exemplo',
            clinicType: 'clinic',
            isActive: true,
            createdAt: DateTime(2026, 1, 1),
            userCount: 7,
            patientCount: 8),
        ClinicSummary(
            id: 'c2',
            name: 'Consultório Individual Modelo',
            clinicType: 'personal',
            isActive: true,
            createdAt: DateTime(2026, 1, 1),
            userCount: 1,
            patientCount: 3),
      ];
}

const _dest = [
  AppNavDestination(
      label: 'Início',
      icon: Icons.home_outlined,
      selectedIcon: Icons.home,
      route: '/platform',
      exactMatch: true),
  AppNavDestination(
      label: 'Clínicas',
      icon: Icons.apartment_outlined,
      selectedIcon: Icons.apartment,
      route: '/platform/clinics'),
  AppNavDestination(
      label: 'Usuários',
      icon: Icons.badge_outlined,
      selectedIcon: Icons.badge,
      route: '/platform/users'),
  AppNavDestination(
      label: 'Pacientes',
      icon: Icons.people_outline,
      selectedIcon: Icons.people,
      route: '/platform/patient-overview'),
];


final _q1 = Questionnaire(
  id: 'q1',
  code: 'QEX_01',
  name: 'Questionário Exemplo 1',
  isActive: true,
  authorName: 'Autor Fictício',
  instrumentVersion: '1.0',
  licenseNotes: 'Licença fictícia de teste.',
  clinicalStatus: QuestionnaireClinicalStatus.approved,
);
final _q2 = Questionnaire(
  id: 'q2',
  code: 'QEX_02',
  name: 'Questionário Exemplo 2',
  isActive: false,
  instrumentVersion: '1.0',
);

List<QuestionnaireCatalogQuestion> _qs() => [
      for (var i = 1; i <= 3; i++)
        QuestionnaireCatalogQuestion(
          id: 'p$i',
          code: 'Q$i',
          text: 'Pergunta fictícia número $i para o questionário de exemplo.',
          orderIndex: i,
          answerType: QuestionAnswerType.likertScale,
          scaleMin: 1,
          scaleMax: 6,
          weight: 1.0,
          reverseScore: false,
        ),
    ];

QuestionnaireCatalogDetail _detail(String id) {
  final pub = id == 'q1';
  return QuestionnaireCatalogDetail(
    questionnaire: {
      'id': id,
      'code': pub ? 'QEX_01' : 'QEX_02',
      'name': pub ? 'Questionário Exemplo 1' : 'Questionário Exemplo 2',
      'description': '',
      'is_active': pub,
      'clinical_status': pub ? 'approved' : 'draft',
    },
    version: {
      'version': '1.0',
      'status': pub ? 'active' : 'draft',
      'scale_min': 1,
      'scale_max': 5,
      'reference_period': 'unspecified',
    },
    questions: _qs(),
    hasDraftVersion: !pub,
  );
}

final _catalog = [
  const QuestionnaireCatalogAdminItem(
    id: 'q1',
    code: 'QEX_01',
    name: 'Questionário Exemplo 1',
    isActive: true,
    clinicalStatus: 'approved',
    questionCount: 10,
    responseCount: 0,
    version: '1.0',
  ),
  const QuestionnaireCatalogAdminItem(
    id: 'q2',
    code: 'QEX_02',
    name: 'Questionário Exemplo 2',
    isActive: false,
    clinicalStatus: 'draft',
    questionCount: 11,
    responseCount: 3,
    version: '1.0',
  ),
];

final _staff = [
  for (final u in _users.where((u) => u.role == ProfileRole.psychologist))
    QuestionnaireProfessionalOption(
        id: u.id, fullName: u.fullName, role: u.role, email: u.email),
];

final _session = QuestionnaireSession(
  responseId: 'admin-preview-q2',
  patientId: 'admin-preview',
  questionnaire: _q2,
  questions: [
    for (final q in _qs())
      QuestionnaireQuestion(
        id: q.id,
        code: q.code,
        text: q.text,
        orderIndex: q.orderIndex,
        answerType: q.answerType,
        scaleMin: 1,
        scaleMax: 6,
      ),
  ],
);

final _e3Overrides = <Override>[
  authControllerProvider.overrideWith((ref) => _FakeAuth()),
  clinicUsersProvider.overrideWith(_FakeUsers.new),
  clinicsProvider.overrideWith(_FakeClinics.new),
  questionnaireCatalogAdminListProvider.overrideWith((ref) async => _catalog),
  questionnaireCatalogAdminDetailProvider
      .overrideWith((ref, id) async => _detail(id)),
  questionnaireStaffOptionsProvider.overrideWith((ref) async => _staff),
  questionnaireAccessManagementProvider.overrideWith(
      (ref, id) async => QuestionnaireAccessManagementData(
            supportsAccessControl: true,
            items: [
              QuestionnaireAccessItem(questionnaire: _q1, isEnabled: true),
              QuestionnaireAccessItem(questionnaire: _q2, isEnabled: false),
            ],
          )),
];

GoRouter _e3Router(String location, {Object? extra}) => GoRouter(
      initialLocation: location,
      initialExtra: extra,
      routes: [
        ShellRoute(
          builder: (_, __, child) =>
              AppNavShell(destinations: _dest, child: child),
          routes: [
            GoRoute(
              path: '/platform',
              builder: (_, __) => const PlatformAdminHomePage(),
              routes: [
                GoRoute(
                    path: 'questionnaires',
                    builder: (_, __) =>
                        const QuestionnaireAccessManagementPage()),
                GoRoute(
                  path: 'questionnaire-catalog',
                  builder: (_, __) => const QuestionnaireCatalogAdminPage(),
                  routes: [
                    GoRoute(
                        path: 'new',
                        builder: (_, __) =>
                            const QuestionnaireCatalogEditorPage()),
                    GoRoute(
                      path: ':questionnaireId',
                      builder: (_, state) => QuestionnaireCatalogEditorPage(
                          questionnaireId:
                              state.pathParameters['questionnaireId']!),
                      routes: [
                        GoRoute(
                          path: 'preview',
                          builder: (_, state) => QuestionnaireAnswerPage(
                            session: state.extra! as QuestionnaireSession,
                            role: ProfileRole.platformAdmin,
                            previewMode: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );



class _FakeRepo implements QuestionnairesRepository {
  static final accessCalls = <(String, String, bool)>[];

  @override
  Future<void> setQuestionnaireAccess({
    required String professionalId,
    required String questionnaireId,
    required bool isEnabled,
  }) async {
    accessCalls.add((professionalId, questionnaireId, isEnabled));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeCatalogRepo implements QuestionnaireCatalogAdminRepository {
  static final calls = <String>[];

  @override
  Future<String> saveDraft(QuestionnaireDraftInput input) async {
    calls.add('saveDraft:${input.code}:${input.name}');
    return input.id ?? 'q2';
  }

  @override
  Future<void> publish(String id) async => calls.add('publish:$id');

  @override
  Future<void> createDraftVersion(String id) async =>
      calls.add('createDraftVersion:$id');

  @override
  Future<void> deleteQuestion(String questionnaireId, String questionId) async =>
      calls.add('deleteQuestion:$questionnaireId:$questionId');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Future<void> _pump(WidgetTester tester, Size size, String location,
    {Object? extra}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  desktopAdminMenuCollapsed.value = false;
  _FakeRepo.accessCalls.clear();
  _FakeCatalogRepo.calls.clear();
  final theme = AppTheme.light;
  await tester.pumpWidget(ProviderScope(
    overrides: [
      ..._e3Overrides,
      questionnairesRepositoryProvider.overrideWithValue(_FakeRepo()),
      questionnaireCatalogAdminRepositoryProvider
          .overrideWithValue(_FakeCatalogRepo()),
    ],
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _e3Router(location, extra: extra),
      theme: theme.copyWith(
          textTheme: theme.textTheme.apply(fontFamily: 'Poppins')),
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
    ),
  ));
  await _settle(tester, 15);
}

Future<void> _settle(WidgetTester tester, [int n = 5]) async {
  for (var i = 0; i < n; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
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

  const desk = Size(1366, 768);
  const phone = Size(390, 844);
  const tablet = Size(834, 1112);
  const catalog = '/platform/questionnaire-catalog';
  const access = '/platform/questionnaires';

  group('Catálogo e Permissões (abas)', () {
    testWidgets('≥768: aba Catálogo em tabela; celular sem casca',
        (tester) async {
      await _pump(tester, desk, catalog);
      expect(find.text('Recolher menu'), findsOneWidget);
      expect(find.text('Catálogo'), findsOneWidget);
      expect(find.text('Permissões'), findsOneWidget);
      expect(find.text('Questionário'), findsOneWidget);
      expect(find.text('Questionário Exemplo 1'), findsOneWidget);
      expect(find.text('Publicado'), findsOneWidget);
      expect(find.text('Novo questionário'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pump(tester, phone, catalog);
      expect(find.text('Recolher menu'), findsNothing);
      expect(find.text('Catálogo de questionários'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('trocar de aba leva a Permissões e volta', (tester) async {
      await _pump(tester, desk, catalog);
      await tester.tap(find.text('Permissões'));
      await _settle(tester, 8);
      expect(find.text('Permissões por psicólogo'), findsOneWidget);
      expect(find.text('Novo questionário'), findsNothing);
      await tester.tap(find.text('Catálogo'));
      await _settle(tester, 8);
      expect(find.text('Questionário Exemplo 2'), findsOneWidget);
    });

    testWidgets('linha do catálogo abre o editor', (tester) async {
      await _pump(tester, desk, catalog);
      await tester.tap(find.text('Questionário Exemplo 2'));
      await _settle(tester, 8);
      expect(find.text('Editor do questionário'), findsOneWidget);
    });

    testWidgets('Permissões: seleciona psicólogo e grava só ao alternar',
        (tester) async {
      await _pump(tester, desk, access);
      expect(find.text('Selecione um psicólogo'), findsOneWidget);
      await tester.tap(find.text('Dr. Paulo Modelo'));
      await _settle(tester, 6);
      expect(find.textContaining('Acesso do profissional selecionado'),
          findsOneWidget);
      expect(find.textContaining('1 de 2 instrumento(s) liberado(s)'),
          findsOneWidget);
      expect(find.text('Liberado'), findsOneWidget);
      expect(find.text('Bloqueado'), findsOneWidget);
      expect(_FakeRepo.accessCalls, isEmpty);
      // Liga o 2º instrumento (bloqueado): grava com o valor oposto.
      await tester.tap(find.byType(AnimatedAlign).last);
      await _settle(tester);
      expect(_FakeRepo.accessCalls, [('1', 'q2', true)]);
    });

    testWidgets('celular de Permissões mantém as abas de hoje',
        (tester) async {
      await _pump(tester, phone, access);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.text('Recolher menu'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet sem overflow', (tester) async {
      await _pump(tester, tablet, catalog);
      expect(find.text('Questionário Exemplo 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await _pump(tester, tablet, access);
      expect(find.text('Permissões por psicólogo'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Editor do questionário', () {
    testWidgets('rascunho: barra de ações, índice e campos', (tester) async {
      await _pump(tester, desk, '$catalog/q2');
      expect(find.text('Governança'), findsOneWidget);
      expect(find.text('Homologar e publicar'), findsOneWidget);
      expect(find.text('Pré-visualizar sem gravar'), findsOneWidget);
      expect(find.text('Excluir rascunho'), findsOneWidget);
      expect(find.text('Identificação'), findsWidgets);
      expect(find.text('Perguntas (3)'), findsWidgets);
      expect(find.text('Nome *'), findsOneWidget);
      expect(find.text('Salvar rascunho'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('versão publicada: faixa de proteção e campos desabilitados',
        (tester) async {
      await _pump(tester, desk, '$catalog/q1');
      expect(find.textContaining('publicada e protegida'), findsOneWidget);
      expect(find.text('Editar — criar nova versão'), findsOneWidget);
      expect(find.text('Salvar rascunho'), findsNothing);
      await tester.tap(find.text('Editar — criar nova versão'));
      await _settle(tester);
      expect(find.text('Criar nova versão'), findsWidgets); // diálogo do app
    });

    testWidgets('índice leva à seção Perguntas', (tester) async {
      await _pump(tester, desk, '$catalog/q2');
      await tester.tap(find.text('Perguntas (3)').first);
      await _settle(tester, 8);
      expect(find.textContaining('Pergunta fictícia número 3'), findsOneWidget);
    });

    testWidgets('pergunta abre no painel lateral e Cancelar fecha',
        (tester) async {
      await _pump(tester, desk, '$catalog/q2');
      await tester.tap(find.text('Perguntas (3)').first);
      await _settle(tester, 8);
      await tester.tap(find.textContaining('Pergunta fictícia número 2'));
      await _settle(tester);
      expect(find.text('Editar pergunta'), findsOneWidget);
      expect(find.text('Enunciado *'), findsOneWidget);
      expect(find.text('Pontuação invertida'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _settle(tester);
      expect(find.text('Editar pergunta'), findsNothing);
    });

    testWidgets('Salvar rascunho chama saveDraft com os campos do formulário',
        (tester) async {
      await _pump(tester, desk, '$catalog/q2');
      await tester.ensureVisible(find.text('Salvar rascunho'));
      await _settle(tester, 2);
      await tester.tap(find.text('Salvar rascunho'));
      await _settle(tester, 6);
      expect(_FakeCatalogRepo.calls,
          ['saveDraft:QEX_02:Questionário Exemplo 2']);
    });

    testWidgets('Homologar e publicar: confirma e grava; cancelar não grava',
        (tester) async {
      await _pump(tester, desk, '$catalog/q2');
      await tester.tap(find.text('Homologar e publicar'));
      await _settle(tester);
      expect(find.text('Homologar e publicar?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _settle(tester);
      expect(_FakeCatalogRepo.calls, isEmpty);

      await tester.tap(find.text('Homologar e publicar'));
      await _settle(tester);
      await tester.tap(find.text('Confirmar'));
      await _settle(tester, 8);
      expect(_FakeCatalogRepo.calls, ['publish:q2']);
    });

    testWidgets('Criar nova versão: confirma e grava; cancelar não grava',
        (tester) async {
      await _pump(tester, desk, '$catalog/q1');
      await tester.tap(find.text('Editar — criar nova versão'));
      await _settle(tester);
      await tester.tap(find.text('Cancelar'));
      await _settle(tester);
      expect(_FakeCatalogRepo.calls, isEmpty);

      await tester.tap(find.text('Editar — criar nova versão'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Criar nova versão'));
      await _settle(tester, 8);
      expect(_FakeCatalogRepo.calls, ['createDraftVersion:q1']);
    });

    testWidgets('Excluir pergunta: confirma e grava; cancelar não grava',
        (tester) async {
      await _pump(tester, desk, '$catalog/q2');
      await tester.ensureVisible(find.byTooltip('Excluir').first);
      await _settle(tester, 2);
      await tester.tap(find.byTooltip('Excluir').first);
      await _settle(tester);
      expect(find.text('Excluir pergunta?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _settle(tester);
      expect(_FakeCatalogRepo.calls, isEmpty);

      await tester.tap(find.byTooltip('Excluir').first);
      await _settle(tester);
      await tester.tap(find.text('Confirmar'));
      await _settle(tester, 8);
      expect(_FakeCatalogRepo.calls, ['deleteQuestion:q2:p1']);
    });

    testWidgets('celular mantém o editor de hoje', (tester) async {
      await _pump(tester, phone, '$catalog/q2');
      expect(find.text('Recolher menu'), findsNothing);
      expect(find.text('Governança'), findsNothing); // barra é só do desktop
      expect(find.text('Identificação'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet sem overflow', (tester) async {
      await _pump(tester, tablet, '$catalog/q2');
      expect(find.text('Homologar e publicar'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Prévia', () {
    testWidgets('≥768: tela cheia, bloco central, navegação entre perguntas',
        (tester) async {
      await _pump(tester, desk, '$catalog/q2/preview', extra: _session);
      expect(find.text('Recolher menu'), findsNothing);
      expect(find.text('Pré-visualização: as respostas não serão salvas.'),
          findsOneWidget);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('Anterior'), findsNothing);
      // Sem resposta, "Próxima" avisa e não avança.
      await tester.tap(find.text('Próxima'));
      await _settle(tester);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.text('Selecione uma resposta'), findsOneWidget);
      // Responde e avança; depois volta.
      await tester.tap(find.text('3').first);
      await _settle(tester, 3);
      await tester.tap(find.text('Próxima'));
      await _settle(tester);
      expect(find.text('2/3'), findsOneWidget);
      await tester.tap(find.text('Anterior'));
      await _settle(tester);
      expect(find.text('1/3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('botão Voltar fecha a prévia e volta ao editor',
        (tester) async {
      await _pump(tester, tablet, '$catalog/q2');
      await tester.tap(find.text('Pré-visualizar sem gravar'));
      await _settle(tester, 8);
      expect(find.text('1/3'), findsOneWidget);
      expect(find.byTooltip('Voltar'), findsOneWidget);
      await tester.tap(find.byTooltip('Voltar'));
      await _settle(tester, 8);
      expect(find.text('1/3'), findsNothing);
      expect(find.text('Editor do questionário'), findsOneWidget);
    });

    testWidgets('celular mantém a prévia de hoje', (tester) async {
      await _pump(tester, phone, '$catalog/q2/preview', extra: _session);
      expect(find.text('Pré-visualização: as respostas não serão salvas.'),
          findsOneWidget);
      expect(find.text('Recolher menu'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('tablet sem overflow', (tester) async {
      await _pump(tester, tablet, '$catalog/q2/preview', extra: _session);
      expect(find.text('1/3'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
