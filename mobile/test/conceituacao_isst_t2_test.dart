import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/initial_assessment.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area.dart';
import 'package:terapia_esquema/features/initial_assessment/domain/life_area_assessment.dart';
import 'package:terapia_esquema/features/mental_map/data/case_conceptualization_repository.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_data.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_edit_page.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_pdf.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_word.dart';
import 'package:terapia_esquema/features/mental_map/providers/case_conceptualization_providers.dart';
import 'package:terapia_esquema/features/profile/data/document_logo_repository.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';
import 'package:terapia_esquema/features/profile/presentation/widgets/document_logo_card.dart';
import 'package:terapia_esquema/features/profile/providers/document_logo_providers.dart';

// PNG 1x1 válido (dados fictícios).
final Uint8List _png = base64Decode(
    'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNkYPhfDwAChwGA60e6kgAAAABJRU5ErkJggg==');

class _FakeConceptRepo implements CaseConceptualizationRepository {
  CaseConceptualization? saved;

  @override
  Future<void> save(String patientId, CaseConceptualization data) async {
    saved = data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeLogoRepo implements DocumentLogoRepository {
  _FakeLogoRepo(this.current);
  Uint8List? current;
  int uploads = 0;
  int removals = 0;

  @override
  Future<Uint8List?> downloadOwn() async => current;

  @override
  Future<void> upload({required Uint8List bytes, required String fileName}) async {
    uploads++;
    current = bytes;
  }

  @override
  Future<void> remove() async {
    removals++;
    current = null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('edição: cabeçalho, N/A (5), X (7.2) e 11.2/11.3/11.4', () {
    testWidgets('salva os novos campos', (tester) async {
      tester.view.physicalSize = const Size(800, 40000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _FakeConceptRepo();
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const CaseConceptualizationEditPage(
              role: ProfileRole.psychologist, patientId: 'p1'),
        ),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          caseConceptualizationProvider('p1')
              .overrideWith((ref) async => CaseConceptualization.empty()),
          caseConceptualizationRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();

      // cabeçalho
      await tester.enterText(
          find.widgetWithText(TextField, 'Nome da psicóloga'), 'Helena Prado');
      await tester.enterText(find.byKey(const Key('edit_fh_sessions')), '18');
      await tester.enterText(find.byKey(const Key('edit_fh_months')), '6');

      // 5: marca nota 3, depois N/A (excludentes), em outra área só a nota 4
      await tester.tap(find.byKey(const Key('func_occupational_3')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('func_occupational_na')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('func_family_relationships_4')));
      await tester.pump();

      // 7.2: X
      final firstNeed = kCoreNeeds.first.key;
      await tester.tap(find.byKey(Key('need_${firstNeed}_X')));
      await tester.pump();

      // 11.2.3, 11.3.3 e 11.4
      await tester.enterText(
          find.widgetWithText(TextField, '11.2.3 Como melhorar a colaboração'),
          'Combinar tarefas curtas.');
      await tester.enterText(
          find.widgetWithText(TextField, '11.3.3 Como fortalecer o vínculo'),
          'Mais escuta.');
      await tester.enterText(
          find.widgetWithText(TextField, '11.4 Outros fatores'), 'Fator X.');

      await tester.tap(find.text('Salvar conceitualização'));
      await tester.pumpAndSettle();

      final m = repo.saved!;
      expect(m.formHeader.therapistName, 'Helena Prado');
      expect(m.formHeader.sessionsCount, 18);
      expect(m.formHeader.monthsSinceFirst, 6);
      final occ = m.functioning.entryFor('occupational');
      expect(occ.notApplicable, isTrue);
      expect(occ.rating, isNull, reason: 'N/A descarta a nota');
      expect(m.functioning.entryFor('family_relationships').rating, 4);
      expect(m.needFor(firstNeed).rating, 'X');
      expect(m.needFor(firstNeed).isInsufficientInfo, isTrue);
      expect(m.relationship.collaborationImprove, 'Combinar tarefas curtas.');
      expect(m.relationship.bondStrengthen, 'Mais escuta.');
      expect(m.relationship.otherFactors, 'Fator X.');
      await tester.pump(const Duration(seconds: 10));
    });

    testWidgets('escolher nota depois de N/A tira o N/A', (tester) async {
      tester.view.physicalSize = const Size(800, 40000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _FakeConceptRepo();
      final router = GoRouter(routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const CaseConceptualizationEditPage(
              role: ProfileRole.psychologist, patientId: 'p1'),
        ),
      ]);
      addTearDown(router.dispose);
      await tester.pumpWidget(ProviderScope(
        overrides: [
          caseConceptualizationProvider('p1')
              .overrideWith((ref) async => CaseConceptualization.empty()),
          caseConceptualizationRepositoryProvider.overrideWithValue(repo),
        ],
        child: MaterialApp.router(routerConfig: router),
      ));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('func_occupational_na')));
      await tester.pump();
      await tester.tap(find.byKey(const Key('func_occupational_5')));
      await tester.pump();
      await tester.tap(find.text('Salvar conceitualização'));
      await tester.pumpAndSettle();
      final occ = repo.saved!.functioning.entryFor('occupational');
      expect(occ.notApplicable, isFalse);
      expect(occ.rating, 5);
      await tester.pump(const Duration(seconds: 10));
    });
  });

  group('logo no perfil (DocumentLogoCard)', () {
    Future<_FakeLogoRepo> mount(WidgetTester tester,
        {Uint8List? current, XFile? picked}) async {
      final repo = _FakeLogoRepo(current);
      await tester.pumpWidget(ProviderScope(
        overrides: [documentLogoRepositoryProvider.overrideWithValue(repo)],
        child: MaterialApp(
          home: Scaffold(
            body: DocumentLogoCard(pickImage: () async => picked),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      return repo;
    }

    test('validate: formato, vazio e 2 MB', () {
      expect(DocumentLogoCard.validate('a.png', 10), isNull);
      expect(DocumentLogoCard.validate('a.JPG', 10), isNull);
      expect(DocumentLogoCard.validate('a.webp', 10), isNull);
      expect(DocumentLogoCard.validate('a.gif', 10), contains('PNG, JPG ou WebP'));
      expect(DocumentLogoCard.validate('semextensao', 10), isNotNull);
      expect(DocumentLogoCard.validate('a.png', 0), contains('vazia'));
      expect(DocumentLogoCard.validate('a.png', 2 * 1024 * 1024 + 1),
          contains('2 MB'));
      expect(DocumentLogoCard.validate('a.png', 2 * 1024 * 1024), isNull);
    });

    testWidgets('sem logo: mostra "Logo padrão" e só Enviar', (tester) async {
      await mount(tester);
      expect(find.byKey(const Key('document_logo_default')), findsOneWidget);
      expect(find.text('Enviar logo'), findsOneWidget);
      expect(find.byKey(const Key('document_logo_remove')), findsNothing);
    });

    testWidgets('com logo: prévia, Trocar e Remover', (tester) async {
      final repo = await mount(tester, current: _png);
      expect(find.byKey(const Key('document_logo_preview')), findsOneWidget);
      expect(find.text('Trocar logo'), findsOneWidget);
      await tester.tap(find.byKey(const Key('document_logo_remove')));
      await tester.pumpAndSettle();
      expect(repo.removals, 1);
      expect(find.byKey(const Key('document_logo_default')), findsOneWidget);
    });

    testWidgets('envia PNG válido', (tester) async {
      final repo = await mount(tester,
          picked: XFile.fromData(_png, path: 'minha.png'));
      await tester.tap(find.byKey(const Key('document_logo_change')));
      await tester.pumpAndSettle();
      expect(repo.uploads, 1);
      expect(find.byKey(const Key('document_logo_preview')), findsOneWidget);
    });

    testWidgets('formato inválido: mensagem clara e nada é enviado',
        (tester) async {
      final repo = await mount(tester,
          picked: XFile.fromData(_png, path: 'logo.gif'));
      await tester.tap(find.byKey(const Key('document_logo_change')));
      await tester.pumpAndSettle();
      expect(repo.uploads, 0);
      expect(find.text('Formato não aceito. Use uma imagem PNG, JPG ou WebP.'),
          findsOneWidget);
    });

    testWidgets('arquivo acima de 2 MB: mensagem clara e nada é enviado',
        (tester) async {
      final big = Uint8List(2 * 1024 * 1024 + 1);
      final repo =
          await mount(tester, picked: XFile.fromData(big, path: 'grande.png'));
      await tester.tap(find.byKey(const Key('document_logo_change')));
      await tester.pumpAndSettle();
      expect(repo.uploads, 0);
      expect(find.text('A imagem tem mais de 2 MB. Escolha uma menor.'),
          findsOneWidget);
    });
  });

  group('exportação (PDF e Word)', () {
    final concept = CaseConceptualization(
      formHeader: CaseFormHeader(
        therapistName: 'Helena Prado',
        formDate: DateTime(2026, 11, 22),
        sessionsCount: 18,
        monthsSinceFirst: 6,
      ),
      unmetNeeds: const [UnmetNeed(needKey: 'conexao', rating: 'X')],
      modeSequences: const [],
      functioning: const FunctioningAssessment(entries: {
        'occupational': FunctioningEntry(rating: 4, explanation: 'Texto A'),
        'family_relationships': FunctioningEntry(notApplicable: true),
      }),
      relationship: const TherapeuticRelationship(
        collaborationRating: 3,
        collaborationNotes: 'Descricao colab',
        collaborationImprove: 'Melhorar colab',
        bondStrengthen: 'Fortalecer vinculo',
        otherFactors: 'Outros fatores texto',
      ),
    );
    final assessment = InitialAssessment(
      patientId: 'p1',
      lifeAreas: const [
        LifeAreaAssessment(area: LifeArea.workCareer, score: 6),
      ],
    );
    final data = MentalMapData.empty;

    test('imageInfo lê PNG e recusa o que não é PNG/JPEG', () {
      final i = CaseConceptualizationWord.imageInfo(_png)!;
      expect(i.type, 'png');
      expect(i.w, 1);
      expect(i.h, 1);
      expect(CaseConceptualizationWord.imageInfo(Uint8List.fromList([1, 2, 3])),
          isNull);
    });

    test('Word: cabeçalho, seção 1, 5 clínica x paciente, X, 11.2–11.4, logo', () {
      final rtf = String.fromCharCodes(CaseConceptualizationWord.buildBytes(
          data: data, concept: concept, assessment: assessment, logoBytes: _png));
      expect(rtf, contains('Helena Prado'));
      expect(rtf, contains('22/11/2026'));
      expect(rtf, contains('1. Informa'));
      expect(rtf, contains('Nota: N/A'));
      expect(rtf, contains('Nota: 4/6'));
      expect(rtf, contains('Dado da paciente'));
      expect(rtf, contains("n\\'e3o \\'e9")); // não é (escapado)
      expect(rtf, contains('X (informa'));
      expect(rtf, contains('11.2.3'));
      expect(rtf, contains('11.3.3'));
      expect(rtf, contains('11.4'));
      expect(rtf, contains('\\pngblip'));
      expect(rtf, contains('89504e47')); // assinatura PNG em hex
    });

    test('Word sem logo não embute imagem', () {
      final rtf = String.fromCharCodes(CaseConceptualizationWord.buildBytes(
          data: data, concept: concept, assessment: assessment));
      expect(rtf, isNot(contains('\\pict')));
    });

    test('PDF gera com logo própria, com logo padrão e com logo inválida',
        () async {
      for (final logo in [_png, null, Uint8List.fromList([1, 2, 3])]) {
        final bytes = await CaseConceptualizationPdf.build(
            data: data,
            concept: concept,
            assessment: assessment,
            logoBytes: logo);
        expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
        expect(bytes.length, greaterThan(2000));
      }
    });

    test('PDF de conceituação antiga (sem cabeçalho/N-A) continua gerando',
        () async {
      final bytes = await CaseConceptualizationPdf.build(
          data: data, concept: CaseConceptualization.empty());
      expect(String.fromCharCodes(bytes.sublist(0, 4)), '%PDF');
    });
  });
}
