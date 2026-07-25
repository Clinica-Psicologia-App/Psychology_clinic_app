/// Catálogo das 12 áreas de vida (Roda da Vida) do Bloco 3 — "Como está sua
/// vida hoje?". Cada área tem a linguagem acolhedora do paciente e o
/// agrupamento clínico (Young) usado na visão do terapeuta.
///
/// As `key` batem com o CHECK de `patient_life_areas.area_key` no banco.
enum LifeArea {
  workCareer,
  financesMoney,
  healthFitness,
  family,
  friends,
  loveRomance,
  personalGrowth,
  recreationFun,
  physicalEnvironment,
  contributionSocial,
  spirituality,
  mentalEmotionalHealth,
}

/// Agrupamentos clínicos de "Funcionamento Atual" (visão do terapeuta).
/// O mapeamento 12→9 é uma leitura de domínio (o documento não fixa um de/para
/// exato); serve apenas para agrupar visualmente. Os dados brutos continuam
/// nas 12 áreas do paciente.
enum FunctioningGroup {
  occupationalEducational,
  intimateRelationship,
  family,
  social,
  solitary,
  lifestyleSelfCare,
  physicalEmotionalHealth,
  practicalFinancialAutonomy,
  valuesPurposeSpirituality,
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
        FunctioningGroup.lifestyleSelfCare => 'Estilo de vida e autocuidado',
        FunctioningGroup.physicalEmotionalHealth => 'Saúde física e emocional',
        FunctioningGroup.practicalFinancialAutonomy =>
          'Autonomia prática e financeira',
        FunctioningGroup.valuesPurposeSpirituality =>
          'Valores, propósito, espiritualidade e contribuição social',
      };
}

extension LifeAreaMeta on LifeArea {
  /// Chave persistida (`patient_life_areas.area_key`).
  String get key => switch (this) {
        LifeArea.workCareer => 'work_career',
        LifeArea.financesMoney => 'finances_money',
        LifeArea.healthFitness => 'health_fitness',
        LifeArea.family => 'family',
        LifeArea.friends => 'friends',
        LifeArea.loveRomance => 'love_romance',
        LifeArea.personalGrowth => 'personal_growth',
        LifeArea.recreationFun => 'recreation_fun',
        LifeArea.physicalEnvironment => 'physical_environment',
        LifeArea.contributionSocial => 'contribution_social',
        LifeArea.spirituality => 'spirituality',
        LifeArea.mentalEmotionalHealth => 'mental_emotional_health',
      };

  /// Nome da área na linguagem do paciente.
  String get label => switch (this) {
        LifeArea.workCareer => 'Trabalho e Carreira',
        LifeArea.financesMoney => 'Finanças & Dinheiro',
        LifeArea.healthFitness => 'Saúde & Fitness',
        LifeArea.family => 'Família',
        LifeArea.friends => 'Amigos',
        LifeArea.loveRomance => 'Amor e Romance',
        LifeArea.personalGrowth => 'Crescimento Pessoal',
        LifeArea.recreationFun => 'Recreação & Diversão',
        LifeArea.physicalEnvironment => 'Ambiente Físico',
        LifeArea.contributionSocial => 'Contribuição & Impacto Social',
        LifeArea.spirituality => 'Espiritualidade',
        LifeArea.mentalEmotionalHealth => 'Saúde Mental & Emocional',
      };

  /// Descrição curta mostrada ao paciente no cartão.
  String get description => switch (this) {
        LifeArea.workCareer =>
          'Satisfação no trabalho e crescimento profissional.',
        LifeArea.financesMoney =>
          'Segurança financeira e gestão do dinheiro.',
        LifeArea.healthFitness =>
          'Saúde física e nível de condicionamento.',
        LifeArea.family => 'Relacionamentos com membros da família.',
        LifeArea.friends => 'Relacionamentos de amizade e parcerias.',
        LifeArea.loveRomance => 'Relacionamentos românticos e intimidade.',
        LifeArea.personalGrowth => 'Aprendizado e desenvolvimento pessoal.',
        LifeArea.recreationFun => 'Hobbies e atividades de lazer.',
        LifeArea.physicalEnvironment =>
          'Satisfação com o espaço físico da casa e outros ambientes que frequenta.',
        LifeArea.contributionSocial => 'Retribuir e fazer a diferença.',
        LifeArea.spirituality => 'Práticas espirituais e crenças.',
        LifeArea.mentalEmotionalHealth =>
          'Bem-estar emocional e saúde mental.',
      };

  /// Pergunta guiada opcional exibida após a nota.
  String get guidedQuestion => switch (this) {
        LifeArea.workCareer => 'O maior desafio hoje é...',
        LifeArea.financesMoney => 'O que mais influencia essa nota?',
        LifeArea.healthFitness => 'O que você gostaria de cuidar melhor?',
        LifeArea.family => 'O que costuma ser mais difícil?',
        LifeArea.friends => 'Como você se sente nessas relações?',
        LifeArea.loveRomance => 'O que mais acontece nessa área?',
        LifeArea.personalGrowth => 'Em que gostaria de avançar?',
        LifeArea.recreationFun => 'Quanto espaço isso ocupa na sua rotina?',
        LifeArea.physicalEnvironment =>
          'O que tornaria esses espaços melhores para você?',
        LifeArea.contributionSocial => 'Como gostaria de contribuir?',
        LifeArea.spirituality => 'Que lugar isso ocupa na sua vida?',
        LifeArea.mentalEmotionalHealth =>
          'O que mais tem afetado seu bem-estar?',
      };

  /// Agrupamento clínico (visão do terapeuta). Mapeamento de domínio.
  FunctioningGroup get group => switch (this) {
        LifeArea.workCareer => FunctioningGroup.occupationalEducational,
        LifeArea.loveRomance => FunctioningGroup.intimateRelationship,
        LifeArea.family => FunctioningGroup.family,
        LifeArea.friends => FunctioningGroup.social,
        LifeArea.recreationFun => FunctioningGroup.solitary,
        LifeArea.physicalEnvironment => FunctioningGroup.lifestyleSelfCare,
        LifeArea.healthFitness => FunctioningGroup.physicalEmotionalHealth,
        LifeArea.mentalEmotionalHealth =>
          FunctioningGroup.physicalEmotionalHealth,
        LifeArea.financesMoney =>
          FunctioningGroup.practicalFinancialAutonomy,
        LifeArea.personalGrowth =>
          FunctioningGroup.practicalFinancialAutonomy,
        LifeArea.contributionSocial =>
          FunctioningGroup.valuesPurposeSpirituality,
        LifeArea.spirituality => FunctioningGroup.valuesPurposeSpirituality,
      };
}

/// Ordem canônica das 12 áreas (mesma da Roda da Vida no documento).
const List<LifeArea> kLifeAreasInOrder = LifeArea.values;

/// Resolve uma [LifeArea] a partir da `key` persistida; null se desconhecida.
LifeArea? lifeAreaFromKey(String? key) {
  if (key == null) return null;
  for (final area in LifeArea.values) {
    if (area.key == key) return area;
  }
  return null;
}
