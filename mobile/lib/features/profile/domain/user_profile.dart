import 'profile_role.dart';

class UserProfile {
  const UserProfile({
    required this.id,
    required this.clinicId,
    required this.role,
    required this.fullName,
    required this.email,
    required this.isActive,
  });

  final String id;
  final String clinicId;
  final ProfileRole role;
  final String fullName;
  final String email;
  final bool isActive;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final role = ProfileRole.tryParse(json['role'] as String?);
    if (role == null) {
      throw FormatException('Invalid profile role: ${json['role']}');
    }

    return UserProfile(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      role: role,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
