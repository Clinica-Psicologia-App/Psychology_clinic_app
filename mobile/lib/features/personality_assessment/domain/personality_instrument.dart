/// Catálogo de instrumentos de personalidade (estrutura de domínios/facetas).
/// Vive no app (não no banco) — o banco só guarda os resultados informados
/// pelo terapeuta, chaveados por estes códigos. Começa pelo NEO PI-R; novos
/// instrumentos entram aqui sem tocar no schema.
library;

/// Classificação qualitativa de um resultado (5 níveis). O terapeuta escolhe;
/// o app NUNCA converte número → classificação automaticamente.
enum PersonalityLevel {
  veryLow('very_low', 'Muito baixo'),
  low('low', 'Baixo'),
  medium('medium', 'Médio'),
  high('high', 'Alto'),
  veryHigh('very_high', 'Muito alto');

  const PersonalityLevel(this.code, this.label);

  final String code;
  final String label;

  /// Posição 0–4 (para o gráfico de faixas).
  int get position => index;

  static PersonalityLevel? fromCode(String? code) {
    if (code == null) return null;
    for (final l in PersonalityLevel.values) {
      if (l.code == code) return l;
    }
    return null;
  }
}

/// Uma faceta de um domínio (código estável + rótulo).
class PersonalityFacet {
  const PersonalityFacet(this.code, this.label);
  final String code;
  final String label;
}

/// Um domínio (fator) com suas facetas.
class PersonalityDomain {
  const PersonalityDomain(this.code, this.label, this.facets);
  final String code;
  final String label;
  final List<PersonalityFacet> facets;
}

/// Um instrumento: código, nome e estrutura de domínios.
class PersonalityInstrument {
  const PersonalityInstrument(this.code, this.name, this.domains);
  final String code;
  final String name;
  final List<PersonalityDomain> domains;
}

/// NEO PI-R — 5 domínios × 6 facetas (Big Five).
const PersonalityInstrument kNeoPiR = PersonalityInstrument(
  'NEO_PI_R',
  'NEO PI-R',
  [
    PersonalityDomain('neuroticism', 'Neuroticismo', [
      PersonalityFacet('anxiety', 'Ansiedade'),
      PersonalityFacet('anger', 'Raiva'),
      PersonalityFacet('depression', 'Depressão'),
      PersonalityFacet('self_consciousness', 'Embaraço'),
      PersonalityFacet('impulsiveness', 'Impulsividade'),
      PersonalityFacet('vulnerability', 'Vulnerabilidade'),
    ]),
    PersonalityDomain('extraversion', 'Extroversão', [
      PersonalityFacet('warmth', 'Acolhimento'),
      PersonalityFacet('gregariousness', 'Gregarismo'),
      PersonalityFacet('assertiveness', 'Assertividade'),
      PersonalityFacet('activity', 'Atividade'),
      PersonalityFacet('excitement_seeking', 'Busca de sensações'),
      PersonalityFacet('positive_emotions', 'Emoções positivas'),
    ]),
    PersonalityDomain('openness', 'Abertura à experiência', [
      PersonalityFacet('fantasy', 'Fantasia'),
      PersonalityFacet('aesthetics', 'Estética'),
      PersonalityFacet('feelings', 'Sentimentos'),
      PersonalityFacet('actions', 'Ações variadas'),
      PersonalityFacet('ideas', 'Ideias'),
      PersonalityFacet('values', 'Valores'),
    ]),
    PersonalityDomain('agreeableness', 'Amabilidade', [
      PersonalityFacet('trust', 'Confiança'),
      PersonalityFacet('straightforwardness', 'Franqueza'),
      PersonalityFacet('altruism', 'Altruísmo'),
      PersonalityFacet('compliance', 'Complacência'),
      PersonalityFacet('modesty', 'Modéstia'),
      PersonalityFacet('tender_mindedness', 'Sensibilidade'),
    ]),
    PersonalityDomain('conscientiousness', 'Conscienciosidade', [
      PersonalityFacet('competence', 'Competência'),
      PersonalityFacet('order', 'Ordem'),
      PersonalityFacet('dutifulness', 'Senso de dever'),
      PersonalityFacet('achievement_striving', 'Esforço por realizações'),
      PersonalityFacet('self_discipline', 'Autodisciplina'),
      PersonalityFacet('deliberation', 'Ponderação'),
    ]),
  ],
);

/// Instrumentos disponíveis (por ora, só o NEO PI-R).
const List<PersonalityInstrument> kPersonalityInstruments = [kNeoPiR];

PersonalityInstrument instrumentForCode(String? code) {
  for (final i in kPersonalityInstruments) {
    if (i.code == code) return i;
  }
  return kNeoPiR;
}
