import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:terapia_esquema/core/errors/error_mapper.dart';
import 'package:terapia_esquema/features/patient_invitations/data/patient_invitations_repository.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/accept_patient_invitation_request.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/create_patient_invitation_request.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/created_patient_invitation.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation.dart';
import 'package:terapia_esquema/features/patient_invitations/domain/patient_invitation_status.dart';
import 'package:terapia_esquema/features/patient_invitations/providers/patient_invitations_providers.dart';

void main() {
  test('patient invitation acceptance includes legal consent versions', () {
    const request = AcceptPatientInvitationRequest(
      token: 'token',
      password: 'ValidPass123',
      profile: AcceptPatientInvitationProfile(fullName: 'Paciente Teste'),
    );

    expect(request.toJson()['legal_consent'], {
      'terms_version': '2026-06-15',
      'privacy_version': '2026-06-15',
    });
  });

  test('PatientInvitation.fromJson parses status and names', () {
    final invitation = PatientInvitation.fromJson({
      'id': 'inv-1',
      'email': 'paciente@example.com',
      'full_name': 'Bruno',
      'status': 'accepted',
      'expires_at': '2026-06-13T12:00:00.000Z',
      'accepted_at': '2026-06-07T12:00:00.000Z',
      'created_at': '2026-06-06T12:00:00.000Z',
      'invited_by': 'staff-1',
      'responsible_psychologist_id': 'psy-1',
      'invited_by_profile': {'full_name': 'Dra. Ana'},
      'responsible_psychologist_profile': {'full_name': 'Dr. Paulo'},
    });

    expect(invitation.status, PatientInvitationStatus.accepted);
    expect(invitation.invitedByName, 'Dra. Ana');
    expect(invitation.responsiblePsychologistName, 'Dr. Paulo');
  });

  test('patient invitation status labels cover expired tokens', () {
    expect(
      patientInvitationStatusFromStorage('expired').label,
      'Expirado',
    );
    expect(
      patientInvitationStatusFromStorage('revoked').isTerminal,
      isTrue,
    );
  });

  test('CreatePatientInvitationRequest.toJson trims and normalizes payload',
      () {
    final json = const CreatePatientInvitationRequest(
      email: '  Bruno@Example.com ',
      fullName: ' Bruno Costa ',
      phone: ' 51999990000 ',
      responsiblePsychologistId: 'psy-1',
    ).toJson();

    expect(json['email'], 'bruno@example.com');
    expect(json['full_name'], 'Bruno Costa');
    expect(json['phone'], '51999990000');
    expect(json['responsible_psychologist_id'], 'psy-1');
  });

  test('AcceptPatientInvitationRequest.toJson maps patient profile fields', () {
    final json = AcceptPatientInvitationRequest(
      token: 'token-123',
      password: 'SenhaSegura1',
      profile: AcceptPatientInvitationProfile(
        fullName: 'Bruno Costa',
        phone: '51999990000',
        cpf: '12345678900',
        birthDate: DateTime(1990, 5, 20),
        gender: 'Masculino',
        relationshipStatus: 'Solteiro(a)',
        educationLevel: 'Ensino superior completo',
        occupation: 'Designer',
        birthCountryState: 'Porto Alegre / Brasil',
        religiousOrientation: 'Sem religiao',
        ethnicGroup: 'Branco',
        sexualOrientation: 'Heterossexual',
        hasChildren: false,
      ),
    ).toJson();

    expect(json['token'], 'token-123');
    expect(json['profile']['birth_date'], '1990-05-20');
    expect(json['profile']['birth_country_state'], 'Porto Alegre / Brasil');
    expect(json['profile']['has_children'], isFalse);
  });

  test('expired invitation keeps generic validation message', () {
    expect(
      messageForApiCode('VALIDATION_ERROR', 'Convite invalido ou expirado.'),
      'Convite invalido ou expirado.',
    );
  });

  test('staff creates invitation through provider', () async {
    final repo = _FakePatientInvitationsRepository();
    final container = ProviderContainer(
      overrides: [
        patientInvitationsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final result =
        await container.read(createPatientInvitationProvider.notifier).submit(
              const CreatePatientInvitationRequest(
                email: 'bruno@example.com',
                fullName: 'Bruno Costa',
                responsiblePsychologistId: 'psy-1',
              ),
            );

    expect(repo.lastCreateRequest?.email, 'bruno@example.com');
    expect(result.inviteUrl, '/accept-invitation?token=secure-token');
  });

  test('patient accepts invitation through provider', () async {
    final repo = _FakePatientInvitationsRepository();
    final container = ProviderContainer(
      overrides: [
        patientInvitationsRepositoryProvider.overrideWithValue(repo),
      ],
    );
    addTearDown(container.dispose);

    final request = const AcceptPatientInvitationRequest(
      token: 'secure-token',
      password: 'SenhaSegura1',
      profile: AcceptPatientInvitationProfile(
        fullName: 'Bruno Costa',
      ),
    );

    await container
        .read(acceptPatientInvitationProvider.notifier)
        .submit(request);

    expect(repo.lastAcceptRequest?.token, 'secure-token');
    expect(repo.lastAcceptRequest?.profile.fullName, 'Bruno Costa');
  });
}

class _FakePatientInvitationsRepository extends PatientInvitationsRepository {
  _FakePatientInvitationsRepository()
      : super(
          client: SupabaseClient(
            'https://example.com',
            'public-anon-key',
          ),
        );

  CreatePatientInvitationRequest? lastCreateRequest;
  AcceptPatientInvitationRequest? lastAcceptRequest;

  @override
  Future<CreatedPatientInvitation> createInvitation(
    CreatePatientInvitationRequest request,
  ) async {
    lastCreateRequest = request;
    return CreatedPatientInvitation(
      invitation: PatientInvitation.fromJson({
        'id': 'inv-1',
        'email': request.email,
        'full_name': request.fullName,
        'status': 'pending',
        'expires_at': '2026-06-13T12:00:00.000Z',
        'created_at': '2026-06-06T12:00:00.000Z',
        'invited_by': 'staff-1',
        'responsible_psychologist_id': request.responsiblePsychologistId,
      }),
      inviteUrl: '/accept-invitation?token=secure-token',
    );
  }

  @override
  Future<void> acceptInvitation(AcceptPatientInvitationRequest request) async {
    lastAcceptRequest = request;
  }
}
