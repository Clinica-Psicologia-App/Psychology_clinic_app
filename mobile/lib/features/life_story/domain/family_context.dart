/// Clima e padrões familiares (Genograma, Tela 3, §32–33) — a família como um
/// todo. Rótulos literais da spec.
library;

/// Etapa 12 (§32) — "O que costumava acontecer em casa?"
enum ClimateTrait {
  showedAffection,
  talkedFeelings,
  couldAskHelp,
  supportWhenNeeded,
  opinionsRespected,
  couldDisagree,
  conflictsResolved,
  roomToPlay,
  clearRules,
  safeToErr,
  manyCriticisms,
  hadToBePerfect,
  muchPressure,
  comparison,
  avoidedEmotions,
  keptFeelingsIn,
  forbiddenTopics,
  muchControl,
  frequentFights,
  unpredictableReactions,
  littleAffection,
  kidsCaredForAdults,
  adultsNeedsFirst,
  other,
}

extension ClimateTraitMeta on ClimateTrait {
  String get key => switch (this) {
        ClimateTrait.showedAffection => 'showed_affection',
        ClimateTrait.talkedFeelings => 'talked_feelings',
        ClimateTrait.couldAskHelp => 'could_ask_help',
        ClimateTrait.supportWhenNeeded => 'support_when_needed',
        ClimateTrait.opinionsRespected => 'opinions_respected',
        ClimateTrait.couldDisagree => 'could_disagree',
        ClimateTrait.conflictsResolved => 'conflicts_resolved',
        ClimateTrait.roomToPlay => 'room_to_play',
        ClimateTrait.clearRules => 'clear_rules',
        ClimateTrait.safeToErr => 'safe_to_err',
        ClimateTrait.manyCriticisms => 'many_criticisms',
        ClimateTrait.hadToBePerfect => 'had_to_be_perfect',
        ClimateTrait.muchPressure => 'much_pressure',
        ClimateTrait.comparison => 'comparison',
        ClimateTrait.avoidedEmotions => 'avoided_emotions',
        ClimateTrait.keptFeelingsIn => 'kept_feelings_in',
        ClimateTrait.forbiddenTopics => 'forbidden_topics',
        ClimateTrait.muchControl => 'much_control',
        ClimateTrait.frequentFights => 'frequent_fights',
        ClimateTrait.unpredictableReactions => 'unpredictable_reactions',
        ClimateTrait.littleAffection => 'little_affection',
        ClimateTrait.kidsCaredForAdults => 'kids_cared_for_adults',
        ClimateTrait.adultsNeedsFirst => 'adults_needs_first',
        ClimateTrait.other => 'other',
      };
  String get label => switch (this) {
        ClimateTrait.showedAffection => 'Demonstrávamos carinho',
        ClimateTrait.talkedFeelings => 'Conversávamos sobre nossos sentimentos',
        ClimateTrait.couldAskHelp => 'Podíamos pedir ajuda',
        ClimateTrait.supportWhenNeeded => 'Havia apoio quando alguém precisava',
        ClimateTrait.opinionsRespected => 'As opiniões eram respeitadas',
        ClimateTrait.couldDisagree => 'Podíamos discordar',
        ClimateTrait.conflictsResolved =>
          'Os conflitos eram conversados e resolvidos',
        ClimateTrait.roomToPlay => 'Havia espaço para brincar e se divertir',
        ClimateTrait.clearRules => 'Existiam regras claras',
        ClimateTrait.safeToErr => 'Era seguro cometer erros',
        ClimateTrait.manyCriticisms => 'Havia muitas críticas',
        ClimateTrait.hadToBePerfect => 'Era preciso fazer tudo muito bem',
        ClimateTrait.muchPressure => 'Havia muita cobrança',
        ClimateTrait.comparison =>
          'Havia comparação entre irmãos ou outras pessoas',
        ClimateTrait.avoidedEmotions => 'Era comum evitar emoções',
        ClimateTrait.keptFeelingsIn => 'As pessoas guardavam o que sentiam',
        ClimateTrait.forbiddenTopics => 'Alguns assuntos não podiam ser falados',
        ClimateTrait.muchControl => 'Havia muito controle',
        ClimateTrait.frequentFights => 'As brigas eram frequentes',
        ClimateTrait.unpredictableReactions =>
          'Nunca sabíamos como alguém iria reagir',
        ClimateTrait.littleAffection => 'Havia pouco carinho ou proximidade',
        ClimateTrait.kidsCaredForAdults =>
          'As crianças precisavam cuidar dos adultos',
        ClimateTrait.adultsNeedsFirst =>
          'As necessidades dos adultos vinham antes das das crianças',
        ClimateTrait.other => 'Outro',
      };
}

const kClimateTraitsInOrder = ClimateTrait.values;
ClimateTrait? climateTraitFromKey(String? k) {
  for (final v in ClimateTrait.values) {
    if (v.key == k) return v;
  }
  return null;
}

/// Etapa 13 (§33) — "Existe algum padrão que parece se repetir?"
enum HasPatterns { yes, maybe, dontKnow, no }

extension HasPatternsMeta on HasPatterns {
  String get key => switch (this) {
        HasPatterns.yes => 'yes',
        HasPatterns.maybe => 'maybe',
        HasPatterns.dontKnow => 'dont_know',
        HasPatterns.no => 'no',
      };
  String get label => switch (this) {
        HasPatterns.yes => 'Sim',
        HasPatterns.maybe => 'Talvez',
        HasPatterns.dontKnow => 'Não sei',
        HasPatterns.no => 'Não',
      };
}

const kHasPatternsInOrder = HasPatterns.values;
HasPatterns? hasPatternsFromKey(String? k) {
  for (final v in HasPatterns.values) {
    if (v.key == k) return v;
  }
  return null;
}

/// Grupo de um padrão transgeracional (só para organizar a UI em §33).
enum PatternGroup { relationships, relating, difficulties }

extension PatternGroupMeta on PatternGroup {
  String get label => switch (this) {
        PatternGroup.relationships => 'Relacionamentos e rupturas',
        PatternGroup.relating => 'Formas de se relacionar',
        PatternGroup.difficulties => 'Dificuldades importantes na família',
      };
}

/// Etapa 13 (§33) — padrões percebidos, agrupados.
enum PatternTrait {
  frequentSeparations,
  abandonment,
  veryConflictual,
  abusiveRelationships,
  familyViolence,
  hardToKeepBonds,
  muchControl,
  frequentCriticism,
  perfectionism,
  littleAffectionShown,
  hardToTalkFeelings,
  overCaretakers,
  earlyResponsibility,
  rupturesNoContact,
  alcoholProblems,
  drugProblems,
  psychologicalSuffering,
  suicidalBehavior,
  seriousIllness,
  financialCrises,
  other,
}

extension PatternTraitMeta on PatternTrait {
  String get key => switch (this) {
        PatternTrait.frequentSeparations => 'frequent_separations',
        PatternTrait.abandonment => 'abandonment',
        PatternTrait.veryConflictual => 'very_conflictual',
        PatternTrait.abusiveRelationships => 'abusive_relationships',
        PatternTrait.familyViolence => 'family_violence',
        PatternTrait.hardToKeepBonds => 'hard_to_keep_bonds',
        PatternTrait.muchControl => 'much_control',
        PatternTrait.frequentCriticism => 'frequent_criticism',
        PatternTrait.perfectionism => 'perfectionism',
        PatternTrait.littleAffectionShown => 'little_affection_shown',
        PatternTrait.hardToTalkFeelings => 'hard_to_talk_feelings',
        PatternTrait.overCaretakers => 'over_caretakers',
        PatternTrait.earlyResponsibility => 'early_responsibility',
        PatternTrait.rupturesNoContact => 'ruptures_no_contact',
        PatternTrait.alcoholProblems => 'alcohol_problems',
        PatternTrait.drugProblems => 'drug_problems',
        PatternTrait.psychologicalSuffering => 'psychological_suffering',
        PatternTrait.suicidalBehavior => 'suicidal_behavior',
        PatternTrait.seriousIllness => 'serious_illness',
        PatternTrait.financialCrises => 'financial_crises',
        PatternTrait.other => 'other',
      };
  String get label => switch (this) {
        PatternTrait.frequentSeparations => 'Separações frequentes',
        PatternTrait.abandonment => 'Abandono ou afastamento entre familiares',
        PatternTrait.veryConflictual => 'Relações muito conflituosas',
        PatternTrait.abusiveRelationships => 'Relacionamentos abusivos',
        PatternTrait.familyViolence => 'Violência familiar',
        PatternTrait.hardToKeepBonds =>
          'Dificuldade de manter vínculos próximos',
        PatternTrait.muchControl => 'Muito controle',
        PatternTrait.frequentCriticism => 'Críticas frequentes',
        PatternTrait.perfectionism => 'Cobrança ou perfeccionismo',
        PatternTrait.littleAffectionShown => 'Pouca demonstração de afeto',
        PatternTrait.hardToTalkFeelings =>
          'Dificuldade de falar sobre sentimentos',
        PatternTrait.overCaretakers =>
          'Pessoas que cuidam muito dos outros e esquecem de si',
        PatternTrait.earlyResponsibility =>
          'Pessoas que assumem responsabilidades muito cedo',
        PatternTrait.rupturesNoContact =>
          'Rompimentos e longos períodos sem contato',
        PatternTrait.alcoholProblems => 'Problemas relacionados ao álcool',
        PatternTrait.drugProblems => 'Problemas relacionados a outras drogas',
        PatternTrait.psychologicalSuffering =>
          'Sofrimento psicológico ou psiquiátrico importante',
        PatternTrait.suicidalBehavior =>
          'Comportamento suicida ou tentativas de suicídio',
        PatternTrait.seriousIllness => 'Doenças graves recorrentes',
        PatternTrait.financialCrises => 'Crises financeiras significativas',
        PatternTrait.other => 'Outro',
      };

  PatternGroup get group => switch (this) {
        PatternTrait.frequentSeparations ||
        PatternTrait.abandonment ||
        PatternTrait.veryConflictual ||
        PatternTrait.abusiveRelationships ||
        PatternTrait.familyViolence ||
        PatternTrait.hardToKeepBonds =>
          PatternGroup.relationships,
        PatternTrait.muchControl ||
        PatternTrait.frequentCriticism ||
        PatternTrait.perfectionism ||
        PatternTrait.littleAffectionShown ||
        PatternTrait.hardToTalkFeelings ||
        PatternTrait.overCaretakers ||
        PatternTrait.earlyResponsibility ||
        PatternTrait.rupturesNoContact =>
          PatternGroup.relating,
        _ => PatternGroup.difficulties,
      };
}

const kPatternTraitsInOrder = PatternTrait.values;
PatternTrait? patternTraitFromKey(String? k) {
  for (final v in PatternTrait.values) {
    if (v.key == k) return v;
  }
  return null;
}

/// Etapa 13 (§33) — "Em quais gerações você percebe esse padrão?"
enum PatternGeneration {
  grandparents,
  parentsUncles,
  myGeneration,
  multipleGenerations,
  dontKnow,
}

extension PatternGenerationMeta on PatternGeneration {
  String get key => switch (this) {
        PatternGeneration.grandparents => 'grandparents',
        PatternGeneration.parentsUncles => 'parents_uncles',
        PatternGeneration.myGeneration => 'my_generation',
        PatternGeneration.multipleGenerations => 'multiple_generations',
        PatternGeneration.dontKnow => 'dont_know',
      };
  String get label => switch (this) {
        PatternGeneration.grandparents => 'Avós ou gerações anteriores',
        PatternGeneration.parentsUncles => 'Pais/tios',
        PatternGeneration.myGeneration => 'Minha geração',
        PatternGeneration.multipleGenerations => 'Mais de uma geração',
        PatternGeneration.dontKnow => 'Não sei',
      };
}

const kPatternGenerationsInOrder = PatternGeneration.values;
PatternGeneration? patternGenerationFromKey(String? k) {
  for (final v in PatternGeneration.values) {
    if (v.key == k) return v;
  }
  return null;
}

/// Clima + padrões da família de um paciente (uma linha em
/// patient_family_context, colunas novas do fluxo unificado).
class FamilyContext {
  const FamilyContext({
    this.climateTraits = const [],
    this.climateNote,
    this.hasPatterns,
    this.patternTraits = const [],
    this.patternGenerations = const [],
    this.patternsNote,
  });

  final List<ClimateTrait> climateTraits;
  final String? climateNote;
  final HasPatterns? hasPatterns;
  final List<PatternTrait> patternTraits;
  final List<PatternGeneration> patternGenerations;
  final String? patternsNote;

  bool get isEmpty =>
      climateTraits.isEmpty &&
      (climateNote ?? '').trim().isEmpty &&
      hasPatterns == null &&
      patternTraits.isEmpty;

  factory FamilyContext.fromJson(Map<String, dynamic> json) {
    List<T> mapKeys<T>(String col, T? Function(String?) from) => [
          for (final k in (json[col] as List?) ?? const [])
            if (from(k as String?) case final v?) v,
        ];
    return FamilyContext(
      climateTraits: mapKeys('climate_traits', climateTraitFromKey),
      climateNote: json['climate_note'] as String?,
      hasPatterns: hasPatternsFromKey(json['has_patterns'] as String?),
      patternTraits: mapKeys('pattern_traits', patternTraitFromKey),
      patternGenerations:
          mapKeys('pattern_generations', patternGenerationFromKey),
      patternsNote: json['patterns_note'] as String?,
    );
  }

  Map<String, dynamic> toRow() => {
        'climate_traits': climateTraits.map((c) => c.key).toList(),
        'climate_note': climateNote,
        'has_patterns': hasPatterns?.key,
        'pattern_traits': patternTraits.map((p) => p.key).toList(),
        'pattern_generations': patternGenerations.map((g) => g.key).toList(),
        'patterns_note': patternsNote,
      };
}
