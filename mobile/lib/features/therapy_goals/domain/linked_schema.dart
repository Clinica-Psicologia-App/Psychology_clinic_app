/// Um esquema ou modo vinculado a um objetivo (seção 12). Guarda código
/// (schemas.code, estável) e o nome para exibição, evitando resolução externa.
class LinkedSchema {
  const LinkedSchema({required this.code, required this.name});

  final String code;
  final String name;

  factory LinkedSchema.fromJson(Map<String, dynamic> j) => LinkedSchema(
        code: (j['code'] ?? '').toString(),
        name: (j['name'] ?? '').toString(),
      );

  Map<String, dynamic> toJson() => {'code': code, 'name': name};

  static List<LinkedSchema> listFromJson(dynamic value) {
    if (value is! List) return const [];
    final out = <LinkedSchema>[];
    for (final e in value) {
      if (e is Map) {
        final link = LinkedSchema.fromJson(Map<String, dynamic>.from(e));
        if (link.name.trim().isNotEmpty || link.code.trim().isNotEmpty) {
          out.add(link);
        }
      }
    }
    return out;
  }
}
