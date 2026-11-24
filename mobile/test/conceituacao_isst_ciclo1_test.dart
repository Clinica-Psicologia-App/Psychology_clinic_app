import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:terapia_esquema/features/mental_map/data/case_conceptualization_repository.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/mental_map/domain/mental_map_data.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_edit_page.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_pdf.dart';
import 'package:terapia_esquema/features/mental_map/presentation/case_conceptualization_word.dart';
import 'package:terapia_esquema/features/mental_map/providers/case_conceptualization_providers.dart';
import 'package:terapia_esquema/features/profile/domain/profile_role.dart';

// Ciclo 1 da revisão do formato ISST (dados fictícios):
// (1) Data vazia no cabeçalho não vira data da exportação;
// (2) 11.1 "Reações pessoais do terapeuta ao cliente" vem ANTES do 11.2.

const _rotulo11_1 = '11.1 Reações pessoais do terapeuta ao cliente';

class _FakeRepo implements CaseConceptualizationRepository {
  CaseConceptualization? saved;

  @override
  Future<void> save(String patientId, CaseConceptualization data) async {
    saved = data;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

String _rtf(CaseConceptualization c) => String.fromCharCodes(
    CaseConceptualizationWord.buildBytes(data: MentalMapData.empty, concept: c));

CaseConceptualization _comRelacao({DateTime? date}) => CaseConceptualization(
      formHeader: CaseFormHeader(therapistName: 'Helena Prado', formDate: date),
      unmetNeeds: const [],
      modeSequences: const [],
      relationship: const TherapeuticRelationship(
        therapistReactions: 'Sinto acolhimento com a paciente fictícia.',
        collaborationNotes: 'Colabora bem.',
        bondNotes: 'Vínculo em formação.',
        otherFactors: 'Fator de teste.',
      ),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  logoTests();

  group('(1) Data vazia fica vazia', () {
    test('PDF: sem data digitada, o campo Data é vazio', () {
      expect(CaseConceptualizationPdf.headerDate(null), '');
      expect(CaseConceptualizationPdf.headerDate(const CaseFormHeader()), '');
      expect(
          CaseConceptualizationPdf.headerDate(
              CaseFormHeader(formDate: DateTime(2026, 11, 22))),
          '22/11/2026');
    });

    test('RTF: sem data digitada, a célula da Data fica vazia', () {
      final rtf = _rtf(_comRelacao());
      expect(rtf, contains(r'\b Data\b0\cell\pard\intbl\ql \cell\row'));
      final hoje = DateTime.now();
      final hojeStr = '${hoje.day.toString().padLeft(2, '0')}/'
          '${hoje.month.toString().padLeft(2, '0')}/${hoje.year}';
      // a data de hoje só pode aparecer no rodapé "Documento gerado em"
      final idx = rtf.indexOf(r'\b Data\b0');
      expect(rtf.substring(idx, idx + 80), isNot(contains(hojeStr)));
    });

    test('RTF: com data digitada, usa a data digitada', () {
      final rtf = _rtf(_comRelacao(date: DateTime(2026, 11, 22)));
      expect(rtf, contains(r'\b Data\b0\cell\pard\intbl\ql 22/11/2026\cell'));
    });
  });

  group('(2) 11.1 Reações pessoais do terapeuta, antes do 11.2', () {
    test('PDF: ordem 11.1, 11.2, 11.3, 11.4 com o rótulo do modelo', () {
      final h = CaseConceptualizationPdf.relationshipHeadings(
          _comRelacao().relationship);
      expect(h, [
        '11.1 Reações pessoais do terapeuta ao cliente',
        '11.2 Colaboração',
        '11.3 Vínculo de reparentalidade',
        '11.4 Outros',
      ]);
    });

    test('PDF: só 11.1 preenchido mostra só 11.1; sem 11.1 ele não aparece', () {
      expect(
          CaseConceptualizationPdf.relationshipHeadings(
              const TherapeuticRelationship(therapistReactions: 'x')),
          ['11.1 Reações pessoais do terapeuta ao cliente']);
      expect(
          CaseConceptualizationPdf.relationshipHeadings(
              const TherapeuticRelationship(collaborationNotes: 'x')),
          ['11.2 Colaboração']);
    });

    test('RTF: 11.1 vem antes de 11.2 e o texto não fica sob 11.4', () {
      final rtf = _rtf(_comRelacao());
      final i11 = rtf.indexOf('11.1 Rea');
      final i12 = rtf.indexOf('11.2 Colabora');
      final i14 = rtf.indexOf('11.4 Outros');
      expect(i11, greaterThan(-1));
      expect(i11, lessThan(i12));
      expect(i12, lessThan(i14));
      expect(rtf, contains(r"11.1 Rea\'e7\'f5es pessoais do terapeuta ao cliente"));
      expect(rtf, isNot(contains('Reações do terapeuta')));
      final texto = rtf.indexOf('Sinto acolhimento');
      expect(texto, greaterThan(i11));
      expect(texto, lessThan(i12), reason: 'o texto fica sob 11.1');
    });

    testWidgets('edição: 11.1 vem antes de 11.2 e salva no mesmo campo',
        (tester) async {
      tester.view.physicalSize = const Size(800, 40000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repo = _FakeRepo();
      final router = GoRouter(routes: [
        GoRoute(path: '/', builder: (_, __) => const Scaffold()),
        GoRoute(
          path: '/edit',
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
      unawaited(router.push<bool>('/edit'));
      await tester.pumpAndSettle();

      final f11_1 = find.widgetWithText(TextField, _rotulo11_1);
      expect(f11_1, findsOneWidget);
      final y11_1 = tester.getTopLeft(f11_1).dy;
      final y11_2 = tester
          .getTopLeft(find.widgetWithText(
              TextField, '11.2.2 Descrição da colaboração'))
          .dy;
      final y11_4 = tester
          .getTopLeft(find.widgetWithText(TextField, '11.4 Outros fatores'))
          .dy;
      expect(y11_1, lessThan(y11_2));
      expect(y11_2, lessThan(y11_4));
      expect(find.text('Reações do terapeuta ao cliente'), findsNothing);

      await tester.enterText(f11_1, 'Sinto acolhimento.');
      await tester.tap(find.text('Salvar conceitualização'));
      await tester.pumpAndSettle();
      expect(repo.saved!.relationship.therapistReactions, 'Sinto acolhimento.');
    });
  });
}

// Logo padrão do documento: a horizontal tem "Core" cortado na borda do próprio
// arquivo; o documento usa a principal (completa) e cabe inteira, sem cortar.
void logoTests() {
  group('logo padrão do documento', () {
    test('PDF e Word usam a logo principal (completa)', () {
      expect(CaseConceptualizationPdf.defaultLogoAsset,
          contains('esquema_core_logo_principal.png'));
      expect(CaseConceptualizationWord.defaultLogoAsset,
          contains('esquema_core_logo_principal.png'));
    });

    test('RTF embute a logo com a proporção do arquivo (sem cortar)', () {
      final bytes = File(CaseConceptualizationPdf.defaultLogoAsset).readAsBytesSync();
      final info = CaseConceptualizationWord.imageInfo(bytes)!;
      final rtf = String.fromCharCodes(CaseConceptualizationWord.buildBytes(
          data: MentalMapData.empty,
          concept: _comRelacao(),
          logoBytes: bytes));
      final w = int.parse(RegExp(r'\picwgoal(\d+)').firstMatch(rtf)!.group(1)!);
      final h = int.parse(RegExp(r'\pichgoal(\d+)').firstMatch(rtf)!.group(1)!);
      expect(w / h, closeTo(info.w / info.h, 0.01));
    });
  });
}
