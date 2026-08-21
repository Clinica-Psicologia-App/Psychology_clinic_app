/// Hipóteses para Conceitualização (spec §43) — anotações clínicas do
/// terapeuta, por tipo. Inteiramente escritas pelo terapeuta; o app não
/// preenche. Rótulos literais da spec.
library;

enum HypothesisKind {
  emotionalNeed,
  schema,
  mode,
  copingStyle,
  currentProblem,
  clinicalNote,
}

extension HypothesisKindMeta on HypothesisKind {
  String get key => switch (this) {
        HypothesisKind.emotionalNeed => 'emotional_need',
        HypothesisKind.schema => 'schema',
        HypothesisKind.mode => 'mode',
        HypothesisKind.copingStyle => 'coping_style',
        HypothesisKind.currentProblem => 'current_problem',
        HypothesisKind.clinicalNote => 'clinical_note',
      };

  /// Rótulo do botão "+" (spec §43).
  String get addLabel => switch (this) {
        HypothesisKind.emotionalNeed => 'Necessidade emocional',
        HypothesisKind.schema => 'Esquema',
        HypothesisKind.mode => 'Modo',
        HypothesisKind.copingStyle => 'Estilo/Resposta de enfrentamento',
        HypothesisKind.currentProblem => 'Problema atual relacionado',
        HypothesisKind.clinicalNote => 'Observação clínica',
      };

  /// Título da seção/grupo.
  String get groupLabel => switch (this) {
        HypothesisKind.emotionalNeed => 'Necessidades emocionais',
        HypothesisKind.schema => 'Esquemas',
        HypothesisKind.mode => 'Modos',
        HypothesisKind.copingStyle => 'Estilos/Respostas de enfrentamento',
        HypothesisKind.currentProblem => 'Problemas atuais relacionados',
        HypothesisKind.clinicalNote => 'Observações clínicas',
      };
}

const kHypothesisKindsInOrder = HypothesisKind.values;

HypothesisKind? hypothesisKindFromKey(String? key) {
  for (final k in HypothesisKind.values) {
    if (k.key == key) return k;
  }
  return null;
}

/// Uma hipótese registrada.
class ClinicalHypothesis {
  const ClinicalHypothesis({
    required this.id,
    required this.kind,
    required this.body,
  });

  final String id;
  final HypothesisKind kind;
  final String body;

  factory ClinicalHypothesis.fromJson(Map<String, dynamic> json) {
    return ClinicalHypothesis(
      id: json['id'] as String,
      kind: hypothesisKindFromKey(json['kind'] as String?) ??
          HypothesisKind.clinicalNote,
      body: (json['body'] as String?) ?? '',
    );
  }
}
