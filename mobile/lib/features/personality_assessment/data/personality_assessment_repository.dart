import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/personality_assessment.dart';

/// Lê/grava avaliações de personalidade (`personality_assessments`).
/// RLS restringe ao staff com acesso ao paciente.
class PersonalityAssessmentRepository {
  PersonalityAssessmentRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _select =
      'id, clinic_id, patient_id, instrument, applied_on, application_form, '
      'protocol_validity, results, shared_with_patient, clinical_synthesis, '
      'conceptualization_integration, created_at, updated_at';

  Future<List<PersonalityAssessment>> listForPatient(String patientId) async {
    try {
      final rows = await _client
          .from('personality_assessments')
          .select(_select)
          .eq('patient_id', patientId)
          .order('applied_on', ascending: false, nullsFirst: false)
          .order('created_at', ascending: false);
      return [
        for (final r in (rows as List))
          PersonalityAssessment.fromJson(Map<String, dynamic>.from(r as Map)),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<PersonalityAssessment?> getById(String id) async {
    try {
      final row = await _client
          .from('personality_assessments')
          .select(_select)
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return PersonalityAssessment.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<String> create({
    required String patientId,
    required String instrument,
    required PersonalityResults results,
    DateTime? appliedOn,
    String? applicationForm,
    ProtocolValidity? protocolValidity,
  }) async {
    try {
      final clinicId = await _clinicIdFor(patientId);
      final row = await _client
          .from('personality_assessments')
          .insert({
            'patient_id': patientId,
            'clinic_id': clinicId,
            'created_by': _client.auth.currentUser?.id,
            'updated_by': _client.auth.currentUser?.id,
            'instrument': instrument,
            'applied_on': _formatDate(appliedOn),
            'application_form': _nullableTrim(applicationForm),
            'protocol_validity': protocolValidity?.code,
            'results': results.toJson(),
          })
          .select('id')
          .single();
      return row['id'] as String;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> update({
    required String id,
    required PersonalityResults results,
    DateTime? appliedOn,
    String? applicationForm,
    ProtocolValidity? protocolValidity,
  }) async {
    try {
      await _client.from('personality_assessments').update({
        'updated_by': _client.auth.currentUser?.id,
        'applied_on': _formatDate(appliedOn),
        'application_form': _nullableTrim(applicationForm),
        'protocol_validity': protocolValidity?.code,
        'results': results.toJson(),
      }).eq('id', id);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Salva a síntese clínica + integração à conceitualização (Fase 2).
  Future<void> saveSynthesis({
    required String id,
    required ClinicalSynthesis synthesis,
    required ConceptualizationIntegration integration,
  }) async {
    try {
      await _client.from('personality_assessments').update({
        'updated_by': _client.auth.currentUser?.id,
        'clinical_synthesis': synthesis.toJson(),
        'conceptualization_integration': integration.toJson(),
      }).eq('id', id);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Liga/desliga o compartilhamento do perfil com o paciente (Fase 3).
  Future<void> setShared({required String id, required bool shared}) async {
    try {
      await _client.from('personality_assessments').update({
        'updated_by': _client.auth.currentUser?.id,
        'shared_with_patient': shared,
      }).eq('id', id);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Lista os perfis que o terapeuta compartilhou com o paciente logado
  /// (via view isolada: só classificação, sem escores/síntese).
  Future<List<PersonalityAssessment>> listSharedForCurrentPatient() async {
    try {
      final rows = await _client
          .from('patient_shared_personality')
          .select()
          .order('applied_on', ascending: false, nullsFirst: false);
      return [
        for (final r in (rows as List))
          PersonalityAssessment.fromPatientView(
              Map<String, dynamic>.from(r as Map)),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> delete(String id) async {
    try {
      await _client.from('personality_assessments').delete().eq('id', id);
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

  static String? _formatDate(DateTime? d) {
    if (d == null) return null;
    final y = d.year.toString().padLeft(4, '0');
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '$y-$m-$day';
  }

  static String? _nullableTrim(String? v) {
    if (v == null) return null;
    final t = v.trim();
    return t.isEmpty ? null : t;
  }
}
