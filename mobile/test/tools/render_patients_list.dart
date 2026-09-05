// Prova visual da lista de pacientes agrupada por urgência: usa os widgets
// reais (PatientGroupHeader + PatientListTile) e o corte real de attentionFor.
//
//   flutter test test/tools/render_patients_list_options.dart
//
// Saída: build/pacientes_lista.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/core/theme/app_colors.dart';
import 'package:terapia_esquema/core/theme/app_theme.dart';
import 'package:terapia_esquema/features/patients/domain/patient.dart';
import 'package:terapia_esquema/features/patients/domain/patient_attention.dart';
import 'package:terapia_esquema/features/patients/domain/patient_data_completion.dart';
import 'package:terapia_esquema/features/patients/presentation/widgets/patient_list_tile.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_config.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_type.dart';

class _Row {
  const _Row(this.patient, this.completion, this.missingDays,
      {this.pendingRelease = false});
  final Patient patient;
  final PatientDataCompletion completion;
  final int? missingDays;
  final bool pendingRelease;

  PatientAttention? get attention => attentionFor(
        patient: patient,
        hasPendingResultsRelease: pendingRelease,
        checkinMissingDays: missingDays,
        completion: completion,
      );
}

Patient _p(String id, String name, String email, {bool active = true}) =>
    Patient(
      id: id,
      fullName: name,
      email: email,
      isActive: active,
      avatarType: AvatarType.custom,
      avatarConfig: AvatarConfig.fromJson(const {}),
    );

PatientDataCompletion _c(String id, List<bool> f) => PatientDataCompletion(
      patientId: id,
      perfil: f[0],
      queixa: f[1],
      areas: f[2],
      historia: f[3],
      familia: f[4],
      questionarios: f[5],
    );

final _rows = <_Row>[
  _Row(_p('1', 'Roberto', 'roberto.paciente@gmail.com'),
      _c('1', [true, true, true, true, true, true]), 999),
  _Row(_p('2', 'Pedro', 'pedro.paciente@gmail.com'),
      _c('2', [false, false, false, false, false, false]), 1),
  _Row(_p('3', 'Maria', 'maria.paciente@gmail.com'),
      _c('3', [true, true, true, true, true, true]), 2),
  _Row(_p('4', 'Ana', 'ana.paciente@gmail.com'),
      _c('4', [true, true, true, false, false, false]), 1,
      pendingRelease: true),
  _Row(_p('5', 'Lucas', 'lucas.paciente@gmail.com'),
      _c('5', [true, true, false, false, false, false]), 4),
  _Row(_p('6', 'Beatriz', 'bia.paciente@gmail.com'),
      _c('6', [true, true, true, true, false, true]), 0),
  _Row(_p('7', 'Caio', 'caio.paciente@gmail.com', active: false),
      _c('7', [true, true, true, true, true, true]), null),
];

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

  testWidgets('lista agrupada por urgência', (tester) async {
    tester.view.physicalSize = const Size(390 * 2, 800 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(tester.view.reset);

    final urgent = _rows.where((r) => r.attention != null).toList()
      ..sort((a, b) => a.attention!.rank.compareTo(b.attention!.rank));
    final ok = _rows
        .where((r) => r.patient.isActive && r.attention == null)
        .toList();
    final inactive = _rows.where((r) => !r.patient.isActive).toList();

    Widget tile(_Row r) => PatientListTile(
          patient: r.patient,
          attention: r.attention,
          checkinMissingDays: r.missingDays,
          dataCompletion: r.completion,
          onTap: () {},
        );

    final theme = AppTheme.light;
    await tester.pumpWidget(MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: theme.copyWith(
        textTheme: theme.textTheme.apply(fontFamily: 'Poppins'),
      ),
      home: Scaffold(
        backgroundColor: AppColors.background,
        body: RepaintBoundary(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                PatientGroupHeader(
                    label: 'Precisam de atenção',
                    count: urgent.length,
                    color: AppColors.error),
                ...urgent.map(tile),
                PatientGroupHeader(
                    label: 'Em dia',
                    count: ok.length,
                    color: AppColors.success,
                    topSpacing: 16),
                ...ok.map(tile),
                PatientGroupHeader(
                    label: 'Inativos',
                    count: inactive.length,
                    color: theme.colorScheme.onSurfaceVariant,
                    topSpacing: 16),
                ...inactive.map(tile),
                const SizedBox(height: 16),
              ],
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
    File('build/pacientes_lista.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/pacientes_lista.png');
  });
}
