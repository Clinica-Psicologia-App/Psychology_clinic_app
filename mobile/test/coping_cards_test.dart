import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:terapia_esquema/core/errors/app_exception.dart';
import 'package:terapia_esquema/features/daily_monitors/providers/daily_monitors_providers.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/psychoeducation/domain/coping_card.dart';
import 'package:terapia_esquema/features/psychoeducation/providers/coping_cards_provider.dart';
import 'package:terapia_esquema/features/results/data/results_repository.dart';
import 'package:terapia_esquema/features/results/domain/patient_response_summary.dart';
import 'package:terapia_esquema/features/results/domain/patient_result_detail.dart';
import 'package:terapia_esquema/features/results/providers/results_providers.dart';

PatientResultDetail detail(String id, String code,
        {String status = 'completed', String patient = 'patient'}) =>
    PatientResultDetail.fromJson({
      'id': id,
      'patient_id': patient,
      'questionnaire_id': code,
      'questionnaire': {'id': code, 'code': code, 'name': code},
      'status': status,
      'completed_at':
          id == 'old' ? '2026-10-01T12:00:00Z' : '2026-10-21T12:00:00Z',
      'questionnaire_results': [
        {
          'id': 'r1',
          'category': {'code': 'style', 'name': 'Tema sintético'},
          'average_score': 2,
          'professional_note': 'PRIVATE_SENTINEL'
        },
      ],
    });

class FakeResults extends ResultsRepository {
  FakeResults(this.details)
      : super(client: SupabaseClient('https://example.test', 'anon'));
  final List<PatientResultDetail> details;
  final requested = <String>[];
  @override
  Future<List<PatientResponseSummary>> listPatientResponses(String patientId,
          {bool onlyReviewed = false}) async =>
      details.map((d) => d.toSummary()).toList();
  @override
  Future<PatientResultDetail?> getResponseDetail(String id,
      {bool requireReviewed = false}) async {
    requested.add(id);
    return details.firstWhere((d) => d.id == id);
  }
}

void main() {
  test('cards accept only completed YCI/YRAI and contain no private note', () {
    for (final code in ['YCI_FOUNDATION_V1', 'YRAI_FOUNDATION_V1']) {
      final cards = CopingCard.fromResult(detail('latest', code));
      expect(cards.single.topic, 'Tema sintético');
      expect(cards.single.source, code.startsWith('YCI') ? 'YCI' : 'YRAI');
      expect(cards.single.observation, isNot(contains('PRIVATE_SENTINEL')));
      expect(CopingCard.fromResult(detail('draft', code, status: 'draft')),
          isEmpty);
    }
    expect(
        CopingCard.fromResult(detail('other', 'YSQ_FOUNDATION_V1')), isEmpty);
  });

  test(
      'only latest completed result per instrument is fetched, never drafts or YSQ',
      () async {
    final repo = FakeResults([
      detail('old', 'YCI_FOUNDATION_V1'),
      detail('latest-yci', 'YCI_FOUNDATION_V1'),
      detail('draft', 'YCI_FOUNDATION_V1', status: 'draft'),
      detail('latest-yrai', 'YRAI_FOUNDATION_V1'),
      detail('ysq', 'YSQ_FOUNDATION_V1'),
    ]);
    final container = ProviderContainer(overrides: [
      myPatientIdProvider.overrideWith((ref) async => 'patient'),
      patientDetailProvider('patient').overrideWith((ref) async => Patient(
          id: 'patient', fullName: 'Teste', resultsReleasedAt: DateTime(2026))),
      resultsRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    final cards = await container.read(myCopingCardsProvider.future);
    expect(repo.requested, ['latest-yci', 'latest-yrai']);
    expect(cards.map((c) => c.source), ['YCI', 'YRAI']);
  });

  test('unreleased results gate stops before any results query', () async {
    final container = ProviderContainer(overrides: [
      myPatientIdProvider.overrideWith((ref) async => 'patient'),
      patientDetailProvider('patient').overrideWith(
          (ref) async => const Patient(id: 'patient', fullName: 'Teste')),
      resultsRepositoryProvider
          .overrideWith((ref) => throw StateError('must not query results')),
    ]);
    addTearDown(container.dispose);
    await expectLater(
        container.read(myCopingCardsProvider.future),
        throwsA(isA<AppException>()
            .having((e) => e.code, 'code', AppExceptionCodes.forbidden)));
  });

  test('release revocation removes cards after refreshing patient state',
      () async {
    var released = true;
    final repo = FakeResults([detail('latest', 'YCI_FOUNDATION_V1')]);
    final container = ProviderContainer(overrides: [
      myPatientIdProvider.overrideWith((ref) async => 'patient'),
      patientDetailProvider('patient').overrideWith((ref) async => Patient(
          id: 'patient',
          fullName: 'Teste',
          resultsReleasedAt: released ? DateTime(2026) : null)),
      resultsRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    final subscription = container.listen(myCopingCardsProvider, (_, __) {});
    addTearDown(subscription.close);
    expect(await container.read(myCopingCardsProvider.future), hasLength(1));
    released = false;
    container.invalidate(patientDetailProvider('patient'));
    await expectLater(container.read(myCopingCardsProvider.future),
        throwsA(isA<AppException>()));
    expect(repo.requested, ['latest']);
  });

  test('patient mismatch cannot become a card', () async {
    final repo =
        FakeResults([detail('latest', 'YCI_FOUNDATION_V1', patient: 'other')]);
    final container = ProviderContainer(overrides: [
      myPatientIdProvider.overrideWith((ref) async => 'patient'),
      patientDetailProvider('patient').overrideWith((ref) async => Patient(
          id: 'patient', fullName: 'Teste', resultsReleasedAt: DateTime(2026))),
      resultsRepositoryProvider.overrideWithValue(repo),
    ]);
    addTearDown(container.dispose);
    expect(await container.read(myCopingCardsProvider.future), isEmpty);
  });
}
