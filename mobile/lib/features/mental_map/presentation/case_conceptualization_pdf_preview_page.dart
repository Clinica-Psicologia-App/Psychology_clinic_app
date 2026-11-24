import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_banner.dart';

/// Função que compartilha o PDF (padrão: folha de compartilhamento do sistema).
typedef PdfShareFn = Future<void> Function(Uint8List bytes, String fileName);

/// Prévia do documento em tela cheia, ANTES de baixar ou enviar. Nada é
/// compartilhado até tocar em "Compartilhar".
class CaseConceptualizationPdfPreviewPage extends StatefulWidget {
  const CaseConceptualizationPdfPreviewPage({
    super.key,
    required this.bytes,
    required this.fileName,
    this.onShare,
    this.previewBuilder,
  });

  final Uint8List bytes;
  final String fileName;

  /// Injeta o compartilhamento (testes). Padrão: [Printing.sharePdf].
  final PdfShareFn? onShare;

  /// Troca o visualizador das páginas (testes/renders, onde não há o motor de
  /// rasterização do `printing`). Padrão: [PdfPreview].
  final Widget Function(BuildContext context, Uint8List bytes)? previewBuilder;

  /// Compartilhamento padrão (WhatsApp, e-mail etc.).
  static Future<void> defaultShare(Uint8List bytes, String fileName) =>
      Printing.sharePdf(bytes: bytes, filename: fileName);

  @override
  State<CaseConceptualizationPdfPreviewPage> createState() =>
      _PreviewState();
}

class _PreviewState extends State<CaseConceptualizationPdfPreviewPage> {
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      await (widget.onShare ?? CaseConceptualizationPdfPreviewPage.defaultShare)(
          widget.bytes, widget.fileName);
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final builder = widget.previewBuilder;
    return Scaffold(
      key: const Key('pdf_preview_page'),
      backgroundColor: const Color(0xFFE9EDF5),
      appBar: AppBar(
        leading: IconButton(
          key: const Key('pdf_preview_close'),
          icon: const Icon(Icons.close),
          tooltip: 'Fechar',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: const Text('Prévia do documento'),
      ),
      body: builder != null
          ? builder(context, widget.bytes)
          : PdfPreview(
              build: (_) async => widget.bytes,
              pdfFileName: widget.fileName,
              useActions: false,
              canChangePageFormat: false,
              canChangeOrientation: false,
              canDebug: false,
              allowPrinting: false,
              allowSharing: false,
              scrollViewDecoration:
                  const BoxDecoration(color: Color(0xFFE9EDF5)),
              loadingWidget: const CircularProgressIndicator(),
            ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: const Key('pdf_preview_back'),
                  onPressed: () => Navigator.of(context).maybePop(),
                  child: const Text('Voltar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: FilledButton.icon(
                  key: const Key('pdf_preview_share'),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.navy,
                      minimumSize: const Size.fromHeight(48)),
                  onPressed: _sharing ? null : _share,
                  icon: const Icon(Icons.ios_share),
                  label: const Text('Compartilhar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
