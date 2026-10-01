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
    this.sleepScore,
    this.stressScore,
    this.problemIntensityScore,
    this.selectedMode,
    this.selectedModes = const [],
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
  final int? sleepScore;
  final int? stressScore;
  final int? problemIntensityScore;
  final CheckInMode? selectedMode;
  final List<CheckInMode> selectedModes;
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
    if (sleepScore != null) parts.add('Sono $sleepScore');
    if (stressScore != null) parts.add('Estresse $stressScore');
    return parts.isEmpty ? 'Check-in' : parts.join(' · ');
  }

  List<CheckInMode> get effectiveModes {
    if (selectedModes.isNotEmpty) return selectedModes;
    if (selectedMode != null) return [selectedMode!];
    return const [];
  }

  factory PatientCheckIn.fromJson(Map<String, dynamic> json) {
    final emotions = json['mood_emotions'];
    final modeJson = json['selected_mode'];
    final modesJson = json['selected_modes'];
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
      sleepScore: json['sleep_score'] as int?,
      stressScore: json['stress_score'] as int?,
      problemIntensityScore: json['problem_intensity_score'] as int?,
      selectedMode: modeJson is Map<String, dynamic>
          ? CheckInMode.fromJson(modeJson)
          : null,
      selectedModes: modesJson is List
          ? modesJson
              .whereType<Map<String, dynamic>>()
              .map(CheckInMode.fromJson)
              .toList()
          : const [],
      notes: json['notes'] as String?,
      checkedInAt: DateTime.parse(json['checked_in_at'] as String).toLocal(),
      createdAt: DateTime.parse(json['created_at'] as String).toLocal(),
      updatedAt: DateTime.parse(json['updated_at'] as String).toLocal(),
    );
  }
}
