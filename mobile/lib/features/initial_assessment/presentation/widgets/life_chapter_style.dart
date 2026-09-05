import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/life_chapter.dart';

/// Paleta e ícone de cada capítulo da vida. Fica na camada de apresentação
/// porque carrega Color/IconData — o domínio (`life_chapter.dart`) continua
/// puro. Chapter nulo = "Outros acontecimentos".
class LifeChapterStyle {
  const LifeChapterStyle({
    required this.accent,
    required this.bg,
    required this.text,
    required this.icon,
  });

  /// Cor forte: traço da espinha, borda do nó, ícone.
  final Color accent;

  /// Fundo suave: preenchimento de selos e pílulas.
  final Color bg;

  /// Cor de texto legível sobre [bg].
  final Color text;

  final IconData icon;
}

LifeChapterStyle styleForChapter(LifeChapter? chapter) => switch (chapter) {
      LifeChapter.childhood => const LifeChapterStyle(
          accent: Color(0xFFD85A30),
          bg: Color(0xFFFAECE7),
          text: Color(0xFF7D2F12),
          icon: Icons.child_care_rounded,
        ),
      LifeChapter.adolescence => const LifeChapterStyle(
          accent: Color(0xFFB97010),
          bg: Color(0xFFFAEEDA),
          text: Color(0xFF7A4408),
          icon: Icons.school_rounded,
        ),
      LifeChapter.adulthood => const LifeChapterStyle(
          accent: Color(0xFF1B9A6E),
          bg: Color(0xFFE1F5EE),
          text: Color(0xFF0D6044),
          icon: Icons.work_outline_rounded,
        ),
      LifeChapter.maturity => const LifeChapterStyle(
          accent: Color(0xFF7240C0),
          bg: Color(0xFFEDE5FA),
          text: Color(0xFF432875),
          icon: Icons.self_improvement_rounded,
        ),
      LifeChapter.today => const LifeChapterStyle(
          accent: Color(0xFF378ADD),
          bg: Color(0xFFE6F1FB),
          text: Color(0xFF185FA5),
          icon: Icons.place_rounded,
        ),
      null => const LifeChapterStyle(
          accent: AppColors.textMuted,
          bg: Color(0xFFF1F4F9),
          text: AppColors.textSecondary,
          icon: Icons.more_horiz_rounded,
        ),
    };
