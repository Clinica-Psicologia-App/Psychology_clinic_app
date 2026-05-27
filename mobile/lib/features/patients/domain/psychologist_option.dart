/// Psicólogo da clínica para seleção no cadastro (admin).
class PsychologistOption {
  const PsychologistOption({
    required this.id,
    required this.fullName,
    this.email,
  });

  final String id;
  final String fullName;
  final String? email;

  factory PsychologistOption.fromJson(Map<String, dynamic> json) {
    return PsychologistOption(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      email: json['email'] as String?,
    );
  }

  String get displayLabel =>
      email != null && email!.isNotEmpty ? '$fullName ($email)' : fullName;
}
