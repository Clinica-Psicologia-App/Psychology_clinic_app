import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/initial_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/providers/initial_assessment_providers.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_data.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_page.dart';
import 'package:terapia_esquema/features/mental_map/providers/case_conceptualization_providers.dart';
import 'package:terapia_esquema/features/mental_map/providers/mental_map_providers.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/providers/patients_providers.dart';
import 'package:terapia_esquema/features/personality_assessment/providers/personality_assessment_providers.dart';
import 'package:terapia_esquema/features/profile/data/document_logo_repository.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/providers/document_logo_providers.dart';

// Botão PDF abre a prévia (nada é compartilhado); só "Compartilhar" envia. Dados fictícios.

const _role = ProfileRole.psychologist;

class _FakeLogoRepo implements DocumentLogoRepository {
  @override
  Future<Uint8List?> downloadOwn() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late List<String> shared;

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 1400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    shared = [];
    final router = GoRouter(routes: [
      GoRoute(
        path: '/',
        builder: (_, __) => CaseConceptualizationPage(
          role: _role,
          patientId: 'p1',
          onSharePdf: (bytes, name) async => shared.add(name),
          pdfPreviewBuilder: (_, bytes) => Text('PAGINAS ${bytes.length > 1000}'),
        ),
      ),
    ]);
    addTearDown(router.dispose);
    const ctx = StaffMentalMapContext(role: _role, patientId: 'p1');
    await tester.pumpWidget(ProviderScope(
      overrides: [
        staffMentalMapProvider(ctx)
            .overrideWith((ref) async => MentalMapData.empty),
        caseConceptualizationProvider('p1')
            .overrideWith((ref) async => CaseConceptualization.empty()),
        initialAssessmentProvider(
                const InitialAssessmentContext(role: _role, patientId: 'p1'))
            .overrideWith((ref) async => const InitialAssessment(patientId: 'p1')),
        personalityIntegrationsProvider('p1').overrideWith((ref) async => []),
        personalityAssessmentsProvider('p1').overrideWith((ref) async => []),
        patientDetailProvider('p1').overrideWith(
            (ref) async => const Patient(id: 'p1', fullName: 'Hilton Teste')),
        documentLogoRepositoryProvider.overrideWithValue(_FakeLogoRepo()),
        documentLogoProvider.overrideWith((ref) async => null),
      ],
      child: MaterialApp.router(routerConfig: router),
    ));
    await tester.pumpAndSettle();
  }

  Future<void> openPreview(WidgetTester tester) async {
    await tester.tap(find.text('PDF'));
    // gerar o PDF é assíncrono de verdade (fora do relógio falso do teste)
    for (var i = 0; i < 20 && find.byKey(const Key('pdf_preview_page')).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 200)));
      await tester.pump();
    }
    await tester.pumpAndSettle();
  }

  testWidgets('PDF abre a prévia e NÃO compartilha', (tester) async {
    await pump(tester);
    await openPreview(tester);
    expect(find.byKey(const Key('pdf_preview_page')), findsOneWidget);
    expect(find.text('Prévia do documento'), findsOneWidget);
    expect(find.text('PAGINAS true'), findsOneWidget);
    expect(find.text('Compartilhar'), findsOneWidget);
    expect(shared, isEmpty);
  });

  testWidgets('Compartilhar chama o envio uma vez, com o nome do PDF',
      (tester) async {
    await pump(tester);
    await openPreview(tester);
    await tester.tap(find.byKey(const Key('pdf_preview_share')));
    await tester.pumpAndSettle();
    expect(shared.length, 1);
    expect(shared.single, endsWith('.pdf'));
    // continua na prévia
    expect(find.byKey(const Key('pdf_preview_page')), findsOneWidget);
  });

  testWidgets('Voltar e fechar saem da prévia sem compartilhar',
      (tester) async {
    await pump(tester);
    await openPreview(tester);
    await tester.tap(find.byKey(const Key('pdf_preview_back')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pdf_preview_page')), findsNothing);
    await openPreview(tester);
    await tester.tap(find.byKey(const Key('pdf_preview_close')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('pdf_preview_page')), findsNothing);
    expect(shared, isEmpty);
  });
}
