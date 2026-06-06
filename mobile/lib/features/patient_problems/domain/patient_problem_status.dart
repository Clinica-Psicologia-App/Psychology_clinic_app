/// Status persistido em `patient_problems.status`.
enum PatientProblemStatus {
  active,
  improved,
  resolved,
  archived,
}

extension PatientProblemStatusParsing on PatientProblemStatus {
  String get storageValue => name;

  String get label => switch (this) {
        PatientProblemStatus.active => 'Ativo',
        PatientProblemStatus.improved => 'Melhorou',
        PatientProblemStatus.resolved => 'Resolvido',
        PatientProblemStatus.archived => 'Arquivado',
      };

  bool get isOpen =>
      this == PatientProblemStatus.active ||
      this == PatientProblemStatus.improved;

  bool get isTerminal =>
      this == PatientProblemStatus.resolved ||
      this == PatientProblemStatus.archived;
}

PatientProblemStatus patientProblemStatusFromStorage(String? value) {
  switch (value) {
    case 'improved':
      return PatientProblemStatus.improved;
    case 'resolved':
      return PatientProblemStatus.resolved;
    case 'archived':
      return PatientProblemStatus.archived;
    case 'active':
    default:
      return PatientProblemStatus.active;
  }
}
