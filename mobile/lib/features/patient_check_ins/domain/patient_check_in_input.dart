import 'patient_check_in.dart';

class PatientCheckInInput {
  const PatientCheckInInput({
    this.moodScore,
    this.anxietyScore,
    this.energyScore,
    this.problemIntensityScore,
    this.notes,
  });

  final int? moodScore;
  final int? anxietyScore;
  final int? energyScore;
  final int? problemIntensityScore;
  final String? notes;

  factory PatientCheckInInput.fromCheckIn(PatientCheckIn checkIn) {
    return PatientCheckInInput(
      moodScore: checkIn.moodScore,
      anxietyScore: checkIn.anxietyScore,
      energyScore: checkIn.energyScore,
      problemIntensityScore: checkIn.problemIntensityScore,
      notes: checkIn.notes,
    );
  }

  String? validate() {
    if (!_scoreValid(moodScore)) return 'Humor deve ser entre 0 e 10.';
    if (!_scoreValid(anxietyScore)) return 'Ansiedade deve ser entre 0 e 10.';
    if (!_scoreValid(energyScore)) return 'Energia deve ser entre 0 e 10.';
    if (!_scoreValid(problemIntensityScore)) {
      return 'Intensidade dos problemas deve ser entre 0 e 10.';
    }
    if (moodScore == null &&
        anxietyScore == null &&
        energyScore == null &&
        problemIntensityScore == null &&
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
      'anxiety_score': anxietyScore,
      'energy_score': energyScore,
      'problem_intensity_score': problemIntensityScore,
      'notes': _nullableTrim(notes),
    };
  }

  static String? _nullableTrim(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
}
