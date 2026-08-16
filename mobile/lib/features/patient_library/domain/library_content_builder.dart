import 'package:flutter/material.dart';

import 'library_content.dart';
import 'library_indication.dart';
import 'library_work.dart';

/// Monta o conteúdo da tela (hero + prateleiras) a partir das indicações do
/// paciente. Agrupa por status — a Biblioteca do paciente é dirigida pelas
/// obras que o psicólogo indicou.
LibraryContent? buildLibraryContent(List<LibraryIndication> indications) {
  if (indications.isEmpty) return null;

  final inProgress = indications.where((i) => i.isInProgress).toList();
  final newOnes = indications.where((i) => i.isNew).toList();
  final watched = indications.where((i) => i.isWatched).toList();

  // Destaque: a indicação nova mais recente; senão a primeira da lista.
  final featured = newOnes.isNotEmpty ? newOnes.first : indications.first;

  final rows = <LibraryRow>[
    if (inProgress.isNotEmpty)
      LibraryRow(
        title: 'Continue assistindo',
        layout: LibraryRowLayout.landscape,
        items: [for (final i in inProgress) _item(i, progress: 0.5)],
      ),
    if (newOnes.isNotEmpty)
      LibraryRow(
        title: 'Indicados pelo seu psicólogo',
        subtitle: 'Selecionados a partir da sua conceitualização',
        items: [for (final i in newOnes) _item(i, isNew: true)],
      ),
    if (watched.isNotEmpty)
      LibraryRow(
        title: 'Já assistidos',
        items: [for (final i in watched) _item(i)],
      ),
  ];

  return LibraryContent(
    hero: _hero(featured),
    rows: rows,
  );
}

LibraryHero _hero(LibraryIndication ind) {
  final w = ind.work;
  return LibraryHero(
    id: ind.id,
    title: w.displayTitle,
    tagline: (w.patientLayer.before?.trim().isNotEmpty ?? false)
        ? w.patientLayer.before!
        : (w.synopsis ?? 'Uma obra escolhida especialmente para você.'),
    eyebrow: 'Indicado pelo seu psicólogo',
    coverGradient: _gradientFor(w.id),
    coverUrl: w.coverUrl,
    kind: LibraryItemKind.movie,
  );
}

LibraryItem _item(LibraryIndication ind,
    {bool isNew = false, double? progress}) {
  final w = ind.work;
  return LibraryItem(
    id: ind.id,
    title: w.displayTitle,
    subtitle: _typeLabel(w),
    badge: _typeBadge(w.workType),
    badgeIcon: _typeIcon(w.workType),
    coverGradient: _gradientFor(w.id),
    coverUrl: w.coverUrl,
    isNew: isNew,
    progress: progress,
  );
}

String _typeBadge(String workType) =>
    workType == 'Minissérie' ? 'Série' : workType;

IconData _typeIcon(String workType) {
  switch (workType) {
    case 'Série':
    case 'Minissérie':
      return Icons.live_tv_outlined;
    case 'Episódio':
      return Icons.subscriptions_outlined;
    default:
      return Icons.movie_outlined;
  }
}

String _typeLabel(LibraryWork w) {
  final parts = <String>[
    w.workType,
    if (w.year != null) '${w.year}',
  ];
  return parts.join(' · ');
}

/// Gradiente determinístico por id (placeholder enquanto não há pôster).
List<Color> _gradientFor(String id) {
  const palette = <List<Color>>[
    [Color(0xFF3B2F8F), Color(0xFF11808F)],
    [Color(0xFF7A2E5D), Color(0xFF2B1030)],
    [Color(0xFF1F6FEB), Color(0xFF0B2A5B)],
    [Color(0xFFB5462A), Color(0xFF3A150C)],
    [Color(0xFF2E7D57), Color(0xFF0F2E22)],
    [Color(0xFFC79A17), Color(0xFF4A3708)],
    [Color(0xFF9B2C6F), Color(0xFF35102A)],
    [Color(0xFF2A9D9A), Color(0xFF0E3A3A)],
    [Color(0xFF334155), Color(0xFF0F172A)],
    [Color(0xFF3B0764), Color(0xFF16032B)],
  ];
  return palette[id.hashCode.abs() % palette.length];
}
