import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../data/document_logo_repository.dart';
import '../../providers/document_logo_providers.dart';

/// Logo que aparece no cabeçalho do PDF/Word da conceituação.
/// Sem logo enviada, os documentos usam a logo padrão do EsquemaCore.
class DocumentLogoCard extends ConsumerStatefulWidget {
  const DocumentLogoCard({super.key, this.pickImage});

  /// Injetável em teste; por padrão abre a galeria.
  final Future<XFile?> Function()? pickImage;

  /// Mensagem de erro clara, ou null se o arquivo serve.
  static String? validate(String fileName, int size) {
    final dot = fileName.lastIndexOf('.');
    final ext = dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase();
    if (!DocumentLogoRepository.allowedExtensions.contains(ext)) {
      return 'Formato não aceito. Use uma imagem PNG, JPG ou WebP.';
    }
    if (size <= 0) return 'A imagem está vazia. Escolha outro arquivo.';
    if (size > DocumentLogoRepository.maxBytes) {
      return 'A imagem tem mais de 2 MB. Escolha uma menor.';
    }
    return null;
  }

  @override
  ConsumerState<DocumentLogoCard> createState() => _DocumentLogoCardState();
}

class _DocumentLogoCardState extends ConsumerState<DocumentLogoCard> {
  bool _busy = false;

  Future<XFile?> _pick() =>
      widget.pickImage?.call() ??
      ImagePicker().pickImage(source: ImageSource.gallery);

  Future<void> _change() async {
    final repo = ref.read(documentLogoRepositoryProvider);
    try {
      final picked = await _pick();
      if (picked == null || !mounted) return;
      final Uint8List bytes = await picked.readAsBytes();
      final problem = DocumentLogoCard.validate(picked.name, bytes.length);
      if (problem != null) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(problem)));
        }
        return;
      }
      setState(() => _busy = true);
      await repo.upload(bytes: bytes, fileName: picked.name);
      ref.invalidate(documentLogoProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo atualizada.')),
        );
      }
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await ref.read(documentLogoRepositoryProvider).remove();
      ref.invalidate(documentLogoProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo removida. Voltou à padrão.')),
        );
      }
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final logo = ref.watch(documentLogoProvider);
    final bytes = logo.valueOrNull;
    return Container(
      key: const Key('document_logo_card'),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.image_outlined, size: 18, color: AppColors.navy),
            const SizedBox(width: 8),
            Text('Logo dos documentos',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800)),
          ]),
          const SizedBox(height: 4),
          Text(
            'Aparece no cabeçalho do PDF e do Word da conceituação. '
            'PNG, JPG ou WebP, até 2 MB. Sem logo, usamos a do EsquemaCore.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 64,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD5DCEB)),
                ),
                child: logo.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : bytes == null
                        ? Text('Logo padrão',
                            key: const Key('document_logo_default'),
                            style: theme.textTheme.labelSmall
                                ?.copyWith(color: AppColors.textMuted))
                        : Padding(
                            padding: const EdgeInsets.all(6),
                            child: Image.memory(bytes,
                                key: const Key('document_logo_preview'),
                                fit: BoxFit.contain),
                          ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    OutlinedButton.icon(
                      key: const Key('document_logo_change'),
                      onPressed: _busy ? null : _change,
                      icon: const Icon(Icons.upload_outlined, size: 16),
                      label: Text(bytes == null ? 'Enviar logo' : 'Trocar logo'),
                    ),
                    if (bytes != null)
                      TextButton(
                        key: const Key('document_logo_remove'),
                        onPressed: _busy ? null : _remove,
                        child: const Text('Remover'),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
