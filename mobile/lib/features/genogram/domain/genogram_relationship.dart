import 'genogram_relationship_type.dart';

class GenogramRelationship {
  const GenogramRelationship({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.createdBy,
    required this.personAId,
    required this.personBId,
    required this.relationshipType,
    this.notes,
    required this.isSensitive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String patientId;
  final String? createdBy;
  final String personAId;
  final String personBId;
  final GenogramRelationshipType relationshipType;
  final String? notes;
  final bool isSensitive;
  final DateTime createdAt;
  final DateTime updatedAt;

  String labelBetween(String personAName, String personBName) {
    return '$personAName - ${relationshipType.label} - $personBName';
  }

  bool involvesPerson(String personId) =>
      personAId == personId || personBId == personId;

  String? otherPersonId(String personId) {
    if (personAId == personId) return personBId;
    if (personBId == personId) return personAId;
    return null;
  }

  factory GenogramRelationship.fromJson(Map<String, dynamic> json) {
    return GenogramRelationship(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      patientId: json['patient_id'] as String,
      createdBy: json['created_by'] as String?,
      personAId: json['person_a_id'] as String,
      personBId: json['person_b_id'] as String,
      relationshipType: genogramRelationshipTypeFromStorage(
        json['relationship_type'] as String?,
      ),
      notes: json['notes'] as String?,
      isSensitive: json['is_sensitive'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }
}
