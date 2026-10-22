// Telas do app para o site de divulgação — widgets reais, tema real e dados
// 100% fictícios (nenhum paciente de verdade).
//
//   flutter test test/tools/render_marketing_screens.dart
//
// Saída: build/marketing/*.png (1170x2532, tamanho de celular @3x)
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:terapia_esquema/core/theme/app_colors.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/clinic_entitlements/domain/clinic_feature_entitlement.dart';
import 'package:terapia_esquema/features/clinic_entitlements/providers/clinic_entitlements_providers.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_case_summary.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_score_row.dart';
import 'package:terapia_esquema/features/clinical_dashboard/presentation/widgets/clinical_dashboard_widgets.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/initial_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/presentation/initial_assessment_context_page.dart';
import 'package:terapia_esquema/features/initial_assessment/providers/initial_assessment_providers.dart';
import 'package:terapia_esquema/features/mental_map/data/case_conceptualization_repository.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/mental_map/domain/demands_text_history.dart';
import 'package:terapia_esquema/features/mental_map/providers/case_conceptualization_providers.dart';
import 'package:terapia_esquema/features/patient_problems/providers/patient_problems_providers.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/presentation/widgets/future_modules_section.dart';
import 'package:terapia_esquema/features/patients/presentation/widgets/patient_context_header.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/therapy_demands/presentation/therapy_demands_page.dart';

class _FakeRepo implements CaseConceptualizationRepository {
  _FakeRepo(this.doc);
  final CaseConceptualization doc;

  @override
  Future<CaseConceptualization> load(String patientId) async => doc;
  @override
  Future<DemandsTextHistory> loadDemandsHistory(String patientId) async =>
      DemandsTextHistory.empty;
  @override
  Future<void> save(String patientId, CaseConceptualization data) async {}
  @override
  Future<void> saveReasons(String patientId,
      {required String? initial,
      required String? current,
      String? previousInitial,
      String? previousCurrent,
      String? authorName}) async {}
  @override
  Future<void> saveImpressions(String patientId, GeneralImpressions value,
      {GeneralImpressions previous = const GeneralImpressions(),
      String? authorName}) async {}
  @override
  Future<Diagnosis> saveDiagnosis(String patientId, Diagnosis next,
          {required Diagnosis previous,
          String? authorName,
          DateTime? now}) async =>
      next;
}

const _pid = 'demo';

final _patient = Patient(
  id: _pid,
  fullName: 'Marina Silveira',
  birthDate: DateTime(1994, 3, 12),
  occupation: 'Arquiteta',
  gender: 'feminino',
);

Future<void> _loadFonts() async {
  const sdk = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
  Future<ByteData> bytes(String path) async =>
      ByteData.sublistView(File(path).readAsBytesSync());

  final icons = FontLoader('MaterialIcons')
    ..addFont(bytes('$sdk\\materialicons-regular.otf'));
  await icons.load();

  final poppins = FontLoader('Poppins')
    ..addFont(bytes('assets/fonts/Poppins-Regular.ttf'))
    ..addFont(bytes('assets/fonts/Poppins-Bold.ttf'))
    ..addFont(bytes('assets/fonts/Poppins-Italic.ttf'));
  await poppins.load();
}

Future<void> _capture(WidgetTester tester, String name) async {
  final boundary =
      tester.renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
  late final Uint8List png;
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 3);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    png = data!.buffer.asUint8List();
  });
  File('build/marketing/$name.png')
    ..parent.createSync(recursive: true)
    ..writeAsBytesSync(png);
  // ignore: avoid_print
  print('Gerado build/marketing/$name.png');
}

Future<void> _pumpScreen(
  WidgetTester tester,
  Widget child, {
  List<Override> overrides = const [],
}) async {
  tester.view.physicalSize = const Size(390 * 3, 844 * 3);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        patientDetailProvider.overrideWith((ref, id) async => _patient),
        staffPatientProblemsProvider.overrideWith((ref, ctx) async => []),
        currentClinicEntitlementsProvider
            .overrideWith((ref) async => ClinicFeatureEntitlements.empty),
        therapyDemandsAuthorNameProvider.overrideWithValue('Dra. Ana'),
        ...overrides,
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        home: RepaintBoundary(key: const Key('cap'), child: child),
      ),
    ),
  );
  await tester.pump(const Duration(milliseconds: 600));
  await tester.pump(const Duration(milliseconds: 600));
}

void main() {
  setUpAll(() async {
    GoogleFonts.config.allowRuntimeFetching = false;
    await _loadFonts();
  });

  testWidgets('módulos do paciente', (tester) async {
    await _pumpScreen(
      tester,
      Scaffold(
        body: SingleChildScrollView(
          child: Column(
            children: [
              const PatientContextHeader(
                patientId: _pid,
                pageTitle: 'PACIENTE',
                role: ProfileRole.psychologist,
                accentColor: AppColors.cyan,
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: const FutureModulesSection(
                  role: ProfileRole.psychologist,
                  patientId: _pid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await _capture(tester, 'modulos');
  });

  testWidgets('demandas terapêuticas', (tester) async {
    final repo = _FakeRepo(CaseConceptualization(
      unmetNeeds: const [],
      modeSequences: const [],
      relationship: const TherapeuticRelationship(),
      motivoInitial:
          'Procurou terapia após uma separação, relatando ansiedade e dificuldade para dormir.',
      motivoCurrent:
          'Busca compreender padrões nas relações e lidar com a dificuldade de expressar as próprias necessidades.',
      generalImpressions: const GeneralImpressions(
        initial: 'Apresentava-se reservada e preocupada em dar respostas corretas.',
        current: 'Comunica opiniões com mais liberdade.',
      ),
      updatedAt: DateTime(2026, 10, 21, 16, 40),
    ));
    await _pumpScreen(
      tester,
      const TherapyDemandsPage(
          role: ProfileRole.psychologist, patientId: _pid),
      overrides: [
        caseConceptualizationRepositoryProvider.overrideWithValue(repo),
      ],
    );
    await _capture(tester, 'demandas');
  });

  testWidgets('contexto de vida', (tester) async {
    const scores = {
      LifeArea.workCareer: 7,
      LifeArea.loveRomance: 3,
      LifeArea.family: 5,
      LifeArea.friends: 10,
      LifeArea.aloneTime: 4,
      LifeArea.physicalHealth: 8,
      LifeArea.emotionalHealth: 4,
      LifeArea.selfCare: 5,
      LifeArea.routineOrganization: 5,
    };
    final assessment = InitialAssessment(
      patientId: _pid,
      lifeAreas: [
        for (final e in scores.entries)
          LifeAreaAssessment(
            area: e.key,
            score: e.value,
            guidedAnswer: e.key == LifeArea.workCareer
                ? 'Ter concentração para trabalhar'
                : null,
          ),
      ],
    );
    await _pumpScreen(
      tester,
      const InitialAssessmentContextPage(
          role: ProfileRole.psychologist, patientId: _pid),
      overrides: [
        initialAssessmentProvider
            .overrideWith((ref, ctx) async => assessment),
      ],
    );
    await _capture(tester, 'contexto-de-vida');
  });

  testWidgets('prioridades clínicas (panorama)', (tester) async {
    const summary = ClinicalCaseSummary(
      patientName: 'Marina Silveira',
      structuredResultCount: 4,
      openProblemsCount: 0,
      activeGoalsCount: 0,
      relevantEventsCount: 0,
      topSchemas: [
        ClinicalDashboardScoreRow(
            name: 'Autossacrifício',
            code: 'YSQ_SS',
            score: 5.4,
            averageScore: 5.4,
            rawScore: 27,
            severityLabel: 'Ativado'),
        ClinicalDashboardScoreRow(
            name: 'Privação emocional',
            code: 'YSQ_ED',
            score: 5.4,
            averageScore: 5.4,
            rawScore: 27,
            severityLabel: 'Ativado'),
        ClinicalDashboardScoreRow(
            name: 'Abandono / Instabilidade',
            code: 'YSQ_AB',
            score: 4.8,
            averageScore: 4.8,
            rawScore: 24,
            severityLabel: 'Ativado'),
        ClinicalDashboardScoreRow(
            name: 'Padrões inflexíveis',
            code: 'YSQ_US',
            score: 4.4,
            averageScore: 4.4,
            rawScore: 22,
            severityLabel: 'Ativado'),
        ClinicalDashboardScoreRow(
            name: 'Defectividade / Vergonha',
            code: 'YSQ_DS',
            score: 4.2,
            averageScore: 4.2,
            rawScore: 21,
            severityLabel: 'Ativado'),
      ],
      topModes: [],
      topAttachment: [
        ClinicalDashboardScoreRow(
            name: 'Ansioso', code: 'ATT_ANX', score: 3.0, averageScore: 3.0),
      ],
      topCoping: [
        ClinicalDashboardScoreRow(
            name: 'Resignação',
            code: 'YCI_RES',
            score: 4.1,
            averageScore: 4.1,
            severityLabel: 'Alto'),
      ],
      highlightedProblems: [],
      highlightedGoals: [],
      relevantEvents: [],
    );
    await _pumpScreen(
      tester,
      const Scaffold(
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: ClinicalPriorityGrid(summary: summary),
          ),
        ),
      ),
    );
    await _capture(tester, 'panorama');
  });
}
