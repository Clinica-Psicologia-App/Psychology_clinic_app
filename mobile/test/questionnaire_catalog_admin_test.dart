import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_catalog_admin.dart';

void main() {
  group('QuestionnaireCatalogAdminItem', () {
    test('draft inactive instrument is editable', () {
      final item = QuestionnaireCatalogAdminItem.fromJson({
        'id': 'questionnaire-id',
        'code': 'CUSTOM_V1',
        'name': 'Instrumento personalizado',
        'is_active': false,
        'clinical_status': 'draft',
        'question_count': 3,
        'response_count': 0,
        'version': '1.0',
        'version_status': 'draft',
      });

      expect(item.isEditable, isTrue);
      expect(item.questionCount, 3);
      expect(item.responseCount, 0);
    });

    test('published instrument is immutable', () {
      final item = QuestionnaireCatalogAdminItem.fromJson({
        'id': 'questionnaire-id',
        'code': 'CUSTOM_V1',
        'name': 'Instrumento publicado',
        'is_active': true,
        'clinical_status': 'approved',
        'question_count': 10,
        'response_count': 2,
      });

      expect(item.isEditable, isFalse);
    });
  });

  test('catalog detail parses scoring configuration', () {
    final detail = QuestionnaireCatalogDetail.fromJson({
      'questionnaire': {
        'id': 'questionnaire-id',
        'is_active': false,
        'clinical_status': 'draft',
      },
      'version': {'id': 'version-id', 'version': '1.0'},
      'questions': [
        {
          'id': 'question-id',
          'code': 'Q1',
          'text': 'Pergunta de teste',
          'order_index': 0,
          'answer_type': 'likert_scale',
          'scale_min': 1,
          'scale_max': 5,
          'weight': 2.5,
          'reverse_score': true,
        }
      ],
    });

    expect(detail.isEditable, isTrue);
    expect(detail.questions.single.weight, 2.5);
    expect(detail.questions.single.reverseScore, isTrue);
  });
}
