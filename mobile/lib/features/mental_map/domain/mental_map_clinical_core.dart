import 'mental_map_problem_summary.dart';
import 'mental_map_score_highlight.dart';

/// Camada M2 - núcleo clínico (esquemas, modos, problemas, apego, enfrentamento).
class MentalMapClinicalCore {
  const MentalMapClinicalCore({
    required this.topSchemas,
    required this.topModes,
    required this.topProblemsByIntensity,
    required this.attachmentStyles,
    required this.copingStyles,
    this.ysqCompletedAt,
    this.yamiCompletedAt,
    this.attachmentCompletedAt,
    this.copingCompletedAt,
  });

  static const empty = MentalMapClinicalCore(
    topSchemas: [],
    topModes: [],
    topProblemsByIntensity: [],
    attachmentStyles: [],
    copingStyles: [],
  );

  final List<MentalMapScoreHighlight> topSchemas;
  final List<MentalMapScoreHighlight> topModes;
  final List<MentalMapProblemSummary> topProblemsByIntensity;
  final List<MentalMapScoreHighlight> attachmentStyles;
  final List<MentalMapScoreHighlight> copingStyles;
  final DateTime? ysqCompletedAt;
  final DateTime? yamiCompletedAt;
  final DateTime? attachmentCompletedAt;
  final DateTime? copingCompletedAt;

  bool get hasSchemas => topSchemas.isNotEmpty;

  bool get hasModes => topModes.isNotEmpty;

  bool get hasProblems => topProblemsByIntensity.isNotEmpty;

  bool get hasAttachment => attachmentStyles.isNotEmpty;

  bool get hasCoping => copingStyles.isNotEmpty;

  bool get hasContent =>
      hasSchemas || hasModes || hasProblems || hasAttachment || hasCoping;
}
