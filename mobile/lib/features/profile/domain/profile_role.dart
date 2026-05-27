enum ProfileRole {
  admin,
  psychologist,
  patient;

  static ProfileRole? tryParse(String? value) {
    switch (value) {
      case 'admin':
        return ProfileRole.admin;
      case 'psychologist':
        return ProfileRole.psychologist;
      case 'patient':
        return ProfileRole.patient;
      default:
        return null;
    }
  }

  String get label {
    switch (this) {
      case ProfileRole.admin:
        return 'Administrador';
      case ProfileRole.psychologist:
        return 'Psicólogo';
      case ProfileRole.patient:
        return 'Paciente';
    }
  }
}
