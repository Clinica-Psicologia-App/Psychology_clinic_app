import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/edge_api_client.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/accept_patient_invitation_request.dart';
import '../domain/create_patient_invitation_request.dart';
import '../domain/created_patient_invitation.dart';
import '../domain/patient_invitation.dart';

class PatientInvitationsRepository {
  PatientInvitationsRepository({
    SupabaseClient? client,
    EdgeApiClient? edgeApi,
  })  : _client = client ?? SupabaseBootstrap.client,
        _edgeApi = edgeApi ?? EdgeApiClient(client: client);

  final SupabaseClient _client;
  final EdgeApiClient _edgeApi;

  static const _select = '''
id,
clinic_id,
invited_by,
responsible_psychologist_id,
email,
full_name,
phone,
status,
expires_at,
accepted_at,
patient_profile_id,
patient_id,
created_at,
invited_by_profile:profiles!patient_invitations_invited_by_fkey(full_name),
responsible_psychologist_profile:profiles!patient_invitations_responsible_psychologist_id_fkey(full_name)
''';

  Future<List<PatientInvitation>> listInvitations() async {
    try {
      final rows = await _client
          .from('patient_invitations')
          .select(_select)
          .order('created_at', ascending: false);

      return (rows as List)
          .map(
            (row) => PatientInvitation.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<CreatedPatientInvitation> createInvitation(
    CreatePatientInvitationRequest request,
  ) async {
    try {
      final data = await _edgeApi.invoke(
        'create-patient-invitation',
        body: request.toJson(),
      );

      final invitationJson = data['invitation'];
      if (invitationJson is! Map) {
        throw AppException(
          code: AppExceptionCodes.unknown,
          message: 'Convite criado, mas resposta incompleta.',
        );
      }

      final inviteUrl = data['invite_url'] as String?;
      if (inviteUrl == null || inviteUrl.trim().isEmpty) {
        throw AppException(
          code: AppExceptionCodes.unknown,
          message: 'Convite criado, mas link não retornado.',
        );
      }

      return CreatedPatientInvitation(
        invitation: PatientInvitation.fromJson(
          Map<String, dynamic>.from(invitationJson),
        ),
        inviteUrl: inviteUrl,
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> acceptInvitation(
    AcceptPatientInvitationRequest request,
  ) async {
    try {
      await _edgeApi.invoke(
        'accept-patient-invitation',
        body: request.toJson(),
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
