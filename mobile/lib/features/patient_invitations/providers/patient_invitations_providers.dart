import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/patient_invitations_repository.dart';
import '../domain/accept_patient_invitation_request.dart';
import '../domain/create_patient_invitation_request.dart';
import '../domain/created_patient_invitation.dart';
import '../domain/patient_invitation.dart';

final patientInvitationsRepositoryProvider =
    Provider<PatientInvitationsRepository>((ref) {
  return PatientInvitationsRepository();
});

final patientInvitationsListProvider = AsyncNotifierProvider<
    PatientInvitationsListNotifier, List<PatientInvitation>>(
  PatientInvitationsListNotifier.new,
);

class PatientInvitationsListNotifier
    extends AsyncNotifier<List<PatientInvitation>> {
  @override
  Future<List<PatientInvitation>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<PatientInvitation>> _load() {
    return ref.read(patientInvitationsRepositoryProvider).listInvitations();
  }
}

final createPatientInvitationProvider =
    AsyncNotifierProvider<CreatePatientInvitationNotifier, void>(
  CreatePatientInvitationNotifier.new,
);

class CreatePatientInvitationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<CreatedPatientInvitation> submit(
    CreatePatientInvitationRequest request,
  ) async {
    state = const AsyncValue.loading();
    try {
      final invitation = await ref
          .read(patientInvitationsRepositoryProvider)
          .createInvitation(request);
      state = const AsyncValue.data(null);
      ref.invalidate(patientInvitationsListProvider);
      return invitation;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

final acceptPatientInvitationProvider =
    AsyncNotifierProvider<AcceptPatientInvitationNotifier, void>(
  AcceptPatientInvitationNotifier.new,
);

class AcceptPatientInvitationNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit(AcceptPatientInvitationRequest request) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(patientInvitationsRepositoryProvider)
          .acceptInvitation(request);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
