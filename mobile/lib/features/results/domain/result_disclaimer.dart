/// Textos de aviso na tela de resultados (por código do questionário).
class ResultStructuredDisclaimer {
  ResultStructuredDisclaimer._();

  static const questionnaireCodeMvpDemo = 'MVP_DEMO';
  static const questionnaireCodeYsqFoundation = 'YSQ_FOUNDATION_V1';
  static const questionnaireCodeYamiModesFoundation =
      'YAMI_MODES_FOUNDATION_V1';
  static const questionnaireCodeParentalStyles = 'PARENTAL_STYLES_V1';
  static const questionnaireCodeAttachmentStyles = 'ATTACHMENT_STYLES_V1';
  static const questionnaireCodeYci = 'YCI_FOUNDATION_V1';
  static const questionnaireCodeYrai = 'YRAI_FOUNDATION_V1';

  /// Mensagem do banner quando o snapshot usa motor estruturado (`scoring-demo-1`).
  static String messageForStructuredSnapshot(String questionnaireCode) {
    final code = questionnaireCode.trim().toUpperCase();

    switch (code) {
      case questionnaireCodeMvpDemo:
        return 'Resultado demonstrativo, sem validade clínica oficial.';
      case questionnaireCodeYsqFoundation:
        return 'Resultado estruturado para validação clínica. '
            'A interpretação final deve ser feita pelo psicólogo responsável.';
      case questionnaireCodeYamiModesFoundation:
        return 'Resultado estruturado de modos esquemáticos para validação clínica. '
            'A interpretação final deve ser feita pelo psicólogo responsável.';
      case questionnaireCodeParentalStyles:
        return 'Resultado estruturado por figura parental para validação clínica. '
            'Revise separadamente mãe e pai antes de consolidar a formulação.';
      case questionnaireCodeAttachmentStyles:
        return 'Resultado estruturado por estilo de apego para validação clínica. '
            'Considere a categoria predominante junto com o contexto relacional do paciente.';
      case questionnaireCodeYci:
        return 'Resultado estruturado do inventário YCI para validação clínica. '
            'Use esta aplicação como apoio à formulação dos estilos de enfrentamento.';
      case questionnaireCodeYrai:
        return 'Resultado estruturado do inventário YRAI para validação clínica. '
            'Use esta aplicação como apoio à formulação dos estilos de enfrentamento.';
      default:
        return 'Resultado estruturado. Revise as regras clínicas antes de uso oficial.';
    }
  }
}
