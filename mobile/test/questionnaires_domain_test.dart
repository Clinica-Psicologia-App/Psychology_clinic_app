import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/questionnaires/supported_questionnaire_codes.dart';
import 'package:terapia_esquema/features/questionnaires/domain/question_answer_type.dart';
import 'package:terapia_esquema/features/questionnaires/domain/parental_contexts.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_question.dart';
import 'package:terapia_esquema/features/questionnaires/domain/questionnaire_session.dart';
import 'package:terapia_esquema/features/questionnaires/domain/reference_period.dart';

void main() {
  test('QuestionnaireSession.fromStartResponse parses questions', () {
    final session = QuestionnaireSession.fromStartResponse(
      {
        'response': {
          'id': 'resp-1',
          'status': 'draft',
        },
        'questionnaire': {
          'id': 'q-1',
          'code': 'MVP_DEMO',
          'name': 'Demo',
          'is_active': true,
        },
        'questions': [
          {
            'id': 'p2',
            'code': 'Q02',
            'text': 'Pergunta 2',
            'order_index': 1,
            'answer_type': 'likert_scale',
            'scale_min': 1,
            'scale_max': 6,
          },
          {
            'id': 'p1',
            'code': 'Q01',
            'text': 'Pergunta 1',
            'order_index': 0,
            'answer_type': 'likert_scale',
            'scale_min': 1,
            'scale_max': 6,
          },
        ],
      },
      'patient-1',
    );

    expect(session.responseId, 'resp-1');
    expect(session.questions.length, 2);
    expect(session.questions.first.code, 'Q01');
    expect(session.questions.last.code, 'Q02');
  });

  test('QuestionnaireSession.fromStartResponse parses contexts', () {
    final session = QuestionnaireSession.fromStartResponse(
      {
        'response': {'id': 'resp-ctx'},
        'questionnaire': {
          'id': 'q-parental',
          'code': 'PARENTAL_STYLES_V1',
          'name': 'Estilos Parentais',
          'is_active': true,
        },
        'questions': const [],
        'contexts': [
          {
            'id': 'c2',
            'context_type': 'parental_figure',
            'context_key': 'father',
            'context_label': 'Pai',
            'sort_order': 1,
            'status': 'draft',
          },
          {
            'id': 'c1',
            'context_type': 'parental_figure',
            'context_key': 'mother',
            'context_label': 'Mãe',
            'sort_order': 0,
            'status': 'draft',
          },
        ],
      },
      'patient-1',
    );

    expect(session.hasContexts, isTrue);
    expect(session.contexts.first.label, 'Mãe');
    expect(session.contexts.last.label, 'Pai');
  });

  test('QuestionnaireQuestion.validateAnswer enforces scale', () {
    const question = QuestionnaireQuestion(
      id: 'p1',
      code: 'Q01',
      text: 'Texto',
      orderIndex: 0,
      answerType: QuestionAnswerType.likertScale,
      scaleMin: 1,
      scaleMax: 6,
    );

    expect(question.validateAnswer(null), isNotNull);
    expect(question.validateAnswer(4), isNull);
    expect(question.validateAnswer(9), isNotNull);
  });

  test('QuestionnaireQuestion.answerLabelFor maps boolean single choice', () {
    const question = QuestionnaireQuestion(
      id: 'p-bin',
      code: 'ATT_01',
      text: 'Texto',
      orderIndex: 0,
      answerType: QuestionAnswerType.singleChoice,
      scaleMin: 0,
      scaleMax: 1,
    );

    expect(question.answerLabelFor(0), 'Não');
    expect(question.answerLabelFor(1), 'Sim');
  });

  test('Questionnaire exposes parental styles guidance', () {
    final questionnaire = Questionnaire.fromJson({
      'id': 'q-parental',
      'code': 'PARENTAL_STYLES_V1',
      'name': 'Estilos Parentais',
      'is_active': true,
      'questionnaire_versions': [
        {'reference_period': 'lifetime'},
      ],
    });

    expect(questionnaire.isParentalStyles, isTrue);
    expect(questionnaire.referencePeriod, ReferencePeriod.lifetime);
    expect(
        questionnaire.patientSpecificGuidance, contains('figuras parentais'));
  });

  test('questionnaire start respects clinical approval and local override', () {
    const pending = Questionnaire(
      id: 'pending',
      code: 'PENDING',
      name: 'Pendente',
      isActive: true,
    );
    const approved = Questionnaire(
      id: 'approved',
      code: 'APPROVED',
      name: 'Aprovado',
      isActive: true,
      clinicalStatus: QuestionnaireClinicalStatus.approved,
    );

    expect(pending.canStart(allowUnvalidated: false), isFalse);
    expect(pending.canStart(allowUnvalidated: true), isTrue);
    expect(approved.canStart(allowUnvalidated: false), isTrue);
  });

  test('parental context selection requires at least one caregiver', () {
    expect(
      validateParentalContextSelection(
        caregivers: const [
          CaregiverInput(enabled: false),
          CaregiverInput(enabled: false),
          CaregiverInput(enabled: false),
        ],
      ),
      contains('pelo menos um'),
    );
  });

  test('parental context selection requires role when caregiver is enabled',
      () {
    expect(
      validateParentalContextSelection(
        caregivers: const [
          CaregiverInput(enabled: true, role: null),
          CaregiverInput(enabled: false),
          CaregiverInput(enabled: false),
        ],
      ),
      contains('Cuidador(a) 1'),
    );
  });

  test('parental context selection requires text fields when "outro" selected',
      () {
    expect(
      validateParentalContextSelection(
        caregivers: const [
          CaregiverInput(
              enabled: true, role: 'outro', otherText1: '', otherText2: ''),
          CaregiverInput(enabled: false),
          CaregiverInput(enabled: false),
        ],
      ),
      contains('Cuidador(a) 1'),
    );
  });

  test('buildParentalContextInputs builds selected contexts', () {
    final items = buildParentalContextInputs(
      caregivers: const [
        CaregiverInput(enabled: true, role: 'mae'),
        CaregiverInput(enabled: false, role: 'pai'),
        CaregiverInput(enabled: true, role: 'avo'),
      ],
    );

    expect(items.length, 2);
    expect(items.first.label, 'Mãe');
    expect(items.last.label, 'Avó');
  });

  test('buildParentalContextInputs uses "outro" text fields as label', () {
    final items = buildParentalContextInputs(
      caregivers: const [
        CaregiverInput(
          enabled: true,
          role: 'outro',
          otherText1: 'Maria',
          otherText2: 'Tia-avó',
        ),
        CaregiverInput(enabled: false),
        CaregiverInput(enabled: false),
      ],
    );

    expect(items.length, 1);
    expect(items.first.label, 'Maria — Tia-avó');
    expect(items.first.key, 'other');
  });

  test('normalizeParentalQuestionText strips parent prefix', () {
    expect(
      normalizeParentalQuestionText('Mãe: Gostava de mim'),
      'Gostava de mim',
    );
    expect(
      normalizeParentalQuestionText('Pai: Costumava me ouvir'),
      'Costumava me ouvir',
    );
  });

  test('progressForContext tracks answers per figure', () {
    final answers = {
      'mother::q1': 3,
      'mother::q2': 4,
      'father::q1': 2,
    };

    expect(
      progressForContext(
        contextId: 'mother',
        answers: answers,
        totalQuestions: 4,
      ),
      0.5,
    );
    expect(
      progressForContext(
        contextId: 'father',
        answers: answers,
        totalQuestions: 4,
      ),
      0.25,
    );
  });

  test('Questionnaire exposes attachment styles guidance', () {
    final questionnaire = Questionnaire.fromJson({
      'id': 'q-attachment',
      'code': 'ATTACHMENT_STYLES_V1',
      'name': 'Estilos de Apego',
      'is_active': true,
    });

    expect(questionnaire.isAttachmentStyles, isTrue);
    expect(questionnaire.patientSpecificGuidance, contains('Marque "Sim"'));
  });

  test('supported questionnaire codes exclude demo instruments', () {
    expect(isSupportedQuestionnaireCode('YSQ_FOUNDATION_V1'), isTrue);
    expect(isSupportedQuestionnaireCode('YAMI_MODES_FOUNDATION_V1'), isTrue);
    expect(isSupportedQuestionnaireCode('MVP_DEMO'), isFalse);
  });
}
