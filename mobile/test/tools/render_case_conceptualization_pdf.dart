// Gera um PDF de exemplo da Conceitualização de caso para inspeção visual.
// Não é um teste de asserção — só exercita o builder com dados realistas e
// grava o arquivo. Rode com: flutter test test/tools/render_case_conceptualization_pdf.dart
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/initial_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area_assessment.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_case_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_clinical_core.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_data.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_goal_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_problem_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_score_highlight.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_pdf.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('render sample conceptualization pdf', () async {
    final data = MentalMapData(
      patientName: 'Maria Silva',
      caseMap: MentalMapData.empty.caseMap,
      caseSummary: const MentalMapCaseSummary(
        intakeSummary: 'Procurou terapia por ansiedade e dificuldade em '
            'estabelecer limites no trabalho.',
        currentLifeContext: 'Mora sozinha, trabalha em regime híbrido.',
        therapyDemands: 'Reduzir autocrítica e melhorar relacionamentos.',
        centralHypotheses: [],
        currentFocuses: [],
      ),
      validationSummary: MentalMapData.empty.validationSummary,
      clinicalCore: const MentalMapClinicalCore(
        topSchemas: [
          MentalMapScoreHighlight(
              name: 'Padrões inflexíveis',
              code: 'PI',
              kind: 'schema',
              scoreLabel: 'alto',
              severityColorKey: 'error'),
          MentalMapScoreHighlight(
              name: 'Autossacrifício',
              code: 'AS',
              kind: 'schema',
              scoreLabel: 'moderado',
              severityColorKey: 'warning'),
        ],
        topModes: [
          MentalMapScoreHighlight(
              name: 'Protetor Desligado', code: 'PD', kind: 'mode'),
          MentalMapScoreHighlight(
              name: 'Crítico Punitivo', code: 'CP', kind: 'mode'),
        ],
        topProblemsByIntensity: [],
        attachmentStyles: [],
        copingStyles: [],
      ),
      historyLinks: MentalMapData.empty.historyLinks,
      therapyPlan: MentalMapData.empty.therapyPlan,
      questionnaires: const [],
      activeProblems: const [
        MentalMapProblemSummary(
            id: '1',
            title: 'Sobrecarga no trabalho',
            intensity: 8,
            statusLabel: 'ativo'),
        MentalMapProblemSummary(
            id: '2',
            title: 'Isolamento social',
            intensity: 5,
            statusLabel: 'ativo'),
      ],
      activeGoals: const [
        MentalMapGoalSummary(
            id: '1',
            title: 'Dizer não a demandas fora do horário',
            statusLabel: 'ativo',
            targetDateLabel: 'até nov/2026'),
        MentalMapGoalSummary(
            id: '2', title: 'Retomar contato com amigos', statusLabel: 'ativo'),
      ],
      recentMonitors: const [],
      recentTimelineEvents: const [],
      genogram: MentalMapData.empty.genogram,
    );

    const concept = CaseConceptualization(
      unmetNeeds: [
        UnmetNeed(
            needKey: 'conexao',
            rating: '1',
            origin: 'Pais emocionalmente distantes.',
            schemas: 'Privação emocional'),
        UnmetNeed(
            needKey: 'limites',
            rating: '4',
            origin: 'Ambiente sem estrutura.',
            schemas: 'Padrões inflexíveis'),
      ],
      modeSequences: [
        ModeSequence(
          trigger: 'Crítica do chefe',
          activatedModes: 'Criança Vulnerável',
          copingMode: 'Protetor Desligado',
          sequence: 'Crítica → retração → isolamento',
          effect: 'Afasta-se da equipe',
          perpetuation: 'Confirma que não pode contar com ninguém',
        ),
      ],
      relationship: TherapeuticRelationship(
        collaborationRating: 3,
        collaborationNotes: 'Engaja, mas evita temas dolorosos.',
        bondRating: 4,
        bondNotes: 'Vínculo crescente.',
        therapistReactions: 'Vontade de proteger.',
      ),
      generalImpressions: GeneralImpressions(
        initial: 'Reservada, fala pouco de si.',
        current: 'Mais aberta, traz temas espontaneamente.',
      ),
      diagnosis: Diagnosis(
        system: 'CID-11',
        items: [
          DiagnosisItem(
              name: 'Transtorno de ansiedade generalizada', code: '6B00'),
        ],
      ),
      additionalComments: 'Reavaliar conceitualização após 10 sessões.',
    );

    final assessment = InitialAssessment(
      patientId: 'p1',
      lifeAreas: const [
        LifeAreaAssessment(area: LifeArea.workCareer, score: 6),
        LifeAreaAssessment(area: LifeArea.loveRomance, score: 3),
        LifeAreaAssessment(area: LifeArea.family, score: 4),
        LifeAreaAssessment(area: LifeArea.emotionalHealth, score: 2),
        LifeAreaAssessment(area: LifeArea.selfCare, score: 8),
      ],
    );

    final bytes = await CaseConceptualizationPdf.build(
      data: data,
      concept: concept,
      assessment: assessment,
    );

    final out = File('build/case_conceptualization_sample.pdf');
    await out.parent.create(recursive: true);
    await out.writeAsBytes(bytes, flush: true);
    // ignore: avoid_print
    print('PDF: ${out.absolute.path} (${bytes.length} bytes)');
    expect(bytes.length, greaterThan(1000));
  });
}
