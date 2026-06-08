import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/results/domain/category_result.dart';
import 'package:terapia_esquema/features/results/domain/patient_result_detail.dart';
import 'package:terapia_esquema/features/results/domain/patient_response_summary.dart';
import 'package:terapia_esquema/features/results/domain/result_disclaimer.dart';
import 'package:terapia_esquema/features/results/domain/result_snapshot.dart';
import 'package:terapia_esquema/features/results/domain/scoring_snapshot.dart';
import 'package:terapia_esquema/features/results/utils/likert_labels.dart';

Map<String, dynamic> _scoringDemoSnapshotJson() => {
      'version': 'scoring-demo-1',
      'category_code': 'DEMO_GERAL',
      'category_name': 'Categoria demonstração',
      'answer_count': 5,
      'total_weighted_score': 18,
      'average_score': 3.6,
      'note': 'Motor DEMO',
      'questionnaire_version': {
        'version': 'v1-demo',
        'scoring_method': 'weighted_sum_demo',
        'scale_min': 1,
        'scale_max': 6,
      },
      'completed_at': '2025-05-31T12:00:00.000Z',
      'summary': {
        'raw_score': 18,
        'weighted_score': 18,
        'average_score': 3.6,
        'answered_items': 5,
        'max_possible_score': 30,
      },
      'domains': [
        {
          'id': 'd1',
          'code': 'DEMO_DOMAIN_DISCONNECTION',
          'name': 'Demo — Domínio Desconexão',
          'raw_score': 7,
          'weighted_score': 7,
          'average_score': 3.5,
          'answered_items': 2,
          'max_possible_score': 12,
          'severity': null,
        },
      ],
      'schemas': [
        {
          'id': 's1',
          'code': 'DEMO_SCHEMA_ABANDONMENT',
          'name': 'Demo — Abandono',
          'raw_score': 4,
          'weighted_score': 4,
          'average_score': 4,
          'answered_items': 1,
          'max_possible_score': 6,
          'severity': {
            'label': 'Demo — Moderado',
            'color_key': 'severity_moderate',
            'min_score': 2.51,
            'max_score': 4,
          },
        },
      ],
      'items': [
        {
          'question_id': 'q1',
          'answer_value': 4,
          'adjusted_score': 4,
          'weight': 1,
          'weighted_score': 4,
          'schema_code': 'DEMO_SCHEMA_ABANDONMENT',
          'domain_code': 'DEMO_DOMAIN_DISCONNECTION',
        },
      ],
    };

void main() {
  test('ResultSnapshot.fromJson parses MVP snapshot', () {
    final snap = ResultSnapshot.fromJson({
      'version': 'mvp-1',
      'category_code': 'DEMO_GERAL',
      'category_name': 'Categoria demonstração',
      'answer_count': 5,
      'total_weighted_score': 18,
      'average_score': 3.6,
      'items': [
        {
          'question_id': 'q1',
          'answer_value': 4,
          'weight': 1,
          'weighted_score': 4,
        },
      ],
      'note': 'Placeholder',
    });

    expect(snap.version, 'mvp-1');
    expect(snap.categoryCode, 'DEMO_GERAL');
    expect(snap.totalWeightedScore, 18);
    expect(snap.items.length, 1);
    expect(snap.hasContent, isTrue);
    expect(snap.isScoringDemo, isFalse);
    expect(snap.scoring, isNull);
  });

  test('ResultSnapshot.fromJson parses scoring-demo-1 snapshot', () {
    final snap = ResultSnapshot.fromJson(_scoringDemoSnapshotJson());

    expect(snap.version, 'scoring-demo-1');
    expect(snap.isScoringDemo, isTrue);
    expect(snap.scoring, isNotNull);
    expect(snap.scoring!.summary.weightedScore, 18);
    expect(snap.scoring!.domains.length, 1);
    expect(snap.scoring!.schemas.length, 1);
    expect(snap.scoring!.items.length, 1);
    expect(snap.scoring!.schemas.first.hasSeverity, isTrue);
    expect(snap.scoring!.domains.first.hasSeverity, isFalse);
    expect(snap.scoring!.questionnaireVersionLabel, 'v1-demo');
  });

  test('ResultSnapshot.fromJson parses parental contexts snapshot', () {
    final snap = ResultSnapshot.fromJson({
      'version': 'parental-context-v1',
      'category_code': 'PARENTAL_CONTEXTS',
      'category_name': 'Estilos Parentais por figura',
      'contexts': [
        {
          'id': 'ctx-1',
          'key': 'mother',
          'label': 'Mãe',
          'status': 'completed',
          'answer_count': 72,
          'total_questions': 72,
          'completion_ratio': 1,
          'summary': {
            'weighted_score': 42,
            'average_score': 3.5,
            'answered_items': 72,
          },
          'schemas': [
            {
              'id': 's1',
              'code': 'MOTHER_ABANDONO',
              'name': 'Abandono — Mãe',
              'weighted_score': 12,
              'average_score': 4.0,
              'answered_items': 3,
              'max_possible_score': 18,
            },
          ],
        },
      ],
    });

    expect(snap.contexts.length, 1);
    expect(snap.contexts.first.label, 'Mãe');
    expect(snap.contexts.first.summary.averageScore, 3.5);
    expect(snap.contexts.first.schemas.first.name, 'Abandono — Mãe');
  });

  test('ResultSnapshot.fromJson returns empty on null', () {
    final snap = ResultSnapshot.fromJson(null);
    expect(snap.hasContent, isFalse);
    expect(snap.items, isEmpty);
    expect(snap.isScoringDemo, isFalse);
  });

  test('ScoringSnapshot handles empty domains and schemas', () {
    final snap = ResultSnapshot.fromJson({
      'version': 'scoring-demo-1',
      'summary': {
        'weighted_score': 10,
        'answered_items': 2,
      },
      'domains': [],
      'schemas': [],
      'items': [],
    });

    expect(snap.isScoringDemo, isTrue);
    expect(snap.scoring!.domains, isEmpty);
    expect(snap.scoring!.schemas, isEmpty);
    expect(snap.scoring!.summary.answeredItems, 2);
  });

  test('ScoringSeverity.fromJson handles null severity safely', () {
    final snap = ResultSnapshot.fromJson(_scoringDemoSnapshotJson());
    expect(snap.scoring!.domains.first.severity, isNull);
    expect(snap.scoring!.domains.first.hasSeverity, isFalse);
  });

  test('CategoryResult uses empty snapshot when null', () {
    final result = CategoryResult.fromJson({
      'id': 'r1',
      'total_score': 10,
      'classification': 'pending_review',
      'snapshot': null,
    });

    expect(result.snapshot.hasContent, isFalse);
    expect(result.classificationLabel, 'Aguardando revisão');
  });

  test('CategoryResult parses scoring-demo via snapshot', () {
    final result = CategoryResult.fromJson({
      'id': 'r1',
      'classification': 'pending_review',
      'snapshot': _scoringDemoSnapshotJson(),
    });

    expect(result.snapshot.isScoringDemo, isTrue);
    expect(result.snapshot.scoring?.schemas.first.severity?.label,
        'Demo — Moderado');
  });

  test('ResultSnapshot parses attachment structured schemas safely', () {
    final snap = ResultSnapshot.fromJson({
      'version': 'scoring-demo-1',
      'category_code': 'ATTACHMENT_ANXIOUS',
      'category_name': 'Ansioso',
      'answer_count': 42,
      'total_weighted_score': 14,
      'average_score': 0.33,
      'summary': {
        'weighted_score': 14,
        'average_score': 0.33,
        'answered_items': 42,
        'max_possible_score': 42,
      },
      'domains': [
        {
          'id': 'd-attachment',
          'code': 'ATTACHMENT_DOMAIN_STYLES',
          'name': 'Estilos de Apego',
          'weighted_score': 14,
          'average_score': 0.33,
          'answered_items': 42,
          'max_possible_score': 42,
          'severity': null,
        },
      ],
      'schemas': [
        {
          'id': 's-anxious',
          'code': 'ATTACHMENT_STYLE_ANXIOUS',
          'name': 'Ansioso',
          'weighted_score': 8,
          'average_score': 0.57,
          'answered_items': 14,
          'max_possible_score': 14,
          'severity': null,
        },
        {
          'id': 's-secure',
          'code': 'ATTACHMENT_STYLE_SECURE',
          'name': 'Seguro',
          'weighted_score': 4,
          'average_score': 0.29,
          'answered_items': 14,
          'max_possible_score': 14,
          'severity': null,
        },
      ],
      'items': const [],
    });

    expect(snap.isScoringDemo, isTrue);
    expect(snap.scoring?.domains.single.name, 'Estilos de Apego');
    expect(snap.scoring?.schemas.first.name, 'Ansioso');
    expect(snap.scoring?.schemas.first.hasSeverity, isFalse);
  });

  test('ResultSnapshot parses YCI structured schema safely', () {
    final snap = ResultSnapshot.fromJson({
      'version': 'scoring-demo-1',
      'category_code': 'YCI_TOTAL',
      'category_name': 'YCI Geral',
      'answer_count': 48,
      'total_weighted_score': 215,
      'average_score': 4.48,
      'questionnaire_version': {
        'version': 'v1',
        'scoring_method': 'legacy_category_average',
        'scale_min': 1,
        'scale_max': 6,
      },
      'summary': {
        'weighted_score': 215,
        'average_score': 4.48,
        'answered_items': 48,
        'max_possible_score': 288,
      },
      'domains': [
        {
          'id': 'd-yci',
          'code': 'COPING_DOMAIN_STYLES',
          'name': 'Estilos de Enfrentamento',
          'weighted_score': 215,
          'average_score': 4.48,
          'answered_items': 48,
          'max_possible_score': 288,
          'severity': null,
        },
      ],
      'schemas': [
        {
          'id': 's-yci',
          'code': 'YCI_TOTAL',
          'name': 'YCI Geral',
          'weighted_score': 215,
          'average_score': 4.48,
          'answered_items': 48,
          'max_possible_score': 288,
          'severity': null,
        },
      ],
      'items': const [],
    });

    expect(snap.isScoringDemo, isTrue);
    expect(snap.scoring?.domains.single.name, 'Estilos de Enfrentamento');
    expect(snap.scoring?.schemas.single.code, 'YCI_TOTAL');
    expect(snap.scoring?.schemas.single.name, 'YCI Geral');
    expect(snap.scoring?.schemas.single.averageScore, 4.48);
    expect(snap.scoring?.scaleMax, 6);
  });

  test('ResultSnapshot parses YRAI structured schema safely', () {
    final snap = ResultSnapshot.fromJson({
      'version': 'scoring-demo-1',
      'category_code': 'YRAI_TOTAL',
      'category_name': 'YRAI Geral',
      'answer_count': 40,
      'total_weighted_score': 154,
      'average_score': 3.85,
      'questionnaire_version': {
        'version': 'v1',
        'scoring_method': 'legacy_category_average',
        'scale_min': 1,
        'scale_max': 6,
      },
      'summary': {
        'weighted_score': 154,
        'average_score': 3.85,
        'answered_items': 40,
        'max_possible_score': 240,
      },
      'domains': [
        {
          'id': 'd-yrai',
          'code': 'COPING_DOMAIN_STYLES',
          'name': 'Estilos de Enfrentamento',
          'weighted_score': 154,
          'average_score': 3.85,
          'answered_items': 40,
          'max_possible_score': 240,
          'severity': null,
        },
      ],
      'schemas': [
        {
          'id': 's-yrai',
          'code': 'YRAI_TOTAL',
          'name': 'YRAI Geral',
          'weighted_score': 154,
          'average_score': 3.85,
          'answered_items': 40,
          'max_possible_score': 240,
          'severity': null,
        },
      ],
      'items': const [],
    });

    expect(snap.isScoringDemo, isTrue);
    expect(snap.scoring?.domains.single.name, 'Estilos de Enfrentamento');
    expect(snap.scoring?.schemas.single.code, 'YRAI_TOTAL');
    expect(snap.scoring?.schemas.single.name, 'YRAI Geral');
    expect(snap.scoring?.schemas.single.averageScore, 3.85);
    expect(snap.scoring?.scaleMax, 6);
  });

  test('CategoryResult derives parental figure and compact label', () {
    final mother = CategoryResult.fromJson({
      'id': 'r-m',
      'category': {'code': 'ABANDONMENT_MOTHER', 'name': 'Abandono — Mãe'},
      'snapshot': null,
    });
    final father = CategoryResult.fromJson({
      'id': 'r-p',
      'category': {'code': 'ABANDONMENT_FATHER', 'name': 'Abandono — Pai'},
      'snapshot': null,
    });

    expect(mother.parentalFigureLabel, 'Mãe');
    expect(mother.shortCategoryLabel, 'Abandono');
    expect(father.parentalFigureLabel, 'Pai');
    expect(father.shortCategoryLabel, 'Abandono');
  });

  test('PatientResponseSummary parses embedded counts', () {
    final summary = PatientResponseSummary.fromJson({
      'id': 'resp-1',
      'questionnaire_id': 'q-1',
      'status': 'completed',
      'completed_at': '2025-05-25T12:00:00Z',
      'reviewed_at': '2025-05-26T12:00:00Z',
      'review_notes': 'Revisado pela terapeuta.',
      'reviewed_by': {'full_name': 'Dra. Helena'},
      'questionnaire': {'id': 'q-1', 'code': 'MVP_DEMO', 'name': 'Demo'},
      'questionnaire_answers': [
        {'count': 5}
      ],
      'questionnaire_results': [
        {'count': 1}
      ],
    });

    expect(summary.answerCount, 5);
    expect(summary.hasResults, isTrue);
    expect(summary.resultsCount, 1);
    expect(summary.status.label, 'Concluído');
    expect(summary.isReviewed, isTrue);
    expect(summary.reviewedByName, 'Dra. Helena');
  });

  test('PatientResultDetail ignores pending review after therapist review', () {
    final detail = PatientResultDetail.fromJson({
      'id': 'resp-1',
      'patient_id': 'p-1',
      'questionnaire_id': 'q-1',
      'status': 'completed',
      'reviewed_at': '2025-05-26T12:00:00Z',
      'review_notes': 'Tudo coerente.',
      'reviewed_by': {'full_name': 'Dra. Helena'},
      'questionnaire': {
        'id': 'q-1',
        'code': 'YSQ_FOUNDATION_V1',
        'name': 'YSQ',
      },
      'questionnaire_answers': const [],
      'questionnaire_results': [
        {
          'id': 'r1',
          'classification': 'pending_review',
          'snapshot': null,
        },
      ],
    });

    expect(detail.isReviewed, isTrue);
    expect(detail.requiresTherapistReview, isFalse);
    expect(detail.reviewedByName, 'Dra. Helena');
  });

  test('PatientResultDetail exposes snapshot contexts when present', () {
    final detail = PatientResultDetail.fromJson({
      'id': 'resp-parental',
      'patient_id': 'p-1',
      'questionnaire_id': 'q-parental',
      'status': 'completed',
      'questionnaire': {
        'id': 'q-parental',
        'code': 'PARENTAL_STYLES_V1',
        'name': 'Estilos Parentais',
      },
      'questionnaire_answers': const [],
      'questionnaire_results': [
        {
          'id': 'r1',
          'classification': 'pending_review',
          'snapshot': {
            'version': 'parental-context-v1',
            'contexts': [
              {
                'id': 'ctx-1',
                'key': 'other',
                'label': 'Avó',
                'status': 'completed',
                'summary': {'average_score': 2.4},
                'schemas': const [],
              },
            ],
          },
        },
      ],
    });

    expect(detail.snapshotContexts.length, 1);
    expect(detail.snapshotContexts.first.label, 'Avó');
  });

  test('PatientResponseSummary fallback when no results', () {
    final summary = PatientResponseSummary.fromJson({
      'id': 'resp-2',
      'questionnaire_id': 'q-1',
      'status': 'draft',
      'questionnaire': {'id': 'q-1', 'code': 'X', 'name': 'Test'},
      'questionnaire_answers': [],
      'questionnaire_results': [],
    });

    expect(summary.hasResults, isFalse);
    expect(summary.resultsCount, 0);
  });

  test('likertLabel returns readable text for 1-6', () {
    expect(likertLabel(1, scaleMin: 1, scaleMax: 6), contains('Nunca'));
    expect(likertLabel(6, scaleMin: 1, scaleMax: 6), contains('Sempre'));
  });

  test('ScoringSnapshot.isDemoVersion identifies demo version', () {
    expect(ScoringSnapshot.isDemoVersion('scoring-demo-1'), isTrue);
    expect(ScoringSnapshot.isDemoVersion('mvp-1'), isFalse);
    expect(ScoringSnapshot.isDemoVersion(null), isFalse);
  });

  test('ResultStructuredDisclaimer MVP_DEMO message', () {
    expect(
      ResultStructuredDisclaimer.messageForStructuredSnapshot('MVP_DEMO'),
      'Resultado demonstrativo, sem validade clínica oficial.',
    );
  });

  test('ResultStructuredDisclaimer YSQ_FOUNDATION_V1 message', () {
    expect(
      ResultStructuredDisclaimer.messageForStructuredSnapshot(
          'YSQ_FOUNDATION_V1'),
      contains('validação clínica'),
    );
    expect(
      ResultStructuredDisclaimer.messageForStructuredSnapshot(
          'ysq_foundation_v1'),
      contains('psicólogo responsável'),
    );
    expect(
      ResultStructuredDisclaimer.messageForStructuredSnapshot(
          'YSQ_FOUNDATION_V1'),
      isNot(contains('modos esquemáticos')),
    );
  });

  test('ResultStructuredDisclaimer YAMI_MODES_FOUNDATION_V1 message', () {
    const expected =
        'Resultado estruturado de modos esquemáticos para validação clínica. '
        'A interpretação final deve ser feita pelo psicólogo responsável.';
    expect(
      ResultStructuredDisclaimer.messageForStructuredSnapshot(
        'YAMI_MODES_FOUNDATION_V1',
      ),
      expected,
    );
    expect(
      ResultStructuredDisclaimer.messageForStructuredSnapshot(
        'yami_modes_foundation_v1',
      ),
      expected,
    );
  });

  test('ResultStructuredDisclaimer PARENTAL_STYLES_V1 message', () {
    const expected =
        'Resultado estruturado por figura parental para validação clínica. '
        'Revise separadamente mãe e pai antes de consolidar a formulação.';
    expect(
      ResultStructuredDisclaimer.messageForStructuredSnapshot(
        'PARENTAL_STYLES_V1',
      ),
      expected,
    );
    expect(
      ResultStructuredDisclaimer.messageForStructuredSnapshot(
        'parental_styles_v1',
      ),
      expected,
    );
  });

  test('ResultStructuredDisclaimer ATTACHMENT_STYLES_V1 message', () {
    const expected =
        'Resultado estruturado por estilo de apego para validação clínica. '
        'Considere a categoria predominante junto com o contexto relacional do paciente.';
    expect(
      ResultStructuredDisclaimer.messageForStructuredSnapshot(
        'ATTACHMENT_STYLES_V1',
      ),
      expected,
    );
    expect(
      ResultStructuredDisclaimer.messageForStructuredSnapshot(
        'attachment_styles_v1',
      ),
      expected,
    );
  });

  test('ResultStructuredDisclaimer YCI_FOUNDATION_V1 message', () {
    const expected =
        'Resultado estruturado do inventário YCI para validação clínica. '
        'Use esta aplicação como apoio à formulação dos estilos de enfrentamento.';
    expect(
      ResultStructuredDisclaimer.messageForStructuredSnapshot(
        'YCI_FOUNDATION_V1',
      ),
      expected,
    );
  });

  test('ResultStructuredDisclaimer YRAI_FOUNDATION_V1 message', () {
    const expected =
        'Resultado estruturado do inventário YRAI para validação clínica. '
        'Use esta aplicação como apoio à formulação dos estilos de enfrentamento.';
    expect(
      ResultStructuredDisclaimer.messageForStructuredSnapshot(
        'YRAI_FOUNDATION_V1',
      ),
      expected,
    );
  });

  test('ResultStructuredDisclaimer default for other questionnaires', () {
    expect(
      ResultStructuredDisclaimer.messageForStructuredSnapshot(
          'CUSTOM_INSTRUMENT'),
      'Resultado estruturado. Revise as regras clínicas antes de uso oficial.',
    );
  });
}
