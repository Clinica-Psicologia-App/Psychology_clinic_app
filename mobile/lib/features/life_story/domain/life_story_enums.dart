/// Enums do fluxo "Minha História / Linha do Tempo" (etapa Conhecer, Tela 2).
///
/// Todos os rótulos e opções vêm literalmente do documento da cliente
/// ("ESQUEMACORE tela 2 e 3"). Não alterar textos sem confirmação clínica.
library;

/// Etapa 1 (spec §4) — "Em qual período da sua vida você gostaria de começar?"
enum LifeChapter {
  earlyYears,
  childhood,
  adolescence,
  adulthood,
  today,
  cannotLocate,
}

extension LifeChapterMeta on LifeChapter {
  /// Chave persistida em `patient_timeline_events.life_chapter`.
  String get key => switch (this) {
        LifeChapter.earlyYears => 'early_years',
        LifeChapter.childhood => 'childhood',
        LifeChapter.adolescence => 'adolescence',
        LifeChapter.adulthood => 'adulthood',
        LifeChapter.today => 'today',
        LifeChapter.cannotLocate => 'cannot_locate',
      };

  /// Texto exibido ao paciente (spec §4).
  String get label => switch (this) {
        LifeChapter.earlyYears => 'Primeiros anos',
        LifeChapter.childhood => 'Infância',
        LifeChapter.adolescence => 'Adolescência',
        LifeChapter.adulthood => 'Vida adulta',
        LifeChapter.today => 'Momento atual',
        LifeChapter.cannotLocate => 'Não consigo localizar exatamente',
      };
}

/// Ordem canônica dos períodos, conforme a spec.
const List<LifeChapter> kLifeChaptersInOrder = LifeChapter.values;

LifeChapter? lifeChapterFromKey(String? key) {
  if (key == null) return null;
  for (final c in LifeChapter.values) {
    if (c.key == key) return c;
  }
  return null;
}

/// Precisão da idade informada (spec §4 — "Não lembro exatamente").
enum AgePrecision { exact, approximate }

extension AgePrecisionMeta on AgePrecision {
  String get key => switch (this) {
        AgePrecision.exact => 'exact',
        AgePrecision.approximate => 'approximate',
      };
}

AgePrecision? agePrecisionFromKey(String? key) => switch (key) {
      'exact' => AgePrecision.exact,
      'approximate' => AgePrecision.approximate,
      _ => null,
    };

/// Etapa 6 (spec §9) — "Quando isso aconteceu, como você se sentiu?"
/// "Selecione até três."
enum TimelineEmotion {
  sad,
  afraid,
  angry,
  alone,
  ashamed,
  guilty,
  confused,
  relieved,
  happy,
  loved,
  proud,
  safe,
}

extension TimelineEmotionMeta on TimelineEmotion {
  String get key => switch (this) {
        TimelineEmotion.sad => 'sad',
        TimelineEmotion.afraid => 'afraid',
        TimelineEmotion.angry => 'angry',
        TimelineEmotion.alone => 'alone',
        TimelineEmotion.ashamed => 'ashamed',
        TimelineEmotion.guilty => 'guilty',
        TimelineEmotion.confused => 'confused',
        TimelineEmotion.relieved => 'relieved',
        TimelineEmotion.happy => 'happy',
        TimelineEmotion.loved => 'loved',
        TimelineEmotion.proud => 'proud',
        TimelineEmotion.safe => 'safe',
      };

  /// Texto exibido ao paciente (spec §9).
  String get label => switch (this) {
        TimelineEmotion.sad => 'Triste',
        TimelineEmotion.afraid => 'Com medo',
        TimelineEmotion.angry => 'Com raiva',
        TimelineEmotion.alone => 'Sozinho(a)',
        TimelineEmotion.ashamed => 'Envergonhado(a)',
        TimelineEmotion.guilty => 'Culpado(a)',
        TimelineEmotion.confused => 'Confuso(a)',
        TimelineEmotion.relieved => 'Aliviado(a)',
        TimelineEmotion.happy => 'Feliz',
        TimelineEmotion.loved => 'Amado(a)',
        TimelineEmotion.proud => 'Orgulhoso(a)',
        TimelineEmotion.safe => 'Seguro(a)',
      };

  String get emoji => switch (this) {
        TimelineEmotion.sad => '😢',
        TimelineEmotion.afraid => '😨',
        TimelineEmotion.angry => '😠',
        TimelineEmotion.alone => '🥺',
        TimelineEmotion.ashamed => '😳',
        TimelineEmotion.guilty => '😔',
        TimelineEmotion.confused => '😕',
        TimelineEmotion.relieved => '😮',
        TimelineEmotion.happy => '😄',
        TimelineEmotion.loved => '🥰',
        TimelineEmotion.proud => '😊',
        TimelineEmotion.safe => '🤗',
      };
}

const List<TimelineEmotion> kTimelineEmotionsInOrder = TimelineEmotion.values;

TimelineEmotion? timelineEmotionFromKey(String? key) {
  if (key == null) return null;
  for (final e in TimelineEmotion.values) {
    if (e.key == key) return e;
  }
  return null;
}

/// Parentesco / relação de uma pessoa (spec §20 — lista de 18).
/// Compartilhado entre a Linha do Tempo (ao adicionar quem participou) e o
/// Genograma. Guardado em `genogram_people.relationship_to_patient`.
enum RelationshipRole {
  mother,
  father,
  stepmother,
  stepfather,
  sister,
  brother,
  grandmother,
  grandfather,
  aunt,
  uncle,
  cousinF,
  cousinM,
  daughter,
  son,
  partner,
  exPartner,
  caregiver,
  other,
}

extension RelationshipRoleMeta on RelationshipRole {
  String get key => switch (this) {
        RelationshipRole.mother => 'mother',
        RelationshipRole.father => 'father',
        RelationshipRole.stepmother => 'stepmother',
        RelationshipRole.stepfather => 'stepfather',
        RelationshipRole.sister => 'sister',
        RelationshipRole.brother => 'brother',
        RelationshipRole.grandmother => 'grandmother',
        RelationshipRole.grandfather => 'grandfather',
        RelationshipRole.aunt => 'aunt',
        RelationshipRole.uncle => 'uncle',
        RelationshipRole.cousinF => 'cousin_f',
        RelationshipRole.cousinM => 'cousin_m',
        RelationshipRole.daughter => 'daughter',
        RelationshipRole.son => 'son',
        RelationshipRole.partner => 'partner',
        RelationshipRole.exPartner => 'ex_partner',
        RelationshipRole.caregiver => 'caregiver',
        RelationshipRole.other => 'other',
      };

  /// Texto exibido ao paciente (spec §20).
  String get label => switch (this) {
        RelationshipRole.mother => 'Mãe',
        RelationshipRole.father => 'Pai',
        RelationshipRole.stepmother => 'Madrasta',
        RelationshipRole.stepfather => 'Padrasto',
        RelationshipRole.sister => 'Irmã',
        RelationshipRole.brother => 'Irmão',
        RelationshipRole.grandmother => 'Avó',
        RelationshipRole.grandfather => 'Avô',
        RelationshipRole.aunt => 'Tia',
        RelationshipRole.uncle => 'Tio',
        RelationshipRole.cousinF => 'Prima',
        RelationshipRole.cousinM => 'Primo',
        RelationshipRole.daughter => 'Filha',
        RelationshipRole.son => 'Filho',
        RelationshipRole.partner => 'Companheiro(a)',
        RelationshipRole.exPartner => 'Ex-companheiro(a)',
        RelationshipRole.caregiver => 'Cuidador(a)',
        RelationshipRole.other => 'Outra relação',
      };
}

const List<RelationshipRole> kRelationshipRolesInOrder = RelationshipRole.values;

RelationshipRole? relationshipRoleFromKey(String? key) {
  if (key == null) return null;
  for (final r in RelationshipRole.values) {
    if (r.key == key) return r;
  }
  return null;
}
