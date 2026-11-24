import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_case_summary.dart';
import 'package:terapia_esquema/features/clinical_dashboard/domain/clinical_dashboard_data.dart';
import 'package:terapia_esquema/features/patient_infographic/domain/authorized_timeline_entry.dart';
import 'package:terapia_esquema/features/patient_infographic/domain/patient_infographic_builder.dart';
import 'package:terapia_esquema/features/patient_infographic/domain/patient_infographic_data.dart';
import 'package:terapia_esquema/features/patient_infographic/presentation/infographic_export.dart';
import 'package:terapia_esquema/features/patient_infographic/presentation/infographic_pdf_preview_page.dart';
import 'package:terapia_esquema/features/patient_infographic/presentation/patient_infographic_page.dart';
import 'package:terapia_esquema/features/patient_infographic/providers/patient_infographic_providers.dart';
import 'package:terapia_esquema/features/patient_timeline/domain/patient_timeline_event.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

ClinicalDashboardData _dash() => const ClinicalDashboardData(
      patientName: 'Roberto',
      caseSummary: ClinicalCaseSummary(
        patientName: 'Roberto',
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
    );

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

List<String> _order(List<PatientTimelineEvent> events, {DateTime? birth}) {
  final data = buildPatientInfographic(
    patient: Patient(id: 'p1', fullName: 'Roberto Silva', birthDate: birth),
    dashboard: _dash(),
    assessment: null,
    timelineEvents: events,
  );
  return data.timeline.map((e) => e.description).toList();
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

/// RGBA sintético: fundo branco; [blocks] = intervalos de linhas pretas.
/// O pixel (0,0) fica branco (é a referência de fundo).
Uint8List _rgba(int w, int h, List<(int, int)> blocks) {
  final b = Uint8List(w * h * 4);
  for (var i = 0; i < b.length; i++) {
    b[i] = 255;
  }
  for (final (from, to) in blocks) {
    for (var y = from; y < to; y++) {
      for (var x = 0; x < w; x++) {
        if (x == 0 && y == 0) continue;
        final o = (y * w + x) * 4;
        b[o] = 0;
        b[o + 1] = 0;
        b[o + 2] = 0;
      }
    }
  }
  return b;
}

List<int> _plan(Uint8List rgba, int w, int h, int maxRows) {
  final cuts = <int>[];
  var start = 0;
  while (start < h) {
    final cut = InfographicExport.pdfCutPoint(rgba, w, h, start, maxRows);
    cuts.add(cut);
    start = cut;
  }
  return cuts;
}

void main() {
  group('ordem da linha do tempo (mais antigo primeiro)', () {
    final birth = DateTime(1986, 6, 1);

    test(
        'com nascimento: data, idade, ano, "aos N anos" e capítulo na mesma régua',
        () {
      final order = _order([
        _ev('hoje', chapter: 'today'),
        _ev('data 2010', date: DateTime(2010, 3, 1)), // 23 anos
        _ev('ano 2015', period: '2015'), // ~29 anos
        _ev('aos 8', period: 'aos 8 anos'),
        _ev('idade 12', age: 12),
        _ev('adolescência', chapter: 'adolescence'), // 15
        _ev('primeiros anos', chapter: 'early_years'), // 3
        _ev('data 1992', date: DateTime(1992, 1, 1)), // ~5,6
      ], birth: birth);
      expect(order, [
        'primeiros anos',
        'data 1992',
        'aos 8',
        'idade 12',
        'adolescência',
        'data 2010',
        'ano 2015',
        'hoje',
      ]);
    });

    test('sem nascimento: datados primeiro (por data), depois idade/capítulo',
        () {
      final order = _order([
        _ev('idade 30', age: 30),
        _ev('data 2018', date: DateTime(2018, 5, 1)),
        _ev('infância', chapter: 'childhood'),
        _ev('ano 2005', period: 'em 2005'),
        _ev('idade 9', age: 9),
      ]);
      expect(
          order, ['ano 2005', 'data 2018', 'infância', 'idade 9', 'idade 30']);
    });

    test('sem referência vai para o fim, pela ordem de cadastro', () {
      final order = _order([
        _ev('sem ref B', created: 5),
        _ev('idade 20', age: 20, created: 9),
        _ev('sem ref A', created: 1),
        _ev('texto livre', period: 'época da faculdade', created: 3),
      ], birth: birth);
      expect(order, ['idade 20', 'sem ref A', 'texto livre', 'sem ref B']);
    });

    test('empate de idade desempata por cadastro (crescente)', () {
      final order = _order([
        _ev('segundo', age: 10, created: 2),
        _ev('primeiro', age: 10, created: 1),
      ], birth: birth);
      expect(order, ['primeiro', 'segundo']);
    });

    test('rótulo exibido não muda (capítulo e data)', () {
      final data = buildPatientInfographic(
        patient: Patient(id: 'p1', fullName: 'R', birthDate: birth),
        dashboard: _dash(),
        assessment: null,
        timelineEvents: [
          _ev('a', date: DateTime(2010, 3, 1)),
          _ev('b', chapter: 'childhood'),
        ],
      );
      expect(
          data.timeline.map((e) => e.periodLabel), ['Infância', '01/03/2010']);
    });

    test('early_years mostra "Primeiros anos", entre Nascimento e Infância',
        () {
      final events = [
        _ev('inf', chapter: 'childhood'),
        _ev('pri', chapter: 'early_years'),
        _ev('nas', chapter: 'birth'),
      ];
      expect(events[1].dateLabel, 'Primeiros anos');
      expect(events.map((e) => e.lifeChapterOrder), [2, 1, 0]);
      final data = buildPatientInfographic(
        patient: Patient(id: 'p1', fullName: 'R', birthDate: birth),
        dashboard: _dash(),
        assessment: null,
        timelineEvents: events,
      );
      expect(data.timeline.map((e) => e.periodLabel),
          ['Nascimento', 'Primeiros anos', 'Infância']);
    });

    test('infográfico do paciente usa a mesma regra', () {
      final list = AuthorizedTimelineEntry.sortChronologically([
        AuthorizedTimelineEntry.fromJson({
          'id': 'x',
          'title': 'sem ref',
          'created_at': '2026-01-01T00:00:00Z',
        }),
        AuthorizedTimelineEntry.fromJson(
            {'id': 'c', 'title': 'capítulo', 'life_chapter': 'early_years'}),
        AuthorizedTimelineEntry.fromJson(
            {'id': 'a', 'title': 'idade', 'age_at_event': 4}),
        AuthorizedTimelineEntry.fromJson(
            {'id': 'd', 'title': 'data', 'event_date': '2012-04-02'}),
      ]);
      expect(list.map((e) => e.id), ['d', 'c', 'a', 'x']);
    });
  });

  group('PDF em A4', () {
    testWidgets('várias páginas A4 retrato com largura 595 pt', (tester) async {
      await tester.runAsync(() async {
        final png = await _png(1000, 4200);
        final pdf = await InfographicExport.buildPdf(png);
        final text = latin1.decode(pdf);
        final pages = RegExp(r'/Type\s*/Page(?![a-z])').allMatches(text).length;
        final bytes = (await (await ui.instantiateImageCodec(png))
                .getNextFrame()
                .then((f) => f.image.toByteData()))!
            .buffer
            .asUint8List();
        final maxRows = ((841.89 - 48) / ((595.28 - 48) / 1000)).floor();
        final expected = _plan(bytes, 1000, 4200, maxRows).length;
        expect(expected, greaterThan(1));
        expect(pages, expected);
        final boxes = RegExp(r'/MediaBox\s*\[\s*0\s+0\s+([\d.]+)\s+([\d.]+)')
            .allMatches(text)
            .toList();
        expect(boxes, isNotEmpty);
        for (final b in boxes) {
          expect(double.parse(b.group(1)!), closeTo(595.28, 0.5));
          expect(double.parse(b.group(2)!), closeTo(841.89, 0.5));
        }
      });
    });

    test('corte cai na faixa de fundo, não no meio do bloco', () {
      // blocos 0-60, 80-140, 160-220, 240-300 (faixas de fundo de 20 linhas)
      final rgba = _rgba(10, 300, [(0, 60), (80, 140), (160, 220), (240, 300)]);
      final cut = InfographicExport.pdfCutPoint(rgba, 10, 300, 0, 100);
      expect(cut, inInclusiveRange(60, 80)); // faixa 60-79 (cut exclusivo)
      final cuts = _plan(rgba, 10, 300, 100);
      for (final c in cuts.take(cuts.length - 1)) {
        // a última linha da fatia é de fundo (branca): nenhum bloco partido
        expect(rgba[((c - 1) * 10 + 5) * 4], 255);
      }
    });

    test('sem faixa de fundo corta no limite da página', () {
      final rgba = _rgba(10, 300, [(1, 300)]);
      expect(InfographicExport.pdfCutPoint(rgba, 10, 300, 0, 100), 100);
      expect(InfographicExport.pdfCutPoint(rgba, 10, 300, 100, 100), 200);
      expect(_plan(rgba, 10, 300, 100), [100, 200, 300]);
    });

    test('faixa só nos 35% de cima da página é ignorada (corta no limite)', () {
      final rgba = _rgba(10, 300, [(0, 20), (40, 300)]);
      expect(InfographicExport.pdfCutPoint(rgba, 10, 300, 0, 100), 100);
    });

    test('número de páginas e nenhuma fatia vazia', () {
      final rgba = _rgba(10, 500,
          [(0, 60), (80, 140), (160, 230), (250, 300), (320, 400), (420, 500)]);
      final cuts = _plan(rgba, 10, 500, 100);
      expect(cuts.last, 500);
      var prev = 0;
      for (final c in cuts) {
        expect(c, greaterThan(prev)); // fatia não vazia
        expect(c - prev, lessThanOrEqualTo(100)); // cabe na página
        prev = c;
      }
      expect(cuts.length, greaterThanOrEqualTo(5));
    });

    test('plano com escala: imagem 3x maior gera cortes proporcionais', () {
      final small = _rgba(10, 500,
          [(0, 60), (80, 140), (160, 230), (250, 300), (320, 400), (420, 500)]);
      final base = _plan(small, 10, 500, 100);
      // original 3x maior (30 x 1500), maxRows 300
      final cuts =
          InfographicExport.pdfCutsScaled(small, 10, 500, 30, 1500, 300);
      expect(cuts.length, base.length);
      var prev = 0;
      for (var i = 0; i < cuts.length; i++) {
        expect(cuts[i], greaterThan(prev));
        expect(cuts[i] - prev, lessThanOrEqualTo(300));
        expect((cuts[i] - base[i] * 3).abs(), lessThanOrEqualTo(3));
        prev = cuts[i];
      }
      expect(cuts.last, 1500);
    });

    test('pôster curto cabe em 1 página', () {
      expect(InfographicExport.pdfPageCount(1000, 900), 1);
    });
  });

  group('prévia do PDF', () {
    testWidgets('tocar em PDF abre a prévia e não compartilha direto',
        (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);
      const data = PatientInfographicData(
        header: InfographicHeader(name: 'Roberto Silva', avatarInitials: 'RS'),
        timeline: [
          InfographicTimelineEntry(
              periodLabel: '2010', description: 'Mudou-se de cidade.'),
        ],
        closingLine: 'Material de apoio.',
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            patientInfographicProvider.overrideWith((ref, ctx) => data),
          ],
          child: MaterialApp(
            home: PatientInfographicPage(
              role: ProfileRole.psychologist,
              patientId: 'p1',
              pdfViewerBuilder: (_, pdf) =>
                  Center(child: Text('visualizador ${pdf.isNotEmpty}')),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Prévia do PDF'), findsNothing);

      await tester.tap(find.text('PDF'));
      for (var i = 0; i < 8; i++) {
        await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 400)));
        await tester.pump(const Duration(milliseconds: 100));
        if (find.byType(InfographicPdfPreviewPage).evaluate().isNotEmpty) break;
      }
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(InfographicPdfPreviewPage), findsOneWidget);
      expect(find.text('Prévia do PDF'), findsOneWidget);
      expect(find.text('Compartilhar'), findsOneWidget);
      expect(find.text('visualizador true'), findsOneWidget);

      // Voltar fecha a prévia sem enviar nada.
      await tester.pageBack();
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(InfographicPdfPreviewPage), findsNothing);
      expect(find.text('PDF'), findsOneWidget);
    });

    Future<void> openPreview(
      WidgetTester tester,
      Future<void> Function(String, Uint8List) share,
    ) async {
      await tester.pumpWidget(MaterialApp(
        home: InfographicPdfPreviewPage(
          pdfBytes: Uint8List.fromList([1, 2, 3]),
          fileName: 'infografico-teste',
          viewerBuilder: (_, __) => const SizedBox(),
          shareFile: share,
        ),
      ));
      await tester.pump();
    }

    testWidgets('compartilhar com falha mostra aviso e reabilita o botão',
        (tester) async {
      var calls = 0;
      await openPreview(tester, (_, __) async {
        calls++;
        throw Exception('falhou');
      });
      await tester.tap(find.text('Compartilhar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(calls, 1);
      expect(find.text('Não foi possível compartilhar o PDF.'), findsOneWidget);
      final button = tester.widget<FilledButton>(find.byType(FilledButton));
      expect(button.onPressed, isNotNull);
      expect(find.text('Compartilhar'), findsOneWidget);
    });

    testWidgets('compartilhar com sucesso envia nome e bytes e não avisa erro',
        (tester) async {
      String? name;
      Uint8List? bytes;
      await openPreview(tester, (n, b) async {
        name = n;
        bytes = b;
      });
      await tester.tap(find.text('Compartilhar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(name, 'infografico-teste.pdf');
      expect(bytes, [1, 2, 3]);
      expect(find.text('Não foi possível compartilhar o PDF.'), findsNothing);
      expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
          isNotNull);
    });
  });
}
