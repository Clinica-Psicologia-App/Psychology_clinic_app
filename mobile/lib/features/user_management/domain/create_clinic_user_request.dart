import '../../profile/domain/profile_role.dart';

class CreateClinicUserRequest {
  const CreateClinicUserRequest({
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    required this.isIndividual,
    this.clinicId,
    this.phone,
    this.crp,
  }) : assert(
          isIndividual || (clinicId != null && clinicId != ''),
          'clinicId é obrigatório quando não for individual',
        );

  final String email;
  final String password;
  final String fullName;
  final ProfileRole role;

  /// true = profissional autônomo; o repository cria a clínica pessoal
  /// automaticamente com o nome do profissional.
  final bool isIndividual;

  final String? clinicId;
  final String? phone;
  final String? crp;

  Map<String, dynamic> toJsonWithClinicId(String resolvedClinicId) {
    return {
      'email': email.trim().toLowerCase(),
      'password': password,
      'full_name': fullName.trim(),
      'role': role.storageValue,
      'clinic_id': resolvedClinicId,
      if (phone != null && phone!.trim().isNotEmpty) 'phone': phone!.trim(),
      if (crp != null && crp!.trim().isNotEmpty) 'crp': crp!.trim(),
    };
  }
}

String? validateClinicUserPassword(String value) {
  if (value.length < 8) return 'Use pelo menos 8 caracteres.';
  return null;
}
