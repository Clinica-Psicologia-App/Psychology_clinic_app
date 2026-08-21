/// Enums das etapas "Aprofundar este momento" (Linha do Tempo, Tela 2).
/// Rótulos literais do documento da cliente. Não alterar sem confirmação.
library;

/// Etapa 3 (§6) — "Isso aconteceu..."
enum EventRecurrence { once, fewTimes, frequent, prolonged, unknown }

extension EventRecurrenceMeta on EventRecurrence {
  String get key => switch (this) {
        EventRecurrence.once => 'once',
        EventRecurrence.fewTimes => 'few_times',
        EventRecurrence.frequent => 'frequent',
        EventRecurrence.prolonged => 'prolonged',
        EventRecurrence.unknown => 'unknown',
      };
  String get label => switch (this) {
        EventRecurrence.once => 'Uma vez',
        EventRecurrence.fewTimes => 'Algumas vezes',
        EventRecurrence.frequent => 'Acontecia com frequência',
        EventRecurrence.prolonged => 'Foi uma situação que durou um período',
        EventRecurrence.unknown => 'Não sei',
      };
}

const kEventRecurrenceInOrder = EventRecurrence.values;

EventRecurrence? eventRecurrenceFromKey(String? key) {
  for (final v in EventRecurrence.values) {
    if (v.key == key) return v;
  }
  return null;
}

/// Etapa 4 (§7) — "Esse acontecimento estava relacionado a..." (até 2).
enum LifeCategory {
  family,
  school,
  friendships,
  romantic,
  work,
  health,
  lifeChange,
  loss,
  arrival,
  achievement,
  difficult,
  happy,
  other,
}

extension LifeCategoryMeta on LifeCategory {
  String get key => switch (this) {
        LifeCategory.family => 'family',
        LifeCategory.school => 'school',
        LifeCategory.friendships => 'friendships',
        LifeCategory.romantic => 'romantic',
        LifeCategory.work => 'work',
        LifeCategory.health => 'health',
        LifeCategory.lifeChange => 'life_change',
        LifeCategory.loss => 'loss',
        LifeCategory.arrival => 'arrival',
        LifeCategory.achievement => 'achievement',
        LifeCategory.difficult => 'difficult',
        LifeCategory.happy => 'happy',
        LifeCategory.other => 'other',
      };
  String get label => switch (this) {
        LifeCategory.family => 'Família',
        LifeCategory.school => 'Escola/estudos',
        LifeCategory.friendships => 'Amizades',
        LifeCategory.romantic => 'Relacionamentos amorosos',
        LifeCategory.work => 'Trabalho',
        LifeCategory.health => 'Saúde',
        LifeCategory.lifeChange => 'Mudança de vida',
        LifeCategory.loss => 'Perda/luto',
        LifeCategory.arrival => 'Nascimento ou chegada de alguém',
        LifeCategory.achievement => 'Conquista',
        LifeCategory.difficult => 'Experiência difícil',
        LifeCategory.happy => 'Experiência feliz',
        LifeCategory.other => 'Outro',
      };
}

const kLifeCategoriesInOrder = LifeCategory.values;

LifeCategory? lifeCategoryFromKey(String? key) {
  for (final v in LifeCategory.values) {
    if (v.key == key) return v;
  }
  return null;
}

/// Etapa 7 (§10) — "Naquele momento, do que você mais precisava?"
enum EmotionalNeed {
  presence,
  safety,
  affection,
  understanding,
  acceptance,
  expression,
  autonomy,
  encouragement,
  limits,
  play,
  dontKnow,
  other,
}

extension EmotionalNeedMeta on EmotionalNeed {
  String get key => switch (this) {
        EmotionalNeed.presence => 'presence',
        EmotionalNeed.safety => 'safety',
        EmotionalNeed.affection => 'affection',
        EmotionalNeed.understanding => 'understanding',
        EmotionalNeed.acceptance => 'acceptance',
        EmotionalNeed.expression => 'expression',
        EmotionalNeed.autonomy => 'autonomy',
        EmotionalNeed.encouragement => 'encouragement',
        EmotionalNeed.limits => 'limits',
        EmotionalNeed.play => 'play',
        EmotionalNeed.dontKnow => 'dont_know',
        EmotionalNeed.other => 'other',
      };
  String get label => switch (this) {
        EmotionalNeed.presence => 'Sentir que alguém estaria comigo',
        EmotionalNeed.safety => 'Sentir-me seguro(a) e protegido(a)',
        EmotionalNeed.affection => 'Receber carinho e atenção',
        EmotionalNeed.understanding => 'Ser ouvido(a) e compreendido(a)',
        EmotionalNeed.acceptance => 'Ser aceito(a) como eu era',
        EmotionalNeed.expression => 'Poder falar sobre o que sentia',
        EmotionalNeed.autonomy =>
          'Ter liberdade para fazer minhas próprias escolhas',
        EmotionalNeed.encouragement => 'Receber incentivo e confiança',
        EmotionalNeed.limits => 'Ter limites e orientação',
        EmotionalNeed.play => 'Poder brincar, descansar ou me divertir',
        EmotionalNeed.dontKnow => 'Não sei',
        EmotionalNeed.other => 'Outro',
      };
}

const kEmotionalNeedsInOrder = EmotionalNeed.values;

EmotionalNeed? emotionalNeedFromKey(String? key) {
  for (final v in EmotionalNeed.values) {
    if (v.key == key) return v;
  }
  return null;
}

/// Etapa 7 (§10) — "Você recebeu isso naquela época?"
enum NeedWasMet { yes, partly, no, dontKnow }

extension NeedWasMetMeta on NeedWasMet {
  String get key => switch (this) {
        NeedWasMet.yes => 'yes',
        NeedWasMet.partly => 'partly',
        NeedWasMet.no => 'no',
        NeedWasMet.dontKnow => 'dont_know',
      };
  String get label => switch (this) {
        NeedWasMet.yes => 'Sim',
        NeedWasMet.partly => 'Em parte',
        NeedWasMet.no => 'Não',
        NeedWasMet.dontKnow => 'Não sei',
      };
}

const kNeedWasMetInOrder = NeedWasMet.values;

NeedWasMet? needWasMetFromKey(String? key) {
  for (final v in NeedWasMet.values) {
    if (v.key == key) return v;
  }
  return null;
}

/// Etapa 9 (§12) — "Você sente que essa experiência ainda influencia...?"
enum StillInfluences { yes, maybe, no, dontKnow }

extension StillInfluencesMeta on StillInfluences {
  String get key => switch (this) {
        StillInfluences.yes => 'yes',
        StillInfluences.maybe => 'maybe',
        StillInfluences.no => 'no',
        StillInfluences.dontKnow => 'dont_know',
      };
  String get label => switch (this) {
        StillInfluences.yes => 'Sim',
        StillInfluences.maybe => 'Talvez',
        StillInfluences.no => 'Não',
        StillInfluences.dontKnow => 'Não sei',
      };
}

const kStillInfluencesInOrder = StillInfluences.values;

StillInfluences? stillInfluencesFromKey(String? key) {
  for (final v in StillInfluences.values) {
    if (v.key == key) return v;
  }
  return null;
}

/// Etapa 9 (§12) — "Se Sim/Talvez: em quais áreas hoje?"
enum PresentArea {
  selfView,
  relationships,
  family,
  emotions,
  work,
  choices,
  coping,
  other,
}

extension PresentAreaMeta on PresentArea {
  String get key => switch (this) {
        PresentArea.selfView => 'self_view',
        PresentArea.relationships => 'relationships',
        PresentArea.family => 'family',
        PresentArea.emotions => 'emotions',
        PresentArea.work => 'work',
        PresentArea.choices => 'choices',
        PresentArea.coping => 'coping',
        PresentArea.other => 'other',
      };
  String get label => switch (this) {
        PresentArea.selfView => 'Como me vejo',
        PresentArea.relationships => 'Meus relacionamentos',
        PresentArea.family => 'Minha família',
        PresentArea.emotions => 'Minhas emoções',
        PresentArea.work => 'Meu trabalho ou estudos',
        PresentArea.choices => 'Minhas escolhas',
        PresentArea.coping => 'Minha maneira de lidar com dificuldades',
        PresentArea.other => 'Outro',
      };
}

const kPresentAreasInOrder = PresentArea.values;

PresentArea? presentAreaFromKey(String? key) {
  for (final v in PresentArea.values) {
    if (v.key == key) return v;
  }
  return null;
}
