import 'package:flutter/material.dart';

/// Nível de severidade clínica canônico do EsquemaCore.
///
/// Toda representação visual de severidade (resultados, mapa mental,
/// dashboard clínico) deve passar por aqui — nunca mapear `color_key`
/// para cores diretamente na tela. Severidade nunca é comunicada apenas
/// por cor: cada nível carrega ícone e rótulo próprios.
enum AppSeverity {
  none,
  low,
  moderate,
  high,
  critical;

  /// Converte a `color_key` vinda do backend (green/yellow/orange/red).
  static AppSeverity fromColorKey(String? key) => switch (key?.toLowerCase()) {
        'green' => AppSeverity.low,
        'yellow' || 'amber' => AppSeverity.moderate,
        'orange' => AppSeverity.high,
        'red' => AppSeverity.critical,
        _ => AppSeverity.none,
      };

  /// Ordem para agregação (pior severidade vence).
  int get rank => switch (this) {
        AppSeverity.none => 0,
        AppSeverity.low => 1,
        AppSeverity.moderate => 2,
        AppSeverity.high => 3,
        AppSeverity.critical => 4,
      };

  /// Cor sólida para indicadores (dots, barras).
  Color get color => switch (this) {
        AppSeverity.none => const Color(0xFF64748B),
        AppSeverity.low => const Color(0xFF059669),
        AppSeverity.moderate => const Color(0xFFB45309),
        AppSeverity.high => const Color(0xFFC2410C),
        AppSeverity.critical => const Color(0xFFB91C1C),
      };

  /// Fundo tonalizado para badges e superfícies passivas.
  Color get container => switch (this) {
        AppSeverity.none => const Color(0xFFF1F5F9),
        AppSeverity.low => const Color(0xFFD1FAE5),
        AppSeverity.moderate => const Color(0xFFFEF3C7),
        AppSeverity.high => const Color(0xFFFFEDD5),
        AppSeverity.critical => const Color(0xFFFEE2E2),
      };

  /// Texto sobre [container] (contraste AA garantido).
  Color get onContainer => switch (this) {
        AppSeverity.none => const Color(0xFF475569),
        AppSeverity.low => const Color(0xFF065F46),
        AppSeverity.moderate => const Color(0xFF92400E),
        AppSeverity.high => const Color(0xFF9A3412),
        AppSeverity.critical => const Color(0xFF991B1B),
      };

  /// Ícone que acompanha a cor — severidade nunca depende só de cor.
  IconData get icon => switch (this) {
        AppSeverity.none => Icons.remove_circle_outline,
        AppSeverity.low => Icons.check_circle_outline,
        AppSeverity.moderate => Icons.info_outline,
        AppSeverity.high => Icons.warning_amber_outlined,
        AppSeverity.critical => Icons.report_outlined,
      };

  /// Rótulo padrão quando o backend não fornecer um.
  String get defaultLabel => switch (this) {
        AppSeverity.none => 'Sem classificação',
        AppSeverity.low => 'Baixa',
        AppSeverity.moderate => 'Moderada',
        AppSeverity.high => 'Alta',
        AppSeverity.critical => 'Crítica',
      };

  bool get hasSeverity => this != AppSeverity.none;
}
