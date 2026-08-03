import 'package:flutter/material.dart';

/// Modelos de apresentação da Biblioteca estilo streaming (Netflix).
///
/// São puramente de UI: o builder (fase 2) vai preenchê-los a partir dos
/// recursos liberados (therapy_resources) e do catálogo de filmes que o
/// admin liberar. A capa aceita uma imagem (coverUrl) ou um gradiente de
/// fallback, para o layout funcionar mesmo sem arte.
enum LibraryItemKind { movie, material }

class LibraryContent {
  const LibraryContent({
    required this.hero,
    this.rows = const [],
  });

  final LibraryHero hero;
  final List<LibraryRow> rows;

  bool get isEmpty => rows.isEmpty;
}

/// Destaque no topo (banner grande).
class LibraryHero {
  const LibraryHero({
    required this.title,
    required this.tagline,
    required this.coverGradient,
    this.eyebrow,
    this.coverUrl,
    this.kind = LibraryItemKind.movie,
  });

  final String title;
  final String tagline;

  /// Selo acima do título (ex.: "Recomendado pelo seu psicólogo").
  final String? eyebrow;
  final List<Color> coverGradient;
  final String? coverUrl;
  final LibraryItemKind kind;
}

/// Uma "prateleira" horizontal (carrossel).
class LibraryRow {
  const LibraryRow({
    required this.title,
    required this.items,
    this.subtitle,
    this.layout = LibraryRowLayout.poster,
  });

  final String title;
  final String? subtitle;
  final List<LibraryItem> items;

  /// Cartaz vertical (filmes) ou cartão paisagem (materiais/vídeos).
  final LibraryRowLayout layout;
}

enum LibraryRowLayout { poster, landscape }

/// Um item da biblioteca (filme ou material).
class LibraryItem {
  const LibraryItem({
    required this.id,
    required this.title,
    required this.coverGradient,
    this.subtitle,
    this.badge,
    this.badgeIcon,
    this.coverUrl,
    this.kind = LibraryItemKind.movie,
    this.progress,
    this.isNew = false,
  });

  final String id;
  final String title;
  final String? subtitle;

  /// Etiqueta curta (ex.: "Filme", "Vídeo", "Exercício").
  final String? badge;
  final IconData? badgeIcon;

  /// Imagem de capa; quando nula, usa [coverGradient].
  final String? coverUrl;
  final List<Color> coverGradient;
  final LibraryItemKind kind;

  /// Progresso de leitura/visualização 0–1 (barrinha no cartão).
  final double? progress;

  /// Selo "Novo" no canto.
  final bool isNew;
}
