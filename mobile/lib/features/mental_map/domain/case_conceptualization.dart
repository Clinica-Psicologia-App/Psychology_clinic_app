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
  CoreNeed('conexao', 'Conexão (afeto, aceitação, amor)'),
  CoreNeed('expressao', 'Expressão de emoções e necessidades'),
  CoreNeed('seguranca', 'Segurança e previsibilidade'),
  CoreNeed('limites', 'Limites realistas e autocontrole'),
  CoreNeed('espontaneidade', 'Espontaneidade e brincadeira'),
  CoreNeed('competencia', 'Afirmação de competência (autonomia)'),
  CoreNeed('autonomia_respeito', 'Respeito à autonomia'),
  CoreNeed('valor', 'Valor intrínseco'),
  CoreNeed('modelo', 'Modelo saudável (cuidador competente)'),
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

/// Documento completo (uma linha por paciente).
class CaseConceptualization {
  const CaseConceptualization({
    required this.unmetNeeds,
    required this.modeSequences,
    required this.relationship,
  });

  final List<UnmetNeed> unmetNeeds;
  final List<ModeSequence> modeSequences;
  final TherapeuticRelationship relationship;

  /// Documento vazio (nenhuma linha ainda) — todas as necessidades em branco.
  factory CaseConceptualization.empty() => CaseConceptualization(
        unmetNeeds: [
          for (final n in kCoreNeeds) UnmetNeed(needKey: n.key),
        ],
        modeSequences: const [],
        relationship: const TherapeuticRelationship(),
      );

  /// A avaliação salva de uma necessidade, ou uma vazia se ainda não houver.
  UnmetNeed needFor(String key) => unmetNeeds.firstWhere(
        (u) => u.needKey == key,
        orElse: () => UnmetNeed(needKey: key),
      );

  bool get hasAnyNeed => unmetNeeds.any((u) => !u.isEmpty);
  bool get hasAnySequence => modeSequences.any((s) => !s.isEmpty);
  bool get hasRelationship => !relationship.isEmpty;

  factory CaseConceptualization.fromJson(Map<String, dynamic> j) {
    final needsRaw = (j['unmet_needs'] as List?) ?? const [];
    final seqRaw = (j['mode_sequences'] as List?) ?? const [];
    final rel = (j['therapeutic_relationship'] as Map?) ?? const {};

    // Mescla o que veio do banco sobre as 9 chaves fixas, preservando a ordem.
    final byKey = <String, UnmetNeed>{
      for (final e in needsRaw)
        (e as Map)['need_key'] as String:
            UnmetNeed.fromJson(Map<String, dynamic>.from(e)),
    };
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
    );
  }

  /// Só as necessidades com algum preenchimento vão ao banco.
  List<Map<String, dynamic>> unmetNeedsJson() =>
      [for (final u in unmetNeeds) if (!u.isEmpty) u.toJson()];

  List<Map<String, dynamic>> modeSequencesJson() =>
      [for (final s in modeSequences) if (!s.isEmpty) s.toJson()];
}
