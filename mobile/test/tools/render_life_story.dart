// Renderiza as telas do novo fluxo "Minha História / Linha do Tempo" para
// conferir o visual (abertura, etapas do fluxo, trilha vertical).
//
//   flutter test test/tools/render_life_story.dart
//
// Saídas em build/life_story_*.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/life_story/domain/life_story_enums.dart';
import 'package:terapia_esquema/features/life_story/domain/life_timeline_event.dart';
import 'package:terapia_esquema/features/life_story/domain/family_person.dart';
import 'package:terapia_esquema/features/life_story/domain/timeline_person.dart';
import 'package:terapia_esquema/features/life_story/domain/family_context.dart';
import 'package:terapia_esquema/features/life_story/presentation/deepen_event_flow_page.dart';
import 'package:terapia_esquema/features/life_story/presentation/deepen_relationship_flow_page.dart';
import 'package:terapia_esquema/features/life_story/presentation/family_context_flow_page.dart';
import 'package:terapia_esquema/features/life_story/presentation/genogram_panel_page.dart';
import 'package:terapia_esquema/features/life_story/domain/genogram_relationship_enums.dart';
import 'package:terapia_esquema/features/life_story/presentation/my_family_page.dart';
import 'package:terapia_esquema/features/life_story/presentation/person_card_page.dart';
import 'package:terapia_esquema/features/life_story/presentation/person_clinical_card_page.dart';
import 'package:terapia_esquema/features/life_story/presentation/my_timeline_page.dart';
import 'package:terapia_esquema/features/life_story/presentation/timeline_event_flow_page.dart';
import 'package:terapia_esquema/features/life_story/providers/life_story_providers.dart';

const _events = [
  LifeTimelineEvent(
    id: '1',
    patientId: 'p',
    title: 'Nasceu minha irmã',
    lifeChapter: LifeChapter.childhood,
    ageAtEvent: 5,
    emotions: [TimelineEmotion.happy],
  ),
  LifeTimelineEvent(
    id: '2',
    patientId: 'p',
    title: 'Separação dos meus pais',
    lifeChapter: LifeChapter.childhood,
    ageAtEvent: 8,
    emotions: [TimelineEmotion.sad, TimelineEmotion.afraid],
  ),
  LifeTimelineEvent(
    id: '3',
    patientId: 'p',
    title: 'Entrei na faculdade',
    lifeChapter: LifeChapter.adulthood,
    ageAtEvent: 18,
    emotions: [TimelineEmotion.happy, TimelineEmotion.proud],
  ),
];

const _people = [
  TimelinePerson(id: 'a', fullName: 'Maria', role: RelationshipRole.mother),
  TimelinePerson(id: 'b', fullName: 'João', role: RelationshipRole.father),
  TimelinePerson(id: 'c', fullName: 'Ana', role: RelationshipRole.sister),
];

const _family = [
  FamilyPerson(
      id: 'a',
      fullName: 'Maria',
      role: RelationshipRole.mother,
      eventCount: 4),
  FamilyPerson(
      id: 'b',
      fullName: 'João',
      role: RelationshipRole.father,
      eventCount: 3),
  FamilyPerson(
      id: 'c',
      fullName: 'Ana',
      role: RelationshipRole.sister,
      eventCount: 2),
];

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    await ui.loadFontFromList(
      File('$dir\\materialicons-regular.otf').readAsBytesSync(),
      fontFamily: 'MaterialIcons',
    );
    for (final f in [
      'roboto-regular.ttf',
      'roboto-medium.ttf',
      'roboto-bold.ttf',
      'roboto-black.ttf',
    ]) {
      await ui.loadFontFromList(
        File('$dir\\$f').readAsBytesSync(),
        fontFamily: 'Roboto',
      );
    }
  });

  Future<void> capture(WidgetTester tester, String file) async {
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byType(RepaintBoundary).first);
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/$file')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/$file');
  }

  Future<void> pump(
    WidgetTester tester,
    Widget page, {
    List<Override> overrides = const [],
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: overrides,
        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: RepaintBoundary(child: page),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 300));
  }

  testWidgets('abertura (convite, sem eventos)', (tester) async {
    await pump(tester, const MyTimelinePage(), overrides: [
      myTimelineProvider.overrideWith((ref) async => <LifeTimelineEvent>[]),
    ]);
    await capture(tester, 'life_story_abertura.png');
  });

  testWidgets('trilha com acontecimentos', (tester) async {
    await pump(tester, const MyTimelinePage(), overrides: [
      myTimelineProvider.overrideWith((ref) async => _events),
    ]);
    await capture(tester, 'life_story_trilha.png');
  });

  testWidgets('fluxo etapa 1 — quando', (tester) async {
    await pump(tester, const TimelineEventFlowPage(), overrides: [
      myTimelinePeopleProvider.overrideWith((ref) async => _people),
    ]);
    await capture(tester, 'life_story_etapa_quando.png');
  });

  testWidgets('fluxo etapa 4 — como se sentiu', (tester) async {
    await pump(tester, const TimelineEventFlowPage(), overrides: [
      myTimelinePeopleProvider.overrideWith((ref) async => _people),
    ]);
    // Avança: quando → o quê (precisa título) → quem → como se sentiu.
    await tester.tap(find.text('Primeiros anos'));
    await tester.pump();
    await tester.tap(find.text('Avançar'));
    await tester.pump();
    await tester.enterText(find.byType(TextField).last, 'Separação dos meus pais');
    await tester.pump();
    await tester.tap(find.text('Avançar'));
    await tester.pump();
    await tester.tap(find.text('Avançar'));
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, 'life_story_etapa_sentiu.png');
  });

  testWidgets('aprofundar — do que precisava', (tester) async {
    await pump(tester, DeepenEventFlowPage(event: _events[1]));
    await tester.tap(find.text('Avançar')); // evento/período → área
    await tester.pump();
    await tester.tap(find.text('Avançar')); // área → do que precisava
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, 'life_story_aprofundar_precisava.png');
  });

  testWidgets('aprofundar — e hoje', (tester) async {
    await pump(tester, DeepenEventFlowPage(event: _events[1]));
    for (var i = 0; i < 4; i++) {
      await tester.tap(find.text('Avançar'));
      await tester.pump(const Duration(milliseconds: 120));
    }
    await capture(tester, 'life_story_aprofundar_hoje.png');
  });

  testWidgets('minha família — lista', (tester) async {
    await pump(tester, const MyFamilyPage(), overrides: [
      myFamilyProvider.overrideWith((ref) async => _family),
    ]);
    await capture(tester, 'life_story_familia.png');
  });

  testWidgets('relação — como era', (tester) async {
    await pump(tester, DeepenRelationshipFlowPage(person: _family[0]));
    await tester.tap(find.text('Avançar')); // papel → como era
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, 'life_story_relacao_comoera.png');
  });

  testWidgets('relação — o que recebi', (tester) async {
    await pump(tester, DeepenRelationshipFlowPage(person: _family[0]));
    for (var i = 0; i < 3; i++) {
      await tester.tap(find.text('Avançar'));
      await tester.pump(const Duration(milliseconds: 120));
    }
    await capture(tester, 'life_story_relacao_recebi.png');
  });

  testWidgets('ver momentos — filtrado por pessoa', (tester) async {
    // Eventos com peopleIds; só os da Maria ('a') aparecem.
    const eventsWithPeople = [
      LifeTimelineEvent(
        id: '1',
        patientId: 'p',
        title: 'Nasceu minha irmã',
        lifeChapter: LifeChapter.childhood,
        ageAtEvent: 5,
        emotions: [TimelineEmotion.happy],
        peopleIds: ['a'],
      ),
      LifeTimelineEvent(
        id: '2',
        patientId: 'p',
        title: 'Separação dos meus pais',
        lifeChapter: LifeChapter.childhood,
        ageAtEvent: 8,
        emotions: [TimelineEmotion.sad, TimelineEmotion.afraid],
        peopleIds: ['a', 'b'],
      ),
      LifeTimelineEvent(
        id: '3',
        patientId: 'p',
        title: 'Entrei na faculdade',
        lifeChapter: LifeChapter.adulthood,
        ageAtEvent: 18,
        emotions: [TimelineEmotion.happy, TimelineEmotion.proud],
        peopleIds: ['b'],
      ),
    ];
    await pump(tester, MyTimelinePage(person: _family[0]), overrides: [
      myTimelineProvider.overrideWith((ref) async => eventsWithPeople),
    ]);
    await capture(tester, 'life_story_ver_momentos.png');
  });

  testWidgets('cartão da pessoa — com dados', (tester) async {
    const person = FamilyPerson(
      id: 'a',
      fullName: 'Maria',
      role: RelationshipRole.mother,
      eventCount: 4,
      bondType: BondType.ambivalent,
      closeness: 5,
      receivedNeeds: [RelationalNeed.affection, RelationalNeed.protection],
      wishedMoreNeeds: [RelationalNeed.freedomToBe, RelationalNeed.understanding],
    );
    await pump(tester, const PersonCardPage(person: person));
    await capture(tester, 'life_story_cartao_pessoa.png');
  });

  testWidgets('cartão da pessoa — sem camada emocional', (tester) async {
    await pump(tester, PersonCardPage(person: _family[2]));
    await capture(tester, 'life_story_cartao_vazio.png');
  });

  testWidgets('cartão terapeuta — síntese', (tester) async {
    const person = FamilyPerson(
      id: 'a',
      fullName: 'Maria',
      patientId: 'p',
      role: RelationshipRole.mother,
      ageApprox: 62,
      deceasedStatus: DeceasedStatus.no,
      eventCount: 4,
      caregiverRole: CaregiverRole.important,
      closeness: 7,
      conflict: 6,
      bondType: BondType.ambivalent,
      feltInRelationship: [
        FeltInRelationship.loved,
        FeltInRelationship.controlled,
        FeltInRelationship.criticized,
      ],
      receivedNeeds: [RelationalNeed.affection, RelationalNeed.protection],
      wishedMoreNeeds: [
        RelationalNeed.freedomToBe,
        RelationalNeed.understanding,
      ],
      currentRelationship: CurrentRelationship.close,
    );
    await pump(tester, const PersonClinicalCardPage(person: person), overrides: [
      personClinicalCommentProvider('a').overrideWith((ref) async =>
          'Sentia-se amada, porém frequentemente controlada e criticada. '
          'Padrão de cuidado ambivalente; explorar autonomia.'),
    ]);
    await capture(tester, 'life_story_cartao_terapeuta.png');
    // Rola até o fim para conferir Relação atual, Linha do Tempo e o
    // comentário clínico (campo privado).
    await tester.drag(find.byType(ListView), const Offset(0, -1400));
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, 'life_story_cartao_terapeuta_fim.png');
  });

  testWidgets('painel do genograma — terapeuta', (tester) async {
    const family = [
      FamilyPerson(
        id: 'a',
        fullName: 'Maria',
        patientId: 'p',
        role: RelationshipRole.mother,
        eventCount: 4,
        caregiverRole: CaregiverRole.important,
        closeness: 7,
        conflict: 6,
        bondType: BondType.ambivalent,
        receivedNeeds: [RelationalNeed.affection, RelationalNeed.protection],
        wishedMoreNeeds: [
          RelationalNeed.freedomToBe,
          RelationalNeed.understanding,
        ],
        currentRelationship: CurrentRelationship.close,
      ),
      FamilyPerson(
        id: 'b',
        fullName: 'João',
        patientId: 'p',
        role: RelationshipRole.father,
        eventCount: 2,
        caregiverRole: CaregiverRole.partial,
        closeness: 3,
        conflict: 4,
        bondType: BondType.distant,
        receivedNeeds: [RelationalNeed.stability],
        wishedMoreNeeds: [RelationalNeed.presence],
      ),
    ];
    const famContext = FamilyContext(
      climateTraits: [
        ClimateTrait.showedAffection,
        ClimateTrait.manyCriticisms,
        ClimateTrait.muchControl,
      ],
      climateNote: 'Todos se gostavam, mas ninguém falava sobre sentimentos.',
      hasPatterns: HasPatterns.yes,
      patternTraits: [
        PatternTrait.perfectionism,
        PatternTrait.hardToTalkFeelings,
      ],
      patternGenerations: [
        PatternGeneration.parentsUncles,
        PatternGeneration.grandparents,
      ],
    );
    await pump(tester, const GenogramPanelPage(patientId: 'p'), overrides: [
      familyForPatientProvider('p').overrideWith((ref) async => family),
      familyContextForPatientProvider('p')
          .overrideWith((ref) async => famContext),
    ]);
    await capture(tester, 'life_story_painel_genograma.png');
    await tester.drag(find.byType(ListView), const Offset(0, -1600));
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, 'life_story_painel_genograma_fim.png');
  });

  testWidgets('família — clima', (tester) async {
    await pump(tester, const FamilyContextFlowPage(context: FamilyContext()));
    await capture(tester, 'life_story_clima.png');
  });

  testWidgets('família — padrões', (tester) async {
    await pump(
      tester,
      const FamilyContextFlowPage(
          context: FamilyContext(hasPatterns: HasPatterns.yes)),
    );
    await tester.tap(find.text('Avançar')); // clima → padrões
    await tester.pump(const Duration(milliseconds: 200));
    await capture(tester, 'life_story_padroes.png');
  });
}
