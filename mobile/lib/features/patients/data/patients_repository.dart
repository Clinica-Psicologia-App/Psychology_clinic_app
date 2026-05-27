import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/edge_api_client.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/create_patient_request.dart';
import '../domain/patient.dart';
import '../domain/psychologist_option.dart';

class PatientsRepository {
  PatientsRepository({
    SupabaseClient? client,
    EdgeApiClient? edgeApi,
  })  : _client = client ?? SupabaseBootstrap.client,
        _edgeApi = edgeApi ?? EdgeApiClient(client: client);

  final SupabaseClient _client;
  final EdgeApiClient _edgeApi;

  static const _patientSelect = '''
id,
full_name,
email,
phone,
cpf,
birth_date,
profile_id,
responsible_psychologist_id,
created_at,
responsible_psychologist:profiles!patients_responsible_psychologist_id_fkey(full_name),
access_profile:profiles!patients_profile_id_fkey(is_active)
''';

  Future<List<Patient>> listPatients() async {
    try {
      final rows = await _client
          .from('patients')
          .select(_patientSelect)
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
          .select(_patientSelect)
          .eq('id', id)
          .maybeSingle();

      if (row == null) return null;
      return Patient.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<PsychologistOption>> listPsychologistsInClinic() async {
    try {
      final rows = await _client
          .from('profiles')
          .select('id, full_name, email')
          .eq('role', 'psychologist')
          .eq('is_active', true)
          .order('full_name');

      return (rows as List)
          .map(
            (row) =>
                PsychologistOption.fromJson(Map<String, dynamic>.from(row)),
          )
          .toList();
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
}
