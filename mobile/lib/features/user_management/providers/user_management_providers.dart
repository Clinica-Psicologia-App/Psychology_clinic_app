import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile_role.dart';
import '../data/user_management_repository.dart';
import '../domain/clinic_user.dart';
import '../domain/create_clinic_user_request.dart';

final userManagementRepositoryProvider =
    Provider<UserManagementRepository>((ref) {
  return UserManagementRepository();
});

final clinicUsersProvider =
    AsyncNotifierProvider<ClinicUsersNotifier, List<ClinicUser>>(
  ClinicUsersNotifier.new,
);

class ClinicUsersNotifier extends AsyncNotifier<List<ClinicUser>> {
  @override
  Future<List<ClinicUser>> build() {
    return ref.read(userManagementRepositoryProvider).listClinicUsers();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(userManagementRepositoryProvider).listClinicUsers(),
    );
  }

  Future<void> create(CreateClinicUserRequest request) async {
    await _mutateAndRefresh(() async {
      await ref.read(userManagementRepositoryProvider).createClinicUser(request);
    });
  }

  Future<void> setActive({
    required String profileId,
    required bool isActive,
  }) async {
    await _mutateAndRefresh(() async {
      await ref.read(userManagementRepositoryProvider).setUserActive(
            profileId: profileId,
            isActive: isActive,
          );
    });
  }

  Future<void> deleteUser(String profileId) async {
    await _mutateAndRefresh(() async {
      await ref.read(userManagementRepositoryProvider).deleteUser(profileId);
    });
  }

  Future<void> updateUserRole({
    required String profileId,
    required ProfileRole newRole,
  }) async {
    await _mutateAndRefresh(() async {
      await ref.read(userManagementRepositoryProvider).updateUserRole(
            profileId: profileId,
            newRole: newRole,
          );
    });
  }

  Future<void> _mutateAndRefresh(Future<void> Function() mutation) async {
    final previousUsers = state.valueOrNull;
    try {
      await mutation();
      final users =
          await ref.read(userManagementRepositoryProvider).listClinicUsers();
      state = AsyncData(users);
    } catch (error, stackTrace) {
      state = previousUsers == null
          ? AsyncError(error, stackTrace)
          : AsyncData(previousUsers);
      rethrow;
    }
  }

  Future<void> updatePsychologistAccess({
    required String profileId,
    required bool canReceivePatients,
    required int? patientAssignmentLimit,
  }) async {
    final previousUsers = state.valueOrNull;
    await ref.read(userManagementRepositoryProvider).updatePsychologistAccess(
          profileId: profileId,
          canReceivePatients: canReceivePatients,
          patientAssignmentLimit: patientAssignmentLimit,
        );
    final refreshedState = await AsyncValue.guard(
      () => ref.read(userManagementRepositoryProvider).listClinicUsers(),
    );
    if (refreshedState.hasError && previousUsers != null) {
      state = AsyncData(previousUsers);
      throw refreshedState.error!;
    }
    state = refreshedState;
  }
}
