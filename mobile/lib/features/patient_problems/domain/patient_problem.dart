import 'patient_problem_status.dart';

class PatientProblem {
  const PatientProblem({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.createdBy,
    required this.title,
    this.description,
    this.category,
    this.intensity,
    required this.status,
    this.identifiedAt,
    this.resolvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String patientId;
  final String? createdBy;
  final String title;
  final String? description;
  final String? category;
  final int? intensity;
  final PatientProblemStatus status;
  final DateTime? identifiedAt;
  final DateTime? resolvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isOpen => status.isOpen;

  factory PatientProblem.fromJson(Map<String, dynamic> json) {
    return PatientProblem(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      patientId: json['patient_id'] as String,
      createdBy: json['created_by'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      category: json['category'] as String?,
      intensity: json['intensity'] as int?,
      status: patientProblemStatusFromStorage(json['status'] as String?),
      identifiedAt: _parseDate(json['identified_at']),
      resolvedAt: _parseDateTime(json['resolved_at']),
      createdAt: _parseDateTime(json['created_at'])!,
      updatedAt: _parseDateTime(json['updated_at'])!,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    return DateTime.parse(value as String).toLocal();
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    final s = value as String;
    final parts = s.split('-');
    if (parts.length != 3) return DateTime.parse(s).toLocal();
    return DateTime(
      int.parse(parts[0]),
      int.parse(parts[1]),
      int.parse(parts[2]),
    );
  }
}
