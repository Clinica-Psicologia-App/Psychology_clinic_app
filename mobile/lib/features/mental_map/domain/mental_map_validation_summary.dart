class MentalMapValidationSummary {
  const MentalMapValidationSummary({
    required this.pendingQuestionnaireReviewCount,
    required this.hasTherapistInputs,
    required this.hasClinicalSynthesis,
  });

  static const empty = MentalMapValidationSummary(
    pendingQuestionnaireReviewCount: 0,
    hasTherapistInputs: false,
    hasClinicalSynthesis: false,
  );

  final int pendingQuestionnaireReviewCount;
  final bool hasTherapistInputs;
  final bool hasClinicalSynthesis;

  bool get hasPendingReview => pendingQuestionnaireReviewCount > 0;

  String get title {
    if (hasPendingReview) return 'Revisão clínica pendente';
    if (hasClinicalSynthesis || hasTherapistInputs) {
      return 'Revisão clínica recomendada';
    }
    return 'Aguardando revisão clínica';
  }

  String get message {
    if (hasPendingReview) {
      return pendingQuestionnaireReviewCount == 1
          ? 'Existe 1 instrumento aguardando revisão do terapeuta antes de consolidar a leitura clínica.'
          : 'Existem $pendingQuestionnaireReviewCount instrumentos aguardando revisão do terapeuta antes de consolidar a leitura clínica.';
    }
    if (hasClinicalSynthesis || hasTherapistInputs) {
      return 'O caso já reúne insumos clínicos, mas a síntese e as sugestões continuam como apoio à revisão do profissional.';
    }
    return 'Registre mais informações da jornada e faça a revisão clínica para consolidar este caso.';
  }
}
