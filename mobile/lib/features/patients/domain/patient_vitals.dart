class PatientVitals {
  const PatientVitals({
    required this.lastCheckinDays,
    required this.activeGoals,
    required this.pendingQuestionnaires,
  });

  /// Dias desde o último check-in. null = nunca fez.
  final int? lastCheckinDays;
  final int activeGoals;
  final int pendingQuestionnaires;

  String get lastCheckinLabel {
    if (lastCheckinDays == null) return 'Nenhum';
    if (lastCheckinDays == 0) return 'Hoje';
    if (lastCheckinDays == 1) return 'Ontem';
    return 'Há ${lastCheckinDays}d';
  }

  factory PatientVitals.fromJson(Map<String, dynamic> json) => PatientVitals(
        lastCheckinDays: json['last_checkin_days'] as int?,
        activeGoals: (json['active_goals'] as num?)?.toInt() ?? 0,
        pendingQuestionnaires:
            (json['pending_questionnaires'] as num?)?.toInt() ?? 0,
      );
}
