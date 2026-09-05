import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/patient_check_ins/domain/check_in_diary_stats.dart';
import 'package:terapia_esquema/features/patient_check_ins/domain/patient_check_in.dart';

final _now = DateTime(2026, 9, 5, 14);

PatientCheckIn _at(int daysAgo, {int? mood}) {
  final d = DateTime(_now.year, _now.month, _now.day - daysAgo, 10);
  return PatientCheckIn(
    id: 'c$daysAgo',
    clinicId: 'c',
    patientId: 'p',
    moodScore: mood,
    checkedInAt: d,
    createdAt: d,
    updatedAt: d,
  );
}

void main() {
  group('sequência de dias', () {
    test('conta a partir de hoje quando hoje tem registro', () {
      final s = buildDiaryStats([_at(0), _at(1), _at(2)], now: _now);
      expect(s.streakDays, 3);
    });

    test('hoje em branco não quebra a sequência de ontem', () {
      final s = buildDiaryStats([_at(1), _at(2), _at(3)], now: _now);
      expect(s.streakDays, 3);
    });

    test('quebra quando falta um dia inteiro', () {
      final s = buildDiaryStats([_at(2), _at(3)], now: _now);
      expect(s.streakDays, 0);
    });

    test('dois registros no mesmo dia contam como um', () {
      final s = buildDiaryStats([_at(0), _at(0), _at(1)], now: _now);
      expect(s.streakDays, 2);
      expect(s.total, 3, reason: 'páginas escritas conta cada registro');
    });

    test('diário vazio não tem sequência', () {
      final s = buildDiaryStats(const [], now: _now);
      expect(s.streakDays, 0);
      expect(s.total, 0);
      expect(s.hasSeries, isFalse);
    });
  });

  group('linha do humor', () {
    test('vem do mais antigo para o mais recente', () {
      final s = buildDiaryStats(
        [_at(0, mood: 8), _at(1, mood: 5), _at(2, mood: 3)],
        now: _now,
      );
      expect(s.moodSeries, [3, 5, 8]);
    });

    test('ignora registros sem humor', () {
      final s = buildDiaryStats(
        [_at(0, mood: 8), _at(1), _at(2, mood: 3)],
        now: _now,
      );
      expect(s.moodSeries, [3, 8]);
    });

    test('não passa de 14 pontos', () {
      final s = buildDiaryStats(
        [for (var i = 0; i < 20; i++) _at(i, mood: 5)],
        now: _now,
      );
      expect(s.moodSeries.length, 14);
    });
  });

  group('tendência', () {
    test('poucos pontos não viram tendência', () {
      final s = buildDiaryStats(
        [_at(0, mood: 9), _at(1, mood: 2), _at(2, mood: 9)],
        now: _now,
      );
      expect(s.trend, isNull);
    });

    test('em alta quando os últimos sobem ao menos um ponto', () {
      // série (antigo → recente): 3, 3, 3, 7, 7, 7
      final s = buildDiaryStats(
        [
          _at(0, mood: 7),
          _at(1, mood: 7),
          _at(2, mood: 7),
          _at(3, mood: 3),
          _at(4, mood: 3),
          _at(5, mood: 3),
        ],
        now: _now,
      );
      expect(s.trend, MoodTrend.rising);
    });

    test('em baixa no sentido contrário', () {
      final s = buildDiaryStats(
        [
          _at(0, mood: 3),
          _at(1, mood: 3),
          _at(2, mood: 3),
          _at(3, mood: 8),
          _at(4, mood: 8),
          _at(5, mood: 8),
        ],
        now: _now,
      );
      expect(s.trend, MoodTrend.falling);
    });

    test('variação pequena continua estável', () {
      final s = buildDiaryStats(
        [
          _at(0, mood: 6),
          _at(1, mood: 5),
          _at(2, mood: 6),
          _at(3, mood: 5),
          _at(4, mood: 6),
          _at(5, mood: 5),
        ],
        now: _now,
      );
      expect(s.trend, MoodTrend.steady);
    });
  });
}
