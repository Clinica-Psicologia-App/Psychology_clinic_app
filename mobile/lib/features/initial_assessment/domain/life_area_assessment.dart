import 'life_area.dart';

/// Avaliação de uma área de vida (Bloco 3). Junta o dado do paciente
/// (nota/sofrimento/comentário) com o comentário clínico do terapeuta
/// (staff-only, vindo de `patient_life_area_notes`), quando disponível.
class LifeAreaAssessment {
  const LifeAreaAssessment({
    required this.area,
    this.score,
    this.suffering,
    this.guidedAnswer,
    this.clinicalComment,
    this.filledByRole,
  });

  final LifeArea area;

  /// Satisfação 1–10 (null = ainda não avaliada).
  final int? score;

  /// Sofrimento 0–10 (opcional, "quando pertinente").
  final int? suffering;

  /// Comentário breve / resposta à pergunta guiada (paciente).
  final String? guidedAnswer;

  /// Comentário clínico do terapeuta (staff-only).
  final String? clinicalComment;

  /// Papel de quem preencheu (patient/psychologist/admin).
  final String? filledByRole;

  bool get hasRating => score != null;

  factory LifeAreaAssessment.fromJson(Map<String, dynamic> json) {
    return LifeAreaAssessment(
      area: lifeAreaFromKey(json['area_key'] as String?) ?? LifeArea.family,
      score: (json['score'] as num?)?.toInt(),
      suffering: (json['suffering'] as num?)?.toInt(),
      guidedAnswer: json['guided_answer'] as String?,
      filledByRole: json['filled_by_role'] as String?,
    );
  }

  LifeAreaAssessment copyWith({
    int? score,
    int? suffering,
    String? guidedAnswer,
    String? clinicalComment,
  }) {
    return LifeAreaAssessment(
      area: area,
      score: score ?? this.score,
      suffering: suffering ?? this.suffering,
      guidedAnswer: guidedAnswer ?? this.guidedAnswer,
      clinicalComment: clinicalComment ?? this.clinicalComment,
      filledByRole: filledByRole,
    );
  }
}
