import 'package:flutter/material.dart';

enum TherapyResourceType {
  article('article'),
  video('video'),
  exercise('exercise'),
  document('document'),
  link('link'),
  other('other');

  const TherapyResourceType(this.value);

  final String value;

  static TherapyResourceType fromString(String raw) {
    return TherapyResourceType.values.firstWhere(
      (t) => t.value == raw,
      orElse: () => TherapyResourceType.other,
    );
  }

  String get label {
    switch (this) {
      case TherapyResourceType.article:
        return 'Artigo';
      case TherapyResourceType.video:
        return 'Vídeo';
      case TherapyResourceType.exercise:
        return 'Exercício';
      case TherapyResourceType.document:
        return 'Documento';
      case TherapyResourceType.link:
        return 'Link';
      case TherapyResourceType.other:
        return 'Outro';
    }
  }

  IconData get icon {
    switch (this) {
      case TherapyResourceType.article:
        return Icons.article_outlined;
      case TherapyResourceType.video:
        return Icons.play_circle_outline;
      case TherapyResourceType.exercise:
        return Icons.fitness_center_outlined;
      case TherapyResourceType.document:
        return Icons.description_outlined;
      case TherapyResourceType.link:
        return Icons.link;
      case TherapyResourceType.other:
        return Icons.folder_outlined;
    }
  }
}
