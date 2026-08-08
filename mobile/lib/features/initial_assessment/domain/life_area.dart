/// Catálogo das 9 áreas de vida (Bloco 3 — "Como está sua vida hoje?")
/// conforme especificação do cliente. Cada área tem a linguagem acolhedora
/// do paciente e o agrupamento clínico Young usado na visão do terapeuta.
///
/// As `key` batem com o CHECK de `patient_life_areas.area_key` no banco.
enum LifeArea {
  workCareer,
  loveRomance,
  family,
  friends,
  aloneTime,
  physicalHealth,
  emotionalHealth,
  selfCare,
  routineOrganization,
}

/// Agrupamentos clínicos de "Funcionamento Atual" (visão do terapeuta).
/// Mapeamento 9→6 seguindo os domínios clássicos da Terapia do Esquema.
enum FunctioningGroup {
  occupationalEducational,
  intimateRelationship,
  family,
  social,
  solitary,
  healthSelfCare,
}

extension FunctioningGroupMeta on FunctioningGroup {
  String get label => switch (this) {
        FunctioningGroup.occupationalEducational =>
          'Funcionamento ocupacional / educacional',
        FunctioningGroup.intimateRelationship =>
          'Funcionamento em relacionamento íntimo',
        FunctioningGroup.family => 'Funcionamento familiar',
        FunctioningGroup.social => 'Funcionamento social',
        FunctioningGroup.solitary => 'Funcionamento solitário',
        FunctioningGroup.healthSelfCare => 'Saúde e autocuidado',
      };
}

extension LifeAreaMeta on LifeArea {
  /// Chave persistida (`patient_life_areas.area_key`).
  String get key => switch (this) {
        LifeArea.workCareer => 'work_career',
        LifeArea.loveRomance => 'love_romance',
        LifeArea.family => 'family',
        LifeArea.friends => 'friends',
        LifeArea.aloneTime => 'alone_time',
        LifeArea.physicalHealth => 'physical_health',
        LifeArea.emotionalHealth => 'emotional_health',
        LifeArea.selfCare => 'self_care',
        LifeArea.routineOrganization => 'routine_organization',
      };

  /// Nome da área na linguagem do paciente.
  String get label => switch (this) {
        LifeArea.workCareer => 'Trabalho ou Estudos',
        LifeArea.loveRomance => 'Relacionamento Amoroso',
        LifeArea.family => 'Família',
        LifeArea.friends => 'Amigos',
        LifeArea.aloneTime => 'Tempo para mim',
        LifeArea.physicalHealth => 'Saúde Física',
        LifeArea.emotionalHealth => 'Saúde Emocional',
        LifeArea.selfCare => 'Autocuidado',
        LifeArea.routineOrganization => 'Rotina e Organização',
      };

  /// Descrição curta mostrada ao paciente no cartão.
  String get description => switch (this) {
        LifeArea.workCareer =>
          'Satisfação no trabalho, estudos e crescimento profissional.',
        LifeArea.loveRomance =>
          'Relacionamentos românticos e intimidade emocional.',
        LifeArea.family => 'Relacionamentos com membros da família.',
        LifeArea.friends => 'Amizades e a qualidade dessas conexões.',
        LifeArea.aloneTime =>
          'Espaço para você mesmo(a): descanso, lazer e hobbies.',
        LifeArea.physicalHealth =>
          'Saúde do corpo, hábitos e bem-estar físico.',
        LifeArea.emotionalHealth =>
          'Bem-estar emocional e saúde mental no dia a dia.',
        LifeArea.selfCare =>
          'Como você cuida de si mesmo(a) nas pequenas coisas.',
        LifeArea.routineOrganization =>
          'Organização da rotina, compromissos e ambiente.',
      };

  /// Pergunta guiada exibida após a nota de satisfação.
  String get guidedQuestion => switch (this) {
        LifeArea.workCareer => 'O maior desafio hoje é...',
        LifeArea.loveRomance => 'O que mais acontece nessa área?',
        LifeArea.family => 'O que costuma ser mais difícil?',
        LifeArea.friends => 'Como você se sente nessas relações?',
        LifeArea.aloneTime => 'Que espaço você reserva para si mesmo(a)?',
        LifeArea.physicalHealth => 'O que você gostaria de cuidar melhor?',
        LifeArea.emotionalHealth => 'O que mais tem afetado seu bem-estar?',
        LifeArea.selfCare => 'Em que área do autocuidado gostaria de avançar?',
        LifeArea.routineOrganization =>
          'O que costuma desorganizar sua rotina?',
      };

  /// Agrupamento clínico (visão do terapeuta).
  FunctioningGroup get group => switch (this) {
        LifeArea.workCareer => FunctioningGroup.occupationalEducational,
        LifeArea.loveRomance => FunctioningGroup.intimateRelationship,
        LifeArea.family => FunctioningGroup.family,
        LifeArea.friends => FunctioningGroup.social,
        LifeArea.aloneTime => FunctioningGroup.solitary,
        LifeArea.physicalHealth => FunctioningGroup.healthSelfCare,
        LifeArea.emotionalHealth => FunctioningGroup.healthSelfCare,
        LifeArea.selfCare => FunctioningGroup.healthSelfCare,
        LifeArea.routineOrganization => FunctioningGroup.healthSelfCare,
      };
}

/// Ordem canônica das 9 áreas conforme especificação do cliente.
const List<LifeArea> kLifeAreasInOrder = LifeArea.values;

/// Resolve uma [LifeArea] a partir da `key` persistida; null se desconhecida.
LifeArea? lifeAreaFromKey(String? key) {
  if (key == null) return null;
  for (final area in LifeArea.values) {
    if (area.key == key) return area;
  }
  return null;
}
