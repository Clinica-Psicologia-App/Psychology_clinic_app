import 'dart:io';
import 'dart:math' as math;
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
/// PNG numa única página, então imagem e documento saem do mesmo layout.
class InfographicExport {
  const InfographicExport._();

  /// Maior lado (px) do PNG capturado. Acima disso muitos aparelhos não
  /// conseguem gerar a imagem (limite de textura gráfica).
  static const int maxCaptureSide = 8192;

  /// Resolução da captura: [wanted], reduzida quando o pôster (com muitos
  /// acontecimentos) passaria de [maxCaptureSide].
  @visibleForTesting
  static double capturePixelRatio(Size size, double wanted) =>
      math.min(wanted, (maxCaptureSide - 1) / size.longestSide);

  /// Captura o widget referenciado por [boundaryKey] como PNG de alta resolução.
  static Future<Uint8List> capturePng(
    GlobalKey boundaryKey, {
    double pixelRatio = 2,
  }) async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(
      pixelRatio: capturePixelRatio(boundary.size, pixelRatio),
    );
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  /// Margem da página do PDF (pt).
  static const double pdfMargin = 24;

  /// Maior lado de página que o formato PDF aceita (pt).
  static const double pdfMaxSide = 14400;

  /// Fundo do pôster, usado também na margem da página.
  static const _paper = PdfColor.fromInt(0xFFFBF8F3);

  /// Monta o PDF numa única página: largura de A4 (595 pt), margem de
  /// [pdfMargin] em volta (a imagem nunca encosta na borda) e altura do tamanho
  /// do pôster. Vale para o celular e para o navegador.
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

    final pageWidth = PdfPageFormat.a4.width;
    var imageWidth = pageWidth - pdfMargin * 2;
    var imageHeight = imageWidth * h / w;
    // Pôster absurdamente comprido: encolhe para caber no limite do formato.
    const maxImageHeight = pdfMaxSide - pdfMargin * 2;
    if (imageHeight > maxImageHeight) {
      imageWidth *= maxImageHeight / imageHeight;
      imageHeight = maxImageHeight;
    }

    final doc = pw.Document();
    final image = pw.MemoryImage(png);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat(pageWidth, imageHeight + pdfMargin * 2),
        margin: pw.EdgeInsets.zero,
        build: (_) => pw.Container(
          color: _paper,
          alignment: pw.Alignment.center,
          child: pw.SizedBox(
            width: imageWidth,
            height: imageHeight,
            child: pw.Image(image, fit: pw.BoxFit.fill),
          ),
        ),
      ),
    );
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
