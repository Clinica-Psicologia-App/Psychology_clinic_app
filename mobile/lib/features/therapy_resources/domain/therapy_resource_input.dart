import 'therapy_resource.dart';
import 'therapy_resource_type.dart';

class TherapyResourceInput {
  const TherapyResourceInput({
    required this.title,
    required this.type,
    this.description,
    this.url,
    this.isActive = true,
  });

  final String title;
  final TherapyResourceType type;
  final String? description;
  final String? url;
  final bool isActive;

  factory TherapyResourceInput.fromResource(TherapyResource resource) {
    return TherapyResourceInput(
      title: resource.title,
      type: resource.type,
      description: resource.description,
      url: resource.url,
      isActive: resource.isActive,
    );
  }

  String? validate() {
    if (title.trim().isEmpty) {
      return 'Informe o titulo do material.';
    }

    final cleanUrl = url?.trim();
    if (cleanUrl != null && cleanUrl.isNotEmpty) {
      final uri = Uri.tryParse(cleanUrl);
      final isSupportedScheme =
          uri != null && (uri.scheme == 'http' || uri.scheme == 'https');
      if (!isSupportedScheme || uri.host.trim().isEmpty) {
        return 'Informe um link válido iniciado por http:// ou https://.';
      }
    }

    return null;
  }

  Map<String, dynamic> toInsertJson({required String clinicId}) {
    return {
      'clinic_id': clinicId,
      ...toUpdateJson(),
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'title': title.trim(),
      'type': type.value,
      'description': _nullableTrim(description),
      'url': _nullableTrim(url),
      'is_active': isActive,
    };
  }

  static String? _nullableTrim(String? value) {
    final clean = value?.trim();
    if (clean == null || clean.isEmpty) return null;
    return clean;
  }
}
