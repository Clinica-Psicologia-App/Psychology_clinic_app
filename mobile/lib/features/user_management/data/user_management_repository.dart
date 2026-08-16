import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/edge_api_client.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../../clinics/data/clinics_repository.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/clinic_user.dart';
import '../domain/create_clinic_user_request.dart';

class UserManagementRepository {
  UserManagementRepository({
    SupabaseClient? client,
    EdgeApiClient? edgeApi,
    ClinicsRepository? clinicsRepo,
  })  : _client = client ?? SupabaseBootstrap.client,
        _edgeApi = edgeApi ?? EdgeApiClient(client: client),
        _clinicsRepo = clinicsRepo ?? ClinicsRepository(client: client);

  final SupabaseClient _client;
  final EdgeApiClient _edgeApi;
  final ClinicsRepository _clinicsRepo;

  /// Mesmo bucket e mesma montagem de URL usados no próprio perfil.
  String _avatarPublicUrl(String path) =>
      _client.storage.from('avatars').getPublicUrl(path);

  Future<List<ClinicUser>> listClinicUsers() async {
    try {
      final rows = await _client
          .from('profiles')
          .select(
            'id, clinic_id, full_name, email, phone, role, crp, is_active, '
            'can_receive_patients, patient_assignment_limit, '
            'avatar_type, avatar_path, avatar_url, avatar_config, '
            'avatar_updated_at, '
            'created_at, clinic:clinics!profiles_clinic_id_fkey('
            'id, name, clinic_type, is_active)',
          )
          .or('role.eq.platform_admin,role.eq.psychologist')
          .order('clinic_id')
          .order('full_name');

      // platform_admin não pode fazer SELECT direto em patients/invitations
      // (RLS bloqueado por privacidade clínica). A RPC get_patient_counts_by_psychologist
      // é SECURITY DEFINER e retorna contagens agregadas com segurança.
      final rpcRows = await _client
          .rpc('get_patient_counts_by_psychologist') as List;

      final patientsByPsychologist = <String, int>{
        for (final row in rpcRows)
          row['psychologist_id'] as String:
              (row['active_count'] as num?)?.toInt() ?? 0,
      };
      final invitationsByPsychologist = <String, int>{
        for (final row in rpcRows)
          row['psychologist_id'] as String:
              (row['pending_invites'] as num?)?.toInt() ?? 0,
      };

      return (rows as List).map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        final id = json['id'] as String;
        json['assigned_patients_count'] = patientsByPsychologist[id] ?? 0;
        json['pending_patient_invitations_count'] =
            invitationsByPsychologist[id] ?? 0;
        return ClinicUser.fromJson(json, publicUrlOf: _avatarPublicUrl);
      }).toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<ClinicUser> createClinicUser(CreateClinicUserRequest request) async {
    try {
      // Para profissionais individuais, cria a clínica pessoal automaticamente
      // usando o nome do profissional como nome da clínica.
      final String resolvedClinicId;
      if (request.isIndividual) {
        resolvedClinicId = await _clinicsRepo.createClinic(
          name: request.fullName.trim(),
          clinicType: 'personal',
        );
      } else {
        resolvedClinicId = request.clinicId!;
      }

      final data = await _edgeApi.invoke(
        'create-staff-user',
        body: request.toJsonWithClinicId(resolvedClinicId),
      );

      final profileJson = data['profile'];
      if (profileJson is! Map) {
        throw AppException(
          code: AppExceptionCodes.unknown,
          message: 'Usuário criado, mas resposta incompleta.',
        );
      }

      return ClinicUser.fromJson(
        Map<String, dynamic>.from(profileJson),
        publicUrlOf: _avatarPublicUrl,
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> setUserActive({
    required String profileId,
    required bool isActive,
  }) async {
    try {
      await _client
          .from('profiles')
          .update({'is_active': isActive}).eq('id', profileId);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> deleteUser(String profileId) async {
    try {
      await _edgeApi.invoke(
        'delete-staff-user',
        body: {'profile_id': profileId},
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> updateUserRole({
    required String profileId,
    required ProfileRole newRole,
  }) async {
    try {
      final row = await _client
          .from('profiles')
          .update({'role': newRole.storageValue})
          .eq('id', profileId)
          .select('id')
          .maybeSingle();

      if (row == null) {
        throw AppException(
          code: AppExceptionCodes.notFound,
          message: 'Usuário não encontrado ou sem permissão para alteração.',
        );
      }
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> updatePsychologistAccess({
    required String profileId,
    required bool canReceivePatients,
    required int? patientAssignmentLimit,
  }) async {
    try {
      final row = await _client
          .from('profiles')
          .update({
            'can_receive_patients': canReceivePatients,
            'patient_assignment_limit': patientAssignmentLimit,
          })
          .eq('id', profileId)
          .eq('role', 'psychologist')
          .select('id')
          .maybeSingle();

      if (row == null) {
        throw AppException(
          code: AppExceptionCodes.notFound,
          message: 'Psicólogo não encontrado ou sem permissão para alteração.',
        );
      }
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}

