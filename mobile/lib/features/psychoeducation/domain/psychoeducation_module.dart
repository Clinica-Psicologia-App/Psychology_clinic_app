import 'package:flutter/material.dart';

/// Um card dentro de um módulo da Biblioteca de Psicoeducação.
///
/// `therapistText` só é preenchido para o staff (a RPC do paciente o remove).
class PsychoeducationCard {
  const PsychoeducationCard({
    required this.title,
    this.imageUrl,
    this.patientText,
    this.therapistText,
    this.reflection,
    this.exercise,
  });

  final String title;
  final String? imageUrl;
  final String? patientText;
  final String? therapistText;
  final String? reflection;
  final String? exercise;

  factory PsychoeducationCard.fromJson(Map<String, dynamic> json) {
    return PsychoeducationCard(
      title: json['title'] as String? ?? '',
      imageUrl: json['image_url'] as String?,
      patientText: json['patient_text'] as String?,
      therapistText: json['therapist_text'] as String?,
      reflection: json['reflection'] as String?,
      exercise: json['exercise'] as String?,
    );
  }
}

/// Módulo ("biblioteca") da jornada de psicoeducação.
class PsychoeducationModule {
  const PsychoeducationModule({
    required this.id,
    required this.number,
    required this.stage,
    required this.title,
    this.presentation,
    this.closing,
    this.accentColor,
    this.coverUrl,
    this.cards = const [],
  });

  final String id;
  final int number;

  /// Conhecer | Compreender | Transformar.
  final String stage;
  final String title;
  final String? presentation;
  final String? closing;

  /// Cor de destaque (hex #RRGGBB) definida na curadoria.
  final String? accentColor;
  final String? coverUrl;
  final List<PsychoeducationCard> cards;

  /// Cor resolvida a partir de [accentColor] (fallback pela etapa).
  Color get color {
    final hex = accentColor;
    if (hex != null && hex.startsWith('#') && hex.length == 7) {
      final value = int.tryParse(hex.substring(1), radix: 16);
      if (value != null) return Color(0xFF000000 | value);
    }
    return switch (stage) {
      'Conhecer' => const Color(0xFF14B8A6),
      'Transformar' => const Color(0xFF059669),
      _ => const Color(0xFF6366F1),
    };
  }

  factory PsychoeducationModule.fromJson(Map<String, dynamic> json) {
    final rawCards = json['cards'];
    return PsychoeducationModule(
      id: json['id'] as String,
      number: (json['number'] as num?)?.toInt() ?? 0,
      stage: json['stage'] as String? ?? 'Compreender',
      title: json['title'] as String? ?? 'Sem título',
      presentation: json['presentation'] as String?,
      closing: json['closing'] as String?,
      accentColor: json['accent_color'] as String?,
      coverUrl: json['cover_url'] as String?,
      cards: rawCards is List
          ? rawCards
              .whereType<Map>()
              .map((c) =>
                  PsychoeducationCard.fromJson(Map<String, dynamic>.from(c)))
              .toList()
          : const [],
    );
  }
}

/// Etapas da jornada, na ordem em que aparecem para o paciente.
enum PsychoeducationStage {
  conhecer('Conhecer', 'Entenda o modelo, as necessidades e as origens.'),
  compreender(
      'Compreender', 'Identifique sua história, seus padrões e esquemas.'),
  transformar(
      'Transformar', 'Reconheça a ativação e fortaleça o Adulto Saudável.');

  const PsychoeducationStage(this.label, this.subtitle);
  final String label;
  final String subtitle;

  static PsychoeducationStage fromLabel(String label) {
    return PsychoeducationStage.values.firstWhere(
      (s) => s.label == label,
      orElse: () => PsychoeducationStage.compreender,
    );
  }
}
