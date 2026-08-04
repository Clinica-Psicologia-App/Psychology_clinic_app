import 'package:flutter/material.dart';

import '../../domain/library_content.dart';

/// Biblioteca no estilo streaming (Netflix): fundo escuro, banner de destaque
/// e prateleiras horizontais de cartazes. Tema escuro fixo — é uma experiência
/// de mídia imersiva, independente do tema do app.
class PatientLibraryView extends StatelessWidget {
  const PatientLibraryView({
    super.key,
    required this.content,
    this.onItemTap,
    this.onHeroTap,
  });

  final LibraryContent content;
  final void Function(LibraryItem item)? onItemTap;
  final VoidCallback? onHeroTap;

  static const _bg = Color(0xFF0B0B10);
  static const _accent = Color(0xFF00C2B8); // turquesa da marca, vibrante

  @override
  Widget build(BuildContext context) {
    return Container(
      color: _bg,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Hero(hero: content.hero, accent: _accent, onTap: onHeroTap),
          const SizedBox(height: 8),
          for (final row in content.rows) ...[
            _Shelf(row: row, onItemTap: onItemTap),
            const SizedBox(height: 22),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Banner de destaque ──────────────────────────────────────────────────────
class _Hero extends StatelessWidget {
  const _Hero({required this.hero, required this.accent, this.onTap});

  final LibraryHero hero;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 460,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _Cover(gradient: hero.coverGradient, url: hero.coverUrl),
          // Scrim inferior para o texto respirar e fundir com o fundo.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.35, 0.72, 1.0],
                colors: [
                  Colors.transparent,
                  Color(0xCC0B0B10),
                  Color(0xFF0B0B10),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20,
            right: 20,
            bottom: 26,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (hero.eyebrow != null) ...[
                  _Eyebrow(text: hero.eyebrow!, accent: accent),
                  const SizedBox(height: 12),
                ],
                Text(
                  hero.title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  hero.tagline,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13.5,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _HeroButton(
                      icon: Icons.play_arrow_rounded,
                      label: 'Assistir',
                      filled: true,
                      accent: accent,
                      onTap: onTap,
                    ),
                    const SizedBox(width: 12),
                    _HeroButton(
                      icon: Icons.info_outline_rounded,
                      label: 'Detalhes',
                      filled: false,
                      accent: accent,
                      onTap: onTap,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.text, required this.accent});
  final String text;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.auto_awesome, size: 13, color: accent),
          const SizedBox(width: 6),
          Text(
            text.toUpperCase(),
            style: TextStyle(
              color: accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroButton extends StatelessWidget {
  const _HeroButton({
    required this.icon,
    required this.label,
    required this.filled,
    required this.accent,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool filled;
  final Color accent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.white : Colors.white.withValues(alpha: 0.18),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 11),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon,
                  size: 22, color: filled ? Colors.black : Colors.white),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: filled ? Colors.black : Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Prateleira (carrossel) ──────────────────────────────────────────────────
class _Shelf extends StatelessWidget {
  const _Shelf({required this.row, this.onItemTap});

  final LibraryRow row;
  final void Function(LibraryItem item)? onItemTap;

  @override
  Widget build(BuildContext context) {
    final poster = row.layout == LibraryRowLayout.poster;
    final cardH = poster ? 178.0 : 128.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                row.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (row.subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 1),
                  child: Text(
                    row.subtitle!,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: cardH,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: row.items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _Card(
              item: row.items[i],
              poster: poster,
              onTap: onItemTap == null ? null : () => onItemTap!(row.items[i]),
            ),
          ),
        ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.item, required this.poster, this.onTap});

  final LibraryItem item;
  final bool poster;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final w = poster ? 120.0 : 228.0;
    return SizedBox(
      width: w,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _Cover(gradient: item.coverGradient, url: item.coverUrl),
                // Scrim para legibilidade do texto sobre a capa.
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: [0.45, 1.0],
                      colors: [Colors.transparent, Color(0xE6000000)],
                    ),
                  ),
                ),
                if (item.badge != null)
                  Positioned(
                    top: 8,
                    left: 8,
                    // Reserva espaço à direita p/ o "Novo" não colidir.
                    right: item.isNew ? 52 : 8,
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: _Badge(text: item.badge!, icon: item.badgeIcon),
                    ),
                  ),
                if (item.isNew)
                  const Positioned(top: 8, right: 8, child: _NewTag()),
                Positioned(
                  left: 8,
                  right: 8,
                  bottom: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      if (item.subtitle != null)
                        Text(
                          item.subtitle!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 10.5,
                          ),
                        ),
                      if (item.progress != null) ...[
                        const SizedBox(height: 6),
                        _ProgressBar(value: item.progress!),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Cover extends StatelessWidget {
  const _Cover({required this.gradient, this.url});
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

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.icon});
  final String text;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 11, color: Colors.white),
            const SizedBox(width: 4),
          ],
          Flexible(
            child: Text(
              text.toUpperCase(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NewTag extends StatelessWidget {
  const _NewTag();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFE50914),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text(
        'NOVO',
        style: TextStyle(
          color: Colors.white,
          fontSize: 8.5,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: Container(
        height: 3,
        color: Colors.white24,
        child: FractionallySizedBox(
          alignment: Alignment.centerLeft,
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(color: const Color(0xFFE50914)),
        ),
      ),
    );
  }
}
