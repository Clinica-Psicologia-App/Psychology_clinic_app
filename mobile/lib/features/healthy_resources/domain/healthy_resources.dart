class HealthyResources {
  const HealthyResources({
    required this.selectedPredefined,
    required this.customResources,
    this.observations,
    this.updatedAt,
  });

  final List<String> selectedPredefined;
  final List<String> customResources;
  final String? observations;
  final DateTime? updatedAt;

  bool get isEmpty =>
      selectedPredefined.isEmpty &&
      customResources.isEmpty &&
      (observations == null || observations!.trim().isEmpty);

  factory HealthyResources.empty() => const HealthyResources(
        selectedPredefined: [],
        customResources: [],
      );

  factory HealthyResources.fromJson(Map<String, dynamic> json) =>
      HealthyResources(
        selectedPredefined: List<String>.from(
            json['selected_predefined'] as List? ?? []),
        customResources: List<String>.from(
            json['custom_resources'] as List? ?? []),
        observations: json['observations'] as String?,
        updatedAt: json['updated_at'] == null
            ? null
            : DateTime.parse(json['updated_at'] as String),
      );

  Map<String, dynamic> toJson() => {
        'selected_predefined': selectedPredefined,
        'custom_resources': customResources,
        'observations': observations,
      };

  HealthyResources copyWith({
    List<String>? selectedPredefined,
    List<String>? customResources,
    String? observations,
  }) =>
      HealthyResources(
        selectedPredefined: selectedPredefined ?? this.selectedPredefined,
        customResources: customResources ?? this.customResources,
        observations: observations ?? this.observations,
        updatedAt: updatedAt,
      );
}
