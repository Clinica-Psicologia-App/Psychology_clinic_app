import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:terapia_esquema/features/auth/providers/auth_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/domain/user_profile.dart';
import 'package:terapia_esquema/features/questionnaires/data/questionnaires_repository.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_access_item.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_access_management_data.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_catalog_visibility.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_professional_option.dart';
import 'package:terapia_esquema/features/questionnaires/domain/reference_period.dart';
import 'package:terapia_esquema/features/questionnaires/presentation/questionnaire_access_management_page.dart';
import 'package:terapia_esquema/features/questionnaires/providers/questionnaires_providers.dart';

void main() {
  test('Questionnaire.fromJson parses catalog metadata', () {
    final questionnaire = Questionnaire.fromJson({
      'id': 'q-1',
      'code': 'YSQ_FOUNDATION_V1',
      'name': 'YSQ',
      'is_active': true,
      'author_name': 'Jeffrey E. Young',
      'instrument_version': 'Foundation v1',
      'citation': 'Manual clínico',
      'license_notes': 'Pendente validação clínica/licenciamento.',
      'questionnaire_versions': [
        {'reference_period': 'last_year'},
      ],
    });

    expect(questionnaire.authorName, 'Jeffrey E. Young');
    expect(questionnaire.instrumentVersion, 'Foundation v1');
    expect(questionnaire.citation, 'Manual clínico');
    expect(questionnaire.hasLicensePendingValidation, isTrue);
    expect(questionnaire.referencePeriod, ReferencePeriod.lastYear);
  });

  test('Questionnaire.fromJson keeps fallback compatibility without FH-03 fields', () {
    final questionnaire = Questionnaire.fromJson({
      'id': 'q-2',
      'code': 'YCI_FOUNDATION_V1',
      'name': 'YCI',
      'is_active': true,
    });

    expect(questionnaire.authorName, isNull);
    expect(questionnaire.instrumentVersion, isNull);
    expect(questionnaire.citation, isNull);
    expect(questionnaire.licenseNotes, isNull);
    expect(questionnaire.hasLicensePendingValidation, isFalse);
  });

  test('visibleQuestionnairesFromEnabledIds filters professional access', () {
    final catalog = [
      _questionnaire('q-1', 'YSQ_FOUNDATION_V1'),
      _questionnaire('q-2', 'YAMI_MODES_FOUNDATION_V1'),
      _questionnaire('q-3', 'YCI_FOUNDATION_V1'),
    ];

    final visible = visibleQuestionnairesFromEnabledIds(
      catalog,
      enabledIds: {'q-1', 'q-3'},
      fallbackToAllWhenUnavailable: true,
    );

    expect(visible.map((item) => item.id), ['q-1', 'q-3']);
  });

  test('visibleQuestionnairesFromEnabledIds falls back to full catalog when migration 022 is unavailable', () {
    final catalog = [
      _questionnaire('q-1', 'YSQ_FOUNDATION_V1'),
      _questionnaire('q-2', 'YAMI_MODES_FOUNDATION_V1'),
    ];

    final visible = visibleQuestionnairesFromEnabledIds(
      catalog,
      enabledIds: null,
      fallbackToAllWhenUnavailable: true,
    );

    expect(visible.map((item) => item.id), ['q-1', 'q-2']);
  });

  test('questionnairesListProvider resolves own patient id before listing questionnaires for patient', () async {
    final repo = _RecordingQuestionnairesRepository();
    final container = ProviderContainer(
      overrides: [
        questionnairesRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final result = await container.read(
      questionnairesListProvider(
        const QuestionnaireListContext(role: ProfileRole.patient),
      ).future,
    );

    expect(repo.lastRole, ProfileRole.patient);
    expect(repo.lastPatientId, 'patient-self');
    expect(result.single.code, 'YSQ_FOUNDATION_V1');
  });

  testWidgets('admin sees questionnaire access management page with fallback warning', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authControllerProvider.overrideWith(
            (ref) => _FakeAuthController(
              const UserProfile(
                id: 'admin-1',
                clinicId: 'clinic-1',
                role: ProfileRole.admin,
                fullName: 'Admin',
                email: 'admin@example.com',
                isActive: true,
              ),
            ),
          ),
          questionnaireStaffOptionsProvider.overrideWith(
            (ref) async => const [
              QuestionnaireProfessionalOption(
                id: 'pro-1',
                fullName: 'Dra. Ana',
                email: 'ana@example.com',
                role: ProfileRole.psychologist,
              ),
            ],
          ),
          questionnaireAccessManagementProvider.overrideWith(
            (ref, professionalId) async => QuestionnaireAccessManagementData(
              supportsAccessControl: false,
              items: [
                QuestionnaireAccessItem(
                  questionnaire: _questionnaire(
                    'q-1',
                    'YSQ_FOUNDATION_V1',
                    licenseNotes: 'Pendente validação clínica/licenciamento.',
                  ),
                  isEnabled: true,
                ),
              ],
            ),
          ),
        ],
        child: const MaterialApp(
          home: QuestionnaireAccessManagementPage(),
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.text('Selecione um profissional'), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Dra. Ana').last);
    await tester.pumpAndSettle();

    expect(find.text('Controle de acesso indisponível'), findsOneWidget);
    expect(find.text('YSQ_FOUNDATION_V1'), findsOneWidget);
  });
}

Questionnaire _questionnaire(
  String id,
  String code, {
  String? licenseNotes,
}) {
  return Questionnaire(
    id: id,
    code: code,
    name: code,
    isActive: true,
    licenseNotes: licenseNotes,
  );
}

class _RecordingQuestionnairesRepository extends QuestionnairesRepository {
  _RecordingQuestionnairesRepository()
      : super(
          client: SupabaseClient(
            'https://example.com',
            'public-anon-key',
          ),
        );

  ProfileRole? lastRole;
  String? lastPatientId;

  @override
  Future<String> getPatientIdForCurrentProfile() async => 'patient-self';

  @override
  Future<List<Questionnaire>> listVisibleQuestionnaires({
    required ProfileRole role,
    required String patientId,
  }) async {
    lastRole = role;
    lastPatientId = patientId;
    return [_questionnaire('q-1', 'YSQ_FOUNDATION_V1')];
  }
}

class _FakeAuthController extends AuthController {
  _FakeAuthController(UserProfile profile) : super(_DummyRef()) {
    _profile = profile;
    state = AsyncValue.data(profile);
  }

  late final UserProfile _profile;

  @override
  Future<void> signOut() async {
    state = const AsyncValue.data(null);
  }

  @override
  Future<void> loadProfile() async {
    state = AsyncValue.data(_profile);
  }
}

class _DummyRef implements Ref {
  @override
  ProviderSubscription<T> listen<T>(
    ProviderListenable<T> provider,
    void Function(T? previous, T next) listener, {
    void Function(Object error, StackTrace stackTrace)? onError,
    bool? fireImmediately,
  }) {
    return _DummyProviderSubscription<T>();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _DummyProviderSubscription<T> implements ProviderSubscription<T> {
  @override
  void close() {}

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
