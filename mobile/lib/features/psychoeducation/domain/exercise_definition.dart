/// Field types used in psychoeducation exercises.
enum ExerciseFieldType { text, multicheck, singlecheck }

/// A single input field inside an exercise step.
class ExerciseField {
  const ExerciseField({
    required this.key,
    required this.type,
    required this.prompt,
    this.options = const [],
    this.hint,
    this.allowOther = false,
    this.prefix,
  });

  final String key;
  final ExerciseFieldType type;
  final String prompt;

  /// Options for [multicheck] and [singlecheck] fields.
  final List<String> options;

  /// Placeholder text for [text] fields.
  final String? hint;

  /// Whether to show an "Outro:" free-text field after the checkboxes.
  final bool allowOther;

  /// Sentence prefix shown before the text input (e.g. "Eu pensei que...").
  final String? prefix;
}

class ExerciseStep {
  const ExerciseStep({
    required this.title,
    this.subtitle,
    required this.fields,
  });

  final String title;
  final String? subtitle;
  final List<ExerciseField> fields;
}

class ExerciseDefinition {
  const ExerciseDefinition({
    required this.moduleNumber,
    required this.title,
    this.intro,
    required this.steps,
  });

  final int moduleNumber;
  final String title;
  final String? intro;
  final List<ExerciseStep> steps;

  static const List<String> closingScaleOptions = [
    'Fácil e esclarecedor',
    'Interessante, mas desafiador',
    'Neutro',
    'Difícil',
    'Muito difícil',
  ];

  static const List<String> closingScaleEmojis = ['😊', '🙂', '😐', '😟', '😔'];
}

/// Saved response for one exercise session.
class ExerciseResponse {
  const ExerciseResponse({
    required this.id,
    required this.patientId,
    required this.moduleId,
    required this.responses,
    this.difficultyScale,
    this.wantsToTalk,
    required this.updatedAt,
  });

  final String id;
  final String patientId;
  final String moduleId;
  final Map<String, dynamic> responses;
  final String? difficultyScale;
  final bool? wantsToTalk;
  final DateTime updatedAt;

  factory ExerciseResponse.fromJson(Map<String, dynamic> json) {
    final raw = json['responses'];
    return ExerciseResponse(
      id: json['id'] as String,
      patientId: json['patient_id'] as String,
      moduleId: json['module_id'] as String,
      responses: raw is Map ? Map<String, dynamic>.from(raw) : {},
      difficultyScale: json['difficulty_scale'] as String?,
      wantsToTalk: json['wants_to_talk'] as bool?,
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
}
