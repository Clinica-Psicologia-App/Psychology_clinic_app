import 'result_snapshot.dart';

/// Resultado por categoria (`questionnaire_results`).
class CategoryResult {
  const CategoryResult({
    required this.id,
    this.categoryCode,
    this.categoryName,
    this.totalScore,
    this.averageScore,
    this.classification,
    required this.snapshot,
    this.professionalAverageScore,
    this.professionalNote,
  });

  final String id;
  final String? categoryCode;
  final String? categoryName;
  final double? totalScore;
  final double? averageScore;
  final String? classification;
  final ResultSnapshot snapshot;
  final double? professionalAverageScore;
  final String? professionalNote;

  factory CategoryResult.fromJson(Map<String, dynamic> json) {
    final category = json['category'];
    Map<String, dynamic>? categoryMap;
    if (category is Map) {
      categoryMap = Map<String, dynamic>.from(category);
    }

    return CategoryResult(
      id: json['id'] as String,
      categoryCode: categoryMap?['code'] as String?,
      categoryName: categoryMap?['name'] as String?,
      totalScore: _num(json['total_score']),
      averageScore: _num(json['average_score']),
      classification: json['classification'] as String?,
      snapshot: ResultSnapshot.fromJson(json['snapshot']),
      professionalAverageScore: _num(json['professional_average_score']),
      professionalNote: json['professional_note'] as String?,
    );
  }

  String get classificationLabel {
    final c = classification?.trim();
    if (c == null || c.isEmpty) return '-';
    if (c == 'pending_review') return 'Aguardando revisão';
    return c;
  }

  String get parentalFigureLabel {
    final value = categoryName ?? categoryCode ?? '';
    if (value.endsWith('- Mãe') || value.endsWith('- Mãe')) return 'Mãe';
    if (value.endsWith('- Pai') || value.endsWith('- Pai')) return 'Pai';
    return 'Geral';
  }

  String get shortCategoryLabel {
    final value = (categoryName ?? categoryCode ?? '').trim();
    if (value.isEmpty) return 'Categoria';

    const separators = ['- Mãe', '- Pai', '- Mãe', '- Pai'];
    for (final separator in separators) {
      if (value.endsWith(separator)) {
        return value.substring(0, value.length - separator.length).trim();
      }
    }
    return value;
  }
}

double? _num(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
