import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/psychoeducation/domain/exercise_definition.dart';
import 'package:terapia_esquema/features/psychoeducation/domain/psychoeducation_module.dart';
import 'package:terapia_esquema/features/psychoeducation/presentation/psychoeducation_patient_exercises_page.dart';
import 'package:terapia_esquema/features/psychoeducation/providers/psychoeducation_providers.dart';

void main() {
  testWidgets('renders prompts, lists, other, closing and saved date read-only',
      (tester) async {
    final response = ExerciseResponse(
      id: 'response',
      patientId: 'profile',
      moduleId: 'module13',
      responses: {
        's1_situation': 'Resposta sintética',
        's1_areas': ['Família', 'Trabalho/Estudos'],
        's1_areas_other': 'Outro contexto'
      },
      difficultyScale: 'Interessante, mas desafiador',
      wantsToTalk: true,
      updatedAt: DateTime(2026, 10, 21, 12),
    );
    await tester.pumpWidget(ProviderScope(
        overrides: [
          patientExerciseResponsesProvider('record')
              .overrideWith((ref) async => [response]),
          psychoeducationJourneyProvider.overrideWith((ref) async => [
                const PsychoeducationModule(
                    id: 'module13',
                    number: 13,
                    stage: 'Praticar',
                    title: 'Módulo'),
              ]),
        ],
        child: const MaterialApp(
            home: PsychoeducationPatientExercisesPage(patientId: 'record'))));
    await tester.pumpAndSettle();
    expect(find.text('Um padrão que percebo em mim:'), findsOneWidget);
    expect(find.text('Resposta sintética'), findsOneWidget);
    expect(find.text('Família\nTrabalho/Estudos'), findsOneWidget);
    expect(find.text('Outro contexto'), findsOneWidget);
    expect(find.textContaining('2026'), findsOneWidget);
    expect(find.text('Quer conversar na sessão: Sim'), findsOneWidget);
    expect(find.byType(TextField), findsNothing);
  });

  testWidgets('empty response state', (tester) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          patientExerciseResponsesProvider('record')
              .overrideWith((ref) async => []),
          psychoeducationJourneyProvider.overrideWith((ref) async => [
                const PsychoeducationModule(
                    id: 'module13',
                    number: 13,
                    stage: 'Praticar',
                    title: 'Módulo'),
              ]),
        ],
        child: const MaterialApp(
            home: PsychoeducationPatientExercisesPage(patientId: 'record'))));
    await tester.pumpAndSettle();
    expect(find.text('Este paciente ainda não respondeu exercícios.'),
        findsOneWidget);
  });
}
