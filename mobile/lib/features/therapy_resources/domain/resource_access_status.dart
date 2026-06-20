/// Progresso do paciente no recurso liberado.
enum ResourceAccessStatus {
  released,
  viewed,
  completed,
}

ResourceAccessStatus deriveResourceAccessStatus({
  required bool isActive,
  DateTime? viewedAt,
  DateTime? completedAt,
}) {
  if (!isActive) return ResourceAccessStatus.released;
  if (completedAt != null) return ResourceAccessStatus.completed;
  if (viewedAt != null) return ResourceAccessStatus.viewed;
  return ResourceAccessStatus.released;
}

extension ResourceAccessStatusX on ResourceAccessStatus {
  String get label {
    switch (this) {
      case ResourceAccessStatus.released:
        return 'Liberado';
      case ResourceAccessStatus.viewed:
        return 'Visualizado';
      case ResourceAccessStatus.completed:
        return 'Concluído';
    }
  }
}
