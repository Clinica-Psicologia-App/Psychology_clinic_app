import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_case_summary.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_data.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/consolidated_schema_row.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/clinical_impressions.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/initial_assessment.dart';
import 'package:terapia_esquema/features/patient_infographic/domain/patient_infographic_builder.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';

ClinicalDashboardData _dashboardWith(List<ConsolidatedSchemaRow> schemas) {
  return ClinicalDashboardData(
    patientName: 'Roberto',
    caseSummary: ClinicalCaseSummary.empty,
    callouts: const [],
    history: const [],
    consolidatedSchemas: schemas,
  );
}

void main() {
  final patient = Patient(
    id: 'p1',
    fullName: 'Roberto Silva',
    birthDate: DateTime(1986, 1, 1),
    occupation: 'Engenheiro',
  );

  test('esquemas vêm apenas dos ativados do dashboard consolidado', () {
    final dashboard = _dashboardWith(const [
      ConsolidatedSchemaRow(
        name: 'Abandono',
        code: 'ABANDONO',
        score: 5.2,
        responseId: 'r1',
        isAutoActivated: true,
      ),
      ConsolidatedSchemaRow(
        name: 'Autossacrifício',
        code: 'AUTOSSACRIFICIO',
        score: 2.0,
        responseId: 'r1',
        isAutoActivated: false,
      ),
    ]);

    final data = buildPatientInfographic(
      patient: patient,
      dashboard: dashboard,
      assessment: null,
      timelineEvents: const [],
    );

    expect(data.schemas.length, 1);
    expect(data.schemas.single.title, 'Abandono');
    // Descrição vem do catálogo Young quando disponível.
    expect(data.schemas.single.description, isNotNull);
  });

  test('necessidades/modos/pontos fortes/desafios/direções saem dos textos', () {
    const impressions = ClinicalImpressions(
      observedTemperament: 'Reservada e cautelosa. Segue outra frase aqui.',
      emotionalNeedsText: 'Ser aceita\nTer segurança',
      modeHypothesesText: 'Protetor distanciado — evita conflito',
      resources: 'Comunicação: expressa-se bem\nResiliência',
      vulnerabilities: 'Autocobrança: exige demais de si',
      therapeuticPriorities: 'Fortalecer autocuidado',
    );
    final assessment = InitialAssessment(
      patientId: 'p1',
      clinicalImpressions: impressions,
    );

    final data = buildPatientInfographic(
      patient: patient,
      dashboard: _dashboardWith(const []),
      assessment: assessment,
      timelineEvents: const [],
    );

    expect(data.needs.map((n) => n.need), ['Ser aceita', 'Ter segurança']);

    // "Título — descrição" vira título + descrição.
    expect(data.modes.single.title, 'Protetor distanciado');
    expect(data.modes.single.description, 'evita conflito');

    // "Título: descrição" também.
    expect(data.strengths.first.title, 'Comunicação');
    expect(data.strengths.first.description, 'expressa-se bem');
    expect(data.challenges.single.title, 'Autocobrança');
    expect(data.directions.single.title, 'Fortalecer autocuidado');

    // Citação = primeira frase do temperamento.
    expect(data.quote, 'Reservada e cautelosa.');
  });

  test('cabeçalho traz idade e avatar do paciente', () {
    final data = buildPatientInfographic(
      patient: patient,
      dashboard: _dashboardWith(const []),
      assessment: null,
      timelineEvents: const [],
    );

    expect(data.header.name, 'Roberto Silva');
    expect(data.header.avatarInitials, 'RS');
    expect(data.header.avatarType, patient.avatarType);
    expect(
      data.header.facts.any((f) => f.text.contains('anos')),
      isTrue,
    );
  });

  test('hasAnyContent e isSparse refletem o preenchimento', () {
    final empty = buildPatientInfographic(
      patient: patient,
      dashboard: _dashboardWith(const []),
      assessment: null,
      timelineEvents: const [],
    );
    expect(empty.hasAnyContent, isFalse);
    expect(empty.isSparse, isTrue);
    expect(empty.generatedOn, isNotNull);

    final rich = buildPatientInfographic(
      patient: patient,
      dashboard: _dashboardWith(const [
        ConsolidatedSchemaRow(
            name: 'Abandono',
            code: 'ABANDONO',
            score: 5,
            responseId: 'r1',
            isAutoActivated: true),
      ]),
      assessment: InitialAssessment(
        patientId: 'p1',
        clinicalImpressions: const ClinicalImpressions(
          emotionalNeedsText: 'A\nB',
          resources: 'X\nY',
          vulnerabilities: 'Z',
        ),
      ),
      timelineEvents: const [],
    );
    expect(rich.hasAnyContent, isTrue);
    expect(rich.contentSectionCount >= 3, isTrue);
  });

  test('seções respeitam o limite máximo de itens', () {
    final manyNeeds =
        List.generate(20, (i) => 'Necessidade $i').join('\n');
    final data = buildPatientInfographic(
      patient: patient,
      dashboard: _dashboardWith(const []),
      assessment: InitialAssessment(
        patientId: 'p1',
        clinicalImpressions: ClinicalImpressions(emotionalNeedsText: manyNeeds),
      ),
      timelineEvents: const [],
    );
    expect(data.needs.length, 6);
  });
}
