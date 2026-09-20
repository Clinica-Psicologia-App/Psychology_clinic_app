/// Campos da Conceitualização de caso preenchidos pelo terapeuta (módulo
/// Síntese) — persistidos em `case_conceptualizations`. As demais seções da
/// síntese vêm da agregação do Mapa mental e não moram aqui.
library;

/// Uma das 9 necessidades essenciais (seção 7.2), na ordem do formulário.
class CoreNeed {
  const CoreNeed(this.key, this.label);
  final String key;
  final String label;
}

/// Chaves fixas das 9 necessidades essenciais (não vão ao banco como catálogo;
/// o banco guarda só a chave + avaliação/origem/esquemas por necessidade).
const List<CoreNeed> kCoreNeeds = [
  CoreNeed('conexao',
      'Necessidade de conexão (nutrição, aceitação, amor incondicional)'),
  CoreNeed('expressao',
      'Necessidade de apoio e orientação para expressar e articular necessidades e emoções e aprender uma socialização saudável'),
  CoreNeed('seguranca',
      'Necessidade de segurança, confiabilidade, justiça, consistência e previsibilidade'),
  CoreNeed('limites',
      'Necessidade de orientação compassiva, firme e apropriada e de estabelecimento de limites para apoiar a aprendizagem de limites realistas e autocontrole'),
  CoreNeed('espontaneidade',
      'Necessidade de apoio e incentivo à brincadeira, abertura emocional e espontaneidade'),
  CoreNeed('competencia',
      'Necessidade de afirmação de capacidade e capacidade para desenvolvimento de competência (Apoio à Autonomia)'),
  CoreNeed('autonomia_respeito',
      'Necessidade de respeito no desenvolvimento da autonomia, por exemplo, ter privacidade e liberdade para aprender a fazer as coisas do seu próprio jeito (Concessão de Autonomia)'),
  CoreNeed('valor',
      'Necessidade de apoio e orientação no desenvolvimento de um senso de valor intrínseco que não depende de ser melhor do que os outros'),
  CoreNeed('modelo',
      'Necessidade de um pai/cuidador que seja experiente, confiante e competente (um modelo saudável)'),
];

/// Avaliação de uma necessidade não atendida (7.2).
class UnmetNeed {
  const UnmetNeed({
    required this.needKey,
    this.rating,
    this.origin,
    this.schemas,
  });

  /// Chave em [kCoreNeeds].
  final String needKey;

  /// '0'–'5' ou 'X' (informação insuficiente). Null = ainda não avaliado.
  final String? rating;
  final String? origin;
  final String? schemas;

  bool get isEmpty =>
      (rating == null || rating!.isEmpty) &&
      (origin ?? '').trim().isEmpty &&
      (schemas ?? '').trim().isEmpty;

  UnmetNeed copyWith({
    String? rating,
    String? origin,
    String? schemas,
  }) =>
      UnmetNeed(
        needKey: needKey,
        rating: rating ?? this.rating,
        origin: origin ?? this.origin,
        schemas: schemas ?? this.schemas,
      );

  factory UnmetNeed.fromJson(Map<String, dynamic> j) => UnmetNeed(
        needKey: j['need_key'] as String,
        rating: j['rating'] as String?,
        origin: j['origin'] as String?,
        schemas: j['schemas'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'need_key': needKey,
        if (rating != null && rating!.isNotEmpty) 'rating': rating,
        if ((origin ?? '').trim().isNotEmpty) 'origin': origin!.trim(),
        if ((schemas ?? '').trim().isNotEmpty) 'schemas': schemas!.trim(),
      };
}

/// Uma sequência de modos (seção 10).
class ModeSequence {
  const ModeSequence({
    this.trigger,
    this.activatedModes,
    this.copingMode,
    this.sequence,
    this.effect,
    this.perpetuation,
  });

  final String? trigger;
  final String? activatedModes;
  final String? copingMode;
  final String? sequence;
  final String? effect;
  final String? perpetuation;

  bool get isEmpty =>
      (trigger ?? '').trim().isEmpty &&
      (activatedModes ?? '').trim().isEmpty &&
      (copingMode ?? '').trim().isEmpty &&
      (sequence ?? '').trim().isEmpty &&
      (effect ?? '').trim().isEmpty &&
      (perpetuation ?? '').trim().isEmpty;

  factory ModeSequence.fromJson(Map<String, dynamic> j) => ModeSequence(
        trigger: j['trigger'] as String?,
        activatedModes: j['activated_modes'] as String?,
        copingMode: j['coping_mode'] as String?,
        sequence: j['sequence'] as String?,
        effect: j['effect'] as String?,
        perpetuation: j['perpetuation'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (t(trigger) != null) 'trigger': t(trigger),
      if (t(activatedModes) != null) 'activated_modes': t(activatedModes),
      if (t(copingMode) != null) 'coping_mode': t(copingMode),
      if (t(sequence) != null) 'sequence': t(sequence),
      if (t(effect) != null) 'effect': t(effect),
      if (t(perpetuation) != null) 'perpetuation': t(perpetuation),
    };
  }
}

/// Relação terapêutica (seção 11).
class TherapeuticRelationship {
  const TherapeuticRelationship({
    this.collaborationRating,
    this.collaborationNotes,
    this.bondRating,
    this.bondNotes,
    this.therapistReactions,
  });

  final int? collaborationRating; // 1–5
  final String? collaborationNotes;
  final int? bondRating; // 1–5
  final String? bondNotes;
  final String? therapistReactions;

  bool get isEmpty =>
      collaborationRating == null &&
      bondRating == null &&
      (collaborationNotes ?? '').trim().isEmpty &&
      (bondNotes ?? '').trim().isEmpty &&
      (therapistReactions ?? '').trim().isEmpty;

  factory TherapeuticRelationship.fromJson(Map<String, dynamic> j) =>
      TherapeuticRelationship(
        collaborationRating: (j['collaboration_rating'] as num?)?.toInt(),
        collaborationNotes: j['collaboration_notes'] as String?,
        bondRating: (j['bond_rating'] as num?)?.toInt(),
        bondNotes: j['bond_notes'] as String?,
        therapistReactions: j['therapist_reactions'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (collaborationRating != null)
        'collaboration_rating': collaborationRating,
      if (t(collaborationNotes) != null)
        'collaboration_notes': t(collaborationNotes),
      if (bondRating != null) 'bond_rating': bondRating,
      if (t(bondNotes) != null) 'bond_notes': t(bondNotes),
      if (t(therapistReactions) != null)
        'therapist_reactions': t(therapistReactions),
    };
  }
}

/// Origens (seção 7) — subseções de texto livre do terapeuta. 7.2
/// (necessidades) mora em [UnmetNeed]; aqui ficam 7.1, 7.3 e 7.4.
class CaseOrigins {
  const CaseOrigins({this.earlyHistory, this.temperament, this.cultural});

  /// 7.1 — Descrição geral da história inicial.
  final String? earlyHistory;

  /// 7.3 — Possíveis fatores temperamentais/biológicos.
  final String? temperament;

  /// 7.4 — Possíveis fatores culturais, étnicos e religiosos.
  final String? cultural;

  bool get isEmpty =>
      (earlyHistory ?? '').trim().isEmpty &&
      (temperament ?? '').trim().isEmpty &&
      (cultural ?? '').trim().isEmpty;

  factory CaseOrigins.fromJson(Map<String, dynamic> j) => CaseOrigins(
        earlyHistory: j['early_history'] as String?,
        temperament: j['temperament'] as String?,
        cultural: j['cultural'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (t(earlyHistory) != null) 'early_history': t(earlyHistory),
      if (t(temperament) != null) 'temperament': t(temperament),
      if (t(cultural) != null) 'cultural': t(cultural),
    };
  }
}

/// Impressões gerais (seção 3) — como o cliente se apresenta, inicial e atual.
class GeneralImpressions {
  const GeneralImpressions({this.initial, this.current});
  final String? initial;
  final String? current;

  bool get isEmpty =>
      (initial ?? '').trim().isEmpty && (current ?? '').trim().isEmpty;

  factory GeneralImpressions.fromJson(Map<String, dynamic> j) =>
      GeneralImpressions(
        initial: j['initial'] as String?,
        current: j['current'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (t(initial) != null) 'initial': t(initial),
      if (t(current) != null) 'current': t(current),
    };
  }
}

/// Um diagnóstico (seção 4).
class DiagnosisItem {
  const DiagnosisItem({this.name, this.code});
  final String? name;
  final String? code;

  bool get isEmpty =>
      (name ?? '').trim().isEmpty && (code ?? '').trim().isEmpty;

  factory DiagnosisItem.fromJson(Map<String, dynamic> j) => DiagnosisItem(
        name: j['name'] as String?,
        code: j['code'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (t(name) != null) 'name': t(name),
      if (t(code) != null) 'code': t(code),
    };
  }
}

/// Perspectiva diagnóstica (seção 4): sistema (CID-11/DSM-5-TR) + diagnósticos.
class Diagnosis {
  const Diagnosis({this.system, this.items = const []});
  final String? system;
  final List<DiagnosisItem> items;

  bool get isEmpty =>
      (system ?? '').trim().isEmpty && items.every((d) => d.isEmpty);

  factory Diagnosis.fromJson(Map<String, dynamic> j) => Diagnosis(
        system: j['system'] as String?,
        items: [
          for (final e in (j['items'] as List?) ?? const [])
            DiagnosisItem.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
      );

  Map<String, dynamic> toJson() {
    final list = [for (final d in items) if (!d.isEmpty) d.toJson()];
    return {
      if ((system ?? '').trim().isNotEmpty) 'system': system!.trim(),
      if (list.isNotEmpty) 'items': list,
    };
  }
}

// ── SEÇÃO 5 ──────────────────────────────────────────────────────────────────

/// Avaliação de uma área de funcionamento pelo terapeuta (1 = Não Funcional,
/// 6 = Excelente). Seção 5 do formulário.
class FunctioningEntry {
  const FunctioningEntry({this.rating, this.explanation});
  final int? rating;
  final String? explanation;
  bool get isEmpty => rating == null && (explanation ?? '').trim().isEmpty;

  factory FunctioningEntry.fromJson(Map<String, dynamic> j) => FunctioningEntry(
        rating: (j['rating'] as num?)?.toInt(),
        explanation: j['explanation'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (rating != null) 'rating': rating,
      if (t(explanation) != null) 'explanation': t(explanation),
    };
  }
}

/// Área de funcionamento canônica (seção 5), com label e código do formulário.
class FunctioningArea {
  const FunctioningArea(this.key, this.label, this.code);
  final String key;
  final String label;
  final String code;
}

const List<FunctioningArea> kFunctioningAreas = [
  FunctioningArea('occupational',
      'Ocupacional ou desempenho educacional', '5.1.1'),
  FunctioningArea('intimate_relationships',
      'Relacionamentos íntimos, românticos e de longo prazo', '5.1.2'),
  FunctioningArea('family_relationships', 'Relações familiares', '5.1.3'),
  FunctioningArea('social_relationships',
      'Amizades e outros relacionamentos sociais', '5.1.4'),
  FunctioningArea(
      'solitary', 'Funcionamento solitário e tempo sozinho', '5.1.5'),
  FunctioningArea('lifestyle',
      'Autocuidado com o estilo de vida: exercícios, dieta, padrões de sono etc.',
      '5.2'),
];

/// Conjunto das avaliações do terapeuta para todas as áreas (seção 5).
class FunctioningAssessment {
  const FunctioningAssessment({this.entries = const {}});
  final Map<String, FunctioningEntry> entries;

  bool get isEmpty => entries.values.every((e) => e.isEmpty);
  FunctioningEntry entryFor(String key) =>
      entries[key] ?? const FunctioningEntry();

  factory FunctioningAssessment.fromJson(Map<String, dynamic> j) =>
      FunctioningAssessment(
        entries: {
          for (final a in kFunctioningAreas)
            if (j[a.key] != null)
              a.key: FunctioningEntry.fromJson(
                  Map<String, dynamic>.from(j[a.key] as Map)),
        },
      );

  Map<String, dynamic> toJson() => {
        for (final e in entries.entries)
          if (!e.value.isEmpty) e.key: e.value.toJson(),
      };
}

// ── SEÇÃO 6 ──────────────────────────────────────────────────────────────────

/// Principais problemas de vida identificados pelo terapeuta (seção 6).
class TherapistLifeProblems {
  const TherapistLifeProblems(
      {this.problem1, this.problem2, this.problem3, this.problem4});
  final String? problem1;
  final String? problem2;
  final String? problem3;
  final String? problem4;

  bool get isEmpty =>
      (problem1 ?? '').trim().isEmpty &&
      (problem2 ?? '').trim().isEmpty &&
      (problem3 ?? '').trim().isEmpty &&
      (problem4 ?? '').trim().isEmpty;

  factory TherapistLifeProblems.fromJson(Map<String, dynamic> j) =>
      TherapistLifeProblems(
        problem1: j['problem1'] as String?,
        problem2: j['problem2'] as String?,
        problem3: j['problem3'] as String?,
        problem4: j['problem4'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (t(problem1) != null) 'problem1': t(problem1),
      if (t(problem2) != null) 'problem2': t(problem2),
      if (t(problem3) != null) 'problem3': t(problem3),
      if (t(problem4) != null) 'problem4': t(problem4),
    };
  }
}

// ── SEÇÃO 8 ──────────────────────────────────────────────────────────────────

/// Um dos 4–6 esquemas centrais com descrição do padrão quando ativado (8.2).
class CentralSchemaEntry {
  const CentralSchemaEntry({this.name, this.description});
  final String? name;
  final String? description;

  bool get isEmpty =>
      (name ?? '').trim().isEmpty && (description ?? '').trim().isEmpty;

  factory CentralSchemaEntry.fromJson(Map<String, dynamic> j) =>
      CentralSchemaEntry(
        name: j['name'] as String?,
        description: j['description'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (t(name) != null) 'name': t(name),
      if (t(description) != null) 'description': t(description),
    };
  }
}

// ── SEÇÃO 9 ──────────────────────────────────────────────────────────────────

/// Exemplo de ativação de um modo infantil (campos a/b/c do formulário).
class ModeExample {
  const ModeExample({this.trigger, this.experience, this.coping});
  final String? trigger;
  final String? experience;
  final String? coping;

  bool get isEmpty =>
      (trigger ?? '').trim().isEmpty &&
      (experience ?? '').trim().isEmpty &&
      (coping ?? '').trim().isEmpty;

  factory ModeExample.fromJson(Map<String, dynamic> j) => ModeExample(
        trigger: j['trigger'] as String?,
        experience: j['experience'] as String?,
        coping: j['coping'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (t(trigger) != null) 'trigger': t(trigger),
      if (t(experience) != null) 'experience': t(experience),
      if (t(coping) != null) 'coping': t(coping),
    };
  }
}

/// 9.1 — Modos saudáveis (Criança Feliz + Adulto Saudável).
class HealthyModes {
  const HealthyModes({
    this.happyChildSpontaneity,
    this.happyChildPlay,
    this.happyChildCreativity,
    this.adultMetaAwareness,
    this.adultEmotionalConnection,
    this.adultRealityOrientation,
    this.adultIdentity,
    this.adultSelfAssertion,
    this.adultAgency,
    this.adultCareForOthers,
    this.adultHope,
  });

  final String? happyChildSpontaneity;
  final String? happyChildPlay;
  final String? happyChildCreativity;
  final String? adultMetaAwareness;
  final String? adultEmotionalConnection;
  final String? adultRealityOrientation;
  final String? adultIdentity;
  final String? adultSelfAssertion;
  final String? adultAgency;
  final String? adultCareForOthers;
  final String? adultHope;

  bool get isEmpty {
    bool e(String? v) => (v ?? '').trim().isEmpty;
    return e(happyChildSpontaneity) &&
        e(happyChildPlay) &&
        e(happyChildCreativity) &&
        e(adultMetaAwareness) &&
        e(adultEmotionalConnection) &&
        e(adultRealityOrientation) &&
        e(adultIdentity) &&
        e(adultSelfAssertion) &&
        e(adultAgency) &&
        e(adultCareForOthers) &&
        e(adultHope);
  }

  factory HealthyModes.fromJson(Map<String, dynamic> j) => HealthyModes(
        happyChildSpontaneity: j['happy_child_spontaneity'] as String?,
        happyChildPlay: j['happy_child_play'] as String?,
        happyChildCreativity: j['happy_child_creativity'] as String?,
        adultMetaAwareness: j['adult_meta_awareness'] as String?,
        adultEmotionalConnection: j['adult_emotional_connection'] as String?,
        adultRealityOrientation: j['adult_reality_orientation'] as String?,
        adultIdentity: j['adult_identity'] as String?,
        adultSelfAssertion: j['adult_self_assertion'] as String?,
        adultAgency: j['adult_agency'] as String?,
        adultCareForOthers: j['adult_care_for_others'] as String?,
        adultHope: j['adult_hope'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (t(happyChildSpontaneity) != null)
        'happy_child_spontaneity': t(happyChildSpontaneity),
      if (t(happyChildPlay) != null) 'happy_child_play': t(happyChildPlay),
      if (t(happyChildCreativity) != null)
        'happy_child_creativity': t(happyChildCreativity),
      if (t(adultMetaAwareness) != null)
        'adult_meta_awareness': t(adultMetaAwareness),
      if (t(adultEmotionalConnection) != null)
        'adult_emotional_connection': t(adultEmotionalConnection),
      if (t(adultRealityOrientation) != null)
        'adult_reality_orientation': t(adultRealityOrientation),
      if (t(adultIdentity) != null) 'adult_identity': t(adultIdentity),
      if (t(adultSelfAssertion) != null)
        'adult_self_assertion': t(adultSelfAssertion),
      if (t(adultAgency) != null) 'adult_agency': t(adultAgency),
      if (t(adultCareForOthers) != null)
        'adult_care_for_others': t(adultCareForOthers),
      if (t(adultHope) != null) 'adult_hope': t(adultHope),
    };
  }
}

/// 9.2 — Modo Criança Vulnerável (nome/subtipos, esquemas, até 3 exemplos).
class VulnerableChildAssessment {
  const VulnerableChildAssessment(
      {this.description, this.schemas, this.examples = const []});
  final String? description;
  final String? schemas;
  final List<ModeExample> examples;

  bool get isEmpty =>
      (description ?? '').trim().isEmpty &&
      (schemas ?? '').trim().isEmpty &&
      examples.every((e) => e.isEmpty);

  factory VulnerableChildAssessment.fromJson(Map<String, dynamic> j) =>
      VulnerableChildAssessment(
        description: j['description'] as String?,
        schemas: j['schemas'] as String?,
        examples: [
          for (final e in (j['examples'] as List?) ?? const [])
            ModeExample.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    final exs = [for (final e in examples) if (!e.isEmpty) e.toJson()];
    return {
      if (t(description) != null) 'description': t(description),
      if (t(schemas) != null) 'schemas': t(schemas),
      if (exs.isNotEmpty) 'examples': exs,
    };
  }
}

/// 9.2 — Outros modos infantis (raiva, impulsivo…) com até 2 exemplos.
class OtherChildAssessment {
  const OtherChildAssessment(
      {this.description, this.schemas, this.examples = const []});
  final String? description;
  final String? schemas;
  final List<ModeExample> examples;

  bool get isEmpty =>
      (description ?? '').trim().isEmpty &&
      (schemas ?? '').trim().isEmpty &&
      examples.every((e) => e.isEmpty);

  factory OtherChildAssessment.fromJson(Map<String, dynamic> j) =>
      OtherChildAssessment(
        description: j['description'] as String?,
        schemas: j['schemas'] as String?,
        examples: [
          for (final e in (j['examples'] as List?) ?? const [])
            ModeExample.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    final exs = [for (final e in examples) if (!e.isEmpty) e.toJson()];
    return {
      if (t(description) != null) 'description': t(description),
      if (t(schemas) != null) 'schemas': t(schemas),
      if (exs.isNotEmpty) 'examples': exs,
    };
  }
}

/// 9.3 — Modo parental disfuncional com mensagens para a criança.
class ParentalModeEntry {
  const ParentalModeEntry({this.name, this.messages});
  final String? name;
  final String? messages;

  bool get isEmpty =>
      (name ?? '').trim().isEmpty && (messages ?? '').trim().isEmpty;

  factory ParentalModeEntry.fromJson(Map<String, dynamic> j) =>
      ParentalModeEntry(
        name: j['name'] as String?,
        messages: j['messages'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (t(name) != null) 'name': t(name),
      if (t(messages) != null) 'messages': t(messages),
    };
  }
}

/// 9.4 — Modo de enfrentamento desadaptativo detalhado (campos a–e).
class CopingModeDetail {
  const CopingModeDetail({
    this.category,
    this.name,
    this.schemas,
    this.example,
    this.experience,
    this.addresses,
    this.perceivedValue,
    this.consequences,
  });
  final String? category;
  final String? name;
  final String? schemas;
  final String? example;
  final String? experience;
  final String? addresses;
  final String? perceivedValue;
  final String? consequences;

  bool get isEmpty {
    bool e(String? v) => (v ?? '').trim().isEmpty;
    return e(category) &&
        e(name) &&
        e(schemas) &&
        e(example) &&
        e(experience) &&
        e(addresses) &&
        e(perceivedValue) &&
        e(consequences);
  }

  factory CopingModeDetail.fromJson(Map<String, dynamic> j) => CopingModeDetail(
        category: j['category'] as String?,
        name: j['name'] as String?,
        schemas: j['schemas'] as String?,
        example: j['example'] as String?,
        experience: j['experience'] as String?,
        addresses: j['addresses'] as String?,
        perceivedValue: j['perceived_value'] as String?,
        consequences: j['consequences'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (t(category) != null) 'category': t(category),
      if (t(name) != null) 'name': t(name),
      if (t(schemas) != null) 'schemas': t(schemas),
      if (t(example) != null) 'example': t(example),
      if (t(experience) != null) 'experience': t(experience),
      if (t(addresses) != null) 'addresses': t(addresses),
      if (t(perceivedValue) != null) 'perceived_value': t(perceivedValue),
      if (t(consequences) != null) 'consequences': t(consequences),
    };
  }
}

/// Seção 9 completa — avaliação de modos de esquema pelo terapeuta.
class SchemaModeAssessment {
  const SchemaModeAssessment({
    this.healthyModes = const HealthyModes(),
    this.vulnerableChild = const VulnerableChildAssessment(),
    this.otherChild = const OtherChildAssessment(),
    this.parentalModes = const [],
    this.copingModes = const [],
  });

  final HealthyModes healthyModes;
  final VulnerableChildAssessment vulnerableChild;
  final OtherChildAssessment otherChild;
  final List<ParentalModeEntry> parentalModes;
  final List<CopingModeDetail> copingModes;

  bool get isEmpty =>
      healthyModes.isEmpty &&
      vulnerableChild.isEmpty &&
      otherChild.isEmpty &&
      parentalModes.every((e) => e.isEmpty) &&
      copingModes.every((e) => e.isEmpty);

  factory SchemaModeAssessment.fromJson(Map<String, dynamic> j) =>
      SchemaModeAssessment(
        healthyModes: HealthyModes.fromJson(
            Map<String, dynamic>.from((j['healthy_modes'] as Map?) ?? {})),
        vulnerableChild: VulnerableChildAssessment.fromJson(
            Map<String, dynamic>.from((j['vulnerable_child'] as Map?) ?? {})),
        otherChild: OtherChildAssessment.fromJson(
            Map<String, dynamic>.from((j['other_child'] as Map?) ?? {})),
        parentalModes: [
          for (final e in (j['parental_modes'] as List?) ?? const [])
            ParentalModeEntry.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
        copingModes: [
          for (final e in (j['coping_modes'] as List?) ?? const [])
            CopingModeDetail.fromJson(Map<String, dynamic>.from(e as Map)),
        ],
      );

  Map<String, dynamic> toJson() {
    final pm = [for (final e in parentalModes) if (!e.isEmpty) e.toJson()];
    final cm = [for (final e in copingModes) if (!e.isEmpty) e.toJson()];
    return {
      if (!healthyModes.isEmpty) 'healthy_modes': healthyModes.toJson(),
      if (!vulnerableChild.isEmpty)
        'vulnerable_child': vulnerableChild.toJson(),
      if (!otherChild.isEmpty) 'other_child': otherChild.toJson(),
      if (pm.isNotEmpty) 'parental_modes': pm,
      if (cm.isNotEmpty) 'coping_modes': cm,
    };
  }
}

// ── SEÇÃO 12 ─────────────────────────────────────────────────────────────────

/// Um objetivo de terapia com os sub-campos (a)–(e) do formulário (seção 12).
class TherapyObjectiveEntry {
  const TherapyObjectiveEntry({
    this.goal,
    this.schemasModes,
    this.healthyBehaviors,
    this.interventions,
    this.progress,
  });
  final String? goal;
  final String? schemasModes;
  final String? healthyBehaviors;
  final String? interventions;
  final String? progress;

  bool get isEmpty {
    bool e(String? v) => (v ?? '').trim().isEmpty;
    return e(goal) &&
        e(schemasModes) &&
        e(healthyBehaviors) &&
        e(interventions) &&
        e(progress);
  }

  factory TherapyObjectiveEntry.fromJson(Map<String, dynamic> j) =>
      TherapyObjectiveEntry(
        goal: j['goal'] as String?,
        schemasModes: j['schemas_modes'] as String?,
        healthyBehaviors: j['healthy_behaviors'] as String?,
        interventions: j['interventions'] as String?,
        progress: j['progress'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (t(goal) != null) 'goal': t(goal),
      if (t(schemasModes) != null) 'schemas_modes': t(schemasModes),
      if (t(healthyBehaviors) != null) 'healthy_behaviors': t(healthyBehaviors),
      if (t(interventions) != null) 'interventions': t(interventions),
      if (t(progress) != null) 'progress': t(progress),
    };
  }
}

// ── DOCUMENTO COMPLETO ────────────────────────────────────────────────────────

/// Documento completo (uma linha por paciente).
class CaseConceptualization {
  const CaseConceptualization({
    required this.unmetNeeds,
    required this.modeSequences,
    required this.relationship,
    this.generalImpressions = const GeneralImpressions(),
    this.diagnosis = const Diagnosis(),
    this.origins = const CaseOrigins(),
    this.functioning = const FunctioningAssessment(),
    this.lifeProblems = const TherapistLifeProblems(),
    this.centralSchemas = const [],
    this.modeAssessment = const SchemaModeAssessment(),
    this.therapyObjectives = const [],
    this.motivoNotes,
    this.additionalComments,
  });

  final List<UnmetNeed> unmetNeeds;
  final List<ModeSequence> modeSequences;
  final TherapeuticRelationship relationship;
  final GeneralImpressions generalImpressions;
  final Diagnosis diagnosis;
  final CaseOrigins origins;

  /// Seção 5 — avaliação do terapeuta de cada área de vida (1–6).
  final FunctioningAssessment functioning;

  /// Seção 6 — principais problemas de vida identificados pelo terapeuta.
  final TherapistLifeProblems lifeProblems;

  /// Seção 8.2 — 4–6 esquemas centrais com descrição quando ativados.
  final List<CentralSchemaEntry> centralSchemas;

  /// Seção 9 — modos de esquema avaliados pelo terapeuta.
  final SchemaModeAssessment modeAssessment;

  /// Seção 12 — objetivos de terapia com sub-campos (a)–(e).
  final List<TherapyObjectiveEntry> therapyObjectives;

  /// Seção 2 — complemento do terapeuta ao motivo/queixa.
  final String? motivoNotes;
  final String? additionalComments;

  /// Documento vazio — todas as necessidades em branco.
  factory CaseConceptualization.empty() => CaseConceptualization(
        unmetNeeds: [
          for (final n in kCoreNeeds) UnmetNeed(needKey: n.key),
        ],
        modeSequences: const [],
        relationship: const TherapeuticRelationship(),
        centralSchemas: List.generate(6, (_) => const CentralSchemaEntry()),
        therapyObjectives:
            List.generate(5, (_) => const TherapyObjectiveEntry()),
      );

  /// A avaliação salva de uma necessidade, ou uma vazia se ainda não houver.
  UnmetNeed needFor(String key) => unmetNeeds.firstWhere(
        (u) => u.needKey == key,
        orElse: () => UnmetNeed(needKey: key),
      );

  bool get hasAnyNeed => unmetNeeds.any((u) => !u.isEmpty);
  bool get hasAnySequence => modeSequences.any((s) => !s.isEmpty);
  bool get hasRelationship => !relationship.isEmpty;
  bool get hasGeneralImpressions => !generalImpressions.isEmpty;
  bool get hasDiagnosis => !diagnosis.isEmpty;
  bool get hasOrigins => !origins.isEmpty;
  bool get hasFunctioning => !functioning.isEmpty;
  bool get hasLifeProblems => !lifeProblems.isEmpty;
  bool get hasCentralSchemas => centralSchemas.any((e) => !e.isEmpty);
  bool get hasModeAssessment => !modeAssessment.isEmpty;
  bool get hasTherapyObjectives => therapyObjectives.any((e) => !e.isEmpty);
  bool get hasMotivoNotes => (motivoNotes ?? '').trim().isNotEmpty;
  bool get hasComments => (additionalComments ?? '').trim().isNotEmpty;

  factory CaseConceptualization.fromJson(Map<String, dynamic> j) {
    final needsRaw = (j['unmet_needs'] as List?) ?? const [];
    final seqRaw = (j['mode_sequences'] as List?) ?? const [];
    final rel = (j['therapeutic_relationship'] as Map?) ?? const {};
    final gi = (j['general_impressions'] as Map?) ?? const {};
    final dx = (j['diagnosis'] as Map?) ?? const {};
    final org = (j['origins'] as Map?) ?? const {};
    final func = (j['functioning'] as Map?) ?? const {};
    final lp = (j['life_problems'] as Map?) ?? const {};
    final csRaw = (j['central_schemas'] as List?) ?? const [];
    final ma = (j['mode_assessment'] as Map?) ?? const {};
    final toRaw = (j['therapy_objectives'] as List?) ?? const [];

    final byKey = <String, UnmetNeed>{
      for (final e in needsRaw)
        (e as Map)['need_key'] as String:
            UnmetNeed.fromJson(Map<String, dynamic>.from(e)),
    };

    final csLoaded = [
      for (final e in csRaw)
        CentralSchemaEntry.fromJson(Map<String, dynamic>.from(e as Map)),
    ];
    final toLoaded = [
      for (final e in toRaw)
        TherapyObjectiveEntry.fromJson(Map<String, dynamic>.from(e as Map)),
    ];

    return CaseConceptualization(
      unmetNeeds: [
        for (final n in kCoreNeeds) byKey[n.key] ?? UnmetNeed(needKey: n.key),
      ],
      modeSequences: [
        for (final e in seqRaw)
          ModeSequence.fromJson(Map<String, dynamic>.from(e as Map)),
      ],
      relationship:
          TherapeuticRelationship.fromJson(Map<String, dynamic>.from(rel)),
      generalImpressions:
          GeneralImpressions.fromJson(Map<String, dynamic>.from(gi)),
      diagnosis: Diagnosis.fromJson(Map<String, dynamic>.from(dx)),
      origins: CaseOrigins.fromJson(Map<String, dynamic>.from(org)),
      functioning:
          FunctioningAssessment.fromJson(Map<String, dynamic>.from(func)),
      lifeProblems:
          TherapistLifeProblems.fromJson(Map<String, dynamic>.from(lp)),
      centralSchemas: csLoaded.isEmpty
          ? List.generate(6, (_) => const CentralSchemaEntry())
          : csLoaded,
      modeAssessment:
          SchemaModeAssessment.fromJson(Map<String, dynamic>.from(ma)),
      therapyObjectives: toLoaded.isEmpty
          ? List.generate(5, (_) => const TherapyObjectiveEntry())
          : toLoaded,
      motivoNotes: j['motivo_notes'] as String?,
      additionalComments: j['additional_comments'] as String?,
    );
  }

  /// Só as necessidades com algum preenchimento vão ao banco.
  List<Map<String, dynamic>> unmetNeedsJson() =>
      [for (final u in unmetNeeds) if (!u.isEmpty) u.toJson()];

  List<Map<String, dynamic>> modeSequencesJson() =>
      [for (final s in modeSequences) if (!s.isEmpty) s.toJson()];

  List<Map<String, dynamic>> centralSchemasJson() =>
      [for (final s in centralSchemas) if (!s.isEmpty) s.toJson()];

  List<Map<String, dynamic>> therapyObjectivesJson() =>
      [for (final o in therapyObjectives) if (!o.isEmpty) o.toJson()];
}
