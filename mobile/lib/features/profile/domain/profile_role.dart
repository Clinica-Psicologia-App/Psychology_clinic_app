enum ProfileRole {
  platformAdmin,
  psychologist,
  patient;

  static ProfileRole? tryParse(String? value) {
    switch (value) {
      case 'platform_admin':
      case 'admin':
        return ProfileRole.platformAdmin;
      case 'psychologist':
        return ProfileRole.psychologist;
      case 'patient':
        return ProfileRole.patient;
      default:
        return null;
    }
  }

  String get storageValue {
    switch (this) {
      case ProfileRole.platformAdmin:
        return 'platform_admin';
      case ProfileRole.psychologist:
        return 'psychologist';
      case ProfileRole.patient:
        return 'patient';
    }
  }

  String get label {
    switch (this) {
      case ProfileRole.platformAdmin:
        return 'Administrador';
      case ProfileRole.psychologist:
        return 'Psicólogo';
      case ProfileRole.patient:
        return 'Paciente';
    }
  }
}
