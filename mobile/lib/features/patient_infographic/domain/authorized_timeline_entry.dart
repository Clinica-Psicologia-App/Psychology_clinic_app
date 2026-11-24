import '../../life_story/domain/life_timeline_age.dart';
import 'timeline_chronology.dart' as chrono;
import 'timeline_chronology.dart' show TimelineRef;

/// Acontecimento que o psicólogo autorizou a aparecer no infográfico do
/// paciente (retorno de `get_patient_infographic_timeline`).
class AuthorizedTimelineEntry {
  const AuthorizedTimelineEntry({
    required this.id,
    required this.title,
    required this.periodLabel,
    this.ageStart,
    this.eventDate,
    this.rawPeriod,
    this.lifeChapter,
    this.createdAt,
  });

  final String id;
  final String title;

  /// Quando aconteceu: data, rótulo livre, idade (ponto ou faixa) ou fase.
  final String periodLabel;

  /// Idade inicial, só para ordenar.
  final int? ageStart;

  /// Campos extras só para ordenar (a função pode ou não devolvê-los).
  final DateTime? eventDate;
  final String? rawPeriod;
  final String? lifeChapter;
  final DateTime? createdAt;

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
      eventDate: _date(json['event_date']),
      rawPeriod: period,
      lifeChapter: json['life_chapter'] as String?,
      createdAt: _date(json['created_at']),
    );
  }

  static DateTime? _date(Object? v) =>
      v is String && v.isNotEmpty ? DateTime.tryParse(v)?.toLocal() : null;

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

  TimelineRef get _ref => TimelineRef(
        eventDate: eventDate,
        ageAtEvent: ageStart,
        periodLabel: rawPeriod,
        lifeChapter: lifeChapter,
        createdAt: createdAt,
      );

  /// Comparador para `List.sort` (mesma regra; prefira [sortChronologically],
  /// que é estável).
  static int compareChronologically(
    AuthorizedTimelineEntry a,
    AuthorizedTimelineEntry b,
  ) =>
      chrono.compareChronologically(a._ref, b._ref);

  /// Cópia em ordem cronológica (mais antigo primeiro), mesma regra do
  /// infográfico do terapeuta; sem nascimento conhecido aqui.
  static List<AuthorizedTimelineEntry> sortChronologically(
    List<AuthorizedTimelineEntry> entries,
  ) =>
      chrono.sortChronologically(entries, (e) => e._ref);
}
