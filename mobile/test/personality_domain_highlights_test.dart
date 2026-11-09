import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/personality_assessment/domain/personality_assessment.dart';
import 'package:terapia_esquema/features/personality_assessment/domain/personality_domain_highlights.dart';
import 'package:terapia_esquema/features/personality_assessment/domain/personality_instrument.dart';
import 'package:terapia_esquema/features/personality_reference/domain/personality_reference_content.dart';

void main() {
  final neuroticism = kNeoPiR.domains.first;

  ScoreEntry t(num score) => ScoreEntry(score: score);

  test('separa facetas altas, baixas e as demais pelo Escore T', () {
    final result = DomainResult(
      overall: t(62),
      facets: {
        'anxiety': t(64), // alto
        'anger': t(70), // muito alto
        'depression': t(50), // médio
        'vulnerability': t(40), // baixo
        'impulsiveness': t(25), // muito baixo
        // self_consciousness sem registro
      },
    );

    final h = PersonalityDomainHighlights.from(neuroticism, result);

    expect(h.highs.map((f) => f.facet.code), ['anxiety', 'anger']);
    expect(h.lows.map((f) => f.facet.code), ['impulsiveness', 'vulnerability']);
    expect(h.others.map((f) => f.facet.code),
        ['depression', 'self_consciousness']);
    expect(h.total, 6);
    expect(h.hasHighlights, isTrue);
  });

  test('guarda a posição da faceta no domínio para ligar ao guia clínico', () {
    final result = DomainResult(facets: {'vulnerability': t(40)});
    final h = PersonalityDomainHighlights.from(neuroticism, result);
    expect(h.lows.single.indexInDomain, 5);
  });

  test('domínio sem facetas altas ou baixas não tem destaques', () {
    final result = DomainResult(facets: {'anxiety': t(50), 'anger': t(48)});
    final h = PersonalityDomainHighlights.from(neuroticism, result);
    expect(h.hasHighlights, isFalse);
    expect(h.others.length, 6);
  });

  test('o guia clínico segue a mesma ordem de fatores e facetas do NEO PI-R', () {
    expect(personalityReferenceFactors.length, kNeoPiR.domains.length);
    for (var i = 0; i < kNeoPiR.domains.length; i++) {
      expect(
        personalityReferenceFactors[i].facets.length,
        kNeoPiR.domains[i].facets.length,
        reason: 'fator ${kNeoPiR.domains[i].label}',
      );
    }
    // Conferência de nome: o primeiro termo da faceta do guia começa com o
    // rótulo da faceta do instrumento (ex.: "Raiva/hostilidade" e "Raiva").
    for (var i = 0; i < kNeoPiR.domains.length; i++) {
      for (var j = 0; j < kNeoPiR.domains[i].facets.length; j++) {
        final instrument = kNeoPiR.domains[i].facets[j].label.toLowerCase();
        final guide =
            personalityReferenceFactors[i].facets[j].name.toLowerCase();
        expect(guide.startsWith(instrument), isTrue,
            reason: '"$guide" não corresponde a "$instrument"');
      }
    }
  });
}
