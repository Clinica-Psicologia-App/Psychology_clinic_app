import 'life_chapter.dart';
import 'timeline_entry.dart';

/// Agregado da Tela 2 — os eventos de um paciente agrupados por capítulo da
/// vida, na ordem cronológica.
class PatientHistory {
  const PatientHistory({
    required this.patientId,
    this.entries = const [],
  });

  final String patientId;
  final List<TimelineEntry> entries;

  /// Eventos de um capítulo, ordenados por idade quando disponível.
  List<TimelineEntry> entriesFor(LifeChapter chapter) {
    final list = entries.where((e) => e.lifeChapter == chapter).toList()
      ..sort((a, b) => (a.ageAtEvent ?? 1 << 30).compareTo(b.ageAtEvent ?? 1 << 30));
    return list;
  }

  /// Eventos sem capítulo atribuído (ex.: importados da linha do tempo antiga).
  List<TimelineEntry> get unchaptered =>
      entries.where((e) => e.lifeChapter == null).toList();

  int get eventCount => entries.length;
}
