/// Status persistido em `therapy_goals.status`.
enum TherapyGoalStatus {
  active,
  completed,
  archived,
}

extension TherapyGoalStatusParsing on TherapyGoalStatus {
  String get storageValue => name;

  String get label => switch (this) {
        TherapyGoalStatus.active => 'Ativo',
        TherapyGoalStatus.completed => 'Concluído',
        TherapyGoalStatus.archived => 'Arquivado',
      };

  bool get isTerminal =>
      this == TherapyGoalStatus.completed || this == TherapyGoalStatus.archived;
}

TherapyGoalStatus therapyGoalStatusFromStorage(String? value) {
  switch (value) {
    case 'completed':
      return TherapyGoalStatus.completed;
    case 'archived':
      return TherapyGoalStatus.archived;
    case 'active':
    default:
      return TherapyGoalStatus.active;
  }
}
