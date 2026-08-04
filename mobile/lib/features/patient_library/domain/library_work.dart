/// Obra do catálogo na perspectiva do PACIENTE (campos seguros apenas — sem
/// camada do psicólogo nem nomes de esquema). Vem da RPC get_my_library.
class LibraryWork {
  const LibraryWork({
    required this.id,
    required this.displayTitle,
    required this.workType,
    this.isAnimation = false,
    this.year,
    this.genres,
    this.duration,
    this.seasons,
    this.rating,
    this.synopsis,
    this.coverUrl,
    this.patientLayer = const LibraryPatientLayer(),
  });

  final String id;
  final String displayTitle;

  /// Filme | Série | Minissérie | Episódio.
  final String workType;
  final bool isAnimation;
  final int? year;
  final String? genres;
  final String? duration;
  final String? seasons;
  final String? rating;
  final String? synopsis;
  final String? coverUrl;
  final LibraryPatientLayer patientLayer;

  factory LibraryWork.fromJson(Map<String, dynamic> json) {
    return LibraryWork(
      id: json['id'] as String,
      displayTitle: json['display_title'] as String? ?? 'Sem título',
      workType: json['work_type'] as String? ?? 'Filme',
      isAnimation: json['is_animation'] as bool? ?? false,
      year: (json['year'] as num?)?.toInt(),
      genres: json['genres'] as String?,
      duration: json['duration'] as String?,
      seasons: json['seasons'] as String?,
      rating: json['rating'] as String?,
      synopsis: json['synopsis'] as String?,
      coverUrl: json['cover_url'] as String?,
      patientLayer: LibraryPatientLayer.fromJson(
        json['patient_layer'] is Map
            ? Map<String, dynamic>.from(json['patient_layer'] as Map)
            : const {},
      ),
    );
  }
}

/// Camada do paciente: antes / durante / depois de assistir.
class LibraryPatientLayer {
  const LibraryPatientLayer({
    this.before,
    this.during = const [],
    this.after = const [],
    this.whereToWatch,
  });

  final String? before;
  final List<String> during;
  final List<LibraryQuestion> after;
  final String? whereToWatch;

  factory LibraryPatientLayer.fromJson(Map<String, dynamic> json) {
    return LibraryPatientLayer(
      before: json['patient_before'] as String?,
      during: _stringList(json['patient_during']),
      after: (json['patient_after'] as List? ?? [])
          .whereType<Map>()
          .map((e) => LibraryQuestion.fromJson(Map<String, dynamic>.from(e)))
          .toList(),
      whereToWatch: json['where_to_watch'] as String?,
    );
  }
}

class LibraryQuestion {
  const LibraryQuestion({required this.question, this.fieldType});

  final String question;
  final String? fieldType;

  factory LibraryQuestion.fromJson(Map<String, dynamic> json) {
    return LibraryQuestion(
      question: json['question'] as String? ?? '',
      fieldType: json['field_type'] as String?,
    );
  }
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return const [];
}
