import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/mental_map/data/case_conceptualization_repository.dart';
import 'package:terapia_esquema/features/mental_map/domain/case_conceptualization.dart';
import 'package:terapia_esquema/features/profile/data/document_logo_repository.dart';

void main() {
  group('cabeçalho do formulário (form_header)', () {
    test('ida e volta do JSON', () {
      final h = CaseFormHeader(
        therapistName: '  Psicóloga Fictícia ',
        formDate: DateTime(2026, 11, 22),
        sessionsCount: 12,
        monthsSinceFirst: 3,
      );
      expect(h.toJson(), {
        'therapist_name': 'Psicóloga Fictícia',
        'form_date': '2026-11-22',
        'sessions_count': 12,
        'months_since_first': 3,
      });
      final back = CaseFormHeader.fromJson(h.toJson());
      expect(back.therapistName, 'Psicóloga Fictícia');
      expect(back.formDate, DateTime(2026, 11, 22));
      expect(back.sessionsCount, 12);
      expect(back.monthsSinceFirst, 3);
    });

    test('vazio vira {} e valores negativos são descartados', () {
      expect(const CaseFormHeader().toJson(), isEmpty);
      expect(const CaseFormHeader().isEmpty, isTrue);
      final h = CaseFormHeader.fromJson(
          {'sessions_count': -2, 'months_since_first': -1, 'form_date': 'x'});
      expect(h.sessionsCount, isNull);
      expect(h.monthsSinceFirst, isNull);
      expect(h.formDate, isNull);
    });

    test('documento antigo (sem form_header) abre com cabeçalho vazio', () {
      final c = CaseConceptualization.fromJson({'unmet_needs': []});
      expect(c.formHeader.isEmpty, isTrue);
    });

    test('vai ao banco como form_header ({} quando vazio, nunca null)', () {
      final empty = synthesisColumns(CaseConceptualization.empty());
      expect(empty['form_header'], <String, dynamic>{});
      final c = CaseConceptualization.fromJson({
        'form_header': {'therapist_name': 'Fulana', 'sessions_count': 4},
      });
      expect(synthesisColumns(c)['form_header'],
          {'therapist_name': 'Fulana', 'sessions_count': 4});
    });
  });

  group('seção 5: N/A', () {
    test('N/A grava not_applicable e descarta a nota', () {
      const e = FunctioningEntry(rating: 4, notApplicable: true);
      expect(e.rating, isNull);
      expect(e.toJson(), {'not_applicable': true});
      expect(e.isEmpty, isFalse);
    });

    test('lê not_applicable; formato antigo (só nota) segue igual', () {
      final na = FunctioningEntry.fromJson(
          {'not_applicable': true, 'explanation': 'sem emprego por ora'});
      expect(na.notApplicable, isTrue);
      expect(na.rating, isNull);
      final old = FunctioningEntry.fromJson({'rating': 5, 'explanation': 'ok'});
      expect(old.notApplicable, isFalse);
      expect(old.rating, 5);
      expect(old.toJson(), {'rating': 5, 'explanation': 'ok'});
    });

    test('ida e volta pela avaliação completa', () {
      final f = FunctioningAssessment.fromJson({
        'occupational': {'not_applicable': true},
        'lifestyle': {'rating': 2},
      });
      expect(f.entryFor('occupational').notApplicable, isTrue);
      expect(f.entryFor('lifestyle').rating, 2);
      expect(f.toJson(), {
        'occupational': {'not_applicable': true},
        'lifestyle': {'rating': 2},
      });
    });
  });

  group('7.2: nota X', () {
    test('X é aceita e preservada; lista de notas da tela', () {
      expect(kUnmetNeedRatings, ['0', '1', '3', '5', 'X']);
      final c = CaseConceptualization.fromJson({
        'unmet_needs': [
          {'need_key': 'conexao', 'rating': 'X', 'origin': 'o'},
          {'need_key': 'valor', 'rating': '2'}, // valor antigo: não se perde
        ],
      });
      expect(c.needFor('conexao').isInsufficientInfo, isTrue);
      final back = c.unmetNeedsJson();
      expect(back.first['rating'], 'X');
      expect(back.last['rating'], '2');
    });
  });

  group('11: 11.2/11.3 em dois campos + 11.4', () {
    test('texto antigo continua como descrição, sem perder nada', () {
      final r = TherapeuticRelationship.fromJson({
        'collaboration_rating': 4,
        'collaboration_notes': 'texto único antigo A',
        'bond_rating': 3,
        'bond_notes': 'texto único antigo B',
        'therapist_reactions': 'reações',
      });
      expect(r.collaborationNotes, 'texto único antigo A');
      expect(r.bondNotes, 'texto único antigo B');
      expect(r.collaborationImprove, isNull);
      expect(r.bondStrengthen, isNull);
      expect(r.otherFactors, isNull);
      // regravar não muda nada do que existia
      expect(r.toJson(), {
        'collaboration_rating': 4,
        'collaboration_notes': 'texto único antigo A',
        'bond_rating': 3,
        'bond_notes': 'texto único antigo B',
        'therapist_reactions': 'reações',
      });
    });

    test('campos novos fazem ida e volta e contam para isEmpty', () {
      const r = TherapeuticRelationship(
        collaborationImprove: 'melhorar',
        bondStrengthen: 'fortalecer',
        otherFactors: 'outros',
      );
      expect(r.isEmpty, isFalse);
      final back = TherapeuticRelationship.fromJson(r.toJson());
      expect(back.collaborationImprove, 'melhorar');
      expect(back.bondStrengthen, 'fortalecer');
      expect(back.otherFactors, 'outros');
      expect(const TherapeuticRelationship(otherFactors: ' ').isEmpty, isTrue);
    });
  });

  group('logo do documento', () {
    test('path = {uid}/logo.ext, igual ao regex do banco', () {
      const uid = 'ff000000-0000-4000-8000-0000000000a1';
      final re = RegExp('^$uid/logo\\.(png|jpg|jpeg|webp)\$');
      for (final ext in DocumentLogoRepository.allowedExtensions) {
        expect(re.hasMatch(DocumentLogoRepository.pathFor(uid, ext)), isTrue);
      }
    });

    test('só imagens png/jpg/jpeg/webp', () {
      expect(DocumentLogoRepository.extensionOf('Minha Logo.PNG'), 'png');
      expect(DocumentLogoRepository.extensionOf('a.webp'), 'webp');
      expect(DocumentLogoRepository.extensionOf('a.gif'), isNull);
      expect(DocumentLogoRepository.extensionOf('semextensao'), isNull);
      expect(DocumentLogoRepository.extensionOf('a.'), isNull);
    });
  });
}
