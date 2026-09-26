import 'check_in_mode.dart';

class PatientCheckIn {
  const PatientCheckIn({
    required this.id,
    required this.clinicId,
    required this.patientId,
    this.createdBy,
    this.moodScore,
    this.moodEmotions = const [],
    this.anxietyScore,
    this.energyScore,
    this.problemIntensityScore,
    this.selectedMode,
    this.notes,
    required this.checkedInAt,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String clinicId;
  final String patientId;
  final String? createdBy;
  final int? moodScore;
  final List<String> moodEmotions;
  final int? anxietyScore;
  final int? energyScore;
  final int? problemIntensityScore;
  final CheckInMode? selectedMode;
  final String? notes;
  final DateTime checkedInAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isToday {
    final now = DateTime.now();
    final local = checkedInAt.toLocal();
    return local.year == now.year &&
        local.month == now.month &&
        local.day == now.day;
  }

  bool get isEditableToday => isToday;

  String get summaryLine {
    final parts = <String>[];
    if (moodScore != null) parts.add('Humor $moodScore');
    if (anxietyScore != null) parts.add('Ansiedade $anxietyScore');
    if (energyScore != null) parts.add('Energia $energyScore');
    if (problemIntensityScore != null) {
      parts.add('Problemas $problemIntensityScore');
    }
    return parts.isEmpty ? 'Check-in' : parts.join(' · ');
  }

  factory PatientCheckIn.fromJson(Map<String, dynamic> json) {
    final emotions = json['mood_emotions'];
    final modeJson = json['selected_mode'];
    return PatientCheckIn(
      id: json['id'] as String,
      clinicId: json['clinic_id'] as String,
      patientId: json['patient_id'] as String,
      createdBy: json['created_by'] as String?,
      moodScore: json['mood_score'] as int?,
      moodEmotions: emotions is List
          ? emotions.map((e) => e as String).toList()
          : const [],
      anxietyScore: json['anxiety_score'] as int?,
      energyScore: json['energy_score'] as int?,
      problemIntensityScore: json['problem_intensity_score'] as int?,
      selectedMode: modeJson is Map<String, dynamic>
          ? CheckInMode.fromJson(modeJson)
          : null,
      notes: json['notes'] as String?,
      checkedInAt: DateTime.parse(json['checked_in_at'] as String).toLocal(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }
}
