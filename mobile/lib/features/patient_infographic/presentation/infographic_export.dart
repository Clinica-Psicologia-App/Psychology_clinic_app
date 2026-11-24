import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

/// Captura + exportação do pôster do infográfico.
///
/// O PNG é capturado nativamente do [RepaintBoundary]; o PDF embute esse mesmo
/// PNG em páginas A4, então imagem e documento saem do mesmo layout.
class InfographicExport {
  const InfographicExport._();

  /// Captura o widget referenciado por [boundaryKey] como PNG de alta resolução.
  static Future<Uint8List> capturePng(
    GlobalKey boundaryKey, {
    double pixelRatio = 2,
  }) async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  /// Margem das páginas A4 do PDF (pt).
  static const double pdfMargin = 24;

  /// Páginas necessárias para um pôster de [w] × [h] px em A4 retrato, com o
  /// pôster ocupando a largura útil.
  @visibleForTesting
  static int pdfPageCount(int w, int h) {
    final usableW = PdfPageFormat.a4.width - pdfMargin * 2;
    final usableH = PdfPageFormat.a4.height - pdfMargin * 2;
    final posterH = usableW * h / w;
    return (posterH / usableH - 1e-9).ceil().clamp(1, 1000);
  }

  /// Ponto de corte (linha exclusiva) da fatia que começa em [start], com no
  /// máximo [maxHeight] linhas, num PNG RGBA de [width] × [height].
  ///
  /// Procura, de baixo para cima a partir do fim da página e até ~35% da sua
  /// altura, uma linha inteira na cor de fundo do pôster (a do pixel 0,0) e
  /// corta no meio da faixa de fundo encontrada, para não partir um cartão.
  /// Sem faixa, corta no limite da página. Sempre devolve um valor > [start].
  @visibleForTesting
  static int pdfCutPoint(
    Uint8List rgba,
    int width,
    int height,
    int start,
    int maxHeight,
  ) {
    final end = start + maxHeight;
    if (end >= height) return height;
    bool isBg(int row) {
      final o = row * width * 4;
      for (var x = 0; x < width; x++) {
        final i = o + x * 4;
        for (var k = 0; k < 4; k++) {
          if ((rgba[i + k] - rgba[k]).abs() > 2) return false;
        }
      }
      return true;
    }

    final minRow = start + (maxHeight * 0.65).floor();
    for (var r = end - 1; r >= minRow; r--) {
      if (!isBg(r)) continue;
      var a = r;
      while (a - 1 >= minRow && isBg(a - 1)) {
        a--;
      }
      final cut = (a + r) ~/ 2 + 1;
      return cut > start ? cut.clamp(start + 1, end) : end;
    }
    return end;
  }

  /// Cortes (linhas exclusivas, em pixels do original [w] × [h]) calculados
  /// sobre uma cópia reduzida RGBA [sw] × [sh]. [maxRows] é a altura máxima da
  /// fatia no original. Cada corte > o anterior e o último = [h].
  @visibleForTesting
  static List<int> pdfCutsScaled(
    Uint8List smallRgba,
    int sw,
    int sh,
    int w,
    int h,
    int maxRows,
  ) {
    final maxSmall = (maxRows * sw / w).floor().clamp(1, sh);
    final cuts = <int>[];
    var startSmall = 0;
    var prev = 0;
    while (startSmall < sh) {
      final cs = pdfCutPoint(smallRgba, sw, sh, startSmall, maxSmall);
      var cut = cs >= sh ? h : (cs * h / sh).floor();
      if (cut > prev + maxRows) cut = prev + maxRows;
      if (cut <= prev) cut = prev + 1;
      if (cut > h) cut = h;
      cuts.add(cut);
      prev = cut;
      startSmall = cs;
      if (cut >= h) break;
    }
    if (cuts.last != h) cuts.add(h);
    return cuts;
  }

  /// Monta o PDF em A4 retrato, em várias páginas: o pôster ocupa a largura
  /// útil da página (nada é cortado na lateral) e é fatiado na altura,
  /// preferindo cortar entre cartões ([pdfCutPoint]). É o mesmo PNG da imagem,
  /// embutido uma só vez. Os cortes são achados numa cópia reduzida (~300 px
  /// de largura), descartada antes de montar o documento.
  static Future<Uint8List> buildPdf(Uint8List png) async {
    final int w;
    final int h;
    final codec = await ui.instantiateImageCodec(png);
    try {
      final frame = await codec.getNextFrame();
      try {
        w = frame.image.width;
        h = frame.image.height;
      } finally {
        frame.image.dispose();
      }
    } finally {
      codec.dispose();
    }

    const format = PdfPageFormat.a4;
    final usableW = format.width - pdfMargin * 2;
    final usableH = format.height - pdfMargin * 2;
    final scale = usableW / w; // pt por pixel
    final maxRows = (usableH / scale).floor();
    final posterH = h * scale;

    final List<int> cuts;
    {
      final small = await ui.instantiateImageCodec(
        png,
        targetWidth: w > 300 ? 300 : w,
      );
      try {
        final frame = await small.getNextFrame();
        try {
          final data =
              await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
          cuts = pdfCutsScaled(
            data!.buffer.asUint8List(),
            frame.image.width,
            frame.image.height,
            w,
            h,
            maxRows,
          );
        } finally {
          frame.image.dispose();
        }
      } finally {
        small.dispose();
      }
    }

    final doc = pw.Document();
    final image = pw.MemoryImage(png);
    var start = 0;
    for (final cut in cuts) {
      final sliceH = (cut - start) * scale;
      final top = -start * scale;
      doc.addPage(
        pw.Page(
          pageFormat: format,
          margin: const pw.EdgeInsets.all(pdfMargin),
          build: (_) => pw.Align(
            alignment: pw.Alignment.topLeft,
            child: pw.SizedBox(
              width: usableW,
              height: sliceH,
              child: pw.ClipRect(
                child: pw.Stack(
                  overflow: pw.Overflow.clip,
                  children: [
                    pw.Positioned(
                      left: 0,
                      top: top,
                      child: pw.SizedBox(
                        width: usableW,
                        height: posterH,
                        child: pw.Image(image, fit: pw.BoxFit.fill),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      start = cut;
    }
    return doc.save();
  }

  /// Salva os bytes num arquivo temporário e retorna o caminho.
  static Future<String> writeTempFile(String fileName, Uint8List bytes) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  /// Abre a folha de compartilhamento com o arquivo.
  static Future<void> share(String path, {String? text}) async {
    await Share.shareXFiles([XFile(path)], text: text);
  }

  /// Nome de arquivo seguro a partir do nome do paciente.
  static String fileBase(String patientName) {
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
    return 'infografico-$base-$date';
  }
}
