class ClinicSummary {
  const ClinicSummary({
    required this.id,
    required this.name,
    required this.clinicType,
    required this.isActive,
    required this.createdAt,
    required this.userCount,
    required this.patientCount,
    this.email,
    this.phone,
    this.document,
  });

  final String id;
  final String name;
  final String clinicType;
  final bool isActive;
  final DateTime? createdAt;
  final int userCount;
  final int patientCount;
  final String? email;
  final String? phone;
  final String? document;

  bool get isPersonal => clinicType == 'personal';

  String get typeLabel => isPersonal ? 'Individual' : 'Clínica';

  factory ClinicSummary.fromJson(
    Map<String, dynamic> json, {
    required int userCount,
    required int patientCount,
  }) {
    return ClinicSummary(
      id: json['id'] as String,
      name: json['name'] as String,
      clinicType: json['clinic_type'] as String? ?? 'clinic',
      isActive: json['is_active'] as bool? ?? true,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse(json['created_at'] as String),
      userCount: userCount,
      patientCount: patientCount,
      email: json['email'] as String?,
      phone: json['phone'] as String?,
      document: json['document'] as String?,
    );
  }
}
