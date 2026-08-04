import 'library_work.dart';

/// Obra do catálogo na perspectiva do PSICÓLOGO: todos os campos, incluindo a
/// camada clínica (não visível ao paciente). Vem da tabela library_works
/// (leitura de staff via RLS).
class LibraryWorkFull {
  const LibraryWorkFull({
    required this.id,
    required this.displayTitle,
    required this.workType,
    this.fichaNumber,
    this.originalTitle,
    this.isAnimation = false,
    this.year,
    this.genres,
    this.duration,
    this.seasons,
    this.rating,
    this.synopsis,
    this.primarySchema,
    this.domain,
    this.associatedSchemas = const [],
    this.themes = const [],
    this.intensity,
    this.coverUrl,
    this.psychologist = const LibraryPsychologistLayer(),
    this.patientLayer = const LibraryPatientLayer(),
  });

  final String id;
  final int? fichaNumber;
  final String displayTitle;
  final String? originalTitle;
  final String workType;
  final bool isAnimation;
  final int? year;
  final String? genres;
  final String? duration;
  final String? seasons;
  final String? rating;
  final String? synopsis;
  final String? primarySchema;
  final String? domain;
  final List<String> associatedSchemas;
  final List<String> themes;
  final String? intensity;
  final String? coverUrl;
  final LibraryPsychologistLayer psychologist;
  final LibraryPatientLayer patientLayer;

  factory LibraryWorkFull.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> asMap(dynamic v) =>
        v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
    List<String> asList(dynamic v) =>
        v is List ? v.map((e) => e.toString()).toList() : const [];

    return LibraryWorkFull(
      id: json['id'] as String,
      fichaNumber: (json['ficha_number'] as num?)?.toInt(),
      displayTitle: json['display_title'] as String? ?? 'Sem título',
      originalTitle: json['original_title'] as String?,
      workType: json['work_type'] as String? ?? 'Filme',
      isAnimation: json['is_animation'] as bool? ?? false,
      year: (json['year'] as num?)?.toInt(),
      genres: json['genres'] as String?,
      duration: json['duration'] as String?,
      seasons: json['seasons'] as String?,
      rating: json['rating'] as String?,
      synopsis: json['synopsis'] as String?,
      primarySchema: json['primary_schema'] as String?,
      domain: json['domain'] as String?,
      associatedSchemas: asList(json['associated_schemas']),
      themes: asList(json['themes']),
      intensity: json['intensity'] as String?,
      coverUrl: json['cover_url'] as String?,
      psychologist:
          LibraryPsychologistLayer.fromJson(asMap(json['psychologist_layer'])),
      patientLayer: LibraryPatientLayer.fromJson(asMap(json['patient_layer'])),
    );
  }
}

/// Camada clínica (fica só com o staff).
class LibraryPsychologistLayer {
  const LibraryPsychologistLayer({
    this.whenToIndicate = const [],
    this.objectives = const [],
    this.observationFocus = const [],
    this.emotionalMobilizations = const [],
    this.clinicalCautions = const [],
    this.schemaModes = const [],
    this.sessionInterventions = const [],
    this.sessionQuestions = const [],
    this.clinicalNote,
  });

  final List<String> whenToIndicate;
  final List<String> objectives;
  final List<String> observationFocus;
  final List<String> emotionalMobilizations;
  final List<String> clinicalCautions;
  final List<String> schemaModes;
  final List<String> sessionInterventions;
  final List<String> sessionQuestions;
  final String? clinicalNote;

  factory LibraryPsychologistLayer.fromJson(Map<String, dynamic> json) {
    List<String> l(String k) => json[k] is List
        ? (json[k] as List).map((e) => e.toString()).toList()
        : const [];
    return LibraryPsychologistLayer(
      whenToIndicate: l('when_to_indicate'),
      objectives: l('objectives'),
      observationFocus: l('observation_focus'),
      emotionalMobilizations: l('emotional_mobilizations'),
      clinicalCautions: l('clinical_cautions'),
      schemaModes: l('schema_modes'),
      sessionInterventions: l('session_interventions'),
      sessionQuestions: l('session_questions'),
      clinicalNote: json['clinical_note'] as String?,
    );
  }
}
