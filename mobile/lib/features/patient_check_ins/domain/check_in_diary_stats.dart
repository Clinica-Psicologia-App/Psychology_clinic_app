import 'patient_check_in.dart';

/// Tendência do humor nos últimos registros. Fala do movimento, nunca do
/// paciente — quem interpreta é o psicólogo, na sessão.
enum MoodTrend { rising, steady, falling }

/// Números da capa do diário: quanto já foi escrito, há quantos dias seguidos,
/// e o fio do humor ao longo dos últimos registros.
class CheckInDiaryStats {
  const CheckInDiaryStats({
    required this.total,
    required this.streakDays,
    required this.moodSeries,
    required this.trend,
  });

  /// Quantas páginas o paciente já escreveu.
  final int total;

  /// Dias consecutivos com registro, contando de hoje para trás. Se hoje ainda
  /// está em branco mas ontem tem registro, a sequência continua valendo — ela
  /// só quebra quando um dia inteiro passa sem nada.
  final int streakDays;

  /// Humores do mais antigo ao mais recente (no máximo 14), para a linha.
  final List<int> moodSeries;

  /// Null quando ainda não há registros suficientes para falar de movimento.
  final MoodTrend? trend;

  bool get hasSeries => moodSeries.length >= 2;
}

/// [items] vem do mais recente para o mais antigo (ordem do repositório).
CheckInDiaryStats buildDiaryStats(
  List<PatientCheckIn> items, {
  DateTime? now,
}) {
  final today = _dayOf(now ?? DateTime.now());

  final days = <DateTime>{
    for (final c in items) _dayOf(c.checkedInAt.toLocal()),
  };

  var streak = 0;
  var cursor = days.contains(today)
      ? today
      : days.contains(_shift(today, -1))
          ? _shift(today, -1)
          : null;
  while (cursor != null && days.contains(cursor)) {
    streak++;
    cursor = _shift(cursor, -1);
  }

  final moods = <int>[
    for (final c in items.take(14).toList().reversed)
      if (c.moodScore != null) c.moodScore!,
  ];

  return CheckInDiaryStats(
    total: items.length,
    streakDays: streak,
    moodSeries: moods,
    trend: _trendOf(moods),
  );
}

/// Compara a média dos três últimos com a dos três anteriores. Menos de quatro
/// pontos não dá para falar de tendência — melhor não dizer nada.
MoodTrend? _trendOf(List<int> moods) {
  if (moods.length < 4) return null;
  final recent = moods.sublist(moods.length - 3);
  final beforeStart = (moods.length - 6).clamp(0, moods.length);
  final before = moods.sublist(beforeStart, moods.length - 3);
  if (before.isEmpty) return null;

  final avgRecent = recent.reduce((a, b) => a + b) / recent.length;
  final avgBefore = before.reduce((a, b) => a + b) / before.length;
  final delta = avgRecent - avgBefore;

  if (delta >= 1) return MoodTrend.rising;
  if (delta <= -1) return MoodTrend.falling;
  return MoodTrend.steady;
}

DateTime _dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

DateTime _shift(DateTime day, int days) =>
    DateTime(day.year, day.month, day.day + days);
