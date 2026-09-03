import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/personality_assessment/domain/personality_assessment.dart';
import 'package:terapia_esquema/features/personality_assessment/domain/personality_instrument.dart';

void main() {
  group('PersonalityResults', () {
    test('round-trip preserva domínios e facetas (score + classification)', () {
      const results = PersonalityResults(domains: {
        'neuroticism': DomainResult(
          overall: ScoreEntry(score: 52, level: PersonalityLevel.medium),
          facets: {
            'anxiety': ScoreEntry(score: 63, level: PersonalityLevel.high),
          },
        ),
      });

      final json = results.toJson();
      final back = PersonalityResults.fromJson(json);

      expect(back.forDomain('neuroticism').overall.score, 52);
      expect(back.forDomain('neuroticism').overall.level,
          PersonalityLevel.medium);
      expect(back.forDomain('neuroticism').facet('anxiety').level,
          PersonalityLevel.high);
      expect(back.forDomain('neuroticism').facet('anxiety').score, 63);
    });

    test('entradas vazias não são serializadas', () {
      const results = PersonalityResults(domains: {
        'neuroticism': DomainResult(),
      });
      final json = results.toJson();
      expect((json['domains'] as Map).isEmpty, isTrue);
    });

    test('toJson omite score nulo mas mantém classification', () {
      const e = ScoreEntry(level: PersonalityLevel.low);
      final j = e.toJson();
      expect(j.containsKey('score'), isFalse);
      expect(j['classification'], 'low');
    });
  });

  group('ClinicalSynthesis', () {
    test('round-trip + isEmpty', () {
      expect(const ClinicalSynthesis().isEmpty, isTrue);
      const s = ClinicalSynthesis(understanding: 'x', hypotheses: 'y');
      final back = ClinicalSynthesis.fromJson(s.toJson());
      expect(back.understanding, 'x');
      expect(back.hypotheses, 'y');
      expect(back.relevant, isNull);
      expect(back.isEmpty, isFalse);
    });
  });

  group('ConceptualizationIntegration', () {
    test('round-trip com status + links + note', () {
      const i = ConceptualizationIntegration(
        status: IntegrationStatus.yes,
        links: {IntegrationLink.schemas, IntegrationLink.temperament},
        note: 'nota',
      );
      final back = ConceptualizationIntegration.fromJson(i.toJson());
      expect(back.status, IntegrationStatus.yes);
      expect(back.links, contains(IntegrationLink.schemas));
      expect(back.links, contains(IntegrationLink.temperament));
      expect(back.note, 'nota');
    });

    test('códigos desconhecidos em links são ignorados', () {
      final back = ConceptualizationIntegration.fromJson({
        'status': 'yes',
        'links': ['schemas', 'inexistente'],
      });
      expect(back.links.length, 1);
      expect(back.links.first, IntegrationLink.schemas);
    });
  });

  group('PersonalityAssessment.fromPatientView', () {
    test('lê só classificação (sem síntese) e marca shared', () {
      final a = PersonalityAssessment.fromPatientView({
        'id': 'a1',
        'patient_id': 'p1',
        'instrument': 'NEO_PI_R',
        'applied_on': '2026-01-10',
        'updated_at': '2026-02-01T10:00:00Z',
        'results': {
          'domains': {
            'neuroticism': {'classification': 'medium'}
          }
        },
      });
      expect(a.sharedWithPatient, isTrue);
      expect(a.results.forDomain('neuroticism').overall.level,
          PersonalityLevel.medium);
      expect(a.results.forDomain('neuroticism').overall.score, isNull);
      expect(a.hasSynthesis, isFalse);
      expect(a.hasIntegration, isFalse);
    });
  });

  test('catálogo NEO PI-R tem 5 domínios × 6 facetas', () {
    expect(kNeoPiR.domains.length, 5);
    for (final d in kNeoPiR.domains) {
      expect(d.facets.length, 6, reason: '${d.code} deve ter 6 facetas');
    }
  });
}
