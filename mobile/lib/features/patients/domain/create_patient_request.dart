/// Payload para `POST /create-patient`.
class CreatePatientRequest {
  const CreatePatientRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.responsiblePsychologistId,
    this.phone,
    this.cpf,
    this.birthDate,
  });

  final String email;
  final String password;
  final String fullName;
  final String responsiblePsychologistId;
  final String? phone;
  final String? cpf;
  final DateTime? birthDate;

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
      'password': password,
      'full_name': fullName.trim(),
      'responsible_psychologist_id': responsiblePsychologistId,
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
      if (cpf != null && cpf!.trim().isNotEmpty) 'cpf': cpf!.trim(),
      if (birthDate != null)
        'birth_date': birthDate!.toIso8601String().split('T').first,
    };
  }
}
