import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patients/data/patients_repository.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/presentation/patient_details_page.dart';
import 'package:terapia_esquema/features/patients/presentation/widgets/patient_registration_widgets.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

class _FakePatientsRepository implements PatientsRepository {
  final statusCalls = <({String patientId, bool isActive})>[];

  @override
  Future<Patient> setPatientActiveStatus({
    required String patientId,
    required bool isActive,
  }) async {
    statusCalls.add((patientId: patientId, isActive: isActive));
    return _patient(isActive: isActive);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Patient _patient({bool isActive = true}) => Patient(
      id: 'p1',
      fullName: 'Guilherme Souza',
      email: 'guilherme.paciente@gmail.com',
      phone: '51999998888',
      cpf: '12345678901',
      birthDate: DateTime(2002, 2, 28),
      gender: 'male',
      relationshipStatus: 'married',
      occupation: 'Analista',
      isActive: isActive,
      accessStatus: PatientAccessStatus.active,
    );

Widget _app(Widget child, {List<Override> overrides = const []}) {
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(body: SingleChildScrollView(child: child)),
    ),
  );
}

void main() {
  group('idade', () {
    test('conta anos completos, sem adiantar antes do aniversário', () {
      final birth = DateTime(2002, 2, 28);
      expect(patientAgeYears(birth, DateTime(2026, 2, 27)), 23);
      expect(patientAgeYears(birth, DateTime(2026, 2, 28)), 24);
      expect(patientAgeYears(birth, DateTime(2026, 11, 9)), 24);
    });

    test('data de nascimento no futuro não dá idade negativa', () {
      expect(patientAgeYears(DateTime(2030, 1, 1), DateTime(2026, 1, 1)), 0);
    });
  });

  testWidgets('a identificação resumida mostra idade, nascimento, profissão e estado civil',
      (tester) async {
    await tester.pumpWidget(_app(
      PatientIdentificationSummary(
        patient: _patient(),
        now: DateTime(2026, 11, 9),
      ),
    ));
    expect(find.text('24 anos'), findsOneWidget);
    expect(find.text('Analista'), findsOneWidget);
    expect(find.text('Idade'), findsOneWidget);
    expect(find.text('Nascimento'), findsOneWidget);
    expect(find.text('Estado civil'), findsOneWidget);
  });

  group('copiar dados', () {
    late List<String> copied;

    setUp(() {
      copied = [];
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, (call) async {
        if (call.method == 'Clipboard.setData') {
          copied.add((call.arguments as Map)['text'] as String);
        }
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    testWidgets('copia o e-mail', (tester) async {
      await tester.pumpWidget(
          _app(PatientRegistrationDataCard(patient: _patient())));
      await tester.tap(find.byTooltip('Copiar E-mail'));
      await tester.pump();
      expect(copied, ['guilherme.paciente@gmail.com']);
      expect(find.text('E-mail copiado.'), findsOneWidget);
    });

    testWidgets('copia o nascimento em dd/mm/aaaa', (tester) async {
      await tester.pumpWidget(
          _app(PatientRegistrationDataCard(patient: _patient())));
      await tester.tap(find.byTooltip('Copiar Nascimento'));
      await tester.pump();
      expect(copied, ['28/02/2002']);
    });

    testWidgets('copia o CPF completo mesmo mascarado na tela', (tester) async {
      await tester.pumpWidget(
          _app(PatientRegistrationDataCard(patient: _patient())));
      expect(find.text('***.***.789-**'), findsOneWidget);
      await tester.tap(find.byTooltip('Copiar CPF'));
      await tester.pump();
      expect(copied, ['12345678901']);
    });
  });

  group('situação do acompanhamento', () {
    testWidgets('inativar pede confirmação e Cancelar não altera nada',
        (tester) async {
      final repo = _FakePatientsRepository();
      await tester.pumpWidget(_app(
        PatientLifecycleCard(patient: _patient()),
        overrides: [patientsRepositoryProvider.overrideWithValue(repo)],
      ));

      await tester.tap(find.text('Inativar acesso'));
      await tester.pumpAndSettle();
      expect(find.text('Inativar acesso?'), findsOneWidget);
      expect(find.textContaining('conceitualização'), findsOneWidget);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(repo.statusCalls, isEmpty);
    });

    testWidgets('confirmar chama só a mudança de situação, sem excluir',
        (tester) async {
      final repo = _FakePatientsRepository();
      await tester.pumpWidget(_app(
        PatientLifecycleCard(patient: _patient()),
        overrides: [
          patientsRepositoryProvider.overrideWithValue(repo),
          patientDetailProvider.overrideWith((ref, id) => _patient()),
          patientsListProvider.overrideWith(() => _NoopListNotifier()),
        ],
      ));

      await tester.tap(find.text('Inativar acesso'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Inativar'));
      await tester.pumpAndSettle();

      expect(repo.statusCalls.single, (patientId: 'p1', isActive: false));
    });
  });

  testWidgets('a ficha do admin continua com dados, situação e exclusão',
      (tester) async {
    tester.view.physicalSize = const Size(460, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(ProviderScope(
      overrides: [patientDetailProvider.overrideWith((ref, id) => _patient())],
      child: const MaterialApp(
        locale: Locale('pt', 'BR'),
        supportedLocales: [Locale('pt', 'BR')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: PatientDetailsPage(
            patientId: 'p1', role: ProfileRole.platformAdmin),
      ),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Dados do paciente'), findsOneWidget);
    expect(find.text('Editar paciente'), findsOneWidget);
    expect(find.text('Dados cadastrais'), findsNothing);
    await tester.scrollUntilVisible(
      find.text('Excluir paciente definitivamente'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Excluir paciente definitivamente'), findsOneWidget);
  });
}

class _NoopListNotifier extends PatientsListNotifier {
  @override
  Future<List<Patient>> build() async => const [];

  @override
  Future<void> refresh() async {}
}
