// Preview do pôster/infográfico do paciente (layout de revista) com dados de
// exemplo ricos.
//
//   flutter test test/tools/render_infographic.dart
//
// Saída: build/infographic.png
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_infographic/domain/patient_infographic_data.dart';
import 'package:terapia_esquema/features/patient_infographic/presentation/widgets/patient_infographic_poster.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_config.dart';
import 'package:terapia_esquema/features/profile/domain/avatar_type.dart';

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
      'roboto-bold.ttf'
    ]) {
      await ui.loadFontFromList(
        File('$dir\\$f').readAsBytesSync(),
        fontFamily: 'Roboto',
      );
    }
  });

  testWidgets('preview do infográfico', (tester) async {
    const purple = Color(0xFF7B5CF6);
    final data = PatientInfographicData(
      header: InfographicHeader(
        name: 'Marina',
        avatarInitials: 'M',
        avatarType: AvatarType.custom,
        avatarConfig: AvatarConfig.fromJson(const {}),
        facts: const [
          InfographicFact(Icons.person_outline, '31 anos'),
          InfographicFact(Icons.school_outlined, 'Ensino superior'),
          InfographicFact(Icons.place_outlined, 'Natural de Pelotas, RS'),
          InfographicFact(Icons.favorite_border, 'Noiva de Guilherme'),
          InfographicFact(Icons.work_outline, 'Arquiteta'),
          InfographicFact(Icons.psychology_alt_outlined, 'Início: ago/2025'),
        ],
      ),
      quote:
          'Sensível, dedicada e comprometida com tudo que faz. Tem um coração generoso e muita força para transformar desafios em crescimento.',
      personality: [
        InfographicPersonalityDomain(
            name: 'Neuroticismo',
            score: 69,
            classification: 'Muito alto',
            meaning: 'Sente intensamente e se preocupa com detalhes.',
            icon: Icons.psychology_outlined,
            accent: purple),
        InfographicPersonalityDomain(
            name: 'Extroversão',
            score: 74,
            classification: 'Muito alto',
            meaning: 'Sociável, comunicativa e carismática.',
            icon: Icons.groups_outlined,
            accent: purple),
        InfographicPersonalityDomain(
            name: 'Abertura',
            score: 56,
            classification: 'Alta',
            meaning: 'Curiosa, criativa e aberta a novas ideias.',
            icon: Icons.lightbulb_outline,
            accent: purple),
        InfographicPersonalityDomain(
            name: 'Amabilidade',
            score: 37,
            classification: 'Baixa',
            meaning: 'Direta, crítica e seletiva; valoriza autenticidade.',
            icon: Icons.favorite_border,
            accent: purple),
        InfographicPersonalityDomain(
            name: 'Consciensiosidade',
            score: 63,
            classification: 'Alta',
            meaning: 'Disciplinada, organizada e determinada.',
            icon: Icons.check_circle_outline,
            accent: purple),
      ],
      timeline: [
        InfographicTimelineEntry(
            periodLabel: '0–11 anos',
            description: 'Nasceu em Pelotas, RS, onde viveu até os 11 anos.',
            icon: Icons.home_outlined),
        InfographicTimelineEntry(
            periodLabel: 'Adolescência',
            description: 'Os pais se separaram.',
            icon: Icons.heart_broken_outlined,
            accent: Color(0xFFE0519A)),
        InfographicTimelineEntry(
            periodLabel: 'Atualidade',
            description: 'Mora com o companheiro; iniciou terapia.',
            icon: Icons.flight_outlined),
      ],
      schemas: [
        InfographicItem(
            title: 'Privação emocional',
            description:
                'Sente que suas necessidades nem sempre foram atendidas.',
            icon: Icons.favorite_border),
        InfographicItem(
            title: 'Abandono / instabilidade',
            description:
                'Medo de não receber atenção e de ser deixada de lado.',
            icon: Icons.person_off_outlined),
        InfographicItem(
            title: 'Padrões rígidos',
            description: 'Autocobrança alta; dificuldade em flexibilizar.',
            icon: Icons.rule_outlined),
      ],
      strengths: [
        InfographicItem(
            title: 'Comunicação e carisma',
            description: 'Sabe se expressar com clareza e influência positiva.',
            icon: Icons.star_outline),
        InfographicItem(
            title: 'Responsável e determinada',
            description: 'Transforma planos em ações e resultados.',
            icon: Icons.star_outline),
      ],
      directions: [
        InfographicItem(
            title: 'Fortalecer o autocuidado',
            description: 'Desenvolver autovalidação independente de terceiros.',
            icon: Icons.check_circle_outline),
        InfographicItem(
            title: 'Flexibilidade e limites',
            description: 'Trabalhar tolerância à frustração nas relações.',
            icon: Icons.check_circle_outline),
      ],
      needs: [
        InfographicNeed(
            need: 'Sentir-se amada de forma consistente',
            relatedEvents: 'Separação dos pais; perdas na adolescência.'),
        InfographicNeed(
            need: 'Ter segurança emocional e estabilidade',
            relatedEvents: 'Mudanças de cidade; perdas familiares.'),
      ],
      modes: [
        InfographicItem(
            title: 'Hipercompensação pelo desempenho',
            icon: Icons.emoji_events_outlined,
            bullets: [
              'Foco em resultados e produtividade.',
              'Precisa se destacar para se sentir valorizada.',
              'Pode ignorar o próprio cansaço.',
            ]),
        InfographicItem(
            title: 'Criança vulnerável',
            icon: Icons.child_care_outlined,
            bullets: [
              'Sente-se injustiçada quando não é reconhecida.',
              'Às vezes se sente insegura apesar de ter recursos.',
            ]),
      ],
      challenges: [
        InfographicItem(
            title: 'Relação com figuras de autoridade',
            description: 'Lidar com a sensação de não receber apoio esperado.',
            icon: Icons.report_problem_outlined),
        InfographicItem(
            title: 'Relações pessoais',
            description: 'Frustração quando o que recebe não é compatível.',
            icon: Icons.report_problem_outlined),
      ],
      resources: [
        InfographicItem(title: 'Resiliente', icon: Icons.shield_outlined),
        InfographicItem(title: 'Dedicada', icon: Icons.favorite_border),
        InfographicItem(title: 'Inteligente', icon: Icons.lightbulb_outline),
        InfographicItem(title: 'Criativa', icon: Icons.brush_outlined),
        InfographicItem(title: 'Empática', icon: Icons.diversity_1_outlined),
      ],
      closingLine:
          'Você já faz muito. Agora, mereça também o apoio e a leveza que sempre ofereceu aos outros.',
      generatedOn: DateTime(2026, 8, 3),
    );

    tester.view.physicalSize = const Size(1060, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: Scaffold(
          body: Center(
            child: RepaintBoundary(
              key: const Key('cap'),
              child: PatientInfographicPoster(data: data),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 80));

    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 2.0);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      png = bytes!.buffer.asUint8List();
    });
    File('build/infographic.png')
      ..parent.createSync(recursive: true)
      ..writeAsBytesSync(png);
    // ignore: avoid_print
    print('Gerado build/infographic.png');
  });
}
