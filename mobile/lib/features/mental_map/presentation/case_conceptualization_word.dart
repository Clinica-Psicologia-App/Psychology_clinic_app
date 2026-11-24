import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show kIsWeb, visibleForTesting;
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../initial_assessment/domain/initial_assessment.dart';
import '../../initial_assessment/domain/life_area.dart';
import '../domain/case_conceptualization.dart';
import '../domain/mental_map_data.dart';

/// Exporta a Conceitualização de caso como um arquivo RTF editável em Word.
/// Usa geração pura em Dart — sem pacotes adicionais. O formato RTF é
/// nativamente suportado pelo Microsoft Word e LibreOffice.
class CaseConceptualizationWord {
  const CaseConceptualizationWord._();

  /// Logo padrão (nunca o mascote) quando a psicóloga não enviou a dela.
  static const defaultLogoAsset =
      'assets/branding/esquema_core_logo_principal.png';

  /// [logoBytes] = logo de quem exporta (null = logo padrão do EsquemaCore).
  /// RTF só embute PNG e JPEG: WebP/ilegível cai na logo padrão.
  static Future<void> shareOrOpen({
    required MentalMapData data,
    CaseConceptualization? concept,
    InitialAssessment? assessment,
    Uint8List? logoBytes,
  }) async {
    if (kIsWeb) {
      throw UnsupportedError(
        'Export em Word não disponível na versão web.',
      );
    }
    var logo = logoBytes;
    if (logo == null || _imageInfo(logo) == null) {
      try {
        logo = (await rootBundle.load(defaultLogoAsset)).buffer.asUint8List();
      } catch (_) {
        logo = null;
      }
    }
    final bytes = _build(
        data: data, concept: concept, assessment: assessment, logoBytes: logo);
    final dir = await getTemporaryDirectory();
    final name = _fileName(data.patientName);
    final file = File('${dir.path}/$name');
    await file.writeAsBytes(bytes, flush: true);
    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'application/rtf')],
      text: 'Formulação de Caso — ${data.patientName}',
    );
  }

  /// Gera os bytes do RTF (para teste e pré-visualização).
  @visibleForTesting
  static Uint8List buildBytes({
    required MentalMapData data,
    CaseConceptualization? concept,
    InitialAssessment? assessment,
    Uint8List? logoBytes,
  }) =>
      _build(
          data: data,
          concept: concept,
          assessment: assessment,
          logoBytes: logoBytes);

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
    Uint8List? logoBytes,
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
      r'\red59\green130\blue246;\red255\green255\blue255;\red234\green240\blue250;\red184\green196\blue220;}'
      '\n'
      r'\paperw12240\paperh15840\margl1134\margr1134\margt1134\margb1134'
      '\n'
      r'\f0\fs22\cf0'
      '\n',
    );

    // ── Cabeçalho (logo + título + quadro do formulário) ─────────────────────
    _logo(buf, logoBytes);
    _heading(buf, 'Conceituação de caso', size: 40, center: true);
    _heading(buf, 'Terapia do Esquema · Formulário de Conceituação de Caso (versão 3.8)',
        size: 20, center: true);
    _blank(buf);
    final fh = c?.formHeader;
    final fd = fh?.formDate;
    // Data digitada pela psicóloga; vazia fica vazia (não usa a data do export).
    final formDate = fd == null
        ? ''
        : '${fd.day.toString().padLeft(2, '0')}/${fd.month.toString().padLeft(2, '0')}/${fd.year}';
    _field(buf, 'Psicóloga', (fh?.therapistName ?? '').trim().isEmpty ? '—' : fh!.therapistName!.trim());
    _field(buf, 'Data', formDate);
    _field(buf, 'Número de sessões', fh?.sessionsCount?.toString() ?? '—');
    _field(buf, 'Meses desde a primeira sessão', fh?.monthsSinceFirst?.toString() ?? '—');
    _divider(buf);

    // ── Seção 1 — Informações básicas do cliente ─────────────────────────────
    _sectionTitle(buf, '1. Informações básicas do cliente');
    final b = assessment?.basics;
    String join(Iterable<String?> parts) => parts
        .where((e) => (e ?? '').trim().isNotEmpty)
        .map((e) => e!.trim())
        .join('  ·  ');
    String? age = b?.age == null ? null : '${b!.age} anos';
    String? birth;
    final bd = b?.birthDate;
    if (bd != null) {
      birth =
          '${bd.day.toString().padLeft(2, '0')}/${bd.month.toString().padLeft(2, '0')}/${bd.year}';
    }
    final kids = b?.hasChildren == null
        ? null
        : (b!.hasChildren! ? 'Tem filhos' : 'Sem filhos');
    String dash(String v) => v.isEmpty ? '—' : v;
    _field(buf, 'Nome/ID do cliente',
        dash(join([data.patientName, b?.preferredName])));
    _field(buf, 'Idade / data de nascimento', dash(join([age, birth])));
    _field(
        buf,
        'Relacionamento atual / orientação sexual / filhos',
        dash(join([
          b?.displayRelationshipStatus,
          b?.displaySexualOrientation,
          kids
        ])));
    _field(buf, 'Ocupação e posição', dash(join([b?.occupation])));
    _field(buf, 'Nível educacional mais alto',
        dash(join([b?.displayEducationLevel])));
    _field(
        buf,
        'País de nascimento / religião / grupo étnico',
        dash(join([b?.countryBirth, b?.religiousOrientation, b?.ethnicGroup])));
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

    // ── Seção 5 — Nível de funcionamento (avaliação clínica 1–6 ou N/A) ──────
    _sectionTitle(buf, '5. Nível atual de funcionamento');
    _body(buf, 'Nota: 1 = não funcional · 6 = excelente · N/A = não se aplica');
    for (final area in kFunctioningAreas) {
      final entry = c?.functioning.entryFor(area.key) ?? const FunctioningEntry();
      final nota = entry.notApplicable
          ? 'N/A'
          : (entry.rating == null ? '—' : '${entry.rating}/6');
      final expl = (entry.explanation ?? '').trim();
      _field(buf, '${area.code} ${area.label}',
          expl.isEmpty ? 'Nota: $nota' : 'Nota: $nota  ·  $expl');
    }
    final lifeScores = [
      if (assessment != null)
        for (final area in kLifeAreasInOrder)
          if (assessment.lifeAreaFor(area).score != null)
            (area.label, assessment.lifeAreaFor(area).score!),
    ];
    if (lifeScores.isNotEmpty) {
      _blank(buf);
      _label(buf,
          'Dado da paciente (Contexto de Vida, escala 0–10) — não é a avaliação clínica');
      for (final ls in lifeScores) {
        _field(buf, ls.$1, '${ls.$2}/10');
      }
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
          _body(buf,
            'Avaliação: ${u.rating == 'X' ? 'X (informação insuficiente)' : u.rating}');
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

    // ── Seção 11 — Relação terapêutica (11.1–11.4) ────────────────────
    _sectionTitle(buf, '11. Relação Terapêutica');
    if (c?.hasRelationship == true) {
      final r = c!.relationship;
      bool has(String? v) => (v ?? '').trim().isNotEmpty;
      if (has(r.therapistReactions)) {
        _label(buf, '11.1 Reações pessoais do terapeuta ao cliente');
        _maybeLine(buf, 'Descrição', r.therapistReactions);
      }
      if (r.collaborationRating != null ||
          has(r.collaborationNotes) ||
          has(r.collaborationImprove)) {
        _label(buf, '11.2 Colaboração');
        if (r.collaborationRating != null) {
          _field(buf, '11.2.1 Nota (1–5)', '${r.collaborationRating}/5');
        }
        _maybeLine(buf, '11.2.2 Descrição', r.collaborationNotes);
        _maybeLine(buf, '11.2.3 Como melhorar', r.collaborationImprove);
      }
      if (r.bondRating != null || has(r.bondNotes) || has(r.bondStrengthen)) {
        _label(buf, '11.3 Vínculo de reparentalidade');
        if (r.bondRating != null) {
          _field(buf, '11.3.1 Nota (1–5)', '${r.bondRating}/5');
        }
        _maybeLine(buf, '11.3.2 Descrição', r.bondNotes);
        _maybeLine(buf, '11.3.3 Como fortalecer', r.bondStrengthen);
      }
      if (has(r.otherFactors)) {
        _label(buf, '11.4 Outros');
        _maybeLine(buf, '11.4 Outros fatores', r.otherFactors);
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

  /// Tipo e dimensões (px) de PNG/JPEG; null se não for um dos dois.
  @visibleForTesting
  static ({String type, int w, int h})? imageInfo(Uint8List b) => _imageInfo(b);

  static ({String type, int w, int h})? _imageInfo(Uint8List b) {
    try {
      if (b.length > 24 &&
          b[0] == 0x89 &&
          b[1] == 0x50 &&
          b[2] == 0x4E &&
          b[3] == 0x47) {
        final w = (b[16] << 24) | (b[17] << 16) | (b[18] << 8) | b[19];
        final h = (b[20] << 24) | (b[21] << 16) | (b[22] << 8) | b[23];
        return (w > 0 && h > 0) ? (type: 'png', w: w, h: h) : null;
      }
      if (b.length > 4 && b[0] == 0xFF && b[1] == 0xD8) {
        var i = 2;
        while (i + 9 < b.length) {
          if (b[i] != 0xFF) {
            i++;
            continue;
          }
          final m = b[i + 1];
          if (m == 0xD8 || m == 0x01 || (m >= 0xD0 && m <= 0xD7)) {
            i += 2;
            continue;
          }
          final len = (b[i + 2] << 8) | b[i + 3];
          final isSof = m >= 0xC0 && m <= 0xCF && m != 0xC4 && m != 0xC8 && m != 0xCC;
          if (isSof) {
            final h = (b[i + 5] << 8) | b[i + 6];
            final w = (b[i + 7] << 8) | b[i + 8];
            return (w > 0 && h > 0) ? (type: 'jpeg', w: w, h: h) : null;
          }
          i += 2 + len;
        }
      }
    } catch (_) {}
    return null;
  }

  /// Logo no topo (PNG/JPEG), com ~2,6 cm de altura no máximo.
  static void _logo(StringBuffer buf, Uint8List? bytes) {
    final info = bytes == null ? null : _imageInfo(bytes);
    if (bytes == null || info == null) return;
    const maxH = 1300.0; // twips
    const maxW = 3400.0;
    var scale = maxH / info.h;
    if (info.w * scale > maxW) scale = maxW / info.w;
    final wg = (info.w * scale).round();
    final hg = (info.h * scale).round();
    final hex = StringBuffer();
    for (final v in bytes) {
      hex.write(v.toRadixString(16).padLeft(2, '0'));
    }
    buf.write('{\\pard\\ql{\\pict\\${info.type}blip\\picw${info.w}\\pich${info.h}'
        '\\picwgoal$wg\\pichgoal$hg\n$hex}\\par}\n');
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
      '{\\pard\\ql\\sb240\\sa100\\b\\fs26\\cf1 ${_e(text)}\\b0\\fs22\\cf0\\par}\n',
    );
  }

  // Quadros: linhas de tabela RTF com borda; linhas seguidas formam um quadro.
  static const _bd = r'\clbrdrt\brdrs\brdrw8\brdrcf6\clbrdrl\brdrs\brdrw8\brdrcf6'
      r'\clbrdrb\brdrs\brdrw8\brdrcf6\clbrdrr\brdrs\brdrw8\brdrcf6';
  static const _wTotal = 9972;
  static const _wLabel = 3000;

  /// Faixa de sub-título do quadro (largura total, fundo claro, negrito).
  static void _label(StringBuffer buf, String text, {bool indent = false}) {
    buf.write('\\trowd\\trgaph90\\trleft0$_bd\\clcbpat5\\cellx$_wTotal'
        '\\pard\\intbl\\ql\\b ${_e(text)}\\b0\\cell\\row\n');
  }

  /// Linha de 2 colunas: rótulo (fundo claro) e resposta.
  static void _field(StringBuffer buf, String label, String value) {
    buf.write('\\trowd\\trgaph90\\trleft0$_bd\\clcbpat5\\cellx$_wLabel'
        '$_bd\\cellx$_wTotal'
        '\\pard\\intbl\\ql\\b ${_e(label)}\\b0\\cell'
        '\\pard\\intbl\\ql ${_e(value)}\\cell\\row\n');
  }

  static void _row1(StringBuffer buf, String inner) {
    buf.write('\\trowd\\trgaph90\\trleft0$_bd\\cellx$_wTotal'
        '\\pard\\intbl\\ql $inner\\cell\\row\n');
  }

  static void _body(StringBuffer buf, String text) => _row1(buf, _e(text));

  static void _bullet(StringBuffer buf, String text) =>
      _row1(buf, '\\bullet   ${_e(text)}');

  static void _empty(StringBuffer buf) =>
      _row1(buf, '\\cf2\\i (não preenchido)\\i0\\cf0');

  static void _blank(StringBuffer buf) {
    buf.write('{\\pard\\fs12\\par}\\n');
  }

  static void _divider(StringBuffer buf) => _blank(buf);

  static void _maybeLine(StringBuffer buf, String label, String? value) {
    if ((value ?? '').trim().isEmpty) return;
    _field(buf, label, value!.trim());
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
