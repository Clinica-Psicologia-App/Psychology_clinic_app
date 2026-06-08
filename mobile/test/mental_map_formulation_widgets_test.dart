import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_check_in_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_clinical_core.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_goal_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_history_links.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_problem_summary.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_score_highlight.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_therapy_plan.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_therapy_plan_builder.dart';
import 'package:terapia_esquema/features/mental_map/presentation/widgets/mental_map_formulation_widgets.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

void main() {
  testWidgets('MentalMapFormulationTabs switches between layers', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MentalMapFormulationTabs(
              clinicalCore: const MentalMapClinicalCore(
                topSchemas: [
                  MentalMapScoreHighlight(
                    name: 'Abandono',
                    code: 'ABN',
                    kind: 'schema',
                    score: 5.8,
                  ),
                ],
                topModes: [],
                topProblemsByIntensity: [],
                attachmentStyles: [],
                copingStyles: [],
              ),
              historyLinks: MentalMapHistoryLinks.empty,
              therapyPlan: MentalMapTherapyPlan.empty,
              role: ProfileRole.patient,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Abandono'), findsOneWidget);

    await tester.tap(find.text('Plano'));
    await tester.pumpAndSettle();

    expect(find.text('Plano terapêutico vazio'), findsOneWidget);
  });

  testWidgets('MentalMapCheckInSparklineChart renders with data', (tester) async {
    final sparkline = buildCheckInSparkline([
      MentalMapCheckInSummary(
        id: 'c1',
        moodScore: 4,
        anxietyScore: 7,
        checkedInAt: DateTime(2025, 6, 2),
      ),
      MentalMapCheckInSummary(
        id: 'c2',
        moodScore: 6,
        anxietyScore: 5,
        checkedInAt: DateTime(2025, 6, 3),
      ),
    ]);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MentalMapCheckInSparklineChart(sparkline: sparkline),
        ),
      ),
    );

    expect(find.text('Humor'), findsOneWidget);
    expect(find.text('Ansiedade'), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
  });

  testWidgets('MentalMapHistoryLinksSection masks sensitive timeline title',
      (tester) async {
    const history = MentalMapHistoryLinks(
      timelineEvents: [
        MentalMapTimelineHighlight(
          id: 'e1',
          displayTitle: 'Evento sensível',
          dateLabel: '01/01/2025',
          isSensitive: true,
        ),
      ],
      genogramPeople: [],
      genogramRelationships: [],
      parentalFigures: [],
      sensitiveItemCount: 1,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MentalMapHistoryLinksSection(
              history: history,
              role: ProfileRole.patient,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Evento sensível'), findsOneWidget);
    expect(find.byIcon(Icons.lock_outline), findsWidgets);
  });

  testWidgets('MentalMapTherapyPlanSection shows goals and problems side data',
      (tester) async {
    const plan = MentalMapTherapyPlan(
      activeGoals: [
        MentalMapGoalSummary(
          id: 'g1',
          title: 'Autocompaixão',
          statusLabel: 'Ativo',
        ),
      ],
      activeProblems: [
        MentalMapProblemSummary(
          id: 'p1',
          title: 'Ansiedade',
          statusLabel: 'Ativo',
        ),
      ],
      recentCheckIns: [],
      sparkline: MentalMapCheckInSparkline.empty,
      resources: MentalMapResourcesSummary.empty,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: MentalMapTherapyPlanSection(
              plan: plan,
              role: ProfileRole.patient,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Autocompaixão'), findsOneWidget);
    expect(find.text('Ansiedade'), findsOneWidget);
  });
}
