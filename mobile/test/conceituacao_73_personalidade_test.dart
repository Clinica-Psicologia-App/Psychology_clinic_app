import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_edit_page.dart';
import 'package:terapia_esquema/features/mental_map/providers/case_conceptualization_providers.dart';
import 'package:terapia_esquema/features/personality_assessment/domain/personality_assessment.dart';
import 'package:terapia_esquema/features/personality_assessment/domain/personality_instrument.dart';
import 'package:terapia_esquema/features/personality_assessment/providers/personality_assessment_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

// #29 — 7.3 "Trazer da Personalidade (NEO PI-R)". Dados fictícios.

PersonalityAssessment _a(String id, DateTime applied,
        Map<String, PersonalityLevel> levels) =>
    PersonalityAssessment(
      id: id,
      patientId: 'p1',
      instrument: 'NEO_PI_R',
      createdAt: applied,
      updatedAt: applied,
      appliedOn: applied,
      results: PersonalityResults(domains: {
        for (final e in levels.entries)
          e.key: DomainResult(overall: ScoreEntry(level: e.value)),
      }),
    );

void main() {
  Future<void> pump(WidgetTester tester, List<PersonalityAssessment> list,
      {CaseConceptualization? concept}) async {
    tester.view.physicalSize = const Size(800, 30000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseConceptualizationProvider('p1').overrideWith(
              (ref) async => concept ?? CaseConceptualization.empty()),
          personalityAssessmentsProvider('p1').overrideWith((ref) async => list),
        ],
        child: const MaterialApp(
          home: CaseConceptualizationEditPage(
            role: ProfileRole.psychologist,
            patientId: 'p1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final field = find.widgetWithText(TextField, 'Temperamento / biológico');
  final button = find.byKey(const Key('edit_pull_personality'));
  String text(WidgetTester t) => t.widget<TextField>(field).controller!.text;

  testWidgets('sem resultado: botão desabilitado com a dica', (tester) async {
    await pump(tester, const []);
    expect(find.text('Trazer da Personalidade (NEO PI-R)'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    expect(find.text('Sem resultado de Personalidade ainda'), findsWidgets);
    expect(text(tester), '');
  });

  testWidgets('resultado sem nenhum nível: também desabilitado',
      (tester) async {
    await pump(tester, [_a('a', DateTime(2026, 11, 1), const {})]);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
  });

  testWidgets('com resultado: acrescenta os domínios com nível ao campo vazio',
      (tester) async {
    await pump(tester, [
      _a('a', DateTime(2026, 11, 1), {
        'neuroticism': PersonalityLevel.high,
        'extraversion': PersonalityLevel.low,
      }),
    ]);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
    expect(find.byKey(const Key('edit_pull_personality_hint')), findsNothing);
    await tester.tap(button);
    await tester.pump();
    expect(text(tester),
        'NEO PI-R (01/11/2026): Neuroticismo: Alto; Extroversão: Baixo.');
  });

  testWidgets('preserva o texto já escrito e acrescenta depois dele',
      (tester) async {
    await pump(tester, [
      _a('a', DateTime(2026, 11, 1), {'neuroticism': PersonalityLevel.veryHigh}),
    ]);
    await tester.enterText(field, 'Irritabilidade desde a infância.');
    await tester.tap(button);
    await tester.pump();
    expect(
        text(tester),
        'Irritabilidade desde a infância.\n\n'
        'NEO PI-R (01/11/2026): Neuroticismo: Muito Alto.');
  });

  testWidgets('texto que veio salvo na conceitualização também é preservado',
      (tester) async {
    await pump(
      tester,
      [
        _a('a', DateTime(2026, 11, 1),
            {'openness': PersonalityLevel.medium}),
      ],
      concept: const CaseConceptualization(
        unmetNeeds: [],
        modeSequences: [],
        relationship: TherapeuticRelationship(),
        origins: CaseOrigins(temperament: 'Sono leve.'),
      ),
    );
    expect(text(tester), 'Sono leve.');
    await tester.tap(button);
    await tester.pump();
    expect(text(tester).startsWith('Sono leve.\n\nNEO PI-R'), isTrue);
  });

  testWidgets('usa a avaliação mais recente', (tester) async {
    await pump(tester, [
      _a('velha', DateTime(2026, 3, 1), {'neuroticism': PersonalityLevel.low}),
      _a('nova', DateTime(2026, 10, 5), {'neuroticism': PersonalityLevel.high}),
    ]);
    await tester.tap(button);
    await tester.pump();
    expect(text(tester), contains('05/10/2026'));
    expect(text(tester), contains('Neuroticismo: Alto'));
    expect(text(tester), isNot(contains('Baixo')));
  });

  Future<void> pumpWith(WidgetTester tester,
      Future<List<PersonalityAssessment>> Function() load) async {
    tester.view.physicalSize = const Size(800, 30000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          caseConceptualizationProvider('p1')
              .overrideWith((ref) async => CaseConceptualization.empty()),
          personalityAssessmentsProvider('p1').overrideWith((ref) => load()),
        ],
        child: const MaterialApp(
          home: CaseConceptualizationEditPage(
            role: ProfileRole.psychologist,
            patientId: 'p1',
          ),
        ),
      ),
    );
  }

  testWidgets('carregando: botão desabilitado com "Carregando Personalidade…" '
      'e sem a dica de vazio', (tester) async {
    final never = Completer<List<PersonalityAssessment>>();
    await pumpWith(tester, () => never.future);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Carregando Personalidade…'), findsOneWidget);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);
    expect(find.text('Sem resultado de Personalidade ainda'), findsNothing);
    expect(find.byKey(const Key('edit_pull_personality_error')), findsNothing);
    // Libera para não deixar timers pendentes.
    never.complete(const []);
    await tester.pumpAndSettle();
  });

  testWidgets('erro: mensagem + "Tentar novamente" refaz a consulta e habilita '
      'o botão; sem a dica de vazio', (tester) async {
    var calls = 0;
    await pumpWith(tester, () async {
      calls++;
      if (calls == 1) throw StateError('falha de rede');
      return [
        _a('a', DateTime(2026, 11, 1), {'neuroticism': PersonalityLevel.high}),
      ];
    });
    await tester.pumpAndSettle();
    expect(calls, 1);
    expect(find.text('Não foi possível carregar a Personalidade.'),
        findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(find.text('Sem resultado de Personalidade ainda'), findsNothing);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNull);

    await tester.tap(find.byKey(const Key('edit_pull_personality_retry')));
    await tester.pumpAndSettle();
    expect(calls, 2);
    expect(find.byKey(const Key('edit_pull_personality_error')), findsNothing);
    expect(tester.widget<OutlinedButton>(button).onPressed, isNotNull);
  });
}
