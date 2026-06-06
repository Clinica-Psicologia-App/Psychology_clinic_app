import '../../profile/domain/profile_role.dart';

class QuestionnaireProfessionalOption {
  const QuestionnaireProfessionalOption({
    required this.id,
    required this.fullName,
    required this.role,
    this.email,
  });

  final String id;
  final String fullName;
  final ProfileRole role;
  final String? email;

  factory QuestionnaireProfessionalOption.fromJson(Map<String, dynamic> json) {
    final role = ProfileRole.tryParse(json['role'] as String?);
    if (role == null) {
      throw FormatException('Invalid professional role: ${json['role']}');
    }

    return QuestionnaireProfessionalOption(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      role: role,
      email: json['email'] as String?,
    );
  }

  String get displayLabel {
    final suffix = email != null && email!.trim().isNotEmpty ? ' · $email' : '';
    return '$fullName (${role.label})$suffix';
  }
}
