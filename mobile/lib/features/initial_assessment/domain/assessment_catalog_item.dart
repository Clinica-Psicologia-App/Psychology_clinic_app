/// Item selecionável de checklist (esquema, modo ou necessidade emocional).
/// Reaproveita os catálogos existentes (`schemas`, `emotional_needs`).
class AssessmentCatalogItem {
  const AssessmentCatalogItem({
    required this.id,
    required this.code,
    required this.name,
    this.description,
  });

  final String id;
  final String code;
  final String name;
  final String? description;

  factory AssessmentCatalogItem.fromJson(Map<String, dynamic> json) {
    return AssessmentCatalogItem(
      id: json['id'] as String,
      code: (json['code'] as String?) ?? '',
      name: (json['name'] as String?) ?? '',
      description: json['description'] as String?,
    );
  }
}
