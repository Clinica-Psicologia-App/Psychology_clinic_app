import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';

void main() {
  test('PatientContent lê os textos e ignora campos vazios', () {
    final content = PatientContent.fromJson({
      'intro': ' Antes de começar. ',
      'fixed_question': '',
      'scale_labels': ['Nunca', 'Às vezes', 'Sempre'],
      'follow_up': 'Texto',
    });
    expect(content.intro, 'Antes de começar.');
    expect(content.fixedQuestion, isNull);
    expect(content.scaleLabels, ['Nunca', 'Às vezes', 'Sempre']);
    expect(content.followUp, 'Texto');
  });

  test('sem patient_content cai nos textos padrão', () {
    final q = Questionnaire.fromJson({
      'id': '1',
      'code': 'ATTACHMENT_STYLES_V1',
      'name': 'Estilos de Apego',
    });
    expect(q.patientContent.intro, isNull);
    expect(q.patientSpecificGuidance, contains('Sim'));
  });

  test('how_to_respond do banco substitui a orientação embutida', () {
    final q = Questionnaire.fromJson({
      'id': '1',
      'code': 'YCI_FOUNDATION_V1',
      'name': 'YCI',
      'patient_content': {'how_to_respond': 'Leia com atenção.'},
    });
    expect(q.patientSpecificGuidance, 'Leia com atenção.');
  });
}
