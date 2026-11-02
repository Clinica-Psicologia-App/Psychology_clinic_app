import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/life_story/domain/life_timeline_age.dart';
import 'package:terapia_esquema/features/patient_timeline/domain/patient_timeline_event.dart';

PatientTimelineEvent _event({int? age, int? ageTo}) => PatientTimelineEvent(
      id: '1',
      clinicId: 'c',
      patientId: 'p',
      title: 'Mudança de cidade',
      ageAtEvent: age,
      ageTo: ageTo,
      isSensitive: false,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

void main() {
  group('LifeAgeSpan', () {
    test('uma idade é ponto', () {
      const span = LifeAgeSpan(start: 15);
      expect(span.isRange, isFalse);
      expect(span.label, '15 anos');
      expect(span.shortLabel, '15a');
    });

    test('1 ano no singular', () {
      expect(const LifeAgeSpan(start: 1).label, '1 ano');
    });

    test('idade final maior que a inicial é faixa', () {
      const span = LifeAgeSpan(start: 15, end: 18);
      expect(span.isRange, isTrue);
      expect(span.label, '15 a 18 anos');
      expect(span.shortLabel, '15–18a');
    });

    test('idade final igual à inicial continua sendo ponto', () {
      const span = LifeAgeSpan(start: 15, end: 15);
      expect(span.isRange, isFalse);
      expect(span.label, '15 anos');
    });

    test('sem idade inicial não há rótulo', () {
      expect(const LifeAgeSpan().label, isNull);
      expect(const LifeAgeSpan(end: 18).label, isNull);
    });

    test('validação: final sem inicial e final menor que inicial', () {
      expect(LifeAgeSpan.validate(start: 15, end: 18), isNull);
      expect(LifeAgeSpan.validate(start: 15), isNull);
      expect(LifeAgeSpan.validate(), isNull);
      expect(LifeAgeSpan.validate(end: 18), isNotNull);
      expect(LifeAgeSpan.validate(start: 18, end: 15), isNotNull);
    });
  });

  group('PatientTimelineEvent.dateLabel', () {
    test('ponto', () => expect(_event(age: 7).dateLabel, '7 anos'));
    test('faixa', () => expect(_event(age: 7, ageTo: 10).dateLabel, '7 a 10 anos'));
    test('evento antigo sem idade final segue igual',
        () => expect(_event(age: 1).dateLabel, '1 ano'));
  });
}
