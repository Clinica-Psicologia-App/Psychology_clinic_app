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

  static const _patientBaseSelect = '''
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
profile_id,
responsible_psychologist_id,
is_active,
inactivated_at,
created_at,
responsible_psychologist:profiles!patients_responsible_psychologist_id_fkey(full_name),
access_profile:profiles!patients_profile_id_fkey(is_active)
''';

  static const _patientDetailSelect = '''
$_patientBaseSelect,
intake_summary,
current_life_context,
therapy_demands
''';

  Future<List<Patient>> listPatients() async {
    try {
      final rows = await _client
          .from('patients')
          .select(_patientBaseSelect)
          .order('full_name');

      return (rows as List)
          .map((row) => Patient.fromJson(Map<String, dynamic>.from(row)))
          .toList();
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
      return Patient.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      if (_isMissingIntakeColumnsError(e)) {
        final row = await _client
            .from('patients')
            .select(_patientBaseSelect)
            .eq('id', id)
            .maybeSingle();

        if (row == null) return null;
        return Patient.fromJson(
          Map<String, dynamic>.from(row),
          supportsIntakeContext: false,
        );
      }
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

  Future<Patient> updatePatientIntake({
    required String patientId,
    String? intakeSummary,
    String? currentLifeContext,
    String? therapyDemands,
  }) async {
    try {
      final row = await _client
          .from('patients')
          .update({
            'intake_summary': _nullableTrim(intakeSummary),
            'current_life_context': _nullableTrim(currentLifeContext),
            'therapy_demands': _nullableTrim(therapyDemands),
          })
          .eq('id', patientId)
          .select(_patientDetailSelect)
          .single();

      return Patient.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      if (_isMissingIntakeColumnsError(e)) {
        throw AppException(
          code: AppExceptionCodes.validation,
          message: 'Este ambiente ainda não possui os campos de anamnese '
              'do paciente. Aplique a migration '
              '20250604193022_patient_intake_context.sql.',
          cause: e,
        );
      }
      throw mapToAppException(e);
    }
  }

  String? _nullableTrim(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }

  bool _isMissingIntakeColumnsError(Object error) {
    if (error is! PostgrestException) return false;
    final code = error.code ?? '';
    final message = error.message.toLowerCase();

    if (code == '42703') {
      return message.contains('intake_summary') ||
          message.contains('current_life_context') ||
          message.contains('therapy_demands');
    }

    return message.contains('column patients.intake_summary does not exist') ||
        message.contains(
          'column patients.current_life_context does not exist',
        ) ||
        message.contains('column patients.therapy_demands does not exist');
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
          .select(_patientBaseSelect)
          .single();
      return Patient.fromJson(Map<String, dynamic>.from(row));
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
