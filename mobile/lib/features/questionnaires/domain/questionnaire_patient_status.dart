enum QuestionnairePatientStatus {
  /// Resposta iniciada mas não concluída.
  draft,

  /// Ao menos uma resposta concluída.
  completed;
}

/// Consolida as respostas do paciente em um status por questionário.
///
/// Prioridade: draft > completed. Se há uma resposta em andamento (inclusive
/// um Estilos Parentais com figuras ainda por responder), o questionário não
/// pode aparecer como concluído por causa de uma resposta anterior.
Map<String, QuestionnairePatientStatus> consolidatePatientResponseStatuses(
  Iterable<({String questionnaireId, String status})> rows,
) {
  final result = <String, QuestionnairePatientStatus>{};
  for (final row in rows) {
    final status = row.status == 'completed'
        ? QuestionnairePatientStatus.completed
        : QuestionnairePatientStatus.draft;
    if (status == QuestionnairePatientStatus.draft ||
        !result.containsKey(row.questionnaireId)) {
      result[row.questionnaireId] = status;
    }
  }
  return result;
}
