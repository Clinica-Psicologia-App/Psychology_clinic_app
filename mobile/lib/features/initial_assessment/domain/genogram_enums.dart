// Listas de múltipla escolha da Tela 3 (Minha Família / Genograma emocional).
// As `key` batem com os CHECK das colunas correspondentes. Rótulos no app
// (opção A) — não há catálogo no banco para estas listas.

/// Converte um `text[]` persistido em enums, ignorando chaves desconhecidas.
List<E> parseKeys<E>(dynamic raw, List<E> all, String Function(E) keyOf) {
  if (raw is! List) return const [];
  final byKey = <String, E>{for (final e in all) keyOf(e): e};
  final out = <E>[];
  for (final item in raw) {
    if (item is String && byKey.containsKey(item)) out.add(byKey[item] as E);
  }
  return out;
}

/// "Como você descreveria sua relação com essa pessoa?" (seleção única).
enum BondQuality {
  affectionate('affectionate', 'Afetiva'),
  conflictual('conflictual', 'Conflituosa'),
  distant('distant', 'Distante'),
  ambivalent('ambivalent', 'Ambivalente'),
  broken('broken', 'Rompida');

  const BondQuality(this.key, this.label);
  final String key;
  final String label;

  static BondQuality? fromKey(String? key) {
    if (key == null) return null;
    for (final v in values) {
      if (v.key == key) return v;
    }
    return null;
  }
}

/// "Como essa pessoa costumava agir com você?" (múltipla escolha).
enum CaregiverTrait {
  welcoming('welcoming', 'Acolhia'),
  affectionate('affectionate', 'Demonstrava carinho'),
  encouraging('encouraging', 'Incentivava'),
  protective('protective', 'Protegia'),
  respectful('respectful', 'Respeitava'),
  critical('critical', 'Criticava'),
  controlling('controlling', 'Controlava'),
  neglectful('neglectful', 'Ignorava'),
  unpredictable('unpredictable', 'Era imprevisível'),
  demanding('demanding', 'Cobrava demais'),
  emotionallyDistant('emotionally_distant', 'Era emocionalmente distante');

  const CaregiverTrait(this.key, this.label);
  final String key;
  final String label;
}

/// Necessidades emocionais em linguagem experiencial. Serve tanto para
/// "geralmente se sentia..." (felt) quanto "o que gostaria de ter recebido"
/// (wished) — o banco usa o mesmo conjunto em ambas as colunas.
enum CaregiverNeed {
  safe('safe', 'Seguro(a)'),
  loved('loved', 'Amado(a)'),
  accepted('accepted', 'Aceito(a)'),
  understood('understood', 'Compreendido(a)'),
  valued('valued', 'Valorizado(a)'),
  respected('respected', 'Respeitado(a)'),
  freeToBe('free_to_be', 'Livre para ser quem era'),
  encouraged('encouraged', 'Incentivado(a)'),
  protected('protected', 'Protegido(a)');

  const CaregiverNeed(this.key, this.label);
  final String key;
  final String label;
}

/// "Existe algum acontecimento importante relacionado a essa pessoa?"
enum LinkedEvent {
  separation('separation', 'Separação'),
  death('death', 'Falecimento'),
  abandonment('abandonment', 'Abandono'),
  violence('violence', 'Violência'),
  relocation('relocation', 'Mudança'),
  alcoholism('alcoholism', 'Alcoolismo'),
  illness('illness', 'Doença');

  const LinkedEvent(this.key, this.label);
  final String key;
  final String label;
}

/// "Na sua família era comum..." (clima emocional).
enum FamilyClimateTrait {
  showAffection('show_affection', 'Demonstrar carinho'),
  talk('talk', 'Conversar'),
  resolveConflicts('resolve_conflicts', 'Resolver conflitos'),
  criticize('criticize', 'Fazer críticas'),
  demandPerfection('demand_perfection', 'Cobrar perfeição'),
  avoidEmotions('avoid_emotions', 'Evitar emoções'),
  control('control', 'Controlar'),
  support('support', 'Apoiar'),
  frequentFighting('frequent_fighting', 'Brigar frequentemente'),
  withholdFeelings('withhold_feelings', 'Guardar sentimentos'),
  respectOpinions('respect_opinions', 'Respeitar opiniões');

  const FamilyClimateTrait(this.key, this.label);
  final String key;
  final String label;
}

/// "Existe histórico na sua família de..." (padrões transgeracionais).
enum TransgenerationalPattern {
  separations('separations', 'Separações'),
  violence('violence', 'Violência'),
  alcoholism('alcoholism', 'Alcoolismo'),
  substanceDependence('substance_dependence', 'Dependência química'),
  depression('depression', 'Depressão'),
  anxiety('anxiety', 'Ansiedade'),
  suicideAttempts('suicide_attempts', 'Tentativas de suicídio'),
  psychiatricDisorders('psychiatric_disorders', 'Transtornos psiquiátricos'),
  abandonment('abandonment', 'Abandono'),
  seriousIllness('serious_illness', 'Doenças graves'),
  financialCrises('financial_crises', 'Crises financeiras'),
  abusiveRelationships('abusive_relationships', 'Relacionamentos abusivos'),
  emotionalRigidity('emotional_rigidity', 'Rigidez emocional'),
  perfectionism('perfectionism', 'Perfeccionismo'),
  excessiveCaretaking(
      'excessive_caretaking', 'Cuidar excessivamente dos outros');

  const TransgenerationalPattern(this.key, this.label);
  final String key;
  final String label;
}

/// Rótulo do gênero (mesmos valores do CHECK de `genogram_people.gender`).
String genderLabel(String? key) => switch (key) {
      'male' => 'Masculino',
      'female' => 'Feminino',
      'other' => 'Outro',
      _ => 'Não informado',
    };
