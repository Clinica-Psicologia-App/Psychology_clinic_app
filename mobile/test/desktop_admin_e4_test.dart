// Admin E4 (Biblioteca e Psicoeducação): ≥768 px vs celular e fluxos.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
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
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_kit.dart';
import 'package:terapia_esquema/shared/widgets/desktop_admin/desktop_admin_shell.dart';

import 'desktop_admin_hover_helper.dart';

import 'package:terapia_esquema/features/patient_library/data/admin_library_repository.dart';
import 'package:terapia_esquema/features/patient_library/domain/library_work.dart';
import 'package:terapia_esquema/features/patient_library/domain/library_work_full.dart';
import 'package:terapia_esquema/features/patient_library/presentation/admin_library_catalog_page.dart';
import 'package:terapia_esquema/features/patient_library/presentation/admin_library_editor_page.dart';
import 'package:terapia_esquema/features/patient_library/providers/admin_library_providers.dart';
import 'package:terapia_esquema/features/platform_admin/presentation/platform_admin_home_page.dart';
import 'package:terapia_esquema/features/psychoeducation/data/admin_psychoeducation_repository.dart';
import 'package:terapia_esquema/features/psychoeducation/domain/psychoeducation_module.dart';
import 'package:terapia_esquema/features/psychoeducation/presentation/admin_psychoeducation_catalog_page.dart';
import 'package:terapia_esquema/features/psychoeducation/presentation/admin_psychoeducation_editor_page.dart';
import 'package:terapia_esquema/features/psychoeducation/providers/psychoeducation_providers.dart';
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


class _FakeLibRepo implements AdminLibraryRepository {
  static final calls = <String>[];

  @override
  Future<List<AdminLibraryWork>> listAll({String? query}) async => [
        for (var i = 1; i <= 6; i++)
          AdminLibraryWork(
            id: 'w$i',
            displayTitle: 'Obra Exemplo $i',
            workType: i.isEven ? 'Série' : 'Filme',
            year: 2000 + i,
            intensity: 'Moderada',
            primarySchema: 'Abandono',
            isPublished: i != 3,
          ),
      ].where((w) =>
          query == null ||
          w.displayTitle.toLowerCase().contains(query.toLowerCase())).toList();

  @override
  Future<LibraryWorkFull?> getWork(String id) async => const LibraryWorkFull(
        id: 'w1',
        displayTitle: 'Obra Exemplo 1',
        workType: 'Filme',
        year: 2001,
        genres: 'Drama',
        synopsis: 'Sinopse fictícia.',
        primarySchema: 'Abandono',
        associatedSchemas: ['Privação emocional'],
        intensity: 'Moderada',
        patientLayer: LibraryPatientLayer(before: 'Antes de assistir fictício.'),
      );

  @override
  Future<void> setPublished(String id, bool published) async =>
      calls.add('setPublished:$id:$published');

  @override
  Future<void> updateWork(String id, Map<String, dynamic> values) async =>
      calls.add('updateWork:$id:${values['display_title']}');

  @override
  Future<String> createWork(Map<String, dynamic> values) async {
    calls.add('createWork');
    return 'w9';
  }

  @override
  Future<void> deleteWork(String id) async => calls.add('deleteWork:$id');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakePsyRepo implements AdminPsychoeducationRepository {
  static final calls = <String>[];

  @override
  Future<List<AdminPsychoModule>> listAll() async => [
        for (var i = 1; i <= 5; i++)
          AdminPsychoModule(
            id: 'm$i',
            number: i,
            stage: 'Conhecer',
            title: 'Módulo Exemplo $i',
            cardCount: 4 + i,
            isPublished: i != 4,
          ),
      ];

  @override
  Future<PsychoeducationModule?> getModule(String id) async =>
      const PsychoeducationModule(
        id: 'm1',
        number: 1,
        stage: 'Conhecer',
        title: 'Módulo Exemplo 1',
        presentation: 'Apresentação fictícia.',
        cards: [
          PsychoeducationCard(
              title: 'Card fictício um', patientText: 'Texto do card um.'),
          PsychoeducationCard(
              title: 'Card fictício dois', patientText: 'Texto do card dois.'),
          PsychoeducationCard(
              title: 'Card fictício três', patientText: 'Texto do card três.'),
        ],
      );

  @override
  Future<void> setPublished(String id, bool published) async =>
      calls.add('setPublished:$id:$published');

  @override
  Future<void> updateModule(String id, Map<String, dynamic> values) async =>
      calls.add('updateModule:$id:${(values['cards'] as List).length}');

  @override
  Future<String> createModule(Map<String, dynamic> values) async {
    calls.add('createModule');
    return 'm9';
  }

  @override
  Future<void> deleteModule(String id) async => calls.add('deleteModule:$id');

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

final _e4Overrides = <Override>[
  authControllerProvider.overrideWith((ref) => _FakeAuth()),
  clinicUsersProvider.overrideWith(_FakeUsers.new),
  clinicsProvider.overrideWith(_FakeClinics.new),
  adminLibraryRepositoryProvider.overrideWithValue(_FakeLibRepo()),
  adminPsychoeducationRepositoryProvider.overrideWithValue(_FakePsyRepo()),
];

GoRouter _e4Router(String location) => GoRouter(
      initialLocation: location,
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
                  path: 'library',
                  builder: (_, __) => const AdminLibraryCatalogPage(),
                  routes: [
                    GoRoute(
                        path: 'new',
                        builder: (_, __) => const AdminLibraryEditorPage()),
                    GoRoute(
                        path: ':id',
                        builder: (_, s) => AdminLibraryEditorPage(
                            workId: s.pathParameters['id'])),
                  ],
                ),
                GoRoute(
                  path: 'psychoeducation',
                  builder: (_, __) => const AdminPsychoeducationCatalogPage(),
                  routes: [
                    GoRoute(
                        path: 'new',
                        builder: (_, __) =>
                            const AdminPsychoeducationEditorPage()),
                    GoRoute(
                        path: ':id',
                        builder: (_, s) => AdminPsychoeducationEditorPage(
                            moduleId: s.pathParameters['id'])),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );



Future<void> _pump(WidgetTester tester, Size size, String location) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  desktopAdminMenuCollapsed.value = false;
  _FakeLibRepo.calls.clear();
  _FakePsyRepo.calls.clear();
  final theme = AppTheme.light;
  await tester.pumpWidget(ProviderScope(
    overrides: _e4Overrides,
    child: MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: _e4Router(location),
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

  group('Biblioteca: catálogo', () {
    testWidgets('≥768: tabela com miniatura; celular sem casca',
        (tester) async {
      await _pump(tester, desk, '/platform/library');
      expect(find.text('Recolher menu'), findsOneWidget);
      expect(find.text('Obra'), findsOneWidget);
      expect(find.text('Liberação'), findsOneWidget);
      expect(find.text('Obra Exemplo 1'), findsOneWidget);
      expect(find.text('Nova obra'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pump(tester, phone, '/platform/library');
      expect(find.text('Recolher menu'), findsNothing);
      expect(find.text('Obra'), findsNothing);
      expect(find.text('Obra Exemplo 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('busca filtra por título', (tester) async {
      await _pump(tester, desk, '/platform/library');
      await tester.enterText(find.byType(TextField), 'exemplo 3');
      await _settle(tester, 6);
      expect(find.text('Obra Exemplo 3'), findsOneWidget);
      expect(find.text('Obra Exemplo 1'), findsNothing);
    });

    testWidgets('switch grava a publicação; linha abre o editor',
        (tester) async {
      await _pump(tester, desk, '/platform/library');
      expect(_FakeLibRepo.calls, isEmpty);
      await tester.tap(find.byType(AnimatedAlign).first);
      await _settle(tester);
      expect(_FakeLibRepo.calls, ['setPublished:w1:false']);
      await tester.tap(find.text('Obra Exemplo 2'));
      await _settle(tester, 8);
      expect(find.text('Editar obra'), findsOneWidget);
    });

    testWidgets('tablet sem overflow', (tester) async {
      await _pump(tester, tablet, '/platform/library');
      expect(find.text('Obra Exemplo 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Biblioteca: editor', () {
    testWidgets('≥768: coluna da capa, índice e seções', (tester) async {
      await _pump(tester, desk, '/platform/library/w1');
      expect(find.text('Editar obra'), findsOneWidget);
      expect(find.text('Salvar alterações'), findsOneWidget);
      expect(find.text('Enviar imagem'), findsOneWidget);
      expect(find.text('URL da capa'), findsOneWidget);
      expect(find.text('Classificação clínica'), findsWidgets);
      expect(find.text('Título exibido'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Salvar alterações grava com o título do formulário',
        (tester) async {
      await _pump(tester, desk, '/platform/library/w1');
      await tester.tap(find.text('Salvar alterações'));
      await _settle(tester, 6);
      expect(_FakeLibRepo.calls, ['updateWork:w1:Obra Exemplo 1']);
    });

    testWidgets('Remover: cancelar não grava; confirmar remove',
        (tester) async {
      await _pump(tester, desk, '/platform/library/w1');
      await tester.tap(find.byTooltip('Remover'));
      await _settle(tester);
      expect(find.text('Remover obra?'), findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _settle(tester);
      expect(_FakeLibRepo.calls, isEmpty);

      await tester.tap(find.byTooltip('Remover'));
      await _settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
      await _settle(tester, 6);
      expect(_FakeLibRepo.calls, ['deleteWork:w1']);
    });

    testWidgets('celular mantém o editor de hoje (sem casca)', (tester) async {
      await _pump(tester, phone, '/platform/library/w1');
      expect(find.text('Recolher menu'), findsNothing);
      expect(find.text('Editar obra'), findsOneWidget);
      tester.takeException(); // aviso de Material que já existe no celular
    });

    testWidgets('tablet sem overflow', (tester) async {
      await _pump(tester, tablet, '/platform/library/w1');
      expect(find.text('Salvar alterações'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Psicoeducação: catálogo', () {
    testWidgets('≥768: tabela de módulos; celular sem casca', (tester) async {
      await _pump(tester, desk, '/platform/psychoeducation');
      expect(find.text('Recolher menu'), findsOneWidget);
      expect(find.text('Nº'), findsOneWidget);
      expect(find.text('Módulo'), findsOneWidget);
      expect(find.text('Etapa'), findsOneWidget);
      expect(find.text('Módulo Exemplo 1'), findsOneWidget);
      expect(find.text('Novo módulo'), findsOneWidget);
      expect(tester.takeException(), isNull);

      await _pump(tester, phone, '/platform/psychoeducation');
      expect(find.text('Recolher menu'), findsNothing);
      expect(find.text('Nº'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('switch grava a publicação; linha abre o editor',
        (tester) async {
      await _pump(tester, desk, '/platform/psychoeducation');
      await tester.tap(find.byType(AnimatedAlign).first);
      await _settle(tester);
      expect(_FakePsyRepo.calls, ['setPublished:m1:false']);
      await tester.tap(find.text('Módulo Exemplo 2'));
      await _settle(tester, 8);
      expect(find.text('Editar módulo'), findsOneWidget);
    });

    testWidgets('tablet sem overflow', (tester) async {
      await _pump(tester, tablet, '/platform/psychoeducation');
      expect(find.text('Módulo Exemplo 1'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Psicoeducação: editor', () {
    testWidgets('≥768: lista de cards + card em edição', (tester) async {
      await _pump(tester, desk, '/platform/psychoeducation/m1');
      expect(find.text('Cards (3)'), findsOneWidget);
      expect(find.text('Card 1'), findsOneWidget);
      await tester.tap(find.text('Card fictício dois'));
      await _settle(tester);
      expect(find.text('Card 2'), findsOneWidget);
      expect(find.text('Identificação'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Remover card?: texto novo, cancelar mantém, remover tira',
        (tester) async {
      await _pump(tester, desk, '/platform/psychoeducation/m1');
      // 1º "Remover" da página é o do módulo (barra); os do card vêm depois.
      await tester.tap(find.byTooltip('Remover').at(1));
      await _settle(tester);
      expect(find.text('Remover card?'), findsOneWidget);
      expect(find.text('O card sai do módulo quando você salvar.'),
          findsOneWidget);
      await tester.tap(find.text('Cancelar'));
      await _settle(tester);
      expect(find.text('Cards (3)'), findsOneWidget);

      await tester.tap(find.byTooltip('Remover').at(1));
      await _settle(tester);
      await tester.tap(find.widgetWithText(FilledButton, 'Remover'));
      await _settle(tester, 6);
      expect(find.text('Cards (2)'), findsOneWidget);
      expect(find.text('Card fictício um'), findsNothing);
      // Nada foi gravado até salvar.
      expect(_FakePsyRepo.calls, isEmpty);
      await tester.tap(find.text('Salvar'));
      await _settle(tester, 6);
      expect(_FakePsyRepo.calls, ['updateModule:m1:2']);
    });

    testWidgets('celular remove sem o diálogo novo (comportamento de hoje)',
        (tester) async {
      await _pump(tester, phone, '/platform/psychoeducation/m1');
      expect(find.text('Recolher menu'), findsNothing);
      expect(find.text('Remover card?'), findsNothing);
      tester.takeException(); // estouro de 23 px que já existe no celular
    });

    testWidgets('tablet sem overflow', (tester) async {
      await _pump(tester, tablet, '/platform/psychoeducation/m1');
      expect(find.text('Cards (3)'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('Hover das linhas', () {
    for (final (nome, rota, linha) in [
      ('Biblioteca', '/platform/library', 'Obra Exemplo 1'),
      ('Psicoeducação', '/platform/psychoeducation', 'Módulo Exemplo 1'),
      ('Cards do módulo', '/platform/psychoeducation/m1', 'Card fictício dois'),
    ]) {
      testWidgets('$nome: fade só no fundo, sem piscada', (tester) async {
        await _pump(tester, desk, rota);
        await expectSmoothRowHover(tester, find.text(linha));
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('Índice do editor da biblioteca: sem piscada', (tester) async {
      await _pump(tester, desk, '/platform/library/w1');
      await expectSmoothRowHover(
          tester,
          find.descendant(
              of: find.byType(DaIndexItem).at(1),
              matching: find.byType(Text)));
      expect(tester.takeException(), isNull);
    });
  });
}
