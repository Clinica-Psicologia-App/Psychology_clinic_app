// INFOGRAFICO_V2: etapa da vida na ordem, todos os acontecimentos, PDF de uma
// página, fonte do aparelho ignorada e nome longo sem estouro. Dados fictícios.
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_case_summary.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_data.dart';
import 'package:terapia_esquema/features/patient_infographic/domain/authorized_timeline_entry.dart';
import 'package:terapia_esquema/features/patient_infographic/domain/patient_infographic_builder.dart';
import 'package:terapia_esquema/features/patient_infographic/domain/patient_infographic_data.dart';
import 'package:terapia_esquema/features/patient_infographic/presentation/infographic_export.dart';
import 'package:terapia_esquema/features/patient_infographic/presentation/patient_infographic_page.dart';
import 'package:terapia_esquema/features/patient_infographic/presentation/widgets/patient_infographic_poster.dart';
import 'package:terapia_esquema/features/patient_infographic/providers/patient_infographic_providers.dart';
import 'package:terapia_esquema/features/patient_timeline/domain/patient_timeline_event.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

PatientTimelineEvent _ev(
  String title, {
  DateTime? date,
  String? period,
  String? chapter,
  int? age,
  int created = 0,
}) =>
    PatientTimelineEvent(
      id: title,
      clinicId: 'c',
      patientId: 'p1',
      title: title,
      eventDate: date,
      periodLabel: period,
      lifeChapter: chapter,
      ageAtEvent: age,
      isSensitive: false,
      createdAt: DateTime(2026, 1, 1).add(Duration(minutes: created)),
      updatedAt: DateTime(2026, 1, 1),
    );

PatientInfographicData _build(List<PatientTimelineEvent> events,
        {DateTime? birth}) =>
    buildPatientInfographic(
      patient: Patient(id: 'p1', fullName: 'Pessoa Fictícia', birthDate: birth),
      dashboard: const ClinicalDashboardData(
        patientName: 'Pessoa Fictícia',
        caseSummary: ClinicalCaseSummary(
          patientName: 'Pessoa Fictícia',
          structuredResultCount: 0,
          openProblemsCount: 0,
          activeGoalsCount: 0,
          relevantEventsCount: 0,
          topSchemas: [],
          topModes: [],
          topAttachment: [],
          topCoping: [],
          highlightedProblems: [],
          highlightedGoals: [],
          relevantEvents: [],
        ),
        callouts: [],
        history: [],
        consolidatedSchemas: [],
      ),
      assessment: null,
      timelineEvents: events,
    );

List<String> _order(List<PatientTimelineEvent> events, {DateTime? birth}) =>
    _build(events, birth: birth).timeline.map((e) => e.description).toList();

/// Etapas como o formulário da psicóloga grava (`period_label`), sem data,
/// cadastradas fora de ordem.
List<PatientTimelineEvent> _stages() => [
      _ev('hoje', chapter: 'today', created: 1),
      _ev('maturidade', period: 'Maturidade', created: 2),
      _ev('vida adulta', period: 'Vida adulta', created: 3),
      _ev('adolescência', period: 'Adolescência', created: 4),
      _ev('infância', period: 'Infância', created: 5),
    ];

PatientInfographicData _poster({int events = 8, bool longName = false}) =>
    PatientInfographicData(
      header: const InfographicHeader(
        name: 'Pessoa Fictícia Aparecida dos Santos Exemplo de Oliveira',
        avatarInitials: 'PO',
        facts: [
          InfographicFact(Icons.person_outline, '39 anos'),
          InfographicFact(Icons.work_outline, 'Coordenadora pedagógica'),
        ],
      ),
      personality: const [
        InfographicPersonalityDomain(
            name: 'Conscienciosidade', score: 63, classification: 'Alto'),
        InfographicPersonalityDomain(
            name: 'Neuroticismo', score: 72, classification: 'Muito Alto'),
        InfographicPersonalityDomain(
            name: 'Extroversão', score: 37, classification: 'Baixo'),
        InfographicPersonalityDomain(
            name: 'Abertura', score: 58, classification: 'Alto'),
        InfographicPersonalityDomain(
            name: 'Amabilidade', score: 50, classification: 'Médio'),
      ],
      timeline: [
        for (var i = 0; i < events; i++)
          InfographicTimelineEntry(
            periodLabel: i.isEven ? '12/05/${1990 + i % 30}' : 'Vida adulta',
            description: 'Acontecimento fictício ${i + 1} com algum texto.',
            icon: Icons.event_note_outlined,
          ),
      ],
      genogramMembers: [
        InfographicGenogramMember(
          name: longName
              ? 'Maria da Conceição Aparecida dos Santos Exemplo de Oliveira '
                  'Fictícia Sobrenome Comprido Demais Para Uma Linha Só'
              : 'Mãe Fictícia',
          relationship: longName
              ? 'Mãe de criação durante boa parte da infância e adolescência '
                  'segundo o relato'
              : 'Mãe',
        ),
      ],
      closingLine: 'Material de apoio à formulação do caso.',
      generatedOn: DateTime(2026, 11, 25),
    );

Future<Size> _pumpPoster(
  WidgetTester tester,
  PatientInfographicData data, {
  double scale = 1,
  bool bold = false,
}) async {
  tester.view.physicalSize = const Size(1000, 20000);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(const SizedBox());
  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale), boldText: bold),
      child: child!,
    ),
    home: Scaffold(
      body: SingleChildScrollView(
        child: RepaintBoundary(
          key: const Key('poster'),
          child: PatientInfographicPoster(data: data),
        ),
      ),
    ),
  ));
  await tester.pump(const Duration(milliseconds: 300));
  return tester.getSize(find.byKey(const Key('poster')));
}

/// (número de páginas, tamanhos de página em pt) lidos do próprio arquivo.
(int, List<Size>) _pages(Uint8List pdf) {
  final text = latin1.decode(pdf);
  final count = RegExp(r'/Type\s*/Page(?![a-z])').allMatches(text).length;
  final boxes = [
    for (final b in RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)')
        .allMatches(text))
      Size(double.parse(b.group(1)!), double.parse(b.group(2)!)),
  ];
  return (count, boxes);
}

Future<Uint8List> _png(int w, int h) async {
  final rec = ui.PictureRecorder();
  ui.Canvas(rec).drawRect(
    Rect.fromLTWH(0, 0, w.toDouble(), h.toDouble()),
    ui.Paint()..color = const Color(0xFF3366CC),
  );
  final img = await rec.endRecording().toImage(w, h);
  final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
  return bytes!.buffer.asUint8List();
}

void main() {
  setUpAll(() async {
    for (final f in ['Poppins-Regular.ttf', 'Poppins-Bold.ttf']) {
      await ui.loadFontFromList(File('assets/fonts/$f').readAsBytesSync(),
          fontFamily: 'Poppins');
    }
  });

  group('etapa da vida na ordem', () {
    final birth = DateTime(1986, 6, 1);
    const inOrder = [
      'infância',
      'adolescência',
      'vida adulta',
      'maturidade',
      'hoje',
    ];

    test('sem nascimento: ordem das etapas, todas antes de Hoje', () {
      expect(_order(_stages()), inOrder);
    });

    test('com nascimento: ordem das etapas, todas antes de Hoje', () {
      expect(_order(_stages(), birth: birth), inOrder);
    });

    test('com nascimento: etapas intercaladas com idades, anos e datas', () {
      final order = _order([
        ..._stages(),
        _ev('4 anos', age: 4),
        _ev('data 1996', date: DateTime(1996, 6, 1)), // 10 anos
        _ev('20 anos', age: 20),
        _ev('data 2021', date: DateTime(2021, 5, 10)), // ~35 anos
        _ev('60 anos', period: 'aos 60 anos'),
      ], birth: birth);
      expect(order, [
        '4 anos',
        'infância',
        'data 1996',
        'adolescência',
        '20 anos',
        'vida adulta',
        'data 2021',
        'maturidade',
        '60 anos',
        'hoje',
      ]);
    });

    test('sem nascimento: datados primeiro, depois etapas e idades', () {
      final order = _order([
        ..._stages(),
        _ev('20 anos', age: 20),
        _ev('ano 2015', period: '2015'),
      ]);
      expect(order, [
        'ano 2015',
        'infância',
        'adolescência',
        '20 anos',
        'vida adulta',
        'maturidade',
        'hoje',
      ]);
    });

    test('data ou idade valem mais que a etapa; rótulo exibido não muda', () {
      final data = _build([
        _ev('infância com data',
            period: 'Infância', date: DateTime(2020, 1, 1)),
        _ev('vida adulta com idade', period: 'Vida adulta', age: 19),
        _ev('só etapa', period: ' adolescência '),
      ], birth: birth);
      expect(data.timeline.map((e) => e.description), [
        'só etapa',
        'vida adulta com idade',
        'infância com data',
      ]);
      expect(data.timeline.map((e) => e.periodLabel),
          ['adolescência', 'Vida adulta', '01/01/2020']);
    });

    test('sem referência continua no fim, depois de Hoje', () {
      expect(
          _order([
            _ev('sem lugar', chapter: 'cannot_locate'),
            _ev('livre', period: 'época da faculdade', created: 1),
            ..._stages(),
          ], birth: birth),
          [...inOrder, 'sem lugar', 'livre']);
    });

    test('visão da paciente usa a mesma regra', () {
      final list = AuthorizedTimelineEntry.sortChronologically([
        for (final e in _stages())
          AuthorizedTimelineEntry.fromJson({
            'id': e.title,
            'title': e.title,
            'period_label': e.periodLabel,
            'life_chapter': e.lifeChapter,
          }),
      ]);
      expect(list.map((e) => e.id), inOrder);
    });
  });

  group('todos os acontecimentos', () {
    for (final n in [20, 40]) {
      testWidgets('$n acontecimentos no pôster, sem estouro', (tester) async {
        final data = _build(
            [for (var i = 0; i < n; i++) _ev('evento $i', age: i)],
            birth: DateTime(1970));
        expect(data.timeline, hasLength(n));
        await _pumpPoster(tester, data);
        for (var i = 0; i < n; i++) {
          expect(find.text('evento $i'), findsOneWidget);
        }
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('PDF de uma página', () {
    for (final (w, h) in [(2000, 900), (2000, 3900), (2000, 8191)]) {
      testWidgets('PNG ${w}x$h: 1 página de 595 pt, altura do pôster',
          (tester) async {
        await tester.runAsync(() async {
          final pdf = await InfographicExport.buildPdf(await _png(w, h));
          final (count, boxes) = _pages(pdf);
          expect(count, 1);
          expect(boxes, isNotEmpty);
          for (final box in boxes) {
            expect(box.width, closeTo(595.28, 0.5));
            expect(box.height, closeTo((595.28 - 48) * h / w + 48, 0.5));
          }
        });
      });
    }

    testWidgets('pôster absurdamente comprido respeita o limite do formato',
        (tester) async {
      await tester.runAsync(() async {
        final pdf = await InfographicExport.buildPdf(await _png(100, 3000));
        final (count, boxes) = _pages(pdf);
        expect(count, 1);
        expect(boxes.single.width, closeTo(595.28, 0.5));
        expect(boxes.single.height, closeTo(14400, 0.5));
      });
    });

    test('captura reduz a resolução só quando passaria do limite', () {
      expect(
          InfographicExport.capturePixelRatio(const Size(1000, 3400), 2), 2);
      for (final h in [5000.0, 9000.0, 20000.0]) {
        final ratio =
            InfographicExport.capturePixelRatio(Size(1000, h), 2);
        expect(ratio, lessThan(2));
        expect((h * ratio).ceil(),
            lessThanOrEqualTo(InfographicExport.maxCaptureSide));
      }
    });

    testWidgets('tela em 390x844 com 40 acontecimentos gera PDF de 1 página',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      Uint8List? pdf;
      await tester.pumpWidget(ProviderScope(
        overrides: [
          patientInfographicProvider
              .overrideWith((ref, ctx) => _poster(events: 40)),
        ],
        child: MaterialApp(
          theme: AppTheme.light,
          home: PatientInfographicPage(
            role: ProfileRole.psychologist,
            patientId: 'p1',
            pdfViewerBuilder: (_, bytes) {
              pdf = bytes;
              return const SizedBox.expand();
            },
          ),
        ),
      ));
      await tester.pump(const Duration(milliseconds: 600));
      await tester.tap(find.text('PDF'));
      for (var i = 0; i < 30 && pdf == null; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 300)));
        await tester.pump(const Duration(milliseconds: 100));
      }
      final (count, boxes) = _pages(pdf!);
      expect(count, 1);
      expect(boxes.single.width, closeTo(595.28, 0.5));
      expect(boxes.single.height, greaterThan(841.89));
    });
  });

  group('fonte do aparelho e nome longo', () {
    testWidgets('fonte 1.6 e negrito do aparelho não mudam o pôster',
        (tester) async {
      final normal = await _pumpPoster(tester, _poster(events: 20));
      final nameBox = tester.getSize(find.text('Conscienciosidade'));
      for (final (scale, bold) in [(1.3, false), (1.6, false), (1.6, true)]) {
        final big = await _pumpPoster(tester, _poster(events: 20),
            scale: scale, bold: bold);
        expect(big, normal, reason: 'escala $scale negrito $bold');
        expect(tester.getSize(find.text('Conscienciosidade')), nameBox);
        expect(tester.takeException(), isNull);
      }
    });

    testWidgets('nome de etapa não parte no meio da palavra', (tester) async {
      const labels = [
        'Infância',
        'Adolescência',
        'Vida adulta',
        'Maturidade',
        '12/05/1996',
      ];
      await _pumpPoster(
        tester,
        PatientInfographicData(
          header: const InfographicHeader(name: 'Pessoa Fictícia'),
          timeline: [
            for (final l in labels)
              InfographicTimelineEntry(periodLabel: l, description: 'x'),
          ],
        ),
      );
      final oneLine = tester.getSize(find.text('Infância')).height;
      for (final l in labels) {
        expect(tester.getSize(find.text(l)).height, oneLine, reason: l);
      }
    });

    testWidgets('nome longo sem desenho do genograma não estoura',
        (tester) async {
      for (final scale in [1.0, 1.6]) {
        await _pumpPoster(tester, _poster(longName: true), scale: scale);
        expect(tester.takeException(), isNull);
        final name = find.textContaining('Maria da Conceição');
        final card = tester.getRect(find.byKey(const Key('poster')));
        // Dentro do pôster, com a margem dele (28) e a do cartão (16).
        expect(tester.getRect(name).right,
            lessThanOrEqualTo(card.right - 28 - 16));
        final text = tester.renderObject<RenderParagraph>(find.descendant(
            of: name, matching: find.byType(RichText)));
        expect(text.size.height, lessThanOrEqualTo(40)); // até 2 linhas
      }
    });
  });
}
