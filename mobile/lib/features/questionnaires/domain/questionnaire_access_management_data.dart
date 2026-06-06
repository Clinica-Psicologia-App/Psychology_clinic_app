import 'questionnaire_access_item.dart';

class QuestionnaireAccessManagementData {
  const QuestionnaireAccessManagementData({
    required this.items,
    required this.supportsAccessControl,
  });

  final List<QuestionnaireAccessItem> items;
  final bool supportsAccessControl;
}
