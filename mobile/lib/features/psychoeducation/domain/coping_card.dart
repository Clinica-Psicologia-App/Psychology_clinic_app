import '../../clinical_dashboard/domain/clinical_dashboard_builder.dart';
import '../../results/domain/patient_result_detail.dart';
import '../../results/domain/questionnaire_response_status.dart';

/// Read-only reflection template, derived from an existing released result.
/// Does not infer a diagnosis or prescribe a replacement coping strategy.
class CopingCard {
  const CopingCard(
      {required this.topic,
      required this.source,
      required this.responseId,
      this.completedAt});

  final String topic;
  final String source;
  final String responseId;
  final DateTime? completedAt;

  String get observation =>
      'Quero observar como o tema “$topic” aparece no meu dia.';
  static const reflection =
      'Em que situação isso aconteceu? O que senti e fiz?';
  static const nextStep =
      'Que resposta diferente quero construir com meu terapeuta?';

  static List<CopingCard> fromResult(PatientResultDetail detail) {
    final code = detail.questionnaireCode.trim().toUpperCase();
    if (detail.status != QuestionnaireResponseStatus.completed ||
        (code != yciInstrumentCode && code != yraiInstrumentCode)) {
      return [];
    }
    final seen = <String>{};
    return [
      for (final row in extractTopSchemaRows(detail, limit: 9999))
        if (row.name.trim().isNotEmpty &&
            row.score.isFinite &&
            seen.add(row.name.trim()))
          CopingCard(
              topic: row.name.trim(),
              source: code == yciInstrumentCode ? 'YCI' : 'YRAI',
              responseId: detail.id,
              completedAt: detail.completedAt),
    ];
  }
}
