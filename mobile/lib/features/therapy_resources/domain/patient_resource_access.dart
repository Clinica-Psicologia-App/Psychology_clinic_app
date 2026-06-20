import 'resource_access_status.dart';
import 'therapy_resource.dart';

/// Liberação de recurso (`patient_resource_access` + join).
class PatientResourceAccess {
  const PatientResourceAccess({
    required this.id,
    required this.patientId,
    required this.resourceId,
    required this.isActive,
    this.releasedAt,
    this.viewedAt,
    this.completedAt,
    required this.resource,
    this.releasedByName,
  });

  final String id;
  final String patientId;
  final String resourceId;
  final bool isActive;
  final DateTime? releasedAt;
  final DateTime? viewedAt;
  final DateTime? completedAt;
  final TherapyResource resource;
  final String? releasedByName;

  ResourceAccessStatus get progressStatus => deriveResourceAccessStatus(
        isActive: isActive,
        viewedAt: viewedAt,
        completedAt: completedAt,
      );

  factory PatientResourceAccess.fromJson(Map<String, dynamic> json) {
    final resourceJson = json['resource'];
    Map<String, dynamic> rMap = {};
    if (resourceJson is Map) {
      rMap = Map<String, dynamic>.from(resourceJson);
    }

    final releasedBy = json['released_by'];
    String? releasedByName;
    if (releasedBy is Map) {
      releasedByName = releasedBy['full_name'] as String?;
    }

    return PatientResourceAccess(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      resourceId: json['resource_id'] as String,
      isActive: json['is_active'] as bool? ?? true,
      releasedAt: _parseDateTime(json['released_at']),
      viewedAt: _parseDateTime(json['viewed_at']),
      completedAt: _parseDateTime(json['completed_at']),
      resource: TherapyResource.fromJson(rMap),
      releasedByName: releasedByName,
    );
  }
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
