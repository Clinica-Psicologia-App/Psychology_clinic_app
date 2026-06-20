import 'therapy_goal.dart';
import 'therapy_goal_status.dart';

class TherapyGoalInput {
  const TherapyGoalInput({
    required this.title,
    this.description,
    this.targetDate,
    this.status,
  });

  final String title;
  final String? description;
  final DateTime? targetDate;
  final TherapyGoalStatus? status;

  factory TherapyGoalInput.fromGoal(TherapyGoal goal) {
    return TherapyGoalInput(
      title: goal.title,
      description: goal.description,
      targetDate: goal.targetDate,
      status: goal.status,
    );
  }

  String? validate() {
    if (title.trim().isEmpty) return 'Informe o título do objetivo.';
    if (title.trim().length > 200) {
      return 'Título muito longo (máx. 200 caracteres).';
    }
    return null;
  }

  /// Campos que o paciente pode alterar.
  Map<String, dynamic> toPatientUpdateJson() {
    final map = <String, dynamic>{
      'title': title.trim(),
      'description': _nullableTrim(description),
    };
    if (status != null) {
      map['status'] = status!.storageValue;
    }
    return map;
  }

  /// Criação (paciente ou staff).
  Map<String, dynamic> toInsertJson() {
    return {
      'title': title.trim(),
      'description': _nullableTrim(description),
      if (targetDate != null) 'target_date': _formatDate(targetDate!),
      'status': (status ?? TherapyGoalStatus.active).storageValue,
    };
  }

  /// Staff pode alterar todos os campos editáveis.
  Map<String, dynamic> toStaffUpdateJson() {
    return {
      'title': title.trim(),
      'description': _nullableTrim(description),
      'target_date': targetDate != null ? _formatDate(targetDate!) : null,
      if (status != null) 'status': status!.storageValue,
    };
  }

  static String? _nullableTrim(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  static String _formatDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
