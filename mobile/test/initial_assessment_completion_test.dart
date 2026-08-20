// Cobre InitialAssessment.completionFraction — a fração que alimenta o anel
// de progresso do nó "Conhecendo você" na trilha do paciente. Bug corrigido:
// esse nó nunca teve nenhuma lógica de status/fração ligada (disponibilidade
// hardcoded), então sempre mostrava "Não iniciado" mesmo com campos
// preenchidos.
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/initial_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/patient_basics.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/patient_intake.dart';

void main() {
  test('total fixo é 24 (10 do Bloco 1 + 5 do Bloco 2 + 9 áreas do Bloco 3)',
      () {
    expect(InitialAssessment.totalFieldCount, 24);
  });

  test('nada preenchido: fração 0.0', () {
    const assessment = InitialAssessment(patientId: 'p1');
    expect(assessment.filledBlock1Count, 0);
    expect(assessment.filledBlock2Count, 0);
    expect(assessment.ratedAreasCount, 0);
    expect(assessment.completionFraction, 0.0);
  });

  test('Bloco 1 conta só campos preenchidos, campos vazios/nulos não contam',
      () {
    const assessment = InitialAssessment(
      patientId: 'p1',
      basics: PatientBasics(
        preferredName: 'Bia',
        occupation: 'Designer',
        // livesWith vazio (string em branco não deve contar)
        livesWith: '   ',
        // hasChildren respondido explicitamente como false — conta como
        // preenchido, não como "não respondido".
        hasChildren: false,
      ),
    );
    expect(assessment.filledBlock1Count, 3); // preferredName, occupation, hasChildren
  });

  test('Bloco 2: conta os 5 campos de intake preenchidos', () {
    const assessment = InitialAssessment(
      patientId: 'p1',
      intake: PatientIntake(
        reasonForSeeking: 'Ansiedade no trabalho',
        problemDuration: '6 meses',
      ),
    );
    expect(assessment.filledBlock2Count, 2);
  });

  test('Bloco 3: reaproveita ratedAreasCount (score != null)', () {
    const assessment = InitialAssessment(
      patientId: 'p1',
      lifeAreas: [
        LifeAreaAssessment(area: LifeArea.family, score: 7),
        LifeAreaAssessment(area: LifeArea.friends, score: 5),
        LifeAreaAssessment(area: LifeArea.workCareer), // sem score
      ],
    );
    expect(assessment.ratedAreasCount, 2);
  });

  test('fração combina os 3 blocos sobre o total fixo de 24', () {
    const assessment = InitialAssessment(
      patientId: 'p1',
      basics: PatientBasics(
        preferredName: 'Bia',
        occupation: 'Designer',
      ), // 2 de 10
      intake: PatientIntake(
        reasonForSeeking: 'Ansiedade',
      ), // 1 de 5
      lifeAreas: [
        LifeAreaAssessment(area: LifeArea.family, score: 7),
        LifeAreaAssessment(area: LifeArea.friends, score: 5),
        LifeAreaAssessment(area: LifeArea.selfCare, score: 3),
      ], // 3 de 9
    );
    // (2 + 1 + 3) / 24 = 0.25
    expect(assessment.completionFraction, closeTo(0.25, 1e-9));
  });

  test('todos os 24 campos preenchidos: fração 1.0', () {
    final assessment = InitialAssessment(
      patientId: 'p1',
      basics: const PatientBasics(
        preferredName: 'Bia',
        birthDate: null, // será substituído abaixo
      ),
      intake: const PatientIntake(
        reasonForSeeking: 'x',
        problemDuration: 'x',
        mainDiscomfort: 'x',
        expectations: 'x',
        relatedEvent: 'x',
      ),
      lifeAreas: [
        for (final area in kLifeAreasInOrder)
          LifeAreaAssessment(area: area, score: 5),
      ],
    );
    // Bloco 1 completo separadamente (birthDate precisa ser não-nulo).
    final fullAssessment = InitialAssessment(
      patientId: 'p1',
      basics: PatientBasics(
        preferredName: 'Bia',
        birthDate: DateTime(1990, 1, 1),
        occupation: 'Designer',
        livesWith: 'Sozinha',
        hasChildren: false,
        usesMedication: false,
        medicationNotes: 'N/A',
        psychiatricFollowup: false,
        psychiatristNotes: 'N/A',
        importantToKnow: 'Nada',
      ),
      intake: assessment.intake,
      lifeAreas: assessment.lifeAreas,
    );
    expect(fullAssessment.filledBlock1Count, 10);
    expect(fullAssessment.filledBlock2Count, 5);
    expect(fullAssessment.ratedAreasCount, 9);
    expect(fullAssessment.completionFraction, 1.0);
  });
}
