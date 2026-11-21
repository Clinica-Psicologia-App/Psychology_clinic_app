import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:terapia_esquema/core/errors/app_exception.dart';
import 'package:terapia_esquema/core/errors/error_mapper.dart';
import 'package:terapia_esquema/features/life_story/domain/life_story_deepen_enums.dart';
import 'package:terapia_esquema/features/life_story/domain/life_timeline_event.dart';
import 'package:terapia_esquema/features/patient_timeline/domain/psychologist_option_labels.dart';

Map<String, dynamic> _row({
  List<String> needs = const [],
  List<String> areas = const [],
}) =>
    {
      'id': 'e1',
      'patient_id': 'p1',
      'title': 'Evento fictício',
      'emotional_need_keys': needs,
      'present_area_keys': areas,
      'emotion_keys': ['sad', 'chave_futura'],
      'category_keys': ['family', 'outra_futura'],
    };

void main() {
  group('modelo da paciente preserva chaves desconhecidas', () {
    test('lê as chaves da psicóloga sem perder e regrava intactas', () {
      final e = LifeTimelineEvent.fromJson(_row(
        needs: ['acceptance', 'connection_acceptance', 'limits_self_control'],
        areas: ['self_view', 'self_esteem', 'body'],
      ));
      expect(e.needs.map((n) => n.key), ['acceptance']);
      expect(
          e.unknownNeedKeys, ['connection_acceptance', 'limits_self_control']);
      expect(e.presentAreas.map((a) => a.key), ['self_view']);
      expect(e.unknownPresentAreaKeys, ['self_esteem', 'body']);

      final out = e.toRow();
      expect(out['emotional_need_keys'],
          ['acceptance', 'connection_acceptance', 'limits_self_control']);
      expect(out['present_area_keys'], ['self_view', 'self_esteem', 'body']);
      expect(out['emotion_keys'], ['sad', 'chave_futura']);
      expect(out['category_keys'], ['family', 'outra_futura']);
    });

    test('só chaves conhecidas: nada muda (sem desconhecidas)', () {
      final e = LifeTimelineEvent.fromJson(
          _row(needs: ['presence'], areas: ['family']));
      expect(e.unknownNeedKeys, isEmpty);
      expect(e.unknownPresentAreaKeys, isEmpty);
      expect(e.toRow()['emotional_need_keys'], ['presence']);
    });

    test('a paciente troca as escolhas dela; as da psicóloga seguem', () {
      final e = LifeTimelineEvent.fromJson(
          _row(needs: ['presence', 'recognition_value']));
      final edited = LifeTimelineEvent(
        id: e.id,
        patientId: e.patientId,
        title: e.title,
        needs: const [],
        unknownNeedKeys: e.unknownNeedKeys,
      );
      expect(edited.toRow()['emotional_need_keys'], ['recognition_value']);
    });
  });

  group('rótulos das chaves da psicóloga (mesmos textos do formulário dela)',
      () {
    test('as 6 necessidades e as 3 áreas não aparecem cruas', () {
      const needs = {
        'connection_acceptance': 'Conexão e Aceitação',
        'autonomy_competence_identity': 'Autonomia, competência e identidade',
        'limits_self_control': 'Limites e autocontrole',
        'expression_freedom': 'Liberdade de Expressão',
        'recognition_value': 'Valorização e reconhecimento',
        'spontaneity_leisure': 'Espontaneidade e Lazer',
      };
      needs.forEach((k, v) => expect(kEmotionalNeedLabels[k], v));
      expect(kPresentAreaLabels['self_esteem'], 'Autoestima');
      expect(kPresentAreaLabels['decisions'], 'Decisões');
      expect(kPresentAreaLabels['body'], 'Corpo');
    });

    test('chaves comuns mostram o texto do formulário da psicóloga', () {
      expect(kPresentAreaLabels['relationships'], 'Relações');
      expect(kPresentAreaLabels['emotions'], 'Emoções');
      expect(kPresentAreaLabels['work'], 'Trabalho');
      expect(kEmotionalNeedLabels['other'], 'Outra');
    });

    test('chave exclusiva da paciente usa o rótulo da paciente', () {
      expect(kEmotionalNeedLabels['acceptance'], 'Ser aceito(a) como eu era');
      expect(kPresentAreaLabels['self_view'], 'Como me vejo');
    });

    test('todas as opções do formulário têm rótulo', () {
      for (final o in kPsychologistEmotionalNeedOptions) {
        expect(kEmotionalNeedLabels.containsKey(o.$1), isTrue, reason: o.$1);
      }
      for (final o in kPsychologistPresentAreaOptions) {
        expect(kPresentAreaLabels.containsKey(o.$1), isTrue, reason: o.$1);
      }
    });
  });

  group('violação de CHECK (23514) na linha do tempo', () {
    test('mensagem clara, sem detalhe técnico', () {
      final ex = mapToAppException(const PostgrestException(
        message:
            'new row for relation "patient_timeline_events" violates check constraint "patient_timeline_events_emotional_need_keys_valid"',
        code: '23514',
      ));
      expect(ex.code, AppExceptionCodes.validation);
      expect(ex.message, contains('opções escolhidas não pôde ser salva'));
      expect(ex.message, isNot(contains('constraint')));
      expect(ex.message, isNot(contains('patient_timeline_events')));
      expect(userMessageFor(ex), ex.message);
    });

    test('CHECK de outra tabela não ganha a mensagem da linha do tempo', () {
      final ex = mapToAppException(const PostgrestException(
        message: 'violates check constraint "outra_tabela_x"',
        code: '23514',
      ));
      expect(ex.message, isNot(contains('opções escolhidas')));
    });
  });
}
