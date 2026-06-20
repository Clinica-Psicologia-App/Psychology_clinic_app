import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/domain/reference_period.dart';

void main() {
  group('referencePeriodFromStorage', () {
    test('maps known values', () {
      expect(
          referencePeriodFromStorage('last_month'), ReferencePeriod.lastMonth);
      expect(referencePeriodFromStorage('last_year'), ReferencePeriod.lastYear);
      expect(referencePeriodFromStorage('lifetime'), ReferencePeriod.lifetime);
      expect(
        referencePeriodFromStorage('unspecified'),
        ReferencePeriod.unspecified,
      );
    });

    test('falls back to unspecified for null, empty and unknown', () {
      expect(referencePeriodFromStorage(null), ReferencePeriod.unspecified);
      expect(referencePeriodFromStorage(''), ReferencePeriod.unspecified);
      expect(
          referencePeriodFromStorage('last_week'), ReferencePeriod.unspecified);
    });
  });

  group('patientOrientationMessage', () {
    test('last_year text', () {
      expect(
        ReferencePeriod.lastYear.patientOrientationMessage,
        contains('últimos 12 meses'),
      );
    });

    test('last_month text', () {
      expect(
        ReferencePeriod.lastMonth.patientOrientationMessage,
        contains('último mês'),
      );
    });

    test('lifetime text', () {
      expect(
        ReferencePeriod.lifetime.patientOrientationMessage,
        contains('história de vida'),
      );
    });

    test('unspecified has no message', () {
      expect(ReferencePeriod.unspecified.patientOrientationMessage, isNull);
      expect(ReferencePeriod.unspecified.showsPatientOrientation, isFalse);
    });
  });

  group('referencePeriodFromQuestionnaireJson', () {
    test('reads nested active version list', () {
      final period = referencePeriodFromQuestionnaireJson({
        'id': 'q1',
        'questionnaire_versions': [
          {'reference_period': 'last_year'},
        ],
      });
      expect(period, ReferencePeriod.lastYear);
    });

    test('reads single nested map', () {
      final period = referencePeriodFromQuestionnaireJson({
        'questionnaire_versions': {'reference_period': 'last_month'},
      });
      expect(period, ReferencePeriod.lastMonth);
    });

    test('reads flat reference_period', () {
      expect(
        referencePeriodFromQuestionnaireJson({'reference_period': 'lifetime'}),
        ReferencePeriod.lifetime,
      );
    });

    test('missing nested data defaults to unspecified', () {
      expect(
        referencePeriodFromQuestionnaireJson({'id': 'q1'}),
        ReferencePeriod.unspecified,
      );
    });
  });

  group('Questionnaire.fromJson', () {
    test('parses reference period from list row', () {
      final q = Questionnaire.fromJson({
        'id': 'q-ysq',
        'code': 'YSQ_FOUNDATION_V1',
        'name': 'YSQ',
        'is_active': true,
        'questionnaire_versions': [
          {'reference_period': 'last_year'},
        ],
      });
      expect(q.referencePeriod, ReferencePeriod.lastYear);
    });

    test('legacy row without versions uses unspecified', () {
      final q = Questionnaire.fromJson({
        'id': 'q-demo',
        'code': 'MVP_DEMO',
        'name': 'Demo',
        'is_active': true,
      });
      expect(q.referencePeriod, ReferencePeriod.unspecified);
    });
  });
}
