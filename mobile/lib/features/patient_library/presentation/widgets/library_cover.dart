import 'package:flutter/material.dart';

/// Capa de uma obra: imagem de rede (coverUrl) ou gradiente de fallback.
class LibraryCover extends StatelessWidget {
  const LibraryCover({super.key, required this.gradient, this.url});

  final List<Color> gradient;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final fallback = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient.length >= 2
              ? gradient
              : [gradient.first, gradient.first],
        ),
      ),
    );
    if (url == null || url!.isEmpty) return fallback;
    return Image.network(
      url!,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallback,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : fallback,
    );
  }
}
