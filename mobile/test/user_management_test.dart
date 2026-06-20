import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/router/route_access.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/patients/domain/psychologist_option.dart';
import 'package:terapia_esquema/features/user_management/domain/clinic_user.dart';
import 'package:terapia_esquema/features/user_management/domain/create_clinic_user_request.dart';
import 'package:terapia_esquema/features/user_management/presentation/user_management_routes.dart';

void main() {
  test('clinic user payload trims values and maps role', () {
    final json = const CreateClinicUserRequest(
      email: '  PSICO@example.com ',
      password: 'SenhaSegura1',
      fullName: '  Ana Souza ',
      phone: ' 51999990000 ',
      crp: ' 06/12345 ',
      role: ProfileRole.psychologist,
      isIndividual: false,
      clinicId: 'clinic-1',
    ).toJsonWithClinicId('clinic-1');

    expect(json['email'], 'psico@example.com');
    expect(json['full_name'], 'Ana Souza');
    expect(json['phone'], '51999990000');
    expect(json['crp'], '06/12345');
    expect(json['role'], 'psychologist');
  });

  test('clinic user parses staff profile json', () {
    final user = ClinicUser.fromJson({
      'id': 'profile-1',
      'clinic_id': 'clinic-1',
      'full_name': 'Ana Souza',
      'email': 'ana@example.com',
      'phone': null,
      'role': 'admin',
      'crp': null,
      'is_active': true,
      'created_at': '2026-06-15T12:00:00Z',
      'clinic': {
        'id': 'clinic-1',
        'name': 'Clínica Horizonte',
        'clinic_type': 'clinic',
        'is_active': true,
      },
    });

    expect(user.id, 'profile-1');
    expect(user.clinicName, 'Clínica Horizonte');
    expect(user.clinicTypeLabel, 'Clínica');
    expect(user.role, ProfileRole.platformAdmin);
    expect(user.isActive, isTrue);
    expect(user.createdAt, isNotNull);
  });

  test('clinic user exposes psychologist access quota summary', () {
    final user = ClinicUser.fromJson({
      'id': 'profile-1',
      'clinic_id': 'clinic-1',
      'full_name': 'Ana Souza',
      'email': 'ana@example.com',
      'role': 'psychologist',
      'is_active': true,
      'can_receive_patients': true,
      'patient_assignment_limit': 3,
      'assigned_patients_count': 2,
      'pending_patient_invitations_count': 1,
    });

    expect(user.reservedPatientSlots, 3);
    expect(user.reachedPatientAssignmentLimit, isTrue);
    expect(user.patientAccessSummary, '3/3 pacientes/convites');
  });

  test('psychologist option marks assignment availability by quota', () {
    const option = PsychologistOption(
      id: 'profile-1',
      fullName: 'Ana Souza',
      canReceivePatients: true,
      patientAssignmentLimit: 2,
      assignedPatientsCount: 1,
      pendingPatientInvitationsCount: 1,
    );

    expect(option.canAssignNewPatient, isFalse);
    expect(option.accessSummary, '2/2 vagas em uso');
  });

  test('platform users route is protected as a platform route', () {
    expect(RouteAccess.isPublic(UserManagementRoutes.platformList), isFalse);
    expect(
      RouteAccess.isAllowed(
        UserManagementRoutes.platformList,
        ProfileRole.platformAdmin,
      ),
      isTrue,
    );
    expect(
      RouteAccess.isAllowed(
        UserManagementRoutes.platformList,
        ProfileRole.psychologist,
      ),
      isFalse,
    );
  });

  test('password validation requires minimum length', () {
    expect(validateClinicUserPassword('1234567'), contains('8'));
    expect(validateClinicUserPassword('SenhaSegura1'), isNull);
  });

  test('only inactive staff can be deleted by another platform admin', () {
    const inactiveAdmin = ClinicUser(
      id: 'admin-2',
      clinicId: 'clinic-1',
      clinicName: 'Clínica',
      clinicType: 'clinic',
      clinicIsActive: true,
      fullName: 'Admin Inativo',
      email: 'admin@example.com',
      role: ProfileRole.platformAdmin,
      isActive: false,
    );
    const activePsychologist = ClinicUser(
      id: 'psych-1',
      clinicId: 'clinic-1',
      clinicName: 'Clínica',
      clinicType: 'clinic',
      clinicIsActive: true,
      fullName: 'Psicólogo Ativo',
      email: 'psych@example.com',
      role: ProfileRole.psychologist,
      isActive: true,
    );

    expect(
      inactiveAdmin.canBeDeletedBy(
        currentProfileId: 'admin-1',
        actorIsPlatformAdmin: true,
      ),
      isTrue,
    );
    expect(
      inactiveAdmin.canBeDeletedBy(
        currentProfileId: 'admin-2',
        actorIsPlatformAdmin: true,
      ),
      isFalse,
    );
    expect(
      activePsychologist.canBeDeletedBy(
        currentProfileId: 'admin-1',
        actorIsPlatformAdmin: true,
      ),
      isFalse,
    );
  });
}
