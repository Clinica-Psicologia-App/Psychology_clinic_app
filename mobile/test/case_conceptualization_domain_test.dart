import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';

void main() {
  group('CaseConceptualization fromJson', () {
    test('lê origins (7.1/7.3/7.4), motivo_notes e demais seções', () {
      final c = CaseConceptualization.fromJson({
        'general_impressions': {'initial': 'reservada', 'current': 'aberta'},
        'diagnosis': {
          'system': 'CID-11',
          'items': [
            {'name': 'TAG', 'code': '6B00'}
          ]
        },
        'origins': {
          'early_history': 'pais distantes',
          'temperament': 'sensível',
          'cultural': 'ênfase em status',
        },
        'motivo_notes': 'complemento do terapeuta',
        'additional_comments': 'reavaliar',
      });

      expect(c.generalImpressions.initial, 'reservada');
      expect(c.diagnosis.system, 'CID-11');
      expect(c.diagnosis.items.single.code, '6B00');
      expect(c.origins.earlyHistory, 'pais distantes');
      expect(c.origins.temperament, 'sensível');
      expect(c.origins.cultural, 'ênfase em status');
      expect(c.motivoNotes, 'complemento do terapeuta');
      expect(c.additionalComments, 'reavaliar');
      expect(c.hasOrigins, isTrue);
      expect(c.hasMotivoNotes, isTrue);
    });

    test('documento vazio: getters has* são falsos', () {
      final c = CaseConceptualization.empty();
      expect(c.hasOrigins, isFalse);
      expect(c.hasMotivoNotes, isFalse);
      expect(c.hasGeneralImpressions, isFalse);
      expect(c.hasDiagnosis, isFalse);
      expect(c.hasComments, isFalse);
      // As 9 necessidades essenciais entram em branco.
      expect(c.unmetNeeds.length, kCoreNeeds.length);
      expect(c.hasAnyNeed, isFalse);
    });
  });

  group('CaseOrigins', () {
    test('toJson omite vazios e trima', () {
      const o = CaseOrigins(earlyHistory: '  história  ', temperament: '   ');
      final j = o.toJson();
      expect(j['early_history'], 'história');
      expect(j.containsKey('temperament'), isFalse);
      expect(j.containsKey('cultural'), isFalse);
    });

    test('isEmpty', () {
      expect(const CaseOrigins().isEmpty, isTrue);
      expect(const CaseOrigins(cultural: 'x').isEmpty, isFalse);
    });
  });

  // ── SEÇÃO 5 ──────────────────────────────────────────────────────────────

  group('FunctioningAssessment (seção 5)', () {
    test('fromJson lê entradas por área', () {
      final f = FunctioningAssessment.fromJson({
        'occupational': {'rating': 3, 'explanation': 'dificuldades no trabalho'},
        'social_relationships': {'rating': 5},
      });
      expect(f.entryFor('occupational').rating, 3);
      expect(f.entryFor('occupational').explanation, 'dificuldades no trabalho');
      expect(f.entryFor('social_relationships').rating, 5);
      expect(f.entryFor('intimate_relationships').isEmpty, isTrue);
      expect(f.isEmpty, isFalse);
    });

    test('toJson omite entradas vazias', () {
      final f = FunctioningAssessment(entries: {
        'occupational': const FunctioningEntry(rating: 2),
        'family_relationships': const FunctioningEntry(),
      });
      final j = f.toJson();
      expect(j.containsKey('occupational'), isTrue);
      expect(j.containsKey('family_relationships'), isFalse);
    });

    test('roundtrip fromJson → toJson', () {
      final original = FunctioningAssessment(entries: {
        'occupational': const FunctioningEntry(rating: 4, explanation: 'ok'),
      });
      final restored = FunctioningAssessment.fromJson(original.toJson());
      expect(restored.entryFor('occupational').rating, 4);
      expect(restored.entryFor('occupational').explanation, 'ok');
    });

    test('CaseConceptualization.fromJson popula functioning', () {
      final c = CaseConceptualization.fromJson({
        'functioning': {'occupational': {'rating': 1}},
      });
      expect(c.hasFunctioning, isTrue);
      expect(c.functioning.entryFor('occupational').rating, 1);
    });

    test('isEmpty quando vazio', () {
      expect(const FunctioningAssessment().isEmpty, isTrue);
    });
  });

  // ── SEÇÃO 6 ──────────────────────────────────────────────────────────────

  group('TherapistLifeProblems (seção 6)', () {
    test('fromJson lê até 4 problemas', () {
      final lp = TherapistLifeProblems.fromJson({
        'problem1': 'ansiedade social',
        'problem2': 'conflitos conjugais',
        'problem3': null,
        'problem4': null,
      });
      expect(lp.problem1, 'ansiedade social');
      expect(lp.problem2, 'conflitos conjugais');
      expect(lp.problem3, isNull);
      expect(lp.isEmpty, isFalse);
    });

    test('toJson omite nulos e vazios, trima', () {
      const lp = TherapistLifeProblems(
        problem1: '  isolamento  ',
        problem2: '',
        problem3: null,
      );
      final j = lp.toJson();
      expect(j['problem1'], 'isolamento');
      expect(j.containsKey('problem2'), isFalse);
      expect(j.containsKey('problem3'), isFalse);
    });

    test('isEmpty quando todos nulos', () {
      expect(const TherapistLifeProblems().isEmpty, isTrue);
    });

    test('CaseConceptualization.fromJson popula lifeProblems', () {
      final c = CaseConceptualization.fromJson({
        'life_problems': {'problem1': 'procrastinação'},
      });
      expect(c.hasLifeProblems, isTrue);
      expect(c.lifeProblems.problem1, 'procrastinação');
    });
  });

  // ── SEÇÃO 8 ──────────────────────────────────────────────────────────────

  group('CentralSchemaEntry (seção 8)', () {
    test('fromJson lê nome e descrição', () {
      final e = CentralSchemaEntry.fromJson({
        'name': 'Abandono',
        'description': 'Medo de perder vínculos',
      });
      expect(e.name, 'Abandono');
      expect(e.description, 'Medo de perder vínculos');
      expect(e.isEmpty, isFalse);
    });

    test('toJson omite vazios e trima', () {
      const e = CentralSchemaEntry(name: '  Desconfiança  ', description: '');
      final j = e.toJson();
      expect(j['name'], 'Desconfiança');
      expect(j.containsKey('description'), isFalse);
    });

    test('CaseConceptualization.fromJson popula 6 slots de centralSchemas', () {
      final c = CaseConceptualization.fromJson({
        'central_schemas': [
          {'name': 'Abandono'},
          {'name': 'Desconfiança'},
        ],
      });
      expect(c.hasCentralSchemas, isTrue);
      expect(c.centralSchemas.first.name, 'Abandono');
    });

    test('centralSchemas default tem 6 entradas vazias quando JSON vazio', () {
      final c = CaseConceptualization.fromJson({});
      expect(c.centralSchemas.length, 6);
      expect(c.hasCentralSchemas, isFalse);
    });

    test('centralSchemasJson omite entradas vazias', () {
      final c = CaseConceptualization.fromJson({
        'central_schemas': [
          {'name': 'Abandono'},
          {},
        ],
      });
      final j = c.centralSchemasJson();
      expect(j.length, 1);
      expect(j.first['name'], 'Abandono');
    });
  });

  // ── SEÇÃO 9 ──────────────────────────────────────────────────────────────

  group('SchemaModeAssessment (seção 9)', () {
    test('fromJson lê healthyModes', () {
      final ma = SchemaModeAssessment.fromJson({
        'healthy_modes': {
          'happy_child_spontaneity': 'presente em contextos seguros',
          'adult_hope': 'emergente',
        },
      });
      expect(ma.healthyModes.happyChildSpontaneity,
          'presente em contextos seguros');
      expect(ma.healthyModes.adultHope, 'emergente');
      expect(ma.isEmpty, isFalse);
    });

    test('fromJson lê vulnerableChild com exemplos', () {
      final ma = SchemaModeAssessment.fromJson({
        'vulnerable_child': {
          'description': 'criança assustada',
          'schemas': 'Abandono, Privação',
          'examples': [
            {'trigger': 'crítica do chefe', 'experience': 'vergonha'},
          ],
        },
      });
      expect(ma.vulnerableChild.description, 'criança assustada');
      expect(ma.vulnerableChild.examples.single.trigger, 'crítica do chefe');
    });

    test('fromJson lê parentalModes e copingModes', () {
      final ma = SchemaModeAssessment.fromJson({
        'parental_modes': [
          {'name': 'Pai Punitivo', 'messages': 'você não presta'},
        ],
        'coping_modes': [
          {'category': 'Rendição', 'name': 'Capitulação', 'example': 'aceita crítica sem questionar'},
        ],
      });
      expect(ma.parentalModes.single.name, 'Pai Punitivo');
      expect(ma.parentalModes.single.messages, 'você não presta');
      expect(ma.copingModes.single.category, 'Rendição');
      expect(ma.copingModes.single.name, 'Capitulação');
    });

    test('isEmpty quando tudo vazio', () {
      expect(const SchemaModeAssessment().isEmpty, isTrue);
    });

    test('CaseConceptualization.fromJson popula modeAssessment', () {
      final c = CaseConceptualization.fromJson({
        'mode_assessment': {
          'healthy_modes': {'adult_hope': 'crescente'},
        },
      });
      expect(c.hasModeAssessment, isTrue);
      expect(c.modeAssessment.healthyModes.adultHope, 'crescente');
    });
  });

  // ── SEÇÃO 12 ─────────────────────────────────────────────────────────────

  group('TherapyObjectiveEntry (seção 12)', () {
    test('fromJson lê todos os campos', () {
      final o = TherapyObjectiveEntry.fromJson({
        'goal': 'Reduzir ansiedade social',
        'schemas_modes': 'Abandono, Criança vulnerável',
        'healthy_behaviors': 'Manter contatos sociais semanais',
        'interventions': 'Reparentalização, exposição gradual',
        'progress': 'Iniciando',
      });
      expect(o.goal, 'Reduzir ansiedade social');
      expect(o.schemasModes, 'Abandono, Criança vulnerável');
      expect(o.healthyBehaviors, 'Manter contatos sociais semanais');
      expect(o.interventions, 'Reparentalização, exposição gradual');
      expect(o.progress, 'Iniciando');
      expect(o.isEmpty, isFalse);
    });

    test('toJson omite vazios e trima', () {
      const o = TherapyObjectiveEntry(goal: '  Meta 1  ', schemasModes: '');
      final j = o.toJson();
      expect(j['goal'], 'Meta 1');
      expect(j.containsKey('schemas_modes'), isFalse);
    });

    test('isEmpty quando todos nulos', () {
      expect(const TherapyObjectiveEntry().isEmpty, isTrue);
    });

    test('CaseConceptualization.fromJson popula therapyObjectives', () {
      final c = CaseConceptualization.fromJson({
        'therapy_objectives': [
          {'goal': 'Meta principal'},
        ],
      });
      expect(c.hasTherapyObjectives, isTrue);
      expect(c.therapyObjectives.first.goal, 'Meta principal');
    });

    test('therapyObjectives default tem 5 entradas vazias quando JSON vazio', () {
      final c = CaseConceptualization.fromJson({});
      expect(c.therapyObjectives.length, 5);
      expect(c.hasTherapyObjectives, isFalse);
    });

    test('therapyObjectivesJson omite entradas vazias', () {
      final c = CaseConceptualization.fromJson({
        'therapy_objectives': [
          {'goal': 'Meta A'},
          {},
        ],
      });
      final j = c.therapyObjectivesJson();
      expect(j.length, 1);
      expect(j.first['goal'], 'Meta A');
    });
  });

  // ── has* getters ──────────────────────────────────────────────────────────

  group('has* getters das novas seções', () {
    test('todos falsos no documento vazio', () {
      final c = CaseConceptualization.empty();
      expect(c.hasFunctioning, isFalse);
      expect(c.hasLifeProblems, isFalse);
      expect(c.hasCentralSchemas, isFalse);
      expect(c.hasModeAssessment, isFalse);
      expect(c.hasTherapyObjectives, isFalse);
    });
  });
}
