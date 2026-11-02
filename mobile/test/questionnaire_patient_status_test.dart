import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_patient_status.dart';

({String questionnaireId, String status}) _row(String q, String s) =>
    (questionnaireId: q, status: s);

void main() {
  test('rascunho vence concluído, em qualquer ordem', () {
    final a = consolidatePatientResponseStatuses(
      [_row('parentais', 'completed'), _row('parentais', 'draft')],
    );
    final b = consolidatePatientResponseStatuses(
      [_row('parentais', 'draft'), _row('parentais', 'completed')],
    );
    expect(a['parentais'], QuestionnairePatientStatus.draft);
    expect(b['parentais'], QuestionnairePatientStatus.draft);
  });

  test('só concluídas resulta em concluído', () {
    final r = consolidatePatientResponseStatuses(
      [_row('yami', 'completed'), _row('yami', 'completed')],
    );
    expect(r['yami'], QuestionnairePatientStatus.completed);
  });

  test('cada questionário é consolidado separadamente', () {
    final r = consolidatePatientResponseStatuses(
      [_row('yami', 'completed'), _row('parentais', 'draft')],
    );
    expect(r['yami'], QuestionnairePatientStatus.completed);
    expect(r['parentais'], QuestionnairePatientStatus.draft);
  });
}
