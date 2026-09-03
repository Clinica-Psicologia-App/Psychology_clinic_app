import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';

void main() {
  group('CaseConceptualization fromJson', () {
    test('lê origins (7.1/7.3/7.4), motivo_notes e demais seções', () {
      final c = CaseConceptualization.fromJson({
        'general_impressions': {'initial': 'reservada', 'current': 'aberta'},
        'diagnosis': {
          'system': 'CID-11',
          'items': [
            {'name': 'TAG', 'code': '6B00'}
          ]
        },
        'origins': {
          'early_history': 'pais distantes',
          'temperament': 'sensível',
          'cultural': 'ênfase em status',
        },
        'motivo_notes': 'complemento do terapeuta',
        'additional_comments': 'reavaliar',
      });

      expect(c.generalImpressions.initial, 'reservada');
      expect(c.diagnosis.system, 'CID-11');
      expect(c.diagnosis.items.single.code, '6B00');
      expect(c.origins.earlyHistory, 'pais distantes');
      expect(c.origins.temperament, 'sensível');
      expect(c.origins.cultural, 'ênfase em status');
      expect(c.motivoNotes, 'complemento do terapeuta');
      expect(c.additionalComments, 'reavaliar');
      expect(c.hasOrigins, isTrue);
      expect(c.hasMotivoNotes, isTrue);
    });

    test('documento vazio: getters has* são falsos', () {
      final c = CaseConceptualization.empty();
      expect(c.hasOrigins, isFalse);
      expect(c.hasMotivoNotes, isFalse);
      expect(c.hasGeneralImpressions, isFalse);
      expect(c.hasDiagnosis, isFalse);
      expect(c.hasComments, isFalse);
      // As 9 necessidades essenciais entram em branco.
      expect(c.unmetNeeds.length, kCoreNeeds.length);
      expect(c.hasAnyNeed, isFalse);
    });
  });

  group('CaseOrigins', () {
    test('toJson omite vazios e trima', () {
      const o = CaseOrigins(earlyHistory: '  história  ', temperament: '   ');
      final j = o.toJson();
      expect(j['early_history'], 'história');
      expect(j.containsKey('temperament'), isFalse);
      expect(j.containsKey('cultural'), isFalse);
    });

    test('isEmpty', () {
      expect(const CaseOrigins().isEmpty, isTrue);
      expect(const CaseOrigins(cultural: 'x').isEmpty, isFalse);
    });
  });
}
