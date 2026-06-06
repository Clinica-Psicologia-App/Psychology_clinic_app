enum PatientInvitationStatus {
  pending,
  accepted,
  expired,
  revoked,
}

PatientInvitationStatus patientInvitationStatusFromStorage(String value) {
  switch (value.trim().toLowerCase()) {
    case 'pending':
      return PatientInvitationStatus.pending;
    case 'accepted':
      return PatientInvitationStatus.accepted;
    case 'expired':
      return PatientInvitationStatus.expired;
    case 'revoked':
      return PatientInvitationStatus.revoked;
    default:
      throw FormatException('Invalid patient invitation status: $value');
  }
}

extension PatientInvitationStatusLabels on PatientInvitationStatus {
  String get label {
    switch (this) {
      case PatientInvitationStatus.pending:
        return 'Pendente';
      case PatientInvitationStatus.accepted:
        return 'Aceito';
      case PatientInvitationStatus.expired:
        return 'Expirado';
      case PatientInvitationStatus.revoked:
        return 'Revogado';
    }
  }

  bool get isTerminal =>
      this == PatientInvitationStatus.accepted ||
      this == PatientInvitationStatus.expired ||
      this == PatientInvitationStatus.revoked;
}
