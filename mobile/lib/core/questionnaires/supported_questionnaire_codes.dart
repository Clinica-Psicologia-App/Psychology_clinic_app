const supportedQuestionnaireCodes = <String>{
  'YSQ_FOUNDATION_V1',
  'YAMI_MODES_FOUNDATION_V1',
  'PARENTAL_STYLES_V1',
  'ATTACHMENT_STYLES_V1',
  'YCI_FOUNDATION_V1',
  'YRAI_FOUNDATION_V1',
};

bool isSupportedQuestionnaireCode(String? code) {
  final normalized = code?.trim().toUpperCase();
  if (normalized == null || normalized.isEmpty) return false;
  return supportedQuestionnaireCodes.contains(normalized);
}
