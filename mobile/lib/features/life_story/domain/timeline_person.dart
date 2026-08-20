import 'life_story_enums.dart';

/// Pessoa citada na história do paciente — identificação e parentesco.
///
/// Vive em `genogram_people` (é o mesmo registro que o Genograma usa, sem
/// duplicar). No fluxo da Linha do Tempo só interessam nome e parentesco;
/// a camada emocional (vínculo, necessidades) pertence ao Genograma.
class TimelinePerson {
  const TimelinePerson({
    required this.id,
    required this.fullName,
    this.role,
    this.eventCount = 0,
  });

  final String id;
  final String fullName;
  final RelationshipRole? role;

  /// Em quantos acontecimentos da linha do tempo essa pessoa aparece.
  /// Alimenta a Etapa 1 do Genograma ("aparece em N momentos"). Derivado da
  /// junção `timeline_event_people`; 0 quando não carregado.
  final int eventCount;

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  factory TimelinePerson.fromJson(Map<String, dynamic> json) {
    return TimelinePerson(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      role: relationshipRoleFromKey(json['relationship_to_patient'] as String?),
      eventCount: (json['event_count'] as num?)?.toInt() ?? 0,
    );
  }
}
