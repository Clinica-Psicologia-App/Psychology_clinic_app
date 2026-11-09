/// Metadados de um nó do hub para o bottom sheet (M5).
class MentalMapNodeDetail {
  const MentalMapNodeDetail({
    required this.id,
    required this.title,
    required this.items,
    required this.dataSource,
    required this.ctaLabel,
    this.lastUpdatedAt,
    this.responseId,
    this.secondaryCtaLabel,
    this.secondaryRoute,
    this.severityColorKey,
    this.itemKeys = const [],
  });

  final String id;
  final String title;
  final List<String> items;

  /// Chave de cada item (mesma ordem de [items]); ver [MentalCaseMapNode].
  final List<String> itemKeys;
  final String dataSource;
  final String ctaLabel;
  final DateTime? lastUpdatedAt;
  final String? responseId;
  final String? secondaryCtaLabel;
  final String? secondaryRoute;

  /// Severidade agregada do nó: `green`, `yellow`, `amber`, `orange`, `red`.
  final String? severityColorKey;

  bool get isFilled => items.isNotEmpty;
}
