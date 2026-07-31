import 'question_answer_type.dart';

class QuestionnaireCatalogAdminItem {
  const QuestionnaireCatalogAdminItem({
    required this.id,
    required this.code,
    required this.name,
    required this.isActive,
    required this.clinicalStatus,
    required this.questionCount,
    required this.responseCount,
    this.version,
    this.versionStatus,
  });

  final String id;
  final String code;
  final String name;
  final bool isActive;
  final String clinicalStatus;
  final int questionCount;
  final int responseCount;
  final String? version;
  final String? versionStatus;

  bool get isEditable =>
      !isActive &&
      (clinicalStatus == 'draft' || clinicalStatus == 'validation');

  factory QuestionnaireCatalogAdminItem.fromJson(Map<String, dynamic> json) {
    return QuestionnaireCatalogAdminItem(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      isActive: json['is_active'] as bool? ?? false,
      clinicalStatus: json['clinical_status'] as String? ?? 'draft',
      questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
      responseCount: (json['response_count'] as num?)?.toInt() ?? 0,
      version: json['version'] as String?,
      versionStatus: json['version_status'] as String?,
    );
  }
}

class QuestionnaireCatalogDetail {
  const QuestionnaireCatalogDetail({
    required this.questionnaire,
    required this.version,
    required this.questions,
    this.hasDraftVersion = false,
    this.activeVersionLabel,
  });

  final Map<String, dynamic> questionnaire;
  final Map<String, dynamic> version;
  final List<QuestionnaireCatalogQuestion> questions;

  /// A versão retornada é um rascunho editável.
  final bool hasDraftVersion;

  /// Rótulo da versão ativa em uso pelos pacientes (se houver).
  final String? activeVersionLabel;

  bool get isPublished => questionnaire['is_active'] == true;

  /// Editável quando a versão exibida é um rascunho (instrumento novo ou
  /// nova versão de um publicado). Mantém o critério legado como fallback
  /// para payloads sem os campos de versão.
  bool get isEditable =>
      hasDraftVersion ||
      version['status'] == 'draft' ||
      (!isPublished &&
          const {'draft', 'validation'}
              .contains(questionnaire['clinical_status']));

  /// Publicado sem rascunho: oferecer "Editar — criar nova versão".
  bool get canCreateDraftVersion => isPublished && !isEditable;

  String? get versionLabel => version['version'] as String?;

  factory QuestionnaireCatalogDetail.fromJson(Map<String, dynamic> json) {
    return QuestionnaireCatalogDetail(
      questionnaire: Map<String, dynamic>.from(json['questionnaire'] as Map),
      version: json['version'] == null
          ? <String, dynamic>{}
          : Map<String, dynamic>.from(json['version'] as Map),
      hasDraftVersion: json['has_draft_version'] as bool? ?? false,
      activeVersionLabel: json['active_version'] as String?,
      questions: (json['questions'] as List? ?? const [])
          .map((item) => QuestionnaireCatalogQuestion.fromJson(
              Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }
}

class QuestionnaireCatalogQuestion {
  const QuestionnaireCatalogQuestion({
    required this.id,
    required this.code,
    required this.text,
    required this.orderIndex,
    required this.answerType,
    required this.scaleMin,
    required this.scaleMax,
    required this.weight,
    required this.reverseScore,
  });

  final String id;
  final String code;
  final String text;
  final int orderIndex;
  final QuestionAnswerType answerType;
  final int scaleMin;
  final int scaleMax;
  final double weight;
  final bool reverseScore;

  factory QuestionnaireCatalogQuestion.fromJson(Map<String, dynamic> json) {
    return QuestionnaireCatalogQuestion(
      id: json['id'] as String,
      code: json['code'] as String,
      text: json['text'] as String,
      orderIndex: (json['order_index'] as num?)?.toInt() ?? 0,
      answerType: QuestionAnswerType.fromString(
          json['answer_type'] as String? ?? 'likert_scale'),
      scaleMin: (json['scale_min'] as num?)?.toInt() ?? 1,
      scaleMax: (json['scale_max'] as num?)?.toInt() ?? 5,
      weight: (json['weight'] as num?)?.toDouble() ?? 1,
      reverseScore: json['reverse_score'] as bool? ?? false,
    );
  }
}

class QuestionnaireDraftInput {
  const QuestionnaireDraftInput({
    this.id,
    required this.code,
    required this.name,
    required this.version,
    required this.scaleMin,
    required this.scaleMax,
    required this.referencePeriod,
    this.description,
    this.authorName,
    this.citation,
    this.licenseNotes,
  });

  final String? id;
  final String code;
  final String name;
  final String version;
  final int scaleMin;
  final int scaleMax;
  final String referencePeriod;
  final String? description;
  final String? authorName;
  final String? citation;
  final String? licenseNotes;
}
