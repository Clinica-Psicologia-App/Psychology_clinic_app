/// A schema the psychologist explicitly activated during the régua review.
/// Schemas with averageScore >= 4 are auto-activated; this table stores the
/// psi overrides for schemas below threshold (displayed with ◎ symbol).
class SchemaActivation {
  const SchemaActivation({
    required this.id,
    required this.questionnaireResponseId,
    required this.schemaCode,
    required this.schemaName,
    this.psiObservation,
    required this.activatedByProfileId,
    required this.createdAt,
  });

  final String id;
  final String questionnaireResponseId;
  final String schemaCode;
  final String schemaName;
  final String? psiObservation;
  final String activatedByProfileId;
  final DateTime createdAt;

  factory SchemaActivation.fromJson(Map<String, dynamic> json) {
    return SchemaActivation(
      id: json['id'] as String,
      questionnaireResponseId: json['questionnaire_response_id'] as String,
      schemaCode: json['schema_code'] as String,
      schemaName: json['schema_name'] as String,
      psiObservation: json['psi_observation'] as String?,
      activatedByProfileId: json['activated_by_profile_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}

/// Threshold above which a schema is considered auto-activated (● symbol).
const double kSchemaActivationThreshold = 4.0;
