// Builder de PDF: const em cada widget `pw.*` prejudica a leitura sem ganho real.
// ignore_for_file: prefer_const_constructors
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show visibleForTesting;
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
import '../domain/schema_catalog.dart';
import '../domain/schema_mode_catalog.dart';

/// Exporta a Conceitualização de caso como um PDF estruturado (multipágina),
/// no formato do formulário padrão (quadros). Espelha o que a tela de síntese
/// mostra — agregação do Mapa mental + campos do terapeuta + áreas da vida.
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

  /// Logo padrão (nunca o mascote) usada quando a psicóloga não enviou a dela.
  // Logo principal (completa): a horizontal tem o "Core" cortado na borda do arquivo.
  static const defaultLogoAsset = 'assets/branding/esquema_core_logo_principal.png';

  /// Nome do arquivo PDF para compartilhar (ex.: conceituacao_maria.pdf).
  static String fileNameFor(String patientName) => _fileName(patientName);

  /// Abre a folha de compartilhamento / impressão com o PDF gerado.
  /// [logoBytes] = logo de quem exporta (null = logo padrão do EsquemaCore).
  static Future<void> shareOrPrint({
    required MentalMapData data,
    CaseConceptualization? concept,
    InitialAssessment? assessment,
    Uint8List? logoBytes,
  }) async {
    final bytes = await build(
      data: data,
      concept: concept,
      assessment: assessment,
      logoBytes: logoBytes,
    );
    await Printing.sharePdf(bytes: bytes, filename: _fileName(data.patientName));
  }

  /// Imagem da logo: a enviada (png/jpg direto; webp via decodificador do
  /// Flutter) ou, se faltar/falhar, a logo padrão do EsquemaCore.
  static Future<pw.MemoryImage?> _logoImage(Uint8List? custom) async {
    if (custom != null && custom.isNotEmpty) {
      try {
        return pw.MemoryImage(custom);
      } catch (_) {}
      try {
        final codec = await ui.instantiateImageCodec(custom);
        final frame = await codec.getNextFrame();
        final bd = await frame.image.toByteData(format: ui.ImageByteFormat.png);
        if (bd != null) return pw.MemoryImage(bd.buffer.asUint8List());
      } catch (_) {}
    }
    try {
      final d = await rootBundle.load(defaultLogoAsset);
      return pw.MemoryImage(d.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  /// Monta os bytes do PDF (útil também para pré-visualizar/testar).
  static Future<Uint8List> build({
    required MentalMapData data,
    CaseConceptualization? concept,
    InitialAssessment? assessment,
    Uint8List? logoBytes,
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

    final logo = await _logoImage(logoBytes);
    final doc = pw.Document(
      title: 'Conceituação de caso — ${data.patientName}',
      theme: theme,
    );
    final summary = data.caseSummary;
    final core = data.clinicalCore;

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 42),
        footer: (ctx) => pw.Container(
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Conceituação de caso · ${data.patientName}',
                  style: const pw.TextStyle(fontSize: 8, color: _muted)),
              pw.Text('Página ${ctx.pageNumber} de ${ctx.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: _muted)),
            ],
          ),
        ),
        build: (ctx) => [
          ..._header(logo, concept?.formHeader),

          // 1. Informações básicas do cliente
          ..._section('1', 'Informações básicas do cliente',
              _basics(data.patientName, assessment)),

          // 2. Motivo da terapia
          ..._section('2', 'Por que o cliente está em terapia',
              _motivo(summary, concept?.motivoInitial, concept?.motivoCurrent)),

          // 3. Impressões gerais (terapeuta)
          ..._section(
            '3',
            'Impressões gerais do cliente',
            (concept?.hasGeneralImpressions ?? false)
                ? _impressions(concept!.generalImpressions)
                : _placeholder(
                    'Como o cliente se apresenta (inicial/atual) — a preencher.'),
          ),

          // 4. Perspectiva diagnóstica (terapeuta)
          ..._section(
            '4',
            'Perspectiva diagnóstica',
            (concept?.hasDiagnosis ?? false)
                ? _diagnosis(concept!.diagnosis)
                : _placeholder(
                    'Sistema (CID-11/DSM-5) e diagnósticos — a preencher.'),
          ),

          // 5. Nível de funcionamento (avaliação clínica 1–6 ou N/A)
          ..._section(
            '5',
            'Nível atual de funcionamento',
            _functioning(concept?.functioning, assessment),
          ),

          // 6. Problemas de vida
          ..._section(
            '6',
            'Principais problemas de vida',
            (concept?.hasLifeProblems ?? false)
                ? _lifeProblems(concept!.lifeProblems)
                : data.activeProblems.isEmpty
                    ? _placeholder('Nenhum problema registrado ainda.')
                    : _grid([
                        for (var i = 0; i < data.activeProblems.length; i++)
                          (
                            '6.${i + 1}',
                            _val(data.activeProblems[i].title +
                                (data.activeProblems[i].intensity == null
                                    ? ''
                                    : '  ·  ${data.activeProblems[i].intensity}/10'))
                          ),
                      ]),
          ),

          // 7. Origens infantis e adolescentes dos problemas atuais (terapeuta)
          ..._section('7', 'Origens infantis e adolescentes dos problemas atuais',
              _origins(concept)),

          // 8. Esquemas
          ..._section('8', 'Esquemas', [
            ..._headed(
              _subHeading('8.1', 'Todos os esquemas identificados'),
              (concept?.hasAllSchemas ?? false)
                  ? _grid([('Esquemas', _val(concept!.allSchemas!.trim()))])
                  : _placeholder('Lista completa de esquemas — a preencher.'),
            ),
            pw.SizedBox(height: 8),
            ..._headed(
              _subHeading('8.2', 'Esquemas desadaptativos centrais'),
              (concept?.hasCentralSchemas ?? false)
                  ? _centralSchemasTherapist(concept!.centralSchemas)
                  : core.topSchemas.isEmpty
                      ? _placeholder('Sem YSQ concluído.')
                      : _rows(_schemas(core.topSchemas)),
            ),
          ]),

          // 9. Modos de esquema
          ..._section(
            '9',
            'Modos de esquema',
            (concept?.hasModeAssessment ?? false)
                ? _modeAssessmentTherapist(concept!.modeAssessment)
                : core.topModes.isEmpty
                    ? _placeholder('Sem YAMI concluído.')
                    : _rows(_modes(core.topModes)),
          ),

          // 10. Sequência de modos (terapeuta)
          ..._section(
            '10',
            'Sequência de modos',
            (concept?.hasAnySequence ?? false)
                ? _sequences(concept!)
                : _placeholder('Gatilho → sequência de modos — a preencher.'),
          ),

          // 11. Relação terapêutica (terapeuta)
          ..._section(
            '11',
            'Relação terapêutica',
            (concept?.hasRelationship ?? false)
                ? _relationship(concept!.relationship)
                : _placeholder(
                    'Colaboração e vínculo de reparentalização (1–5) — a preencher.'),
          ),

          // 12. Objetivos terapêuticos
          ..._section(
            '12',
            'Objetivos terapêuticos',
            (concept?.hasTherapyObjectives ?? false)
                ? _therapyObjectivesPdf(concept!.therapyObjectives)
                : data.activeGoals.isEmpty
                    ? _placeholder('Nenhum objetivo ativo.')
                    : _rows([
                        for (var i = 0; i < data.activeGoals.length; i++)
                          _goal(i + 1, data.activeGoals[i]),
                      ]),
          ),

          // 13. Comentários adicionais (terapeuta)
          ..._section(
            '13',
            'Comentários adicionais',
            (concept?.hasComments ?? false)
                ? _grid([('Comentários', _val(concept!.additionalComments!.trim()))])
                : _placeholder('Sem comentários adicionais.'),
          ),
        ],
      ),
    );

    return doc.save();
  }

  // ── Cabeçalho (logo + título + quadro do formulário) ──────────────────────
  static List<pw.Widget> _header(pw.MemoryImage? logo, CaseFormHeader? fh) {
    // Data digitada pela psicóloga; vazia fica vazia (não usa a data do export).
    final date = headerDate(fh);
    return [
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          if (logo != null) ...[
            pw.SizedBox(
              width: 84,
              height: 62,
              child: pw.Image(logo, fit: pw.BoxFit.contain, alignment: pw.Alignment.centerLeft),
            ),
            pw.SizedBox(width: 14),
          ],
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Conceituação de caso',
                    style: pw.TextStyle(
                        fontSize: 21,
                        fontWeight: pw.FontWeight.bold,
                        color: _navy)),
                pw.SizedBox(height: 3),
                pw.Text(
                    'Terapia do Esquema · itens na ordem do Formulário de Conceituação de Caso (versão 3.8)',
                    style: const pw.TextStyle(fontSize: 9, color: _muted)),
              ],
            ),
          ),
        ],
      ),
      pw.SizedBox(height: 8),
      pw.Divider(height: 1, thickness: 1.4, color: _navy),
      pw.SizedBox(height: 10),
      _row([
        _labelCell('Psicóloga'),
        _valCell(_val(fh?.therapistName)),
        _labelCell('Data'),
        _valCell(_val(date)),
      ], const [100, null, 150, 90]),
      _row([
        _labelCell('Número de sessões'),
        _valCell(_val(fh?.sessionsCount?.toString())),
        _labelCell('Meses desde a primeira sessão'),
        _valCell(_val(fh?.monthsSinceFirst?.toString())),
      ], const [100, null, 150, 90]),
    ];
  }

  // ── Quadros ────────────────────────────────────────────────────────────
  // Cada linha do quadro é um widget próprio (o MultiPage quebra a página
  // entre linhas e o título fica junto da primeira linha: ver [_headed]).
  static const _line = PdfColor.fromInt(0xFFB8C4DC);
  static const _labelBg = PdfColor.fromInt(0xFFEAF0FA);

  static pw.Widget _val(String? text) => (text ?? '').trim().isEmpty
      ? pw.Text('—',
          style: const pw.TextStyle(fontSize: 10, color: _muted))
      : pw.Text(text!.trim(),
          style: const pw.TextStyle(fontSize: 10, color: _navy, lineSpacing: 2));

  static pw.Widget _labelCell(String text) => pw.Text(text,
      style: pw.TextStyle(
          fontSize: 9.5, fontWeight: pw.FontWeight.bold, color: _navy));

  static pw.Widget _valCell(pw.Widget w) => w;

  /// Uma linha do quadro: [cells] com larguras [widths] (null = flexível).
  /// Células de índice par com larguras fixas ficam no tom de rótulo quando
  /// [labelCols] as inclui (por padrão: coluna 0 e, em 4 colunas, a 2).
  static pw.Widget _row(List<pw.Widget> cells, List<double?> widths,
      {Set<int>? labelCols}) {
    final labels = labelCols ?? (cells.length == 4 ? {0, 2} : {0});
    // Tabela de 1 linha: as células ficam com a mesma altura (rótulo e resposta).
    return pw.Table(
      border: pw.TableBorder.all(color: _line, width: 0.5),
      columnWidths: {
        for (var i = 0; i < cells.length; i++)
          i: widths[i] == null
              ? pw.FlexColumnWidth()
              : pw.FixedColumnWidth(widths[i]!),
      },
      children: [
        pw.TableRow(
          verticalAlignment: pw.TableCellVerticalAlignment.full,
          children: [
            for (var i = 0; i < cells.length; i++)
              pw.Container(
                color: labels.contains(i) ? _labelBg : null,
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                child: cells[i],
              ),
          ],
        ),
      ],
    );
  }

  /// Quadro de 2 colunas: rótulo (fundo claro) à esquerda, resposta ao lado.
  static List<pw.Widget> _grid(List<(String, pw.Widget)> rows) => [
        for (final r in rows) _row([_labelCell(r.$1), r.$2], const [150, null]),
      ];

  /// Quadro de 1 coluna, uma linha por item.
  static List<pw.Widget> _rows(List<pw.Widget> items) => [
        for (final w in items) _row([w], const [null], labelCols: {}),
      ];

  /// Título + primeira linha do quadro juntos (evita título órfão no fim da
  /// página). Linhas seguintes seguem soltas e podem quebrar a página.
  static List<pw.Widget> _headed(pw.Widget head, List<pw.Widget> body) {
    if (body.isEmpty) return [head];
    // Inseparable: Column sozinha é "spanning" e o MultiPage a quebraria entre
    // o título e a primeira linha.
    return [
      pw.Inseparable(
        child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [head, body.first]),
      ),
      ...body.skip(1),
    ];
  }

  static pw.Widget _subHeading(String number, String title) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4, top: 2),
        child: pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(
                text: '$number  ',
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColor.fromInt(0xFF0096D6))),
            pw.TextSpan(
                text: title,
                style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy)),
          ]),
        ),
      );

  /// Título da seção (selo numerado) seguido dos quadros, juntos na quebra.
  static List<pw.Widget> _section(
      String number, String title, List<pw.Widget> body) {
    final head = pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Container(
            width: 20,
            height: 20,
            alignment: pw.Alignment.center,
            decoration: pw.BoxDecoration(
              color: _navy,
              borderRadius: pw.BorderRadius.circular(5),
            ),
            child: pw.Text(number,
                style: pw.TextStyle(
                    fontSize: number.length > 1 ? 8.5 : 10,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white)),
          ),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Text(title,
                style: pw.TextStyle(
                    fontSize: 12.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy)),
          ),
        ],
      ),
    );
    return [pw.SizedBox(height: 14), ..._headed(head, body)];
  }

  static List<pw.Widget> _placeholder(String text) => _rows([
        pw.Text(text,
            style: pw.TextStyle(
                fontSize: 9.5, color: _muted, fontStyle: pw.FontStyle.italic)),
      ]);

  // ── Conteúdos ──────────────────────────────────────────────────────────

  /// 1 — dados do cliente (Contexto de vida / Dados iniciais), em quadros.
  static List<pw.Widget> _basics(String patientName, InitialAssessment? a) {
    final b = a?.basics;
    String join(Iterable<String?> parts) => parts
        .where((e) => (e ?? '').trim().isNotEmpty)
        .map((e) => e!.trim())
        .join('  ·  ');
    String? age;
    if (b?.age != null) {
      age = '${b!.age} anos';
    }
    String? birth;
    final bd = b?.birthDate;
    if (bd != null) {
      String two(int n) => n.toString().padLeft(2, '0');
      birth = '${two(bd.day)}/${two(bd.month)}/${bd.year}';
    }
    final children = b?.hasChildren == null
        ? null
        : (b!.hasChildren! ? 'Tem filhos' : 'Sem filhos');
    final rows = <(String, String)>[
      ('Nome/ID do cliente', join([patientName, b?.preferredName])),
      ('Idade / data de nascimento', join([age, birth])),
      (
        'Relacionamento atual / orientação sexual / filhos',
        join([b?.displayRelationshipStatus, b?.displaySexualOrientation, children])
      ),
      ('Ocupação e posição', join([b?.occupation])),
      ('Nível educacional mais alto', join([b?.displayEducationLevel])),
      (
        'País de nascimento / religião / grupo étnico',
        join([b?.countryBirth, b?.religiousOrientation, b?.ethnicGroup])
      ),
    ];
    return _grid([for (final r in rows) (r.$1, _val(r.$2))]);
  }

  static List<pw.Widget> _motivo(MentalMapCaseSummary s,
      String? motivoInitial, String? motivoCurrent) {
    final parts = <(String, String?)>[
      ('Contexto de vida atual', s.currentLifeContext),
      ('Demandas terapêuticas', s.therapyDemands),
      ('Resumo da queixa', s.intakeSummary),
      ('a. Inicialmente', motivoInitial),
      ('b. Atualmente', motivoCurrent),
    ].where((e) => (e.$2 ?? '').trim().isNotEmpty).toList();
    if (parts.isEmpty) return _placeholder('Motivo/queixa ainda não registrado.');
    return _grid([for (final p in parts) (p.$1, _val(p.$2))]);
  }

  static List<pw.Widget> _impressions(GeneralImpressions g) {
    final rows = <(String, pw.Widget)>[
      if ((g.initial ?? '').trim().isNotEmpty) ('a. Inicialmente', _val(g.initial)),
      if ((g.current ?? '').trim().isNotEmpty) ('b. Atualmente', _val(g.current)),
    ];
    return rows.isEmpty ? _placeholder('— a preencher.') : _grid(rows);
  }

  static List<pw.Widget> _diagnosis(Diagnosis d) {
    final items = d.items.where((e) => !e.isEmpty).toList();
    final rows = <(String, pw.Widget)>[
      if ((d.system ?? '').trim().isNotEmpty)
        ('Sistema diagnóstico', _val(d.system)),
      if (d.noDiagnosis)
        ('Diagnóstico', _val('Sem diagnóstico estabelecido no momento.')),
      for (var i = 0; i < items.length; i++)
        (
          'Diagnóstico ${i + 1}',
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _val([
                (items[i].name ?? '').trim(),
                if ((items[i].code ?? '').trim().isNotEmpty)
                  '·  ${items[i].code!.trim()}',
              ].join('  ')),
              if (items[i].metaLine(d.system) != null)
                pw.Text(items[i].metaLine(d.system)!,
                    style: const pw.TextStyle(fontSize: 9, color: _muted)),
              if ((items[i].notes ?? '').trim().isNotEmpty)
                pw.Text(items[i].notes!.trim(),
                    style: const pw.TextStyle(fontSize: 9, color: _muted)),
            ],
          ),
        ),
    ];
    return rows.isEmpty ? _placeholder('— a preencher.') : _grid(rows);
  }

  /// Quadradinhos de nota: [options] com a [selected] em destaque.
  static pw.Widget _chips(List<String> options, String? selected,
      {double size = 16}) {
    final sel = (selected ?? '').trim().toUpperCase();
    return pw.Row(children: [
      for (final k in options)
        pw.Container(
          width: k.length > 1 ? size + 7 : size,
          height: size,
          margin: const pw.EdgeInsets.only(right: 3),
          alignment: pw.Alignment.center,
          decoration: pw.BoxDecoration(
            color: sel == k.toUpperCase() ? _navy : null,
            border: pw.Border.all(
                color: sel == k.toUpperCase() ? _navy : _line, width: 0.6),
            borderRadius: pw.BorderRadius.circular(3),
          ),
          child: pw.Text(k,
              style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight:
                      sel == k.toUpperCase() ? pw.FontWeight.bold : pw.FontWeight.normal,
                  color: sel == k.toUpperCase() ? PdfColors.white : _muted)),
        ),
    ]);
  }

  /// 5 — avaliação CLÍNICA (1–6 ou N/A) como quadro principal. As notas 0–10
  /// do Contexto de Vida da paciente entram só como linha secundária.
  static List<pw.Widget> _functioning(
      FunctioningAssessment? f, InitialAssessment? a) {
    final out = <pw.Widget>[
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(
            'Nota: 1 = não funcional · 6 = excelente · N/A = não se aplica',
            style: const pw.TextStyle(fontSize: 8, color: _muted)),
      ),
      for (final area in kFunctioningAreas)
        () {
          final e = f?.entryFor(area.key) ?? const FunctioningEntry();
          return _row([
            pw.Text('${area.code} ${area.label}',
                style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: _navy)),
            _chips(
              const ['1', '2', '3', '4', '5', '6', 'N/A'],
              e.notApplicable ? 'N/A' : e.rating?.toString(),
              size: 14,
            ),
            _val(e.explanation),
          ], const [150, 150, null], labelCols: {0});
        }(),
    ];
    final patient = <(String, pw.Widget)>[
      if (a != null)
        for (final area in kLifeAreasInOrder)
          if (a.lifeAreaFor(area).score != null)
            (area.label, _val('${a.lifeAreaFor(area).score}/10')),
    ];
    if (patient.isNotEmpty) {
      out.add(pw.SizedBox(height: 8));
      out.addAll(_headed(
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Text(
              'Dado da paciente (Contexto de Vida, escala 0–10) — não é a avaliação clínica',
              style: pw.TextStyle(
                  fontSize: 8.5,
                  fontWeight: pw.FontWeight.bold,
                  color: _muted)),
        ),
        _grid(patient),
      ));
    }
    return _headedAll(out);
  }

  /// Mantém a nota do quadro junto da primeira linha (a nota é o primeiro
  /// item de [items]).
  static List<pw.Widget> _headedAll(List<pw.Widget> items) =>
      items.length < 2 ? items : _headed(items.first, items.sublist(1));

  static List<pw.Widget> _origins(CaseConceptualization? concept) {
    final o = concept?.origins;
    return [
      ..._headed(_subHeading('7.1', 'Descrição geral da história inicial'),
          _grid([('História', _val(o?.earlyHistory))])),
      pw.SizedBox(height: 8),
      ..._headed(
          _subHeading('7.2', 'Avaliação das necessidades essenciais não atendidas'),
          (concept?.hasAnyNeed ?? false)
              ? _needs(concept!)
              : _placeholder(
                  'Necessidades essenciais (X/0/1/3/5), origem e esquemas — a preencher.')),
      pw.SizedBox(height: 8),
      ..._headed(_subHeading('7.3', 'Possíveis fatores temperamentais/biológicos'),
          _grid([('Temperamento', _val(o?.temperament))])),
      pw.SizedBox(height: 8),
      ..._headed(_subHeading('7.4', 'Possíveis fatores culturais, étnicos e religiosos'),
          _grid([('Fatores culturais', _val(o?.cultural))])),
    ];
  }

  static List<pw.Widget> _needs(CaseConceptualization concept) {
    final labels = {for (final n in kCoreNeeds) n.key: n.label};
    final filled = concept.unmetNeeds.where((u) => !u.isEmpty).toList();
    final out = <pw.Widget>[
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 4),
        child: pw.Text(
            'Nota: X = informação insuficiente · 0 = quase nada · 1 = muito limitado · 3 = moderado · 5 = em grande medida',
            style: const pw.TextStyle(fontSize: 8, color: _muted)),
      ),
    ];
    for (var i = 0; i < filled.length; i++) {
      final n = filled[i];
      out.add(pw.Inseparable(child: pw.Column(children: [
        _row([
          _labelCell('7.2.${i + 1} ${labels[n.needKey] ?? n.needKey}'),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Avaliação',
                  style: const pw.TextStyle(fontSize: 8, color: _muted)),
              pw.SizedBox(height: 2),
              _chips(const ['X', '0', '1', '3', '5'], n.rating, size: 17),
            ],
          ),
        ], const [150, null]),
        _row([_labelCell('a. Origem'), _val(n.origin)], const [150, null]),
        _row([_labelCell('b. Esquemas'), _val(n.schemas)], const [150, null]),
        pw.SizedBox(height: 6),
      ])));
    }
    // Nota + primeiro quadro juntos (o título da subseção vem colado a eles).
    if (out.length > 1) {
      out[0] = pw.Inseparable(child: pw.Column(children: [out[0], out[1]]));
      out.removeAt(1);
    }
    return out;
  }

  static List<pw.Widget> _sequences(CaseConceptualization concept) {
    final seqs = concept.modeSequences.where((s) => !s.isEmpty).toList();
    return [
      for (var i = 0; i < seqs.length; i++) ...[
        ..._grid([
          (
            'Sequência ${i + 1}',
            _val((seqs[i].trigger ?? '').trim().isEmpty
                ? null
                : 'Gatilho: ${seqs[i].trigger!.trim()}')
          ),
          if ((seqs[i].activatedModes ?? '').trim().isNotEmpty)
            ('Modos', _val(seqs[i].activatedModes)),
          if ((seqs[i].copingMode ?? '').trim().isNotEmpty)
            ('Enfrentamento', _val(seqs[i].copingMode)),
          if ((seqs[i].sequence ?? '').trim().isNotEmpty)
            ('Sequência', _val(seqs[i].sequence)),
          if ((seqs[i].effect ?? '').trim().isNotEmpty)
            ('Efeito', _val(seqs[i].effect)),
          if ((seqs[i].perpetuation ?? '').trim().isNotEmpty)
            ('Perpetua', _val(seqs[i].perpetuation)),
        ]),
        pw.SizedBox(height: 8),
      ],
    ];
  }

  static List<(String, String, List<(String, pw.Widget)>)> _relationshipGroups(
      TherapeuticRelationship rel) {
    String score(int? v) => v == null ? '—' : '${v.clamp(0, 5)}/5';
    bool has(String? s) => (s ?? '').trim().isNotEmpty;
    final collab = <(String, pw.Widget)>[
      if (rel.collaborationRating != null)
        ('11.2.1 Nota (1–5)', _val(score(rel.collaborationRating))),
      if (has(rel.collaborationNotes))
        ('11.2.2 Descrição', _val(rel.collaborationNotes)),
      if (has(rel.collaborationImprove))
        ('11.2.3 Como melhorar', _val(rel.collaborationImprove)),
    ];
    final bond = <(String, pw.Widget)>[
      if (rel.bondRating != null)
        ('11.3.1 Nota (1–5)', _val(score(rel.bondRating))),
      if (has(rel.bondNotes)) ('11.3.2 Descrição', _val(rel.bondNotes)),
      if (has(rel.bondStrengthen))
        ('11.3.3 Como fortalecer', _val(rel.bondStrengthen)),
    ];
    final other = <(String, pw.Widget)>[
      if (has(rel.otherFactors)) ('11.4 Outros fatores', _val(rel.otherFactors)),
    ];
    final reactions = <(String, pw.Widget)>[
      if (has(rel.therapistReactions))
        ('Descrição', _val(rel.therapistReactions)),
    ];
    // Ordem do modelo 3.8: 11.1, 11.2, 11.3, 11.4.
    return [
      ('11.1', 'Reações pessoais do terapeuta ao cliente', reactions),
      ('11.2', 'Colaboração', collab),
      ('11.3', 'Vínculo de reparentalidade', bond),
      ('11.4', 'Outros', other),
    ].where((g) => g.$3.isNotEmpty).toList();
  }

  /// Títulos das subseções da 11 que saem no PDF, na ordem (para teste).
  @visibleForTesting
  static List<String> relationshipHeadings(TherapeuticRelationship rel) => [
        for (final g in _relationshipGroups(rel)) '${g.$1} ${g.$2}',
      ];

  /// Texto do campo "Data" do cabeçalho: a data digitada ou vazio.
  @visibleForTesting
  static String headerDate(CaseFormHeader? fh) {
    final d = fh?.formDate;
    if (d == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(d.day)}/${two(d.month)}/${d.year}';
  }

  /// 11 — 11.1 reações do terapeuta, 11.2 colaboração, 11.3 vínculo, 11.4 outros.
  static List<pw.Widget> _relationship(TherapeuticRelationship rel) {
    final groups = _relationshipGroups(rel);
    final out = <pw.Widget>[
      for (var i = 0; i < groups.length; i++) ...[
        if (i > 0) pw.SizedBox(height: 8),
        ..._headed(_subHeading(groups[i].$1, groups[i].$2), _grid(groups[i].$3)),
      ],
    ];
    return out.isEmpty ? _placeholder('— a preencher.') : out;
  }

  // ── Seções terapeuta (6, 8, 9, 12) ───────────────────────────────────────

  static List<pw.Widget> _lifeProblems(TherapistLifeProblems lp) {
    final problems = [lp.problem1, lp.problem2, lp.problem3, lp.problem4]
        .map((p) => (p ?? '').trim())
        .toList();
    final rows = <(String, pw.Widget)>[
      for (var i = 0; i < problems.length; i++)
        if (problems[i].isNotEmpty) ('6.${i + 1}', _val(problems[i])),
    ];
    return rows.isEmpty ? _placeholder('— a preencher.') : _grid(rows);
  }

  static List<pw.Widget> _centralSchemasTherapist(
      List<CentralSchemaEntry> schemas) {
    final filled = schemas.where((e) => !e.isEmpty).toList();
    if (filled.isEmpty) return _placeholder('Nenhum esquema central registrado.');
    return _grid([
      for (var i = 0; i < filled.length; i++)
        ('8.2.${i + 1} ${(filled[i].name ?? '').trim()}',
            _val(filled[i].description)),
    ]);
  }

  static List<pw.Widget> _modeAssessmentTherapist(SchemaModeAssessment ma) {
    final out = <pw.Widget>[];

    // 9.1 Modos saudáveis
    if (!ma.healthyModes.isEmpty) {
      final hm = ma.healthyModes;
      final fields = <(String, String?)>[
        ('Espontaneidade', hm.happyChildSpontaneity),
        ('Brincadeira', hm.happyChildPlay),
        ('Criatividade', hm.happyChildCreativity),
        ('Meta-consciência', hm.adultMetaAwareness),
        ('Conexão emocional', hm.adultEmotionalConnection),
        ('Orientação para a realidade', hm.adultRealityOrientation),
        ('Identidade', hm.adultIdentity),
        ('Autoafirmação', hm.adultSelfAssertion),
        ('Agência', hm.adultAgency),
        ('Cuidado com os outros', hm.adultCareForOthers),
        ('Esperança', hm.adultHope),
      ].where((e) => (e.$2 ?? '').trim().isNotEmpty).toList();
      if (fields.isNotEmpty) {
        out.addAll(_headed(_subHeading('9.1', 'Modos saudáveis'),
            _grid([for (final f in fields) (f.$1, _val(f.$2))])));
        out.add(pw.SizedBox(height: 8));
      }
    }

    List<(String, pw.Widget)> childRows(dynamic c) => [
          if ((c.description ?? '').toString().trim().isNotEmpty)
            ('Descrição', _val(c.description as String?)),
          if ((c.schemas ?? '').toString().trim().isNotEmpty)
            ('Esquemas', _val(c.schemas as String?)),
          for (final e in (c.examples as List).where((e) => !e.isEmpty))
            if ((e.trigger ?? '').toString().trim().isNotEmpty)
              ('Exemplo', _val(e.trigger as String?)),
        ];

    // 9.2 Criança vulnerável
    if (!ma.vulnerableChild.isEmpty) {
      final rows = childRows(ma.vulnerableChild);
      if (rows.isNotEmpty) {
        out.addAll(_headed(_subHeading('9.2', 'Criança vulnerável'), _grid(rows)));
        out.add(pw.SizedBox(height: 8));
      }
    }

    // 9.3 Outros modos da criança
    if (!ma.otherChild.isEmpty) {
      final rows = childRows(ma.otherChild);
      if (rows.isNotEmpty) {
        out.addAll(
            _headed(_subHeading('9.3', 'Outros modos da criança'), _grid(rows)));
        out.add(pw.SizedBox(height: 8));
      }
    }

    // 9.4 Modos parentais + coping
    final pm = ma.parentalModes.where((e) => !e.isEmpty).toList();
    final cm = ma.copingModes.where((e) => !e.isEmpty).toList();
    if (pm.isNotEmpty || cm.isNotEmpty) {
      out.addAll(_headed(
        _subHeading('9.4', 'Modos parentais e de enfrentamento'),
        _grid([
          for (final p in pm)
            (
              (p.name ?? '').trim().isEmpty ? 'Modo parental' : p.name!.trim(),
              _val(p.messages)
            ),
          for (final c in cm)
            (
              [c.category, c.name]
                  .where((v) => (v ?? '').trim().isNotEmpty)
                  .map((v) => v!.trim())
                  .join(' · '),
              _val(c.example)
            ),
        ]),
      ));
    }

    if (out.isEmpty) return _placeholder('Avaliação de modos não preenchida.');
    return out;
  }

  static List<pw.Widget> _therapyObjectivesPdf(
      List<TherapyObjectiveEntry> objectives) {
    final filled = objectives.where((e) => !e.isEmpty).toList();
    if (filled.isEmpty) {
      return _placeholder('Nenhum objetivo terapêutico registrado.');
    }
    return [
      for (var i = 0; i < filled.length; i++) ...[
        ..._grid([
          ('12.${i + 1} Objetivo', _val(filled[i].goal)),
          if ((filled[i].schemasModes ?? '').trim().isNotEmpty)
            ('Esquemas/modos', _val(filled[i].schemasModes)),
          if ((filled[i].healthyBehaviors ?? '').trim().isNotEmpty)
            ('Comportamentos saudáveis', _val(filled[i].healthyBehaviors)),
          if ((filled[i].interventions ?? '').trim().isNotEmpty)
            ('Intervenções', _val(filled[i].interventions)),
          if ((filled[i].progress ?? '').trim().isNotEmpty)
            ('Progresso', _val(filled[i].progress)),
        ]),
        pw.SizedBox(height: 8),
      ],
    ];
  }

  // ── Primitivos ─────────────────────────────────────────────────────────
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
                pw.SizedBox(height: 3),
                pw.Row(
                  children: [
                    pw.Expanded(child: _bar(g.progress, 100, _blue)),
                    pw.SizedBox(width: 8),
                    pw.Text('${g.progress}%',
                        style: pw.TextStyle(
                            fontSize: 8.5,
                            fontWeight: pw.FontWeight.bold,
                            color: _blue)),
                  ],
                ),
                if (g.linkedLabels.isNotEmpty) ...[
                  pw.SizedBox(height: 4),
                  pw.Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      for (final l in g.linkedLabels)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: pw.BoxDecoration(
                            color: _tint,
                            borderRadius: pw.BorderRadius.circular(20),
                          ),
                          child: pw.Text(l,
                              style: pw.TextStyle(
                                  fontSize: 8,
                                  fontWeight: pw.FontWeight.bold,
                                  color: _blue)),
                        ),
                    ],
                  ),
                ],
                if ((g.targetDateLabel ?? '').trim().isNotEmpty) ...[
                  pw.SizedBox(height: 3),
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

  static PdfColor _catColor(String key) => switch (key) {
        'blue' => _blue,
        'warning' => _warning,
        'error' => _error,
        'success' => _success,
        'purple' => _purple,
        'cyan' => const PdfColor.fromInt(0xFF17A2B8),
        _ => const PdfColor.fromInt(0xFF17A2B8),
      };

  /// 8 — esquemas priorizados do YSQ, com domínio e descrição (catálogo de ST).
  static List<pw.Widget> _schemas(List<MentalMapScoreHighlight> schemas) => [
        for (var i = 0; i < schemas.length; i++)
          () {
            final h = schemas[i];
            final info = schemaInfoForCode(h.code);
            final color = info == null
                ? const PdfColor.fromInt(0xFF17A2B8)
                : _catColor(info.domain.colorKey);
            final hasScore = h.scoreLabel != null &&
                h.scoreLabel!.trim().isNotEmpty &&
                h.scoreLabel != '-';
            return pw.Container(
              margin:
                  pw.EdgeInsets.only(bottom: i == schemas.length - 1 ? 0 : 9),
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
                          pw.Text(info.domain.label,
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
