enum ProfessionalAccountMode {
  solo,
  clinic,
}

String? validateProfessionalPassword(String? value) {
  if (value == null || value.isEmpty) {
    return 'Informe a senha';
  }
  if (value.length < 8) {
    return 'A senha deve ter pelo menos 8 caracteres';
  }
  return null;
}

String? validateClinicNameForMode(
  ProfessionalAccountMode mode,
  String? value,
) {
  if (mode != ProfessionalAccountMode.clinic) return null;
  if (value == null || value.trim().isEmpty) {
    return 'Informe o nome da clínica';
  }
  return null;
}

class CreateProfessionalAccountRequest {
  const CreateProfessionalAccountRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.mode,
    this.phone,
    this.crp,
    this.clinic,
  });

  final String email;
  final String password;
  final String fullName;
  final String? phone;
  final String? crp;
  final ProfessionalAccountMode mode;
  final ProfessionalClinicRegistration? clinic;

  Map<String, dynamic> toJson() {
    return {
      'email': email.trim().toLowerCase(),
      'password': password,
      'full_name': fullName.trim(),
      'mode': mode.name,
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
      if (crp != null && crp!.trim().isNotEmpty) 'crp': crp!.trim(),
      if (clinic != null) 'clinic': clinic!.toJson(),
    };
  }
}

class ProfessionalClinicRegistration {
  const ProfessionalClinicRegistration({
    required this.name,
    this.phone,
    this.email,
  });

  final String name;
  final String? phone;
  final String? email;

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
      if (email != null && email!.trim().isNotEmpty)
        'email': email!.trim().toLowerCase(),
    };
  }
}
