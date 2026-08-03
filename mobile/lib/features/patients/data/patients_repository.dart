import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/edge_api_client.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/create_patient_request.dart';
import '../domain/patient.dart';
import '../domain/psychologist_option.dart';
import '../domain/update_patient_request.dart';

class PatientsRepository {
  PatientsRepository({
    SupabaseClient? client,
    EdgeApiClient? edgeApi,
  })  : _client = client ?? SupabaseBootstrap.client,
        _edgeApi = edgeApi ?? EdgeApiClient(client: client);

  final SupabaseClient _client;
  final EdgeApiClient _edgeApi;

  static const _patientDetailSelect = '''
id,
full_name,
email,
phone,
cpf,
birth_date,
gender,
relationship_status,
education_level,
occupation,
country_birth,
state_birth,
religious_orientation,
ethnic_group,
sexual_orientation,
has_children,
intake_summary,
current_life_context,
therapy_demands,
profile_id,
responsible_psychologist_id,
is_active,
inactivated_at,
results_released_at,
created_at,
responsible_psychologist:profiles!patients_responsible_psychologist_id_fkey(full_name),
access_profile:profiles!patients_profile_id_fkey(is_active, avatar_type, avatar_path, avatar_url, avatar_config, avatar_updated_at)
''';

  /// Mesmo bucket e mesma montagem de URL usados no próprio perfil.
  String _avatarPublicUrl(String path) =>
      _client.storage.from('avatars').getPublicUrl(path);

  Future<List<Patient>> listPatients() async {
    try {
      final rows = await _client
          .from('patients')
          .select(_patientDetailSelect)
          .order('full_name');

      return (rows as List)
          .map((row) => Patient.fromJson(
                Map<String, dynamic>.from(row),
                publicUrlOf: _avatarPublicUrl,
              ))
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Registro do paciente logado (via profile_id). RLS garante que só o
  /// próprio paciente (ou staff da clínica) leia a linha.
  Future<Patient?> getMyPatient() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) return null;
      final row = await _client
          .from('patients')
          .select(_patientDetailSelect)
          .eq('profile_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return Patient.fromJson(
        Map<String, dynamic>.from(row),
        publicUrlOf: _avatarPublicUrl,
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<Patient?> getPatientById(String id) async {
    try {
      final row = await _client
          .from('patients')
          .select(_patientDetailSelect)
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return Patient.fromJson(
        Map<String, dynamic>.from(row),
        publicUrlOf: _avatarPublicUrl,
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<PsychologistOption>> listPsychologistsInClinic() async {
    try {
      final rows = await _client
          .from('profiles')
          .select(
            'id, full_name, email, can_receive_patients, patient_assignment_limit',
          )
          .eq('role', 'psychologist')
          .eq('is_active', true)
          .order('full_name');

      final patientRows = await _client
          .from('patients')
          .select('responsible_psychologist_id')
          .eq('is_active', true);
      final invitationRows = await _client
          .from('patient_invitations')
          .select('responsible_psychologist_id')
          .eq('status', 'pending');
      final patientsByPsychologist = _countByProfile(
        patientRows as List,
        'responsible_psychologist_id',
      );
      final invitationsByPsychologist = _countByProfile(
        invitationRows as List,
        'responsible_psychologist_id',
      );

      return (rows as List).map((row) {
        final json = Map<String, dynamic>.from(row as Map);
        final id = json['id'] as String;
        json['assigned_patients_count'] = patientsByPsychologist[id] ?? 0;
        json['pending_patient_invitations_count'] =
            invitationsByPsychologist[id] ?? 0;
        return PsychologistOption.fromJson(json);
      }).toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<Patient> createPatient(CreatePatientRequest request) async {
    try {
      final data = await _edgeApi.invoke(
        'create-patient',
        body: request.toJson(),
      );

      final patientJson = data['patient'];
      if (patientJson is! Map) {
        throw AppException(
          code: AppExceptionCodes.unknown,
          message: 'Paciente criado, mas resposta incompleta.',
        );
      }

      final id = patientJson['id'] as String?;
      if (id == null) {
        throw AppException(
          code: AppExceptionCodes.unknown,
          message: 'Paciente criado, mas ID não retornado.',
        );
      }

      final patient = await getPatientById(id);
      if (patient != null) return patient;

      return Patient.fromJson(Map<String, dynamic>.from(patientJson));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<Patient> setPatientActiveStatus({
    required String patientId,
    required bool isActive,
  }) async {
    try {
      await _client.rpc(
        'set_patient_active_status',
        params: {
          'p_patient_id': patientId,
          'p_is_active': isActive,
        },
      );

      final patient = await getPatientById(patientId);
      if (patient == null) {
        throw AppException(
          code: AppExceptionCodes.notFound,
          message: 'Paciente não encontrado após a atualização.',
        );
      }
      return patient;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Libera (ou revoga) o acesso do paciente aos resultados clínicos.
  Future<Patient> setResultsReleased({
    required String patientId,
    required bool released,
  }) async {
    try {
      await _client.rpc(
        'set_patient_results_released',
        params: {
          'p_patient_id': patientId,
          'p_released': released,
        },
      );

      final patient = await getPatientById(patientId);
      if (patient == null) {
        throw AppException(
          code: AppExceptionCodes.notFound,
          message: 'Paciente não encontrado após a liberação.',
        );
      }
      return patient;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<Patient> updatePatient(UpdatePatientRequest request) async {
    try {
      final data = request.toJson();
      if (data.isEmpty) {
        final patient = await getPatientById(request.patientId);
        if (patient == null) {
          throw AppException(
            code: AppExceptionCodes.notFound,
            message: 'Paciente não encontrado.',
          );
        }
        return patient;
      }
      final row = await _client
          .from('patients')
          .update(data)
          .eq('id', request.patientId)
          .select(_patientDetailSelect)
          .single();
      return Patient.fromJson(
        Map<String, dynamic>.from(row),
        publicUrlOf: _avatarPublicUrl,
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> deletePatient(String patientId) async {
    try {
      await _client.rpc(
        'delete_patient_as_admin',
        params: {'p_patient_id': patientId},
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}

Map<String, int> _countByProfile(List<dynamic> rows, String field) {
  final counts = <String, int>{};
  for (final row in rows) {
    final profileId = (row as Map)[field] as String?;
    if (profileId == null || profileId.isEmpty) continue;
    counts[profileId] = (counts[profileId] ?? 0) + 1;
  }
  return counts;
}
