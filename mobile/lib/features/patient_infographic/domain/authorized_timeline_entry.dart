import '../../life_story/domain/life_timeline_age.dart';

/// Acontecimento que o psicólogo autorizou a aparecer no infográfico do
/// paciente (retorno de `get_patient_infographic_timeline`).
class AuthorizedTimelineEntry {
  const AuthorizedTimelineEntry({
    required this.id,
    required this.title,
    required this.periodLabel,
    this.ageStart,
  });

  final String id;
  final String title;

  /// Quando aconteceu: data, rótulo livre, idade (ponto ou faixa) ou fase.
  final String periodLabel;

  /// Idade inicial, só para ordenar.
  final int? ageStart;

  factory AuthorizedTimelineEntry.fromJson(Map<String, dynamic> json) {
    final age = (json['age_at_event'] as num?)?.toInt();
    final label = LifeAgeSpan(
      start: age,
      end: (json['age_to'] as num?)?.toInt(),
    ).label;
    final period = (json['period_label'] as String?)?.trim();
    return AuthorizedTimelineEntry(
      id: json['id'] as String,
      title: json['title'] as String,
      periodLabel: label ??
          (period != null && period.isNotEmpty ? period : _chapter(json)),
      ageStart: age,
    );
  }

  static String _chapter(Map<String, dynamic> json) =>
      switch (json['life_chapter']) {
        'birth' => 'Nascimento',
        'early_years' => 'Primeiros anos',
        'childhood' => 'Infância',
        'adolescence' => 'Adolescência',
        'adulthood' => 'Vida adulta',
        'maturity' => 'Maturidade',
        'today' => 'Hoje',
        _ => '',
      };

  /// Mais antigos primeiro; sem idade vão para o fim.
  static int compareChronologically(
    AuthorizedTimelineEntry a,
    AuthorizedTimelineEntry b,
  ) {
    final x = a.ageStart;
    final y = b.ageStart;
    if (x == null && y == null) return 0;
    if (x == null) return 1;
    if (y == null) return -1;
    return x.compareTo(y);
  }
}
