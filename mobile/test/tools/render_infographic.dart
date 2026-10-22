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
import 'package:terapia_esquema/features/genogram/domain/genogram_data.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_gender.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_person.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship.dart';
import 'package:terapia_esquema/features/genogram/domain/genogram_relationship_type.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area.dart';
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
    final t0 = DateTime(2026, 1, 1);
    GenogramPerson person(
            String id, String name, String role, GenogramGender gender) =>
        GenogramPerson(
          id: id,
          clinicId: 'c',
          patientId: 'p',
          fullName: name,
          relationshipToPatient: role,
          gender: gender,
          isDeceased: false,
          isSensitive: false,
          createdAt: t0,
          updatedAt: t0,
        );
    GenogramRelationship rel(
            String id, String a, String b, GenogramRelationshipType type) =>
        GenogramRelationship(
          id: id,
          clinicId: 'c',
          patientId: 'p',
          personAId: a,
          personBId: b,
          relationshipType: type,
          isSensitive: false,
          createdAt: t0,
          updatedAt: t0,
        );

    final genogram = GenogramData(
      people: [
        person('pai', 'Pai', 'Pai', GenogramGender.male),
        person('mae', 'Mãe', 'Mãe', GenogramGender.female),
        person('eu', 'Marina', 'Paciente', GenogramGender.female),
        person('irm', 'Irmão', 'Irmão', GenogramGender.male),
        person('mar', 'Marido', 'Companheiro', GenogramGender.male),
        person('fil', 'Filha', 'Filha', GenogramGender.female),
      ],
      relationships: [
        rel('1', 'pai', 'mae', GenogramRelationshipType.separation),
        rel('2', 'pai', 'eu', GenogramRelationshipType.parentChild),
        rel('3', 'mae', 'eu', GenogramRelationshipType.parentChild),
        rel('4', 'pai', 'irm', GenogramRelationshipType.parentChild),
        rel('5', 'mae', 'irm', GenogramRelationshipType.parentChild),
        rel('6', 'eu', 'mar', GenogramRelationshipType.spouse),
        rel('7', 'eu', 'fil', GenogramRelationshipType.parentChild),
        rel('8', 'mar', 'fil', GenogramRelationshipType.parentChild),
      ],
    );

    final data = PatientInfographicData(
      header: InfographicHeader(
        name: 'Marina Silveira',
        avatarInitials: 'MS',
        avatarType: AvatarType.custom,
        avatarConfig: AvatarConfig.fromJson(const {}),
        facts: const [
          InfographicFact(Icons.person_outline, '32 anos'),
          InfographicFact(Icons.school_outlined, 'Ensino superior'),
          InfographicFact(Icons.place_outlined, 'Natural de Pelotas, RS'),
          InfographicFact(Icons.favorite_border, 'Casada'),
          InfographicFact(Icons.work_outline, 'Arquiteta'),
          InfographicFact(Icons.child_care_outlined, 'Tem filhos'),
        ],
      ),
      reasonsInitial:
          'Procurou terapia após uma separação, com ansiedade e dificuldade para dormir.',
      reasonsCurrent:
          'Cuido de todos e acabo ficando por último. Busca entender padrões nas relações.',
      demands: const [
        InfographicItem(
            title: 'Dificuldade de pedir ajuda',
            description: 'Sobrecarga no trabalho e em casa.',
            icon: Icons.flag_outlined,
            accent: Color(0xFF3B82F6)),
      ],
      lifeWheel: const {
        LifeArea.workCareer: 7,
        LifeArea.loveRomance: 3,
        LifeArea.family: 5,
        LifeArea.friends: 10,
        LifeArea.aloneTime: 4,
        LifeArea.physicalHealth: 8,
        LifeArea.emotionalHealth: 4,
        LifeArea.selfCare: 5,
        LifeArea.routineOrganization: 5,
      },
      personality: const [
        InfographicPersonalityDomain(
            name: 'Neuroticismo',
            score: 72,
            classification: 'Muito Alto',
            accent: Color(0xFFDC2626)),
        InfographicPersonalityDomain(
            name: 'Extroversão',
            score: 37,
            classification: 'Baixo',
            accent: Color(0xFFD97706)),
        InfographicPersonalityDomain(
            name: 'Abertura',
            score: 58,
            classification: 'Alto',
            accent: Color(0xFF059669)),
        InfographicPersonalityDomain(
            name: 'Amabilidade',
            score: 50,
            classification: 'Médio',
            accent: purple),
        InfographicPersonalityDomain(
            name: 'Conscienciosidade',
            score: 63,
            classification: 'Alto',
            accent: Color(0xFF3B82F6)),
      ],
      timeline: const [
        InfographicTimelineEntry(
            periodLabel: '8 anos',
            description: 'Os pais se separaram.',
            icon: Icons.event_note_outlined),
        InfographicTimelineEntry(
            periodLabel: '15 anos',
            description: 'Mudou de cidade e de escola.',
            icon: Icons.event_note_outlined,
            accent: Color(0xFF00B2A9)),
        InfographicTimelineEntry(
            periodLabel: 'Vida adulta',
            description: 'Casou-se e tornou-se mãe.',
            icon: Icons.event_note_outlined,
            accent: purple),
        InfographicTimelineEntry(
            periodLabel: 'Hoje',
            description: 'Iniciou a terapia.',
            icon: Icons.event_note_outlined,
            accent: Color(0xFF3B82F6)),
      ],
      genogram: genogram,
      genogramMembers: const [
        InfographicGenogramMember(name: 'Pai', relationship: 'Pai'),
      ],
      schemas: const [
        InfographicItem(
            title: 'Autossacrifício',
            description: 'Cuida do outro e adia as próprias necessidades.',
            icon: Icons.psychology_outlined,
            accent: purple),
        InfographicItem(
            title: 'Abandono / Instabilidade',
            description: 'Teme que discordar coloque o vínculo em risco.',
            icon: Icons.psychology_outlined,
            accent: purple),
        InfographicItem(
            title: 'Padrões Inflexíveis',
            description:
                'Exige desempenho elevado e se permite pouco descanso.',
            icon: Icons.psychology_outlined,
            accent: purple),
      ],
      attachment: const InfographicItem(
        title: 'Apego ansioso',
        description:
            'Deseja muita proximidade e teme rejeição ou abandono; tende a buscar confirmação constante do vínculo.',
        icon: Icons.link_outlined,
        accent: Color(0xFF3B82F6),
      ),
      modes: const [
        InfographicItem(
            title: 'Criança Vulnerável',
            description: 'Média 4,8 no YAMI',
            icon: Icons.theater_comedy_outlined,
            accent: Color(0xFF00B2A9)),
        InfographicItem(
            title: 'Pai Punitivo',
            description: 'Média 4,2 no YAMI',
            icon: Icons.theater_comedy_outlined,
            accent: Color(0xFF00B2A9)),
      ],
      coping: const [
        InfographicItem(
            title: 'Resignação',
            description: 'Média 4,1',
            icon: Icons.shield_outlined,
            accent: Color(0xFF0096D6)),
      ],
      resources: const [
        InfographicItem(
            title: 'Resiliência',
            icon: Icons.spa_outlined,
            accent: Color(0xFF059669)),
        InfographicItem(
            title: 'Capacidade reflexiva',
            icon: Icons.spa_outlined,
            accent: Color(0xFF059669)),
        InfographicItem(
            title: 'Rede familiar de apoio',
            icon: Icons.spa_outlined,
            accent: Color(0xFF059669)),
        InfographicItem(
            title: 'Senso de humor',
            icon: Icons.spa_outlined,
            accent: Color(0xFF059669)),
      ],
      plan: const [
        InfographicItem(
            title: 'Reconhecer necessidades e construir limites',
            description: 'Praticar pedir ajuda em situações pequenas.',
            bullets: ['Progresso: 40%'],
            icon: Icons.flag_outlined,
            accent: Color(0xFF7C6A9C)),
        InfographicItem(
            title: 'Negociar divisão de tarefas em casa',
            icon: Icons.flag_outlined,
            accent: Color(0xFF7C6A9C)),
      ],
      closingLine:
          'Um retrato de apoio à formulação do caso — sempre sob leitura clínica do profissional.',
      generatedOn: DateTime(2026, 10, 22),
    );

    tester.view.physicalSize = const Size(1060, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(fontFamily: 'Roboto'),
        home: Scaffold(
          body: SingleChildScrollView(
            child: Center(
              child: RepaintBoundary(
                key: const Key('cap'),
                child: PatientInfographicPoster(data: data),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.runAsync(() async {
      await precacheImage(
          const AssetImage('assets/branding/esquema_core_logo_principal.png'),
          tester.element(find.byKey(const Key('cap'))));
    });
    await tester.pump(const Duration(milliseconds: 200));

    final boundary = tester
        .renderObject<RenderRepaintBoundary>(find.byKey(const Key('cap')));
    late final Uint8List png;
    await tester.runAsync(() async {
      final image = await boundary.toImage(pixelRatio: 1.5);
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
