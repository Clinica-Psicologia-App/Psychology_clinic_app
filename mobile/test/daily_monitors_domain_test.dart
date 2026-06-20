import 'package:flutter_test/flutter_test.dart';
import 'package:terapia_esquema/features/daily_monitors/domain/daily_monitor.dart';
import 'package:terapia_esquema/features/daily_monitors/domain/daily_monitor_input.dart';

void main() {
  test('parseEmotionNotes extracts intensity and triggers', () {
    final parsed = parseEmotionNotes(
      'Intensidade: 8/10\nGatilhos: Reunião no trabalho',
    );
    expect(parsed.intensity, 8);
    expect(parsed.triggers, 'Reunião no trabalho');
  });

  test('buildEmotionNotes round-trips intensity and triggers', () {
    final raw = buildEmotionNotes(intensity: 5, triggers: 'Discussão');
    expect(raw, contains('Intensidade: 5/10'));
    expect(raw, contains('Gatilhos: Discussão'));

    final parsed = parseEmotionNotes(raw);
    expect(parsed.intensity, 5);
    expect(parsed.triggers, 'Discussão');
  });

  test('DailyMonitor.fromJson parses timestamps', () {
    final monitor = DailyMonitor.fromJson({
      'id': 'm1',
      'clinic_id': 'c1',
      'patient_id': 'p1',
      'mood_notes': 'Ansioso',
      'sleep_notes': 'Dormi mal',
      'activity_notes': 'Evitei sair',
      'emotion_notes': 'Intensidade: 7/10\nGatilhos: Notícias',
      'created_at': '2025-05-20T14:30:00Z',
      'updated_at': '2025-05-20T14:30:00Z',
    });

    expect(monitor.moodState, 'Ansioso');
    expect(monitor.emotionPayload.intensity, 7);
    expect(monitor.createdAt, isNotNull);
  });

  test('DailyMonitorInput.validate requires at least one field', () {
    expect(const DailyMonitorInput().validate(), isNotNull);
    expect(
      const DailyMonitorInput(moodState: 'Bem').validate(),
      isNull,
    );
  });

  test('DailyMonitorInput.validate rejects invalid intensity', () {
    expect(
      const DailyMonitorInput(intensity: 0).validate(),
      isNotNull,
    );
    expect(
      const DailyMonitorInput(intensity: 11).validate(),
      isNotNull,
    );
  });

  test('DailyMonitorInput.toRowJson maps to table columns', () {
    final json = const DailyMonitorInput(
      moodState: 'Calmo',
      intensity: 3,
      triggers: 'Barulho',
      behaviors: 'Caminhada',
      observations: 'Sono regular',
    ).toRowJson();

    expect(json['mood_notes'], 'Calmo');
    expect(json['activity_notes'], 'Caminhada');
    expect(json['sleep_notes'], 'Sono regular');
    expect(json['emotion_notes'], contains('Intensidade: 3/10'));
    expect(json['emotion_notes'], contains('Gatilhos: Barulho'));
  });

  test('DailyMonitorInput.fromMonitor restores form fields', () {
    final monitor = DailyMonitor.fromJson({
      'id': 'm2',
      'clinic_id': 'c1',
      'patient_id': 'p1',
      'mood_notes': 'Triste',
      'emotion_notes': 'Intensidade: 4/10',
      'created_at': '2025-05-01T10:00:00Z',
      'updated_at': '2025-05-01T10:00:00Z',
    });

    final input = DailyMonitorInput.fromMonitor(monitor);
    expect(input.moodState, 'Triste');
    expect(input.intensity, 4);
  });
}
