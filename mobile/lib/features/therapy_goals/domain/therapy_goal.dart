import 'linked_schema.dart';
import 'therapy_goal_status.dart';

class TherapyGoal {
  const TherapyGoal({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.createdBy,
    required this.title,
    this.description,
    required this.status,
    this.targetDate,
    this.completedAt,
    this.progress = 0,
    this.linkedSchemas = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String patientId;
  final String? createdBy;
  final String title;
  final String? description;
  final TherapyGoalStatus status;
  final DateTime? targetDate;
  final DateTime? completedAt;

  /// Progresso em porcentagem (0–100).
  final int progress;

  /// Esquemas/modos que o objetivo endereça (código + nome).
  final List<LinkedSchema> linkedSchemas;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isActive => status == TherapyGoalStatus.active;

  factory TherapyGoal.fromJson(Map<String, dynamic> json) {
    return TherapyGoal(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      patientId: json['patient_id'] as String,
      createdBy: json['created_by'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      status: therapyGoalStatusFromStorage(json['status'] as String?),
      targetDate: _parseDate(json['target_date']),
      completedAt: _parseDateTime(json['completed_at']),
      progress: (json['progress'] as num?)?.toInt() ?? 0,
      linkedSchemas: LinkedSchema.listFromJson(json['linked_schemas']),
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
