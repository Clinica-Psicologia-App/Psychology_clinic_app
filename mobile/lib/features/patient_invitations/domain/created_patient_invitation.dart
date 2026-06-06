import 'patient_invitation.dart';

class CreatedPatientInvitation {
  const CreatedPatientInvitation({
    required this.invitation,
    required this.inviteUrl,
  });

  final PatientInvitation invitation;
  final String inviteUrl;
}
