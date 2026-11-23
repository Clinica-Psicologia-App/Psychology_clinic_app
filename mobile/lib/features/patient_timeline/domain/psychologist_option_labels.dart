import '../../life_story/domain/life_story_deepen_enums.dart';

/// Opções (chave → texto) do formulário da psicóloga para necessidades
/// emocionais e áreas do presente. Fonte única: o formulário e as telas que
/// exibem o evento usam estes mesmos textos, para nenhuma chave aparecer crua.
const kPsychologistEmotionalNeedOptions = <(String, String)>[
  ('connection_acceptance', 'Conexão e Aceitação'),
  ('autonomy_competence_identity', 'Autonomia, competência e identidade'),
  ('limits_self_control', 'Limites e autocontrole'),
  ('expression_freedom', 'Liberdade de Expressão'),
  ('recognition_value', 'Valorização e reconhecimento'),
  ('spontaneity_leisure', 'Espontaneidade e Lazer'),
  ('other', 'Outra'),
];

const kPsychologistPresentAreaOptions = <(String, String)>[
  ('relationships', 'Relações'),
  ('self_esteem', 'Autoestima'),
  ('work', 'Trabalho'),
  ('emotions', 'Emoções'),
  ('decisions', 'Decisões'),
  ('body', 'Corpo'),
];

/// Rótulos para exibir o evento na tela da psicóloga: toda chave do formulário
/// dela mostra o texto do formulário dela; só chave exclusiva da paciente usa o
/// rótulo da paciente.
final Map<String, String> kEmotionalNeedLabels = {
  for (final need in EmotionalNeed.values) need.key: need.label,
  for (final o in kPsychologistEmotionalNeedOptions) o.$1: o.$2,
};

final Map<String, String> kPresentAreaLabels = {
  for (final area in PresentArea.values) area.key: area.label,
  for (final o in kPsychologistPresentAreaOptions) o.$1: o.$2,
};
