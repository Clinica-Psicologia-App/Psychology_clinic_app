import 'questionnaire.dart';

List<Questionnaire> visibleQuestionnairesFromEnabledIds(
  List<Questionnaire> catalog, {
  required Set<String>? enabledIds,
  required bool fallbackToAllWhenUnavailable,
}) {
  if (enabledIds == null) {
    return fallbackToAllWhenUnavailable ? catalog : const [];
  }

  return catalog
      .where((questionnaire) => enabledIds.contains(questionnaire.id))
      .toList();
}
