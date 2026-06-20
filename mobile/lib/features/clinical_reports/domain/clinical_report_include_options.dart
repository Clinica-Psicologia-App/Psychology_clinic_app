/// Seções opcionais do relatório clínico PDF (staff).
class ClinicalReportIncludeOptions {
  const ClinicalReportIncludeOptions({
    this.questionnaires = true,
    this.mentalMap = true,
    this.goals = true,
    this.problems = true,
    this.checkIns = true,
    this.dailyMonitors = true,
    this.timeline = true,
    this.genogram = true,
  });

  static const defaults = ClinicalReportIncludeOptions();

  final bool questionnaires;
  final bool mentalMap;
  final bool goals;
  final bool problems;
  final bool checkIns;
  final bool dailyMonitors;
  final bool timeline;
  final bool genogram;

  bool get hasAnySection =>
      questionnaires ||
      mentalMap ||
      goals ||
      problems ||
      checkIns ||
      dailyMonitors ||
      timeline ||
      genogram;

  ClinicalReportIncludeOptions copyWith({
    bool? questionnaires,
    bool? mentalMap,
    bool? goals,
    bool? problems,
    bool? checkIns,
    bool? dailyMonitors,
    bool? timeline,
    bool? genogram,
  }) {
    return ClinicalReportIncludeOptions(
      questionnaires: questionnaires ?? this.questionnaires,
      mentalMap: mentalMap ?? this.mentalMap,
      goals: goals ?? this.goals,
      problems: problems ?? this.problems,
      checkIns: checkIns ?? this.checkIns,
      dailyMonitors: dailyMonitors ?? this.dailyMonitors,
      timeline: timeline ?? this.timeline,
      genogram: genogram ?? this.genogram,
    );
  }

  Map<String, dynamic> toIncludeJson() => {
        'questionnaires': questionnaires,
        'mental_map': mentalMap,
        'goals': goals,
        'problems': problems,
        'check_ins': checkIns,
        'daily_monitors': dailyMonitors,
        'timeline': timeline,
        'genogram': genogram,
      };

  Map<String, dynamic> toRequestJson(String patientId) => {
        'patient_id': patientId,
        'include': toIncludeJson(),
      };
}
