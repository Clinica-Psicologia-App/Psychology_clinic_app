import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/timeline_entry.dart';
import 'package:terapia_esquema/features/patient_infographic/domain/authorized_timeline_entry.dart';

void main() {
  test('rótulo: faixa, ponto, período livre e fase', () {
    expect(
      AuthorizedTimelineEntry.fromJson(
              {'id': '1', 'title': 'a', 'age_at_event': 7, 'age_to': 10})
          .periodLabel,
      '7 a 10 anos',
    );
    expect(
      AuthorizedTimelineEntry.fromJson(
              {'id': '1', 'title': 'a', 'age_at_event': 7}).periodLabel,
      '7 anos',
    );
    expect(
      AuthorizedTimelineEntry.fromJson(
              {'id': '1', 'title': 'a', 'period_label': ' Ensino médio '})
          .periodLabel,
      'Ensino médio',
    );
    expect(
      AuthorizedTimelineEntry.fromJson(
              {'id': '1', 'title': 'a', 'life_chapter': 'childhood'})
          .periodLabel,
      'Infância',
    );
  });

  test('ordem cronológica, sem idade no fim', () {
    final list = [
      AuthorizedTimelineEntry.fromJson({'id': '3', 'title': 'sem idade'}),
      AuthorizedTimelineEntry.fromJson(
          {'id': '2', 'title': 'b', 'age_at_event': 12}),
      AuthorizedTimelineEntry.fromJson(
          {'id': '1', 'title': 'a', 'age_at_event': 4}),
    ]..sort(AuthorizedTimelineEntry.compareChronologically);
    expect(list.map((e) => e.id), ['1', '2', '3']);
  });

  test('acontecimento sem autorização nasce escondido no modelo', () {
    final entry = TimelineEntry.fromJson(
        {'id': '1', 'patient_id': 'p', 'title': 'a'});
    expect(entry.sharedWithPatient, isFalse);
    expect(
      TimelineEntry.fromJson({
        'id': '1',
        'patient_id': 'p',
        'title': 'a',
        'shared_with_patient': true,
      }).sharedWithPatient,
      isTrue,
    );
  });
}
