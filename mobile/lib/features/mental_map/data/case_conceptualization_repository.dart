import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/case_conceptualization.dart';

/// Lê/grava os campos do terapeuta da Conceitualização de caso
/// (`case_conceptualizations`). RLS restringe ao staff com acesso ao paciente.
class CaseConceptualizationRepository {
  CaseConceptualizationRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _select =
      'id, clinic_id, patient_id, unmet_needs, mode_sequences, '
      'therapeutic_relationship, general_impressions, diagnosis, '
      'origins, motivo_notes, additional_comments, updated_at';

  /// Carrega o documento do paciente; se ainda não existe, devolve um vazio.
  Future<CaseConceptualization> load(String patientId) async {
    try {
      final row = await _client
          .from('case_conceptualizations')
          .select(_select)
          .eq('patient_id', patientId)
          .maybeSingle();
      if (row == null) return CaseConceptualization.empty();
      return CaseConceptualization.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Upsert do documento (uma linha por paciente, chave `patient_id`).
  Future<void> save(String patientId, CaseConceptualization data) async {
    try {
      final clinicId = await _clinicIdFor(patientId);
      await _client.from('case_conceptualizations').upsert(
        {
          'patient_id': patientId,
          'clinic_id': clinicId,
          'updated_by': _client.auth.currentUser?.id,
          'unmet_needs': data.unmetNeedsJson(),
          'mode_sequences': data.modeSequencesJson(),
          'therapeutic_relationship': data.relationship.toJson(),
          'general_impressions': data.generalImpressions.toJson(),
          'diagnosis': data.diagnosis.toJson(),
          'origins': data.origins.toJson(),
          'motivo_notes': (data.motivoNotes ?? '').trim().isEmpty
              ? null
              : data.motivoNotes!.trim(),
          'additional_comments':
              (data.additionalComments ?? '').trim().isEmpty
                  ? null
                  : data.additionalComments!.trim(),
        },
        onConflict: 'patient_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<String> _clinicIdFor(String patientId) async {
    final row = await _client
        .from('patients')
        .select('clinic_id')
        .eq('id', patientId)
        .maybeSingle();
    if (row == null) {
      throw AppException(
        code: AppExceptionCodes.notFound,
        message: 'Paciente não encontrado.',
      );
    }
    return row['clinic_id'] as String;
  }
}
