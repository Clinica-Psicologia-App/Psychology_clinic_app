import 'questionnaire_response_context.dart';

class CaregiverInput {
  const CaregiverInput({
    required this.enabled,
    this.role,
    this.otherText1,
    this.otherText2,
  });

  final bool enabled;

  /// One of: 'mae', 'pai', 'tia', 'avo', 'avoo', 'outro'
  final String? role;
  final String? otherText1;
  final String? otherText2;

  static const _roleLabels = <String, String>{
    'mae': 'Mãe',
    'pai': 'Pai',
    'tia': 'Tia',
    'avo': 'Avó',
    'avoo': 'Avô',
  };

  String? get label {
    if (!enabled || role == null) return null;
    if (role == 'outro') {
      final parts = [
        otherText1?.trim(),
        otherText2?.trim(),
      ].where((s) => s != null && s.isNotEmpty).join(' — ');
      return parts.isNotEmpty ? parts : null;
    }
    return _roleLabels[role];
  }
}

/// Maps a caregiver role to the backend context key.
/// 'mae' → 'mother', 'pai' → 'father', everything else → 'other'.
String _backendKey(String role) {
  if (role == 'mae') return 'mother';
  if (role == 'pai') return 'father';
  return 'other';
}

List<QuestionnaireContextInput> buildParentalContextInputs({
  required List<CaregiverInput> caregivers,
}) {
  final contexts = <QuestionnaireContextInput>[];
  for (final c in caregivers) {
    if (!c.enabled) continue;
    final lbl = c.label;
    if (lbl == null || c.role == null) continue;
    contexts.add(QuestionnaireContextInput(
      key: _backendKey(c.role!),
      label: lbl,
    ));
  }
  return contexts;
}

String? validateParentalContextSelection({
  required List<CaregiverInput> caregivers,
}) {
  final enabled = caregivers.indexed.where((e) => e.$2.enabled).toList();

  if (enabled.isEmpty) {
    return 'Selecione pelo menos um cuidador.';
  }

  for (final (i, c) in enabled) {
    if (c.role == null) {
      return 'Selecione o tipo do Cuidador(a) ${i + 1}.';
    }
    if (c.role == 'outro') {
      final t1 = c.otherText1?.trim() ?? '';
      final t2 = c.otherText2?.trim() ?? '';
      if (t1.isEmpty && t2.isEmpty) {
        return 'Preencha ao menos um campo para o Cuidador(a) ${i + 1}.';
      }
    }
  }

  // Backend não permite chave 'mother' ou 'father' duplicada.
  final roles = enabled.map((e) => e.$2.role).toList();
  if (roles.where((r) => r == 'mae').length > 1) {
    return 'Mãe só pode ser selecionada em um cuidador.';
  }
  if (roles.where((r) => r == 'pai').length > 1) {
    return 'Pai só pode ser selecionado em um cuidador.';
  }

  return null;
}

String normalizeParentalQuestionText(String text) {
  final idx = text.indexOf(':');
  if (idx <= 0) return text.trim();
  return text.substring(idx + 1).trim();
}

double progressForContext({
  required String contextId,
  required Map<String, int> answers,
  required int totalQuestions,
}) {
  if (totalQuestions <= 0) return 0;
  final answered =
      answers.keys.where((key) => key.startsWith('$contextId::')).length;
  return answered / totalQuestions;
}
