import 'reference_period.dart';

class Questionnaire {
  const Questionnaire({
    required this.id,
    required this.code,
    required this.name,
    this.description,
    required this.isActive,
    this.referencePeriod = ReferencePeriod.unspecified,
    this.authorName,
    this.instrumentVersion,
    this.citation,
    this.licenseNotes,
  });

  final String id;
  final String code;
  final String name;
  final String? description;
  final bool isActive;
  final ReferencePeriod referencePeriod;
  final String? authorName;
  final String? instrumentVersion;
  final String? citation;
  final String? licenseNotes;

  bool get isParentalStyles =>
      code.trim().toUpperCase() == 'PARENTAL_STYLES_V1';

  bool get isAttachmentStyles =>
      code.trim().toUpperCase() == 'ATTACHMENT_STYLES_V1';

  String? get patientSpecificGuidance {
    if (isParentalStyles) {
      return 'Antes de começar, selecione as figuras parentais relevantes. '
          'O app repetirá o mesmo conjunto de perguntas para cada uma delas.';
    }
    if (isAttachmentStyles) {
      return 'Marque "Sim" apenas quando a afirmação for verdadeira para você. '
          'Se não combinar com o seu jeito de se relacionar, marque "Não".';
    }
    return null;
  }

  bool get hasLicensePendingValidation {
    final normalized = licenseNotes?.trim().toLowerCase();
    if (normalized == null || normalized.isEmpty) return false;
    return normalized.contains('pendente valida');
  }

  factory Questionnaire.fromJson(Map<String, dynamic> json) {
    return Questionnaire(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      referencePeriod: referencePeriodFromQuestionnaireJson(json),
      authorName: json['author_name'] as String?,
      instrumentVersion: json['instrument_version'] as String?,
      citation: json['citation'] as String?,
      licenseNotes: json['license_notes'] as String?,
    );
  }
}
