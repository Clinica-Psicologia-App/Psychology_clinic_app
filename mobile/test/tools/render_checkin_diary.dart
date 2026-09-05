// Prova visual do diário de check-ins com os widgets reais do app.
//
//   flutter test test/tools/render_checkin_diary.dart
//
// Saídas: build/checkin_diario.png (paciente) e build/checkin_diario_staff.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_colors.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/patient_check_ins/domain/check_in_diary_stats.dart';
import 'package:terapia_esquema/features/patient_check_ins/domain/patient_check_in.dart';
import 'package:terapia_esquema/features/patient_check_ins/presentation/widgets/check_in_diary_widgets.dart';

PatientCheckIn _ci(
  String id,
  DateTime at, {
  int? mood,
  int? anxiety,
  int? energy,
  int? problems,
  String? notes,
}) =>
    PatientCheckIn(
      id: id,
      clinicId: 'c',
      patientId: 'p',
      moodScore: mood,
      anxietyScore: anxiety,
      energyScore: energy,
      problemIntensityScore: problems,
      notes: notes,
      checkedInAt: at,
      createdAt: at,
      updatedAt: at,
    );

/// Do mais recente para o mais antigo, como o repositório devolve. As datas
/// são relativas a hoje para o "hoje"/sequência baterem na renderização.
List<PatientCheckIn> _items({required bool withToday}) {
  final today = DateTime.now();
  DateTime d(int back, int h, int m) => DateTime(
      today.year, today.month, today.day - back, h, m);
  return [
    if (withToday)
      _ci('t', d(0, 8, 12),
          mood: 7,
          anxiety: 3,
          energy: 8,
          problems: 2,
          notes: 'Acordei leve. Vou tentar manter o ritmo de ontem.'),
    _ci('a', d(1, 21, 38),
        mood: 7,
        anxiety: 3,
        energy: 8,
        problems: 2,
        notes: 'Estou bem melhor hoje! Consegui sair para caminhar e '
            'liguei para a minha irmã.'),
    _ci('b', d(2, 18, 3),
        mood: 4,
        anxiety: 8,
        energy: 3,
        problems: 7,
        notes: 'Sinto que estou no automático.'),
    _ci('c', d(3, 8, 15), mood: 6, anxiety: 5, energy: 6, problems: 4),
    _ci('d', d(8, 22, 40),
        mood: 3,
        anxiety: 9,
        energy: 2,
        problems: 8,
        notes: 'Semana difícil no trabalho. Dormi mal de novo.'),
    _ci('e', d(40, 19, 5), mood: 5, anxiety: 6, energy: 5, problems: 5),
  ];
}

void main() {
  setUpAll(() async {
    const dir = r'C:\Users\bruno\flutter\bin\cache\artifacts\material_fonts';
    await ui.loadFontFromList(
      File('$dir\\materialicons-regular.otf').readAsBytesSync(),
      fontFamily: 'MaterialIcons',
    );
    for (final f in ['Poppins-Regular.ttf', 'Poppins-Bold.ttf']) {
      await ui.loadFontFromList(
        File('assets/fonts/$f').readAsBytesSync(),
        fontFamily: 'Poppins',
      );
    }
  });

  Future<void> shoot(
    WidgetTester tester,
    String file,
    Widget body, {
    double height = 1200,
  }) async {
    tester.view.physicalSize = Size(390 * 2, height * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final theme = AppTheme.light;
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: const Locale('pt', 'BR'),
      supportedLocales: const [Locale('pt', 'BR')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'Poppins'),
      ),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: RepaintBoundary(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: body,
            ),
          ),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byType(RepaintBoundary).first);
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

  Widget diary(BuildContext context, List<PatientCheckIn> items,
      {required bool patientView}) {
    final loc = MaterialLocalizations.of(context);
    final blocks = <Widget>[];
    if (patientView) {
      blocks.add(CheckInDiaryCover(stats: buildDiaryStats(items)));
      blocks.add(const SizedBox(height: 16));
      if (!items.any((c) => c.isToday)) {
        blocks.add(CheckInBlankPage(onWrite: () {}));
        blocks.add(const SizedBox(height: 16));
      }
    }
    String? month;
    for (var i = 0; i < items.length; i++) {
      final m = loc.formatMonthYear(items[i].checkedInAt);
      if (m != month) {
        month = m;
        blocks.add(CheckInMonthDivider(label: m));
      }
      final lastOfMonth = i == items.length - 1 ||
          loc.formatMonthYear(items[i + 1].checkedInAt) != m;
      blocks.add(CheckInDiaryEntry(
        checkIn: items[i],
        isToday: items[i].isToday,
        isLast: lastOfMonth,
        onTap: () {},
      ));
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: blocks,
    );
  }

  testWidgets('diário do paciente — hoje em branco', (tester) async {
    await shoot(
      tester,
      'checkin_diario.png',
      Builder(
        builder: (c) => diary(c, _items(withToday: false), patientView: true),
      ),
    );
  });

  testWidgets('diário do paciente — hoje escrito', (tester) async {
    await shoot(
      tester,
      'checkin_diario_hoje.png',
      Builder(
        builder: (c) => diary(c, _items(withToday: true), patientView: true),
      ),
    );
  });

  testWidgets('diário na visão do psicólogo', (tester) async {
    await shoot(
      tester,
      'checkin_diario_staff.png',
      Builder(
        builder: (c) => diary(c, _items(withToday: true), patientView: false),
      ),
      height: 900,
    );
  });
}
