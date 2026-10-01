import 'check_in_mode.dart';
import 'patient_check_in.dart';

class PatientCheckInInput {
  const PatientCheckInInput({
    this.moodScore,
    this.moodEmotions = const [],
    this.anxietyScore,
    this.energyScore,
    this.sleepScore,
    this.stressScore,
    this.selectedModes = const [],
    this.notes,
  });

  final int? moodScore;
  final List<String> moodEmotions;
  final int? anxietyScore;
  final int? energyScore;
  final int? sleepScore;
  final int? stressScore;
  final List<CheckInMode> selectedModes;
  final String? notes;

  factory PatientCheckInInput.fromCheckIn(PatientCheckIn checkIn) {
    return PatientCheckInInput(
      moodScore: checkIn.moodScore,
      moodEmotions: checkIn.moodEmotions,
      anxietyScore: checkIn.anxietyScore,
      energyScore: checkIn.energyScore,
      sleepScore: checkIn.sleepScore,
      stressScore: checkIn.stressScore,
      selectedModes: checkIn.effectiveModes,
      notes: checkIn.notes,
    );
  }

  String? validate() {
    if (!_scoreValid(moodScore)) return 'Humor deve ser entre 0 e 10.';
    if (!_scoreValid(anxietyScore)) return 'Ansiedade deve ser entre 0 e 10.';
    if (!_scoreValid(energyScore)) return 'Energia deve ser entre 0 e 10.';
    if (!_scoreValid(sleepScore)) return 'Sono deve ser entre 0 e 10.';
    if (!_scoreValid(stressScore)) return 'Estresse deve ser entre 0 e 10.';
    if (moodScore == null &&
        anxietyScore == null &&
        energyScore == null &&
        sleepScore == null &&
        stressScore == null &&
        (notes == null || notes!.trim().isEmpty)) {
      return 'Informe ao menos uma escala ou observação.';
    }
    return null;
  }

  bool _scoreValid(int? value) {
    if (value == null) return true;
    return value >= 0 && value <= 10;
  }

  Map<String, dynamic> toRowJson() {
    return {
      'mood_score': moodScore,
      'mood_emotions': moodEmotions,
      'anxiety_score': anxietyScore,
      'energy_score': energyScore,
      'sleep_score': sleepScore,
      'stress_score': stressScore,
      'selected_modes':
          selectedModes.isEmpty ? null : selectedModes.map((m) => m.toJson()).toList(),
      'notes': _nullableTrim(notes),
    };
  }

  static String? _nullableTrim(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
}
