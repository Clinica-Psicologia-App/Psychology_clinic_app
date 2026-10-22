import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../initial_assessment/domain/initial_assessment.dart';
import '../domain/case_conceptualization.dart';
import '../domain/mental_map_data.dart';

/// Exporta a Conceitualização de caso como um arquivo RTF editável em Word.
/// Usa geração pura em Dart — sem pacotes adicionais. O formato RTF é
/// nativamente suportado pelo Microsoft Word e LibreOffice.
class CaseConceptualizationWord {
  const CaseConceptualizationWord._();

  static Future<void> shareOrOpen({
    required MentalMapData data,
    CaseConceptualization? concept,
    InitialAssessment? assessment,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Export em Word não disponível na versão web.',
      );
    }
    final bytes = _build(data: data, concept: concept, assessment: assessment);
    final dir = await getTemporaryDirectory();
    final name = _fileName(data.patientName);
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/rtf')],
      text: 'Formulação de Caso — ${data.patientName}',
    );
  }

  static String _fileName(String name) {
    final safe = name
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]'), '_')
        .replaceAll(RegExp(r'_+'), '_');
    return 'formulacao_${safe}.rtf';
  }

  static Uint8List _build({
    required MentalMapData data,
    CaseConceptualization? concept,
    InitialAssessment? assessment,
  }) {
    final buf = StringBuffer();
    final c = concept;
    final s = data.caseSummary;
    final core = data.clinicalCore;
    final imp = assessment?.clinicalImpressions;
    final now = DateTime.now();
    final dateStr =
        '${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}';

    // ── RTF header ──────────────────────────────────────────────────────────
    buf.write(
      r'{\rtf1\ansi\ansicpg1252\deff0'
      r'{\fonttbl{\f0\fswiss\fcharset0 Arial;}{\f1\fnil\fcharset0 Arial;}}'
      r'{\colortbl;\red13\green27\blue61;\red74\green85\blue104;'
      r'\red59\green130\blue246;\red255\green255\blue255;}'
      '\n'
      r'\paperw12240\paperh15840\margl1800\margr1800\margt1440\margb1440'
      '\n'
      r'\f0\fs22\cf0'
      '\n',
    );

    // ── Capa ────────────────────────────────────────────────────────────────
    _heading(buf, 'FORMULAÇÃO DE CASO', size: 40, center: true);
    _heading(buf, 'Terapia do Esquema', size: 28, center: true);
    _blank(buf);
    _field(buf, 'Paciente', data.patientName);
    _field(buf, 'Data', dateStr);
    if ((assessment?.basics?.preferredName ?? '').trim().isNotEmpty) {
      _field(buf, 'Nome preferido', assessment!.basics!.preferredName!);
    }
    _divider(buf);

    // ── Seção 2 — Motivo da busca ────────────────────────────────────────────
    _sectionTitle(buf, '2. Motivo da Busca / Queixa Principal');
    if ((s.patientReason ?? '').trim().isNotEmpty) {
      _label(buf, 'Relatado pelo paciente');
      _body(buf, s.patientReason!);
    }
    if ((s.currentLifeContext ?? '').trim().isNotEmpty) {
      _label(buf, 'Contexto de vida atual');
      _body(buf, s.currentLifeContext!);
    }
    if ((s.therapyDemands ?? '').trim().isNotEmpty) {
      _label(buf, 'Demandas terapêuticas');
      _body(buf, s.therapyDemands!);
    }
    if ((c?.motivoInitial ?? '').trim().isNotEmpty) {
      _label(buf, 'a. Inicialmente');
      _body(buf, c!.motivoInitial!);
    }
    if ((c?.motivoCurrent ?? '').trim().isNotEmpty) {
      _label(buf, 'b. Atualmente');
      _body(buf, c!.motivoCurrent!);
    }
    if ((c?.motivoInitial ?? '').isEmpty &&
        (s.patientReason ?? '').isEmpty &&
        (s.therapyDemands ?? '').isEmpty) {
      _empty(buf);
    }
    _divider(buf);

    // ── Seção 3 — Impressões gerais ──────────────────────────────────────────
    _sectionTitle(buf, '3. Impressões Gerais');
    if (c?.hasGeneralImpressions == true) {
      if ((c!.generalImpressions.initial ?? '').trim().isNotEmpty) {
        _label(buf, 'Impressão inicial');
        _body(buf, c.generalImpressions.initial!);
      }
      if ((c.generalImpressions.current ?? '').trim().isNotEmpty) {
        _label(buf, 'Impressão atual');
        _body(buf, c.generalImpressions.current!);
      }
    } else if ((imp?.observedTemperament ?? '').trim().isNotEmpty) {
      _body(buf, imp!.observedTemperament!);
    } else {
      _empty(buf);
    }
    _divider(buf);

    // ── Seção 4 — Diagnóstico ────────────────────────────────────────────────
    _sectionTitle(buf, '4. Diagnóstico');
    if (c?.hasDiagnosis == true) {
      if ((c!.diagnosis.system ?? '').trim().isNotEmpty) {
        _label(buf, 'Sistema diagnóstico');
        _body(buf, c.diagnosis.system!);
      }
      if (c.diagnosis.noDiagnosis) {
        _body(buf, 'Sem diagnóstico estabelecido no momento.');
      }
      for (final d in c.diagnosis.items) {
        if (d.isEmpty) continue;
        final diag = [
          if ((d.name ?? '').trim().isNotEmpty) d.name!.trim(),
          if ((d.code ?? '').trim().isNotEmpty) '(${d.code!.trim()})',
          if (d.metaLine(c.diagnosis.system) != null)
            '— ${d.metaLine(c.diagnosis.system)}',
          if ((d.notes ?? '').trim().isNotEmpty) '— ${d.notes!.trim()}',
        ].join(' ');
        _bullet(buf, diag);
      }
    } else {
      _empty(buf);
    }
    _divider(buf);

    // ── Seção 5 — Funcionamento ──────────────────────────────────────────────
    _sectionTitle(buf, '5. Funcionamento Global');
    if (c?.hasFunctioning == true) {
      for (final area in kFunctioningAreas) {
        final entry = c!.functioning.entryFor(area.key);
        if (entry.isEmpty) continue;
        _label(buf, '${area.code} — ${area.label}');
        if (entry.rating != null) {
          _body(buf, 'Avaliação: ${entry.rating}/6');
        }
        if ((entry.explanation ?? '').trim().isNotEmpty) {
          _body(buf, entry.explanation!);
        }
      }
    } else {
      _empty(buf);
    }
    _divider(buf);

    // ── Seção 6 — Problemas de vida ──────────────────────────────────────────
    _sectionTitle(buf, '6. Principais Problemas de Vida');
    final probs = [
      c?.lifeProblems.problem1,
      c?.lifeProblems.problem2,
      c?.lifeProblems.problem3,
      c?.lifeProblems.problem4,
    ].where((p) => (p ?? '').trim().isNotEmpty).cast<String>().toList();
    if (probs.isNotEmpty) {
      for (final p in probs) {
        _bullet(buf, p);
      }
    } else if (data.activeProblems.isNotEmpty) {
      for (final p in data.activeProblems.take(6)) {
        _bullet(buf, p.title);
      }
    } else {
      _empty(buf);
    }
    _divider(buf);

    // ── Seção 7 — Origens ────────────────────────────────────────────────────
    _sectionTitle(buf, '7. Origens dos Esquemas');
    if (c?.hasOrigins == true) {
      if ((c!.origins.earlyHistory ?? '').trim().isNotEmpty) {
        _label(buf, '7.1 História inicial');
        _body(buf, c.origins.earlyHistory!);
      }
      if ((c.origins.temperament ?? '').trim().isNotEmpty) {
        _label(buf, '7.3 Fatores temperamentais/biológicos');
        _body(buf, c.origins.temperament!);
      }
      if ((c.origins.cultural ?? '').trim().isNotEmpty) {
        _label(buf, '7.4 Fatores culturais, étnicos e religiosos');
        _body(buf, c.origins.cultural!);
      }
    } else {
      _empty(buf);
    }
    _blank(buf);

    _label(buf, '7.2 Necessidades emocionais não atendidas');
    if (c?.hasAnyNeed == true) {
      for (final n in kCoreNeeds) {
        final u = c!.needFor(n.key);
        if (u.isEmpty) continue;
        _label(buf, n.label, indent: true);
        if ((u.rating ?? '').trim().isNotEmpty) {
          _body(buf, 'Avaliação: ${u.rating}');
        }
        if ((u.origin ?? '').trim().isNotEmpty) {
          _body(buf, 'Origem: ${u.origin!}');
        }
        if ((u.schemas ?? '').trim().isNotEmpty) {
          _body(buf, 'Esquemas: ${u.schemas!}');
        }
      }
    } else {
      _empty(buf);
    }
    _divider(buf);

    // ── Seção 8 — Esquemas ───────────────────────────────────────────────────
    _sectionTitle(buf, '8. Esquemas');
    if ((c?.allSchemas ?? '').trim().isNotEmpty) {
      _label(buf, '8.1 Todos os esquemas identificados');
      _body(buf, c!.allSchemas!);
    } else if (core.topSchemas.isNotEmpty) {
      _label(buf, '8.1 Esquemas identificados (dashboard)');
      for (final sc in core.topSchemas.take(10)) {
        _bullet(buf, sc.name.trim().isEmpty ? sc.code : sc.name);
      }
    }
    _blank(buf);
    _label(buf, '8.2 Esquemas centrais (4–6)');
    if (c?.hasCentralSchemas == true) {
      for (final cs in c!.centralSchemas) {
        if (cs.isEmpty) continue;
        _label(buf, cs.name ?? '(sem nome)', indent: true);
        if ((cs.description ?? '').trim().isNotEmpty) {
          _body(buf, cs.description!);
        }
      }
    } else {
      _empty(buf);
    }
    _divider(buf);

    // ── Seção 9 — Modos ─────────────────────────────────────────────────────
    _sectionTitle(buf, '9. Avaliação dos Modos de Esquema');
    if (c?.hasModeAssessment == true) {
      final ma = c!.modeAssessment;

      // 9.1 Modos saudáveis
      if (!ma.healthyModes.isEmpty) {
        _label(buf, '9.1 Modos saudáveis');
        _maybeLine(buf, 'Criança Feliz — Espontaneidade',
            ma.healthyModes.happyChildSpontaneity);
        _maybeLine(buf, 'Criança Feliz — Jogo', ma.healthyModes.happyChildPlay);
        _maybeLine(buf, 'Criança Feliz — Criatividade',
            ma.healthyModes.happyChildCreativity);
        _maybeLine(buf, 'Adulto Saudável — Metaconsciência',
            ma.healthyModes.adultMetaAwareness);
        _maybeLine(buf, 'Adulto Saudável — Conexão emocional',
            ma.healthyModes.adultEmotionalConnection);
        _maybeLine(buf, 'Adulto Saudável — Identidade',
            ma.healthyModes.adultIdentity);
        _maybeLine(buf, 'Adulto Saudável — Autoafirmação',
            ma.healthyModes.adultSelfAssertion);
        _maybeLine(
            buf, 'Adulto Saudável — Esperança', ma.healthyModes.adultHope);
      }

      // 9.2 Criança Vulnerável
      if (!ma.vulnerableChild.isEmpty) {
        _label(buf, '9.2a Criança Vulnerável');
        _maybeLine(buf, 'Descrição', ma.vulnerableChild.description);
        _maybeLine(buf, 'Esquemas', ma.vulnerableChild.schemas);
        for (var i = 0; i < ma.vulnerableChild.examples.length; i++) {
          final ex = ma.vulnerableChild.examples[i];
          if (ex.isEmpty) continue;
          _label(buf, 'Exemplo ${i + 1}', indent: true);
          _maybeLine(buf, 'Gatilho', ex.trigger);
          _maybeLine(buf, 'Experiência', ex.experience);
          _maybeLine(buf, 'Enfrentamento', ex.coping);
        }
      }

      // Outros modos infantis
      if (!ma.otherChild.isEmpty) {
        _label(buf, '9.2b Outros modos infantis');
        _maybeLine(buf, 'Descrição', ma.otherChild.description);
        _maybeLine(buf, 'Esquemas', ma.otherChild.schemas);
      }

      // Modos parentais
      for (var i = 0; i < ma.parentalModes.length; i++) {
        final pm = ma.parentalModes[i];
        if (pm.isEmpty) continue;
        _label(buf, '9.3 Modo Parental ${i + 1}: ${pm.name ?? ''}');
        _maybeLine(buf, 'Mensagens', pm.messages);
      }

      // Modos de enfrentamento
      for (var i = 0; i < ma.copingModes.length; i++) {
        final cm = ma.copingModes[i];
        if (cm.isEmpty) continue;
        final title =
            '9.4 Enfrentamento ${i + 1}${(cm.name ?? '').isNotEmpty ? ': ${cm.name}' : ''}';
        _label(buf, title);
        _maybeLine(buf, 'Categoria', cm.category);
        _maybeLine(buf, 'Esquemas', cm.schemas);
        _maybeLine(buf, 'Exemplo', cm.example);
        _maybeLine(buf, 'Experiência', cm.experience);
        _maybeLine(buf, 'O que aborda', cm.addresses);
        _maybeLine(buf, 'Valor percebido', cm.perceivedValue);
        _maybeLine(buf, 'Consequências', cm.consequences);
      }
    } else {
      _empty(buf);
    }
    _divider(buf);

    // ── Seção 10 — Sequências de modos ──────────────────────────────────────
    _sectionTitle(buf, '10. Sequências de Modos');
    if (c?.hasAnySequence == true) {
      for (var i = 0; i < c!.modeSequences.length; i++) {
        final seq = c.modeSequences[i];
        if (seq.isEmpty) continue;
        _label(buf, 'Sequência ${i + 1}');
        _maybeLine(buf, 'Gatilho', seq.trigger);
        _maybeLine(buf, 'Modos ativados', seq.activatedModes);
        _maybeLine(buf, 'Modo de enfrentamento', seq.copingMode);
        _maybeLine(buf, 'Sequência', seq.sequence);
        _maybeLine(buf, 'Efeito', seq.effect);
        _maybeLine(buf, 'Perpetuação', seq.perpetuation);
        _blank(buf);
      }
    } else {
      _empty(buf);
    }
    _divider(buf);

    // ── Seção 11 — Relação terapêutica ──────────────────────────────────────
    _sectionTitle(buf, '11. Relação Terapêutica');
    if (c?.hasRelationship == true) {
      final r = c!.relationship;
      if (r.collaborationRating != null) {
        _field(buf, 'Colaboração', '${r.collaborationRating}/5');
      }
      if ((r.collaborationNotes ?? '').trim().isNotEmpty) {
        _body(buf, r.collaborationNotes!);
      }
      if (r.bondRating != null) {
        _field(buf, 'Vínculo', '${r.bondRating}/5');
      }
      if ((r.bondNotes ?? '').trim().isNotEmpty) {
        _body(buf, r.bondNotes!);
      }
      if ((r.therapistReactions ?? '').trim().isNotEmpty) {
        _label(buf, 'Reações do terapeuta');
        _body(buf, r.therapistReactions!);
      }
    } else {
      _empty(buf);
    }
    _divider(buf);

    // ── Seção 12 — Objetivos de terapia ─────────────────────────────────────
    _sectionTitle(buf, '12. Objetivos de Terapia');
    if (c?.hasTherapyObjectives == true) {
      for (var i = 0; i < c!.therapyObjectives.length; i++) {
        final obj = c.therapyObjectives[i];
        if (obj.isEmpty) continue;
        _label(buf, 'Objetivo ${i + 1}${(obj.goal ?? '').isNotEmpty ? ': ${obj.goal}' : ''}');
        _maybeLine(buf, 'a. Esquemas/modos', obj.schemasModes);
        _maybeLine(buf, 'b. Comportamentos saudáveis', obj.healthyBehaviors);
        _maybeLine(buf, 'c. Intervenções', obj.interventions);
        _maybeLine(buf, 'd. Progresso', obj.progress);
        _blank(buf);
      }
    } else if (data.activeGoals.isNotEmpty) {
      for (final g in data.activeGoals.take(6)) {
        _bullet(buf, g.title);
        if ((g.description ?? '').trim().isNotEmpty) {
          _body(buf, g.description!);
        }
      }
    } else {
      _empty(buf);
    }
    _divider(buf);

    // ── Seção 13 — Comentários adicionais ───────────────────────────────────
    _sectionTitle(buf, '13. Comentários Adicionais');
    if ((c?.additionalComments ?? '').trim().isNotEmpty) {
      _body(buf, c!.additionalComments!);
    } else {
      _empty(buf);
    }

    // ── Rodapé ───────────────────────────────────────────────────────────────
    _divider(buf);
    _body(
      buf,
      'Documento gerado em $dateStr — EsquemaCore. '
      'Uso clínico restrito ao profissional responsável.',
    );

    buf.write('}');

    // RTF está em ASCII + escapes, então utf8.encode é seguro.
    return Uint8List.fromList(buf.toString().codeUnits);
  }

  // ── RTF helpers ─────────────────────────────────────────────────────────────

  static void _heading(
    StringBuffer buf,
    String text, {
    int size = 32,
    bool center = false,
  }) {
    final align = center ? r'\qc' : r'\ql';
    buf.write(
      '{\\pard$align\\b\\fs$size\\cf1 ${_e(text)}\\b0\\fs22\\cf0\\par}\n',
    );
  }

  static void _sectionTitle(StringBuffer buf, String text) {
    buf.write(
      '{\\pard\\ql\\b\\fs26\\cf1 ${_e(text)}\\b0\\fs22\\cf0\\par}\n',
    );
  }

  static void _label(StringBuffer buf, String text, {bool indent = false}) {
    final left = indent ? r'\li360' : '';
    buf.write(
      '{\\pard\\ql$left\\b ${_e(text)}:\\b0\\par}\n',
    );
  }

  static void _field(StringBuffer buf, String label, String value) {
    buf.write(
      '{\\pard\\ql\\b ${_e(label)}:\\b0  ${_e(value)}\\par}\n',
    );
  }

  static void _body(StringBuffer buf, String text) {
    buf.write('{\\pard\\ql\\li360 ${_e(text)}\\par}\n');
  }

  static void _bullet(StringBuffer buf, String text) {
    buf.write('{\\pard\\ql\\li360 \\bullet   ${_e(text)}\\par}\n');
  }

  static void _empty(StringBuffer buf) {
    buf.write(
      '{\\pard\\ql\\li360\\cf2\\i (não preenchido)\\i0\\cf0\\par}\n',
    );
  }

  static void _blank(StringBuffer buf) {
    buf.write('{\\pard\\par}\n');
  }

  static void _divider(StringBuffer buf) {
    buf.write('{\\pard\\brdrb\\brdrs\\brdrw10\\brsp20 \\par}\n');
    _blank(buf);
  }

  static void _maybeLine(StringBuffer buf, String label, String? value) {
    if ((value ?? '').trim().isEmpty) return;
    buf.write(
      '{\\pard\\ql\\li360\\b ${_e(label)}:\\b0  ${_e(value!.trim())}\\par}\n',
    );
  }

  /// Escapa texto para RTF ANSI (codepage 1252 + unicode fallback).
  static String _e(String text) {
    final sb = StringBuffer();
    for (final cp in text.runes) {
      if (cp == 92) {
        sb.write(r'\\');
      } else if (cp == 123) {
        sb.write(r'\{');
      } else if (cp == 125) {
        sb.write(r'\}');
      } else if (cp < 128) {
        sb.writeCharCode(cp);
      } else if (cp <= 255) {
        sb.write("\\'${cp.toRadixString(16).padLeft(2, '0')}");
      } else {
        sb.write('\\u$cp?');
      }
    }
    return sb.toString();
  }
}
