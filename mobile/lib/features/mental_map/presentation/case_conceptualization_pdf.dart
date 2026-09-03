// Builder de PDF: const em cada widget `pw.*` prejudica a leitura sem ganho real.
// ignore_for_file: prefer_const_constructors
import 'dart:typed_data';

import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../initial_assessment/domain/initial_assessment.dart';
import '../../initial_assessment/domain/life_area.dart';
import '../domain/case_conceptualization.dart';
import '../domain/mental_map_case_summary.dart';
import '../domain/mental_map_data.dart';
import '../domain/mental_map_goal_summary.dart';
import '../domain/mental_map_score_highlight.dart';
import '../domain/schema_mode_catalog.dart';

/// Exporta a Conceitualização de caso como um PDF estruturado (multipágina),
/// no formato do formulário padrão. Espelha o que a tela de síntese mostra —
/// agregação do Mapa mental + campos do terapeuta + áreas da vida.
class CaseConceptualizationPdf {
  const CaseConceptualizationPdf._();

  static const _navy = PdfColor.fromInt(0xFF0D1B3D);
  static const _muted = PdfColor.fromInt(0xFF718096);
  static const _secondary = PdfColor.fromInt(0xFF4A5568);
  static const _tint = PdfColor.fromInt(0xFFEFF3FC);
  static const _blue = PdfColor.fromInt(0xFF3B82F6);
  static const _success = PdfColor.fromInt(0xFF2E7D53);
  static const _warning = PdfColor.fromInt(0xFFB7791F);
  static const _error = PdfColor.fromInt(0xFFC53030);
  static const _purple = PdfColor.fromInt(0xFF7C3AED);

  /// Abre a folha de compartilhamento / impressão com o PDF gerado.
  static Future<void> shareOrPrint({
    required MentalMapData data,
    CaseConceptualization? concept,
    InitialAssessment? assessment,
  }) async {
    final bytes = await build(
      data: data,
      concept: concept,
      assessment: assessment,
    );
    await Printing.sharePdf(bytes: bytes, filename: _fileName(data.patientName));
  }

  /// Monta os bytes do PDF (útil também para pré-visualizar/testar).
  static Future<Uint8List> build({
    required MentalMapData data,
    CaseConceptualization? concept,
    InitialAssessment? assessment,
  }) async {
    // Poppins empacotada (mesma tipografia do app), 100% offline. DejaVu Sans
    // como fallback cobre símbolos que o Poppins não tem (setas "→" etc.).
    pw.ThemeData? theme;
    try {
      Future<pw.Font> load(String f) async =>
          pw.Font.ttf(await rootBundle.load('assets/fonts/$f'));
      theme = pw.ThemeData.withFont(
        base: await load('Poppins-Regular.ttf'),
        bold: await load('Poppins-Bold.ttf'),
        italic: await load('Poppins-Italic.ttf'),
        fontFallback: [await load('DejaVuSans.ttf')],
      );
    } catch (_) {
      theme = null;
    }

    final doc = pw.Document(
      title: 'Conceitualização de caso — ${data.patientName}',
      theme: theme,
    );
    final summary = data.caseSummary;
    final core = data.clinicalCore;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 42),
        footer: (ctx) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text(
            'Página ${ctx.pageNumber}/${ctx.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ),
        build: (ctx) => [
          _header(data.patientName),
          pw.SizedBox(height: 16),

          // 2. Motivo da terapia
          _section('2', 'Motivo da terapia', _motivo(summary)),

          // 3. Impressões gerais (terapeuta)
          _section(
            '3',
            'Impressões gerais',
            (concept?.hasGeneralImpressions ?? false)
                ? _impressions(concept!.generalImpressions)
                : _placeholder(
                    'Como o cliente se apresenta (inicial/atual) — a preencher.'),
          ),

          // 4. Perspectiva diagnóstica (terapeuta)
          _section(
            '4',
            'Perspectiva diagnóstica',
            (concept?.hasDiagnosis ?? false)
                ? _diagnosis(concept!.diagnosis)
                : _placeholder(
                    'Sistema (CID-11/DSM-5) e diagnósticos — a preencher.'),
          ),

          // 5. Funcionamento — áreas da vida
          _section('5', 'Funcionamento · áreas da vida', _lifeAreas(assessment)),

          // 6. Problemas de vida
          _section(
            '6',
            'Principais problemas de vida',
            data.activeProblems.isEmpty
                ? _placeholder('Nenhum problema registrado ainda.')
                : [
                    for (final p in data.activeProblems)
                      _bullet(p.title,
                          trailing: p.intensity == null
                              ? null
                              : '${p.intensity}/10'),
                  ],
          ),

          // 7. Origens — necessidades não atendidas (terapeuta)
          _section(
            '7',
            'Origens · necessidades não atendidas',
            (concept?.hasAnyNeed ?? false)
                ? _needs(concept!)
                : _placeholder(
                    'Avaliação das necessidades essenciais (0–5), origem e '
                    'esquemas — a preencher.'),
          ),

          // 8. Esquemas centrais
          _section(
            '8',
            'Esquemas centrais',
            core.topSchemas.isEmpty
                ? _placeholder('Sem YSQ concluído.')
                : _chips([
                    for (final h in core.topSchemas)
                      h.scoreLabel == null ? h.name : '${h.name} · ${h.scoreLabel}',
                  ]),
          ),

          // 9. Modos
          _section(
            '9',
            'Modos',
            core.topModes.isEmpty
                ? _placeholder('Sem YAMI concluído.')
                : _modes(core.topModes),
          ),

          // 10. Sequência de modos (terapeuta)
          _section(
            '10',
            'Sequência de modos',
            (concept?.hasAnySequence ?? false)
                ? _sequences(concept!)
                : _placeholder('Gatilho → sequência de modos — a preencher.'),
          ),

          // 11. Relação terapêutica (terapeuta)
          _section(
            '11',
            'Relação terapêutica',
            (concept?.hasRelationship ?? false)
                ? _relationship(concept!.relationship)
                : _placeholder(
                    'Colaboração e vínculo de reparentalização (1–5) — a preencher.'),
          ),

          // 12. Objetivos da terapia
          _section(
            '12',
            'Objetivos da terapia',
            data.activeGoals.isEmpty
                ? _placeholder('Nenhum objetivo ativo.')
                : [
                    for (var i = 0; i < data.activeGoals.length; i++)
                      _goal(i + 1, data.activeGoals[i]),
                  ],
          ),

          // 13. Comentários adicionais (terapeuta)
          _section(
            '13',
            'Comentários adicionais',
            (concept?.hasComments ?? false)
                ? [
                    pw.Text(concept!.additionalComments!.trim(),
                        style: const pw.TextStyle(
                            fontSize: 10, color: _navy, lineSpacing: 3)),
                  ]
                : _placeholder('Sem comentários adicionais.'),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ── Cabeçalho ──────────────────────────────────────────────────────────
  static pw.Widget _header(String patientName) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: _navy,
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('TERAPIA DO ESQUEMA · SÍNTESE',
              style: pw.TextStyle(
                  fontSize: 8,
                  letterSpacing: 0.6,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromInt(0xFF9DB2E0))),
          pw.SizedBox(height: 4),
          pw.Text('Conceitualização de caso',
              style: pw.TextStyle(
                  fontSize: 19,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white)),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(patientName,
                  style: const pw.TextStyle(
                      fontSize: 11, color: PdfColor.fromInt(0xFFC9D6F0))),
              pw.Text('Gerado em ${_dateStamp()}',
                  style: const pw.TextStyle(
                      fontSize: 9, color: PdfColor.fromInt(0xFF9DB2E0))),
            ],
          ),
        ],
      ),
    );
  }

  // ── Bloco de seção ─────────────────────────────────────────────────────
  static pw.Widget _section(String number, String title, List<pw.Widget> body) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Container(
                width: 18,
                height: 18,
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: _navy,
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Text(number,
                    style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white)),
              ),
              pw.SizedBox(width: 7),
              pw.Text(title,
                  style: pw.TextStyle(
                      fontSize: 12,
                      fontWeight: pw.FontWeight.bold,
                      color: _navy)),
            ],
          ),
          pw.SizedBox(height: 5),
          pw.Divider(height: 1, thickness: 0.5, color: PdfColor.fromInt(0xFFD9DFEC)),
          pw.SizedBox(height: 6),
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 25),
            child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start, children: body),
          ),
        ],
      ),
    );
  }

  static List<pw.Widget> _placeholder(String text) => [
        pw.Text(text,
            style: pw.TextStyle(
                fontSize: 9.5,
                color: _muted,
                fontStyle: pw.FontStyle.italic)),
      ];

  // ── Conteúdos ──────────────────────────────────────────────────────────
  static List<pw.Widget> _motivo(MentalMapCaseSummary s) {
    final parts = <(String, String?)>[
      ('Contexto de vida atual', s.currentLifeContext),
      ('Demandas terapêuticas', s.therapyDemands),
      ('Resumo da queixa', s.intakeSummary),
    ].where((e) => (e.$2 ?? '').trim().isNotEmpty).toList();
    if (parts.isEmpty) return _placeholder('Motivo/queixa ainda não registrado.');
    return [for (final p in parts) _labeledBlock(p.$1, p.$2!.trim())];
  }

  static List<pw.Widget> _impressions(GeneralImpressions g) {
    final out = <pw.Widget>[];
    if ((g.initial ?? '').trim().isNotEmpty) {
      out.add(_labeledBlock('Inicialmente', g.initial!.trim()));
    }
    if ((g.current ?? '').trim().isNotEmpty) {
      out.add(_labeledBlock('Atualmente', g.current!.trim()));
    }
    return out;
  }

  static List<pw.Widget> _diagnosis(Diagnosis d) {
    final items = d.items.where((e) => !e.isEmpty).toList();
    return [
      if ((d.system ?? '').trim().isNotEmpty)
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 6),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: pw.BoxDecoration(
            color: _tint,
            borderRadius: pw.BorderRadius.circular(20),
          ),
          child: pw.Text(d.system!.trim(),
              style: pw.TextStyle(
                  fontSize: 9, fontWeight: pw.FontWeight.bold, color: _blue)),
        ),
      for (final e in items)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.RichText(
            text: pw.TextSpan(
              style: const pw.TextStyle(fontSize: 10, color: _navy),
              children: [
                pw.TextSpan(
                    text: (e.name ?? '').trim(),
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                if ((e.code ?? '').trim().isNotEmpty)
                  pw.TextSpan(
                      text: '   ·   ${e.code!.trim()}',
                      style: const pw.TextStyle(color: _muted)),
              ],
            ),
          ),
        ),
    ];
  }

  static List<pw.Widget> _lifeAreas(InitialAssessment? a) {
    final rated = a == null
        ? const <(LifeArea, int)>[]
        : [
            for (final area in kLifeAreasInOrder)
              if (a.lifeAreaFor(area).score != null)
                (area, a.lifeAreaFor(area).score!),
          ];
    if (rated.isEmpty) return _placeholder('Áreas da vida ainda não avaliadas.');

    PdfColor tone(int s) => s >= 7 ? _success : (s >= 4 ? _warning : _error);
    return [
      for (final r in rated)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 7),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(r.$1.label,
                      style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: _navy)),
                  pw.Text('${r.$2}/10',
                      style: pw.TextStyle(
                          fontSize: 9,
                          fontWeight: pw.FontWeight.bold,
                          color: tone(r.$2))),
                ],
              ),
              pw.SizedBox(height: 3),
              _bar(r.$2, 10, tone(r.$2)),
            ],
          ),
        ),
    ];
  }

  static List<pw.Widget> _needs(CaseConceptualization concept) {
    final labels = {for (final n in kCoreNeeds) n.key: n.label};
    final filled = concept.unmetNeeds.where((u) => !u.isEmpty).toList();

    PdfColor ratingColor(String? r) {
      final v = int.tryParse(r ?? '');
      if (v == null) return _muted;
      if (v <= 1) return _error;
      if (v <= 3) return _warning;
      return _success;
    }

    return [
      for (final n in filled)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 22,
                alignment: pw.Alignment.center,
                padding: const pw.EdgeInsets.symmetric(vertical: 2),
                decoration: pw.BoxDecoration(
                  color: _withAlpha(ratingColor(n.rating), 0.14),
                  borderRadius: pw.BorderRadius.circular(5),
                ),
                child: pw.Text(
                    (n.rating == null || n.rating!.isEmpty) ? '–' : n.rating!,
                    style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.bold,
                        color: ratingColor(n.rating))),
              ),
              pw.SizedBox(width: 8),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(labels[n.needKey] ?? n.needKey,
                        style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: _navy)),
                    if ((n.origin ?? '').trim().isNotEmpty)
                      pw.Text('Origem: ${n.origin!.trim()}',
                          style: const pw.TextStyle(
                              fontSize: 9, color: _secondary, lineSpacing: 2)),
                    if ((n.schemas ?? '').trim().isNotEmpty)
                      pw.Text('Esquemas: ${n.schemas!.trim()}',
                          style: const pw.TextStyle(
                              fontSize: 9, color: _purple, lineSpacing: 2)),
                  ],
                ),
              ),
            ],
          ),
        ),
    ];
  }

  static List<pw.Widget> _sequences(CaseConceptualization concept) {
    final seqs = concept.modeSequences.where((s) => !s.isEmpty).toList();

    pw.Widget line(String label, String? value) {
      if ((value ?? '').trim().isEmpty) return pw.SizedBox();
      return pw.Padding(
        padding: const pw.EdgeInsets.only(top: 2),
        child: pw.RichText(
          text: pw.TextSpan(
            style: const pw.TextStyle(fontSize: 9, color: _secondary, lineSpacing: 2),
            children: [
              pw.TextSpan(
                  text: '$label ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TextSpan(text: value!.trim()),
            ],
          ),
        ),
      );
    }

    return [
      for (var i = 0; i < seqs.length; i++)
        pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 7),
          padding: const pw.EdgeInsets.all(9),
          decoration: pw.BoxDecoration(
            color: _tint,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                  (seqs[i].trigger ?? '').trim().isEmpty
                      ? 'Sequência ${i + 1}'
                      : 'Gatilho: ${seqs[i].trigger!.trim()}',
                  style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: _navy)),
              line('Modos:', seqs[i].activatedModes),
              line('Enfrentamento:', seqs[i].copingMode),
              line('Sequência:', seqs[i].sequence),
              line('Efeito:', seqs[i].effect),
              line('Perpetua:', seqs[i].perpetuation),
            ],
          ),
        ),
    ];
  }

  static List<pw.Widget> _relationship(TherapeuticRelationship rel) {
    pw.Widget meter(String label, int? value) {
      final v = (value ?? 0).clamp(0, 5);
      final color = v >= 4 ? _success : (v >= 3 ? _warning : _error);
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 6),
        child: pw.Row(
          children: [
            pw.SizedBox(
                width: 78,
                child: pw.Text(label,
                    style: const pw.TextStyle(fontSize: 9, color: _secondary))),
            pw.Expanded(child: _bar(v, 5, color)),
            pw.SizedBox(width: 8),
            pw.Text(value == null ? '—' : '$v/5',
                style: pw.TextStyle(
                    fontSize: 9, fontWeight: pw.FontWeight.bold, color: color)),
          ],
        ),
      );
    }

    pw.Widget note(String label, String? value) {
      if ((value ?? '').trim().isEmpty) return pw.SizedBox();
      return pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.RichText(
          text: pw.TextSpan(
            style: const pw.TextStyle(fontSize: 9, color: _secondary, lineSpacing: 2),
            children: [
              pw.TextSpan(
                  text: '$label ',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              pw.TextSpan(text: value!.trim()),
            ],
          ),
        ),
      );
    }

    return [
      if (rel.collaborationRating != null)
        meter('Colaboração', rel.collaborationRating),
      if (rel.bondRating != null) meter('Vínculo', rel.bondRating),
      note('Colaboração:', rel.collaborationNotes),
      note('Vínculo:', rel.bondNotes),
      note('Reações do terapeuta:', rel.therapistReactions),
    ];
  }

  // ── Primitivos ─────────────────────────────────────────────────────────
  static pw.Widget _labeledBlock(String label, String value) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 7),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label.toUpperCase(),
                style: pw.TextStyle(
                    fontSize: 8,
                    letterSpacing: 0.3,
                    fontWeight: pw.FontWeight.bold,
                    color: _muted)),
            pw.SizedBox(height: 2),
            pw.Text(value,
                style: const pw.TextStyle(fontSize: 10, color: _navy, lineSpacing: 3)),
          ],
        ),
      );

  static pw.Widget _bullet(String text, {String? trailing}) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 5),
        child: pw.Row(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Container(
                width: 4,
                height: 4,
                margin: const pw.EdgeInsets.only(top: 4, right: 6),
                decoration:
                    const pw.BoxDecoration(color: _muted, shape: pw.BoxShape.circle)),
            pw.Expanded(
                child: pw.Text(text,
                    style: const pw.TextStyle(fontSize: 10, color: _navy, lineSpacing: 2))),
            if (trailing != null) ...[
              pw.SizedBox(width: 8),
              pw.Text(trailing,
                  style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                      color: _secondary)),
            ],
          ],
        ),
      );

  static pw.Widget _goal(int index, MentalMapGoalSummary g) {
    final prazoColor = g.isOverdue ? _error : _muted;
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 7),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 15,
            height: 15,
            alignment: pw.Alignment.center,
            decoration:
                const pw.BoxDecoration(color: _tint, shape: pw.BoxShape.circle),
            child: pw.Text('$index',
                style: pw.TextStyle(
                    fontSize: 8, fontWeight: pw.FontWeight.bold, color: _blue)),
          ),
          pw.SizedBox(width: 7),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(g.title,
                    style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: _navy,
                        lineSpacing: 2)),
                if ((g.description ?? '').trim().isNotEmpty)
                  pw.Text(g.description!.trim(),
                      style: const pw.TextStyle(
                          fontSize: 9, color: _secondary, lineSpacing: 2)),
                if ((g.targetDateLabel ?? '').trim().isNotEmpty)
                  pw.Text(
                      g.isOverdue
                          ? 'Prazo vencido · ${g.targetDateLabel}'
                          : 'Prazo: ${g.targetDateLabel}',
                      style: pw.TextStyle(
                          fontSize: 8.5,
                          color: prazoColor,
                          fontWeight: g.isOverdue
                              ? pw.FontWeight.bold
                              : pw.FontWeight.normal)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static PdfColor _modeColor(String key) => switch (key) {
        'blue' => _blue,
        'warning' => _warning,
        'error' => _error,
        'success' => _success,
        _ => PdfColor.fromInt(0xFF17A2B8),
      };

  static List<pw.Widget> _modes(List<MentalMapScoreHighlight> modes) => [
        for (var i = 0; i < modes.length; i++)
          () {
            final h = modes[i];
            final info = schemaModeInfoForCode(h.code);
            final color = info == null
                ? const PdfColor.fromInt(0xFF17A2B8)
                : _modeColor(info.category.colorKey);
            final hasScore = h.scoreLabel != null &&
                h.scoreLabel!.trim().isNotEmpty &&
                h.scoreLabel != '-';
            return pw.Container(
              margin: pw.EdgeInsets.only(bottom: i == modes.length - 1 ? 0 : 9),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: 3,
                    height: 30,
                    margin: const pw.EdgeInsets.only(top: 1, right: 8),
                    decoration: pw.BoxDecoration(
                      color: color,
                      borderRadius: pw.BorderRadius.circular(2),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Expanded(
                              child: pw.Text(info?.name ?? h.name,
                                  style: pw.TextStyle(
                                      fontSize: 10,
                                      fontWeight: pw.FontWeight.bold,
                                      color: _navy)),
                            ),
                            if (hasScore) ...[
                              pw.SizedBox(width: 8),
                              pw.Text(h.scoreLabel!,
                                  style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: color)),
                            ],
                          ],
                        ),
                        if (info != null) ...[
                          pw.Text(info.category.label,
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  letterSpacing: 0.3,
                                  fontWeight: pw.FontWeight.bold,
                                  color: color)),
                          pw.SizedBox(height: 1),
                          pw.Text(info.description,
                              style: const pw.TextStyle(
                                  fontSize: 9, color: _secondary, lineSpacing: 2)),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }(),
      ];

  static List<pw.Widget> _chips(List<String> items) => [
        pw.Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final t in items)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: pw.BoxDecoration(
                  color: _tint,
                  borderRadius: pw.BorderRadius.circular(20),
                ),
                child: pw.Text(t,
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold, color: _navy)),
              ),
          ],
        ),
      ];

  /// Barra proporcional [value]/[max] (evita depender de widgets de gráfico).
  static pw.Widget _bar(int value, int max, PdfColor color) {
    final v = value.clamp(0, max);
    return pw.ClipRRect(
      horizontalRadius: 3,
      verticalRadius: 3,
      child: pw.Container(
        height: 5,
        color: _withAlpha(color, 0.15),
        child: pw.Row(
          children: [
            if (v > 0) pw.Expanded(flex: v, child: pw.Container(color: color)),
            if (v < max) pw.Expanded(flex: max - v, child: pw.SizedBox()),
          ],
        ),
      ),
    );
  }

  static PdfColor _withAlpha(PdfColor c, double a) =>
      PdfColor(c.red, c.green, c.blue, a);

  static String _dateStamp() {
    final n = DateTime.now();
    String two(int x) => x.toString().padLeft(2, '0');
    return '${two(n.day)}/${two(n.month)}/${n.year}';
  }

  static String _fileName(String patientName) {
    final safe = patientName
        .toLowerCase()
        .replaceAll(RegExp(r'[àáâã]'), 'a')
        .replaceAll(RegExp(r'[éê]'), 'e')
        .replaceAll(RegExp(r'[íî]'), 'i')
        .replaceAll(RegExp(r'[óôõ]'), 'o')
        .replaceAll(RegExp(r'[úû]'), 'u')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '')
        .trim();
    final base = safe.isEmpty ? 'paciente' : safe;
    final date = DateTime.now().toIso8601String().substring(0, 10);
    return 'conceitualizacao-$base-$date.pdf';
  }
}
