import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

Future<void> openResourceUrl(BuildContext context, String? url) async {
  if (url == null || url.trim().isEmpty) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este recurso não possui link externo.')),
      );
    }
    return;
  }

  final uri = Uri.tryParse(url);
  if (uri == null) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Link inválido.')),
      );
    }
    return;
  }

  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Não foi possível abrir o link.')),
    );
  }
}
