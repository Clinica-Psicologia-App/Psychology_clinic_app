import 'daily_monitor.dart';

/// Payload de formulário mapeado para colunas de `daily_monitors`.
class DailyMonitorInput {
  const DailyMonitorInput({
    this.moodState,
    this.intensity,
    this.observations,
    this.triggers,
    this.behaviors,
  });

  final String? moodState;
  final int? intensity;
  final String? observations;
  final String? triggers;
  final String? behaviors;

  factory DailyMonitorInput.fromMonitor(DailyMonitor monitor) {
    final payload = monitor.emotionPayload;
    return DailyMonitorInput(
      moodState: monitor.moodState,
      intensity: payload.intensity,
      observations: monitor.observations,
      triggers: payload.triggers,
      behaviors: monitor.behaviors,
    );
  }

  String? validate() {
    final hasMood = moodState?.trim().isNotEmpty == true;
    final hasObs = observations?.trim().isNotEmpty == true;
    final hasBeh = behaviors?.trim().isNotEmpty == true;
    final hasTrig = triggers?.trim().isNotEmpty == true;
    final hasIntensity = intensity != null;

    if (!hasMood && !hasObs && !hasBeh && !hasTrig && !hasIntensity) {
      return 'Preencha ao menos um campo do registro.';
    }

    if (intensity != null && (intensity! < 1 || intensity! > 10)) {
      return 'Intensidade deve ser entre 1 e 10.';
    }

    return null;
  }

  Map<String, dynamic> toRowJson() {
    return {
      'mood_notes': _emptyToNull(moodState),
      'sleep_notes': _emptyToNull(observations),
      'activity_notes': _emptyToNull(behaviors),
      'emotion_notes': buildEmotionNotes(
        intensity: intensity,
        triggers: triggers,
      ),
    };
  }

  static String? _emptyToNull(String? value) {
    final t = value?.trim();
    if (t == null || t.isEmpty) return null;
    return t;
  }
}
