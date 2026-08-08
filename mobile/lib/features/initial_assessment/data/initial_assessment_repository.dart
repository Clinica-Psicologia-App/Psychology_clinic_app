import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/edge_api_client.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/assessment_catalog_item.dart';
import '../domain/clinical_impressions.dart';
import '../domain/clinical_intake.dart';
import '../domain/functioning_level.dart';
import '../domain/initial_assessment.dart';
import '../domain/life_area.dart';
import '../domain/life_area_assessment.dart';
import '../domain/patient_basics.dart';
import '../domain/patient_intake.dart';

/// Código do domínio que agrupa os modos YAMI dentro da tabela `schemas`.
const String kYamiModesDomainCode = 'YAMI_DOMAIN_SCHEMA_MODES';

/// Acesso à Tela 1 do fluxo Conhecer (Blocos 1–4).
///
/// A RLS decide o que cada lente enxerga: para o paciente, as tabelas
/// staff-only simplesmente retornam vazio, então `clinicalIntake`,
/// `clinicalImpressions` e os `clinicalComment` das áreas vêm nulos.
class InitialAssessmentRepository {
  InitialAssessmentRepository({
    SupabaseClient? client,
    EdgeApiClient? edgeApi,
  })  : _client = client ?? SupabaseBootstrap.client,
        _edgeApi = edgeApi ?? EdgeApiClient(client: client);

  final SupabaseClient _client;
  final EdgeApiClient _edgeApi;

  String? get _currentProfileId => _client.auth.currentUser?.id;

  /// Resolve o `patients.id` do paciente logado (lente do paciente).
  Future<String> getPatientIdForCurrentProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw AppException(
          code: AppExceptionCodes.unauthorized,
          message: 'Sessão não encontrada.',
        );
      }
      final row = await _client
          .from('patients')
          .select('id')
          .eq('profile_id', userId)
          .maybeSingle();
      if (row == null) {
        throw AppException(
          code: AppExceptionCodes.notFound,
          message: 'Cadastro de paciente não encontrado para este login.',
        );
      }
      return row['id'] as String;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Leitura
  // ---------------------------------------------------------------------------

  static const _basicsSelect =
      'full_name, preferred_name, birth_date, occupation, lives_with, '
      'has_children, uses_medication, medication_notes, psychiatric_followup, '
      'psychiatrist_notes, important_to_know, '
      'relationship_status, sexual_orientation, country_birth, '
      'ethnic_group, religious_orientation, '
      'access_profile:profiles!patients_profile_id_fkey'
      '(avatar_type, avatar_path, avatar_url, avatar_config, avatar_updated_at)';

  String _avatarPublicUrl(String path) =>
      _client.storage.from('avatars').getPublicUrl(path);

  Future<InitialAssessment> load(String patientId) async {
    try {
      final basicsRow = await _client
          .from('patients')
          .select(_basicsSelect)
          .eq('id', patientId)
          .maybeSingle();

      final intakeRow = await _client
          .from('patient_intake')
          .select()
          .eq('patient_id', patientId)
          .maybeSingle();

      final areaRows = await _client
          .from('patient_life_areas')
          .select()
          .eq('patient_id', patientId);

      // Staff-only — vazio/nulo quando o solicitante é o paciente (RLS).
      final clinicalIntakeRow = await _client
          .from('patient_clinical_intake')
          .select()
          .eq('patient_id', patientId)
          .maybeSingle();

      final noteRows = await _client
          .from('patient_life_area_notes')
          .select()
          .eq('patient_id', patientId);

      final impressionsRow = await _client
          .from('patient_clinical_impressions')
          .select()
          .eq('patient_id', patientId)
          .maybeSingle();

      return InitialAssessment(
        patientId: patientId,
        basics: basicsRow == null
            ? null
            : PatientBasics.fromJson(
                Map<String, dynamic>.from(basicsRow),
                publicUrlOf: _avatarPublicUrl,
              ),
        intake: intakeRow == null
            ? null
            : PatientIntake.fromJson(Map<String, dynamic>.from(intakeRow)),
        clinicalIntake: clinicalIntakeRow == null
            ? null
            : ClinicalIntake.fromJson(
                Map<String, dynamic>.from(clinicalIntakeRow)),
        lifeAreas: _mergeLifeAreas(areaRows, noteRows),
        clinicalImpressions: impressionsRow == null
            ? null
            : ClinicalImpressions.fromJson(
                Map<String, dynamic>.from(impressionsRow),
              ),
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  List<LifeAreaAssessment> _mergeLifeAreas(
    List<dynamic> areaRows,
    List<dynamic> noteRows,
  ) {
    final byArea = <LifeArea, LifeAreaAssessment>{};
    for (final row in areaRows) {
      final a = LifeAreaAssessment.fromJson(Map<String, dynamic>.from(row));
      byArea[a.area] = a;
    }
    final notesByArea = <LifeArea, String?>{};
    for (final row in noteRows) {
      final area = lifeAreaFromKey(row['area_key'] as String?);
      if (area != null) notesByArea[area] = row['clinical_comment'] as String?;
    }
    return [
      for (final area in kLifeAreasInOrder)
        (byArea[area] ?? LifeAreaAssessment(area: area))
            .copyWith(clinicalComment: notesByArea[area]),
    ];
  }

  // ---------------------------------------------------------------------------
  // Catálogos (checklists do Bloco 4)
  // ---------------------------------------------------------------------------

  /// Esquemas (YSQ) e modos (YAMI) vivem na mesma tabela `schemas`; separamos
  /// pelo código do domínio.
  Future<
      ({
        List<AssessmentCatalogItem> schemas,
        List<AssessmentCatalogItem> modes
      })> loadSchemaAndModeCatalog() async {
    try {
      final rows = await _client
          .from('schemas')
          .select('id, code, name, description, sort_order, '
              'schema_domains!inner(code)')
          .eq('is_active', true)
          .order('sort_order');

      final schemas = <AssessmentCatalogItem>[];
      final modes = <AssessmentCatalogItem>[];
      for (final row in rows) {
        final map = Map<String, dynamic>.from(row);
        final domain = map['schema_domains'];
        final domainCode = domain is Map ? domain['code'] as String? : null;
        final item = AssessmentCatalogItem.fromJson(map);
        if (domainCode == kYamiModesDomainCode) {
          modes.add(item);
        } else {
          schemas.add(item);
        }
      }
      return (schemas: schemas, modes: modes);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<List<AssessmentCatalogItem>> loadEmotionalNeeds() async {
    try {
      final rows = await _client
          .from('emotional_needs')
          .select('id, code, name, description')
          .eq('is_active', true)
          .order('sort_order');
      return [
        for (final row in rows)
          AssessmentCatalogItem.fromJson(Map<String, dynamic>.from(row)),
      ];
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Escrita — lente do paciente (visível ao paciente)
  // ---------------------------------------------------------------------------

  /// Bloco 1 — grava via edge function `update-patient-basics`, porque a RLS
  /// de `patients` não permite UPDATE pelo paciente. A função valida o
  /// chamador e escreve só as colunas da lista branca.
  Future<void> savePatientBasics({
    required String patientId,
    String? preferredName,
    DateTime? birthDate,
    String? occupation,
    String? livesWith,
    bool? hasChildren,
    bool? usesMedication,
    String? medicationNotes,
    bool? psychiatricFollowup,
    String? psychiatristNotes,
    String? importantToKnow,
  }) async {
    await _edgeApi.invoke(
      'update-patient-basics',
      body: {
        'patient_id': patientId,
        'preferred_name': preferredName,
        'birth_date': birthDate?.toIso8601String().split('T').first,
        'occupation': occupation,
        'lives_with': livesWith,
        'has_children': hasChildren,
        'uses_medication': usesMedication,
        'medication_notes': medicationNotes,
        'psychiatric_followup': psychiatricFollowup,
        'psychiatrist_notes': psychiatristNotes,
        'important_to_know': importantToKnow,
      },
    );
  }

  Future<void> saveIntake({
    required String patientId,
    required String filledByRole,
    String? reasonForSeeking,
    String? problemDuration,
    String? mainDiscomfort,
    String? expectations,
    String? relatedEvent,
    bool markCompleted = false,
  }) async {
    try {
      await _client.from('patient_intake').upsert(
        {
          'patient_id': patientId,
          'reason_for_seeking': reasonForSeeking,
          'problem_duration': problemDuration,
          'main_discomfort': mainDiscomfort,
          'expectations': expectations,
          'related_event': relatedEvent,
          'filled_by_profile_id': _currentProfileId,
          'filled_by_role': filledByRole,
          if (markCompleted)
            'completed_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'patient_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> saveLifeArea({
    required String patientId,
    required String filledByRole,
    required LifeArea area,
    int? score,
    int? suffering,
    String? guidedAnswer,
  }) async {
    try {
      await _client.from('patient_life_areas').upsert(
        {
          'patient_id': patientId,
          'area_key': area.key,
          'score': score,
          'suffering': suffering,
          'guided_answer': guidedAnswer,
          'filled_by_profile_id': _currentProfileId,
          'filled_by_role': filledByRole,
          'assessed_at': DateTime.now().toUtc().toIso8601String(),
        },
        onConflict: 'patient_id,area_key',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Upsert de várias áreas de uma vez (Bloco 3 inteiro).
  Future<void> saveLifeAreasBulk({
    required String patientId,
    required String filledByRole,
    required List<LifeAreaAssessment> areas,
  }) async {
    if (areas.isEmpty) return;
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await _client.from('patient_life_areas').upsert(
        [
          for (final a in areas)
            {
              'patient_id': patientId,
              'area_key': a.area.key,
              'score': a.score,
              'suffering': a.suffering,
              'guided_answer': a.guidedAnswer,
              'filled_by_profile_id': _currentProfileId,
              'filled_by_role': filledByRole,
              'assessed_at': now,
            },
        ],
        onConflict: 'patient_id,area_key',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  // ---------------------------------------------------------------------------
  // Escrita — lente do terapeuta (staff-only)
  // ---------------------------------------------------------------------------

  Future<void> saveClinicalIntake({
    required String patientId,
    String? initialObservations,
    String? mainComplaint,
    String? currentProblem,
    String? precipitatingFactors,
    String? patientGoals,
    String? motivation,
    String? initialHypotheses,
  }) async {
    try {
      await _client.from('patient_clinical_intake').upsert(
        {
          'patient_id': patientId,
          'initial_observations': initialObservations,
          'main_complaint': mainComplaint,
          'current_problem': currentProblem,
          'precipitating_factors': precipitatingFactors,
          'patient_goals': patientGoals,
          'motivation': motivation,
          'initial_hypotheses': initialHypotheses,
          'updated_by_profile_id': _currentProfileId,
        },
        onConflict: 'patient_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Upsert em lote dos comentários clínicos por área (Bloco 3, terapeuta).
  Future<void> saveLifeAreaNotesBulk({
    required String patientId,
    required Map<LifeArea, String?> notes,
  }) async {
    if (notes.isEmpty) return;
    try {
      await _client.from('patient_life_area_notes').upsert(
        [
          for (final entry in notes.entries)
            {
              'patient_id': patientId,
              'area_key': entry.key.key,
              'clinical_comment': (entry.value ?? '').trim().isEmpty
                  ? null
                  : entry.value!.trim(),
              'updated_by_profile_id': _currentProfileId,
            },
        ],
        onConflict: 'patient_id,area_key',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> saveLifeAreaNote({
    required String patientId,
    required LifeArea area,
    String? clinicalComment,
  }) async {
    try {
      await _client.from('patient_life_area_notes').upsert(
        {
          'patient_id': patientId,
          'area_key': area.key,
          'clinical_comment': clinicalComment,
          'updated_by_profile_id': _currentProfileId,
        },
        onConflict: 'patient_id,area_key',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> saveClinicalImpressions({
    required String patientId,
    String? observedTemperament,
    String? therapeuticBond,
    String? resources,
    String? vulnerabilities,
    String? hypotheses,
    String? previousDiagnoses,
    String? differentialDiagnosis,
    FunctioningLevel? functioningLevel,
    String? therapeuticPriorities,
    String? schemaHypothesesText,
    String? modeHypothesesText,
    String? emotionalNeedsText,
  }) async {
    try {
      await _client.from('patient_clinical_impressions').upsert(
        {
          'patient_id': patientId,
          'observed_temperament': observedTemperament,
          'therapeutic_bond': therapeuticBond,
          'resources': resources,
          'vulnerabilities': vulnerabilities,
          'hypotheses': hypotheses,
          'previous_diagnoses': previousDiagnoses,
          'differential_diagnosis': differentialDiagnosis,
          'functioning_level': functioningLevel?.key,
          'therapeutic_priorities': therapeuticPriorities,
          'schema_hypotheses_text': schemaHypothesesText,
          'mode_hypotheses_text': modeHypothesesText,
          'emotional_needs_text': emotionalNeedsText,
          'updated_by_profile_id': _currentProfileId,
        },
        onConflict: 'patient_id',
      );
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Substitui a seleção de esquemas para o paciente.
  Future<void> setSchemaHypotheses(String patientId, List<String> schemaIds) =>
      _replaceSelection(
        table: 'patient_schema_hypotheses',
        column: 'schema_id',
        patientId: patientId,
        ids: schemaIds,
      );

  Future<void> setModeHypotheses(String patientId, List<String> modeIds) =>
      _replaceSelection(
        table: 'patient_mode_hypotheses',
        column: 'mode_id',
        patientId: patientId,
        ids: modeIds,
      );

  Future<void> setEmotionalNeeds(String patientId, List<String> needIds) =>
      _replaceSelection(
        table: 'patient_emotional_needs',
        column: 'emotional_need_id',
        patientId: patientId,
        ids: needIds,
      );

  Future<void> _replaceSelection({
    required String table,
    required String column,
    required String patientId,
    required List<String> ids,
  }) async {
    try {
      await _client.from(table).delete().eq('patient_id', patientId);
      if (ids.isEmpty) return;
      await _client.from(table).insert([
        for (final id in ids)
          {
            'patient_id': patientId,
            column: id,
            'created_by_profile_id': _currentProfileId,
          },
      ]);
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
