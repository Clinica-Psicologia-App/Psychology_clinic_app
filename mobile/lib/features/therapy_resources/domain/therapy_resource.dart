import 'therapy_resource_type.dart';

class TherapyResource {
  const TherapyResource({
    required this.id,
    required this.title,
    required this.type,
    this.description,
    this.url,
    required this.isActive,
  });

  final String id;
  final String title;
  final TherapyResourceType type;
  final String? description;
  final String? url;
  final bool isActive;

  factory TherapyResource.fromJson(Map<String, dynamic> json) {
    return TherapyResource(
      id: json['id'] as String,
      title: json['title'] as String,
      type: TherapyResourceType.fromString(json['type'] as String? ?? 'other'),
      description: json['description'] as String?,
      url: json['url'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}
