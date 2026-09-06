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
  // ── totalFieldCount dinâmico ────────────────────────────────────────────

  test('sem basics: total mínimo = 22 (8 fixos + 5 bloco2 + 9 áreas)', () {
    const assessment = InitialAssessment(patientId: 'p1');
    expect(assessment.totalFieldCount, 22);
  });

  test('usesMedication=true: total sobe para 23', () {
    const assessment = InitialAssessment(
      patientId: 'p1',
      basics: PatientBasics(usesMedication: true),
    );
    expect(assessment.totalFieldCount, 23);
  });

  test('usesMedication=true + psychiatricFollowup=true: total sobe para 24',
      () {
    const assessment = InitialAssessment(
      patientId: 'p1',
      basics: PatientBasics(usesMedication: true, psychiatricFollowup: true),
    );
    expect(assessment.totalFieldCount, 24);
  });

  // ── filledBlock1Count ───────────────────────────────────────────────────

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
        livesWith: '   ', // string em branco não conta
        hasChildren: false, // false explícito conta como respondido
      ),
    );
    expect(assessment.filledBlock1Count, 3); // preferredName, occupation, hasChildren
  });

  test('medicationNotes só conta quando usesMedication=true', () {
    // usesMedication=false: a nota não é aplicável e não conta
    const semMedicacao = InitialAssessment(
      patientId: 'p1',
      basics: PatientBasics(
        usesMedication: false,
        medicationNotes: 'preenchido mas não aplicável',
      ),
    );
    expect(semMedicacao.filledBlock1Count, 1); // só usesMedication conta

    // usesMedication=true: a nota é aplicável e conta quando preenchida
    const comMedicacao = InitialAssessment(
      patientId: 'p1',
      basics: PatientBasics(
        usesMedication: true,
        medicationNotes: 'Ritalina 10mg',
      ),
    );
    expect(comMedicacao.filledBlock1Count, 2); // usesMedication + medicationNotes
  });

  test('psychiatristNotes só conta quando psychiatricFollowup=true', () {
    const semAcompanhamento = InitialAssessment(
      patientId: 'p1',
      basics: PatientBasics(
        psychiatricFollowup: false,
        psychiatristNotes: 'preenchido mas não aplicável',
      ),
    );
    expect(semAcompanhamento.filledBlock1Count, 1);

    const comAcompanhamento = InitialAssessment(
      patientId: 'p1',
      basics: PatientBasics(
        psychiatricFollowup: true,
        psychiatristNotes: 'Dra. Silva',
      ),
    );
    expect(comAcompanhamento.filledBlock1Count, 2);
  });

  // ── Blocos 2 e 3 ───────────────────────────────────────────────────────

  test('Bloco 2: conta os campos de intake preenchidos', () {
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

  // ── completionFraction ─────────────────────────────────────────────────

  test('fração usa o total dinâmico (sem campos condicionais = 22)', () {
    const assessment = InitialAssessment(
      patientId: 'p1',
      basics: PatientBasics(
        preferredName: 'Bia',
        occupation: 'Designer',
      ), // 2 de 8 fixos
      intake: PatientIntake(
        reasonForSeeking: 'Ansiedade',
      ), // 1 de 5
      lifeAreas: [
        LifeAreaAssessment(area: LifeArea.family, score: 7),
        LifeAreaAssessment(area: LifeArea.friends, score: 5),
        LifeAreaAssessment(area: LifeArea.selfCare, score: 3),
      ], // 3 de 9
    );
    // (2 + 1 + 3) / 22 ≈ 0.2727
    expect(assessment.totalFieldCount, 22);
    expect(assessment.completionFraction, closeTo(6 / 22, 1e-9));
  });

  test(
      'paciente sem medicação nem psiquiatra consegue chegar a 100% — bug 88%',
      () {
    // Bug original: medicationNotes e psychiatristNotes eram contados no
    // denominador mesmo quando o paciente disse que não usa medicação e não
    // tem acompanhamento, impedindo de chegar a 100%.
    final fullAssessment = InitialAssessment(
      patientId: 'p1',
      basics: PatientBasics(
        preferredName: 'Bia',
        birthDate: DateTime(1990, 1, 1),
        occupation: 'Designer',
        livesWith: 'Sozinha',
        hasChildren: false,
        usesMedication: false, // notas NÃO entram no total
        psychiatricFollowup: false, // notas NÃO entram no total
        importantToKnow: 'Nada',
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
    expect(fullAssessment.filledBlock1Count, 8); // 8 campos fixos
    expect(fullAssessment.totalFieldCount, 22); // sem os condicionais
    expect(fullAssessment.completionFraction, 1.0);
  });

  test('paciente com medicação e psiquiatra: total 24, fração 1.0 quando tudo preenchido',
      () {
    final fullAssessment = InitialAssessment(
      patientId: 'p1',
      basics: PatientBasics(
        preferredName: 'Bia',
        birthDate: DateTime(1990, 1, 1),
        occupation: 'Designer',
        livesWith: 'Sozinha',
        hasChildren: false,
        usesMedication: true,
        medicationNotes: 'Ritalina',
        psychiatricFollowup: true,
        psychiatristNotes: 'Dra. Silva',
        importantToKnow: 'Nada',
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
    expect(fullAssessment.filledBlock1Count, 10);
    expect(fullAssessment.totalFieldCount, 24);
    expect(fullAssessment.completionFraction, 1.0);
  });
}
