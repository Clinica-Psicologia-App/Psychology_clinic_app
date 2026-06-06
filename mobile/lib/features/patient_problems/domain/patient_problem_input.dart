import 'patient_problem.dart';
import 'patient_problem_status.dart';

class PatientProblemInput {
  const PatientProblemInput({
    required this.title,
    this.description,
    this.category,
    this.intensity,
    this.identifiedAt,
    this.status,
  });

  final String title;
  final String? description;
  final String? category;
  final int? intensity;
  final DateTime? identifiedAt;
  final PatientProblemStatus? status;

  factory PatientProblemInput.fromProblem(PatientProblem problem) {
    return PatientProblemInput(
      title: problem.title,
      description: problem.description,
      category: problem.category,
      intensity: problem.intensity,
      identifiedAt: problem.identifiedAt,
      status: problem.status,
    );
  }

  String? validate() {
    if (title.trim().isEmpty) return 'Informe o título do problema.';
    if (title.trim().length > 200) {
      return 'Título muito longo (máx. 200 caracteres).';
    }
    if (intensity != null && (intensity! < 0 || intensity! > 10)) {
      return 'Intensidade deve ser entre 0 e 10.';
    }
    return null;
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'title': title.trim(),
      'description': _nullableTrim(description),
      'category': _nullableTrim(category),
      if (intensity != null) 'intensity': intensity,
      if (identifiedAt != null) 'identified_at': _formatDate(identifiedAt!),
      'status': (status ?? PatientProblemStatus.active).storageValue,
    };
  }

  Map<String, dynamic> toPatientUpdateJson() {
    final map = <String, dynamic>{
      'title': title.trim(),
      'description': _nullableTrim(description),
      'category': _nullableTrim(category),
      'intensity': intensity,
    };
    if (status != null) {
      map['status'] = status!.storageValue;
    }
    return map;
  }

  Map<String, dynamic> toStaffUpdateJson() {
    return {
      'title': title.trim(),
      'description': _nullableTrim(description),
      'category': _nullableTrim(category),
      'intensity': intensity,
      'identified_at':
          identifiedAt != null ? _formatDate(identifiedAt!) : null,
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
