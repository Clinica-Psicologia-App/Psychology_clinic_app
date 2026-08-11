import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Capa de uma obra: imagem de rede (coverUrl) ou gradiente de fallback.
///
/// Cache em disco (via [CachedNetworkImage]) — sem isso, cada aparição da
/// capa (card da lista, detalhe, tela do paciente) refaria o download da
/// rede. Com a capa agora também no card da lista — potencialmente dezenas
/// por tela —, cache em memória sozinho não bastava para não pesar o scroll.
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
    return CachedNetworkImage(
      imageUrl: url!,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 150),
      errorWidget: (_, __, ___) => fallback,
      placeholder: (_, __) => fallback,
    );
  }
}
