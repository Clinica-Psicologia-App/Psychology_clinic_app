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
/// PNG numa página A4, então imagem e documento saem do mesmo layout.
class InfographicExport {
  const InfographicExport._();

  /// Captura o widget referenciado por [boundaryKey] como PNG de alta resolução.
  static Future<Uint8List> capturePng(
    GlobalKey boundaryKey, {
    double pixelRatio = 3,
  }) async {
    final boundary =
        boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: pixelRatio);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return bytes!.buffer.asUint8List();
  }

  /// Monta um PDF A4 com o PNG ocupando a largura da página.
  static Future<Uint8List> buildPdf(Uint8List png) async {
    final doc = pw.Document();
    final image = pw.MemoryImage(png);
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (_) => pw.Center(
          child: pw.Image(image, fit: pw.BoxFit.contain),
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
