import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/case_conceptualization.dart';
import '../domain/demands_text_history.dart';

/// Lê/grava os campos do terapeuta da Conceitualização de caso
/// (`case_conceptualizations`). RLS restringe ao staff com acesso ao paciente.
class CaseConceptualizationRepository {
  CaseConceptualizationRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _select =
      'id, clinic_id, patient_id, unmet_needs, mode_sequences, '
      'therapeutic_relationship, general_impressions, diagnosis, '
      'origins, motivo_initial, motivo_current, all_schemas, additional_comments, '
      'functioning, life_problems, central_schemas, mode_assessment, '
      'therapy_objectives, updated_at';

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

  /// Upsert dos campos da Síntese (uma linha por paciente, chave `patient_id`).
  ///
  /// Motivos (2), impressões (3) e perspectiva diagnóstica (4) pertencem à tela
  /// Demandas terapêuticas e NÃO são gravados aqui — assim um formulário aberto
  /// há muito tempo não sobrescreve o que foi salvo lá.
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
          'origins': data.origins.toJson(),
          'all_schemas': (data.allSchemas ?? '').trim().isEmpty
              ? null
              : data.allSchemas!.trim(),
          'additional_comments':
              (data.additionalComments ?? '').trim().isEmpty
                  ? null
                  : data.additionalComments!.trim(),
          'functioning': data.functioning.isEmpty ? null : data.functioning.toJson(),
          'life_problems': data.lifeProblems.isEmpty ? null : data.lifeProblems.toJson(),
          'central_schemas': data.centralSchemasJson(),
          'mode_assessment': data.modeAssessment.isEmpty ? null : data.modeAssessment.toJson(),
          'therapy_objectives': data.therapyObjectivesJson(),
        },
        onConflict: 'patient_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  // ── Demandas terapêuticas (itens 2, 3 e 4) ────────────────────────────────
  // Cada aba grava só as próprias colunas (upsert parcial): salvar uma não
  // exige nem altera as outras.

  static String? _nullIfBlank(String? v) {
    final t = (v ?? '').trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _savePartial(
      String patientId, Map<String, dynamic> columns) async {
    final clinicId = await _clinicIdFor(patientId);
    await _client.from('case_conceptualizations').upsert(
      {
        'patient_id': patientId,
        'clinic_id': clinicId,
        'updated_by': _client.auth.currentUser?.id,
        ...columns,
      },
      onConflict: 'patient_id',
    );
  }

  /// Versões anteriores dos textos. A coluna `demands_history` é opcional:
  /// se ainda não existir no banco, devolve vazio em vez de falhar.
  Future<DemandsTextHistory> loadDemandsHistory(String patientId) async {
    try {
      final row = await _client
          .from('case_conceptualizations')
          .select('demands_history')
          .eq('patient_id', patientId)
          .maybeSingle();
      final raw = row?['demands_history'];
      if (raw is Map) {
        return DemandsTextHistory.fromJson(Map<String, dynamic>.from(raw));
      }
    } catch (_) {}
    return DemandsTextHistory.empty;
  }

  /// Guarda o texto substituído. Falha em silêncio: o histórico é um
  /// complemento e nunca deve impedir o salvamento do texto principal.
  Future<void> _recordTextHistory(
    String patientId,
    List<({String field, String? previous, String? next})> changes,
    String? author,
  ) async {
    final real = [
      for (final c in changes)
        if ((c.previous ?? '').trim().isNotEmpty &&
            (c.previous ?? '').trim() != (c.next ?? '').trim())
          c,
    ];
    if (real.isEmpty) return;
    try {
      var history = await loadDemandsHistory(patientId);
      final now = DateTime.now();
      for (final c in real) {
        history = history.withReplaced(c.field,
            previousText: c.previous,
            newText: c.next,
            now: now,
            author: author);
      }
      await _savePartial(patientId, {'demands_history': history.toJson()});
    } catch (_) {}
  }

  /// Aba "Motivos da terapia": motivos inicial e atual.
  Future<void> saveReasons(
    String patientId, {
    required String? initial,
    required String? current,
    String? previousInitial,
    String? previousCurrent,
    String? authorName,
  }) async {
    try {
      await _savePartial(patientId, {
        'motivo_initial': _nullIfBlank(initial),
        'motivo_current': _nullIfBlank(current),
      });
    } catch (e) {
      throw mapToAppException(e);
    }
    await _recordTextHistory(
      patientId,
      [
        (
          field: DemandsTextField.reasonsInitial,
          previous: previousInitial,
          next: initial
        ),
        (
          field: DemandsTextField.reasonsCurrent,
          previous: previousCurrent,
          next: current
        ),
      ],
      authorName,
    );
  }

  /// Aba "Impressões clínicas": impressões inicial e atual.
  Future<void> saveImpressions(
    String patientId,
    GeneralImpressions value, {
    GeneralImpressions previous = const GeneralImpressions(),
    String? authorName,
  }) async {
    try {
      await _savePartial(
          patientId, {'general_impressions': value.toJson()});
    } catch (e) {
      throw mapToAppException(e);
    }
    await _recordTextHistory(
      patientId,
      [
        (
          field: DemandsTextField.impressionsInitial,
          previous: previous.initial,
          next: value.initial
        ),
        (
          field: DemandsTextField.impressionsCurrent,
          previous: previous.current,
          next: value.current
        ),
      ],
      authorName,
    );
  }

  /// Aba "Perspectiva diagnóstica". Aplica autoria e preserva as versões
  /// anteriores; devolve o que ficou gravado.
  Future<Diagnosis> saveDiagnosis(
    String patientId,
    Diagnosis next, {
    required Diagnosis previous,
    String? authorName,
    DateTime? now,
  }) async {
    final stored = next.withRevisions(
      previous: previous,
      now: now ?? DateTime.now(),
      authorName: authorName,
    );
    try {
      await _savePartial(patientId, {'diagnosis': stored.toJson()});
    } catch (e) {
      throw mapToAppException(e);
    }
    return stored;
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
