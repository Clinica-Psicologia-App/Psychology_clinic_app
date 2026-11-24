import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import 'infographic_export.dart';

/// Prévia do PDF do infográfico antes de enviar. Voltar não envia nada;
/// "Compartilhar" abre a folha de compartilhamento do aparelho (de lá também
/// dá para salvar em Arquivos).
class InfographicPdfPreviewPage extends StatefulWidget {
  const InfographicPdfPreviewPage({
    super.key,
    required this.pdfBytes,
    required this.fileName,
    this.viewerBuilder,
    this.shareFile,
  });

  final Uint8List pdfBytes;

  /// Nome do arquivo sem extensão.
  final String fileName;

  /// Só para testes/render: substitui o visualizador (que usa o plugin
  /// `printing`, indisponível em teste).
  final Widget Function(BuildContext context, Uint8List pdf)? viewerBuilder;

  /// Envia o PDF (padrão: grava em arquivo temporário e abre a folha de
  /// compartilhamento). Injetável para teste.
  final Future<void> Function(String fileName, Uint8List pdf)? shareFile;

  @override
  State<InfographicPdfPreviewPage> createState() =>
      _InfographicPdfPreviewPageState();
}

class _InfographicPdfPreviewPageState extends State<InfographicPdfPreviewPage> {
  bool _busy = false;

  Future<void> _share() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final custom = widget.shareFile;
      if (custom != null) {
        await custom('${widget.fileName}.pdf', widget.pdfBytes);
      } else {
        final path = await InfographicExport.writeTempFile(
            '${widget.fileName}.pdf', widget.pdfBytes);
        await InfographicExport.share(path, text: 'Infográfico clínico');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível compartilhar o PDF.')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final viewer = widget.viewerBuilder;
    return AppScaffold(
      title: 'Prévia do PDF',
      accent: AppColors.purple,
      body: Column(
        children: [
          Expanded(
            child: viewer != null
                ? viewer(context, widget.pdfBytes)
                : PdfPreview(
                    build: (_) => widget.pdfBytes,
                    useActions: false,
                    canChangePageFormat: false,
                    canChangeOrientation: false,
                    canDebug: false,
                    allowPrinting: false,
                    allowSharing: false,
                    pdfFileName: '${widget.fileName}.pdf',
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            decoration: const BoxDecoration(color: AppColors.surface),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _busy ? null : _share,
                  icon: const Icon(Icons.ios_share),
                  label: Text(_busy ? 'Gerando…' : 'Compartilhar'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
