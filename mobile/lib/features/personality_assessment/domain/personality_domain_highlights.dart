import 'personality_assessment.dart';
import 'personality_instrument.dart';

/// Uma faceta com o resultado registrado (ou vazio, se não houver).
class PersonalityFacetResult {
  const PersonalityFacetResult({
    required this.facet,
    required this.indexInDomain,
    required this.entry,
  });

  final PersonalityFacet facet;

  /// Posição da faceta no domínio (liga ao cartão do guia clínico).
  final int indexInDomain;
  final ScoreEntry entry;
}

/// Facetas de um domínio separadas pelo que se destacou: altas, baixas e as
/// demais (nível médio ou sem registro).
class PersonalityDomainHighlights {
  const PersonalityDomainHighlights({
    required this.highs,
    required this.lows,
    required this.others,
  });

  final List<PersonalityFacetResult> highs;
  final List<PersonalityFacetResult> lows;
  final List<PersonalityFacetResult> others;

  int get total => highs.length + lows.length + others.length;

  bool get hasHighlights => highs.isNotEmpty || lows.isNotEmpty;

  factory PersonalityDomainHighlights.from(
    PersonalityDomain domain,
    DomainResult result,
  ) {
    final highs = <PersonalityFacetResult>[];
    final lows = <PersonalityFacetResult>[];
    final others = <PersonalityFacetResult>[];
    for (var i = 0; i < domain.facets.length; i++) {
      final facet = domain.facets[i];
      final item = PersonalityFacetResult(
        facet: facet,
        indexInDomain: i,
        entry: result.facet(facet.code),
      );
      switch (item.entry.level) {
        case PersonalityLevel.high:
        case PersonalityLevel.veryHigh:
          highs.add(item);
        case PersonalityLevel.low:
        case PersonalityLevel.veryLow:
          lows.add(item);
        case PersonalityLevel.medium:
        case null:
          others.add(item);
      }
    }
    return PersonalityDomainHighlights(
      highs: highs,
      lows: lows,
      others: others,
    );
  }
}
