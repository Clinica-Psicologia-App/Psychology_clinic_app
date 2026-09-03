class MentalMapGoalSummary {
  const MentalMapGoalSummary({
    required this.id,
    required this.title,
    required this.statusLabel,
    this.description,
    this.targetDateLabel,
    this.isOverdue = false,
    this.progress = 0,
    this.linkedLabels = const [],
  });

  final String id;
  final String title;
  final String statusLabel;

  /// Detalhe do objetivo (como será alcançado / o que muda) — pode ser nulo.
  final String? description;
  final String? targetDateLabel;

  /// Prazo já vencido com o objetivo ainda ativo.
  final bool isOverdue;

  /// Progresso em porcentagem (0–100).
  final int progress;

  /// Nomes dos esquemas/modos vinculados ao objetivo.
  final List<String> linkedLabels;
}
