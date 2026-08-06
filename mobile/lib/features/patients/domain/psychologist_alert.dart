enum PsychologistAlertKind {
  missingCheckin,
  expiringInvitation,
  staleQuestionnaire,
}

class PsychologistAlert {
  const PsychologistAlert({
    required this.kind,
    required this.patientName,
    required this.daysCount,
    this.patientId,
    this.invitationId,
  });

  final PsychologistAlertKind kind;
  final String patientName;
  final int daysCount;
  final String? patientId;
  final String? invitationId;

  String get message {
    switch (kind) {
      case PsychologistAlertKind.missingCheckin:
        if (daysCount >= 999) return '$patientName nunca fez check-in';
        return '$patientName sem check-in há $daysCount dias';
      case PsychologistAlertKind.expiringInvitation:
        if (daysCount == 0) return 'Convite de $patientName expira hoje';
        if (daysCount == 1) return 'Convite de $patientName expira amanhã';
        return 'Convite de $patientName expira em $daysCount dias';
      case PsychologistAlertKind.staleQuestionnaire:
        return '$patientName com questionário em andamento há $daysCount dias';
    }
  }

  static List<PsychologistAlert> fromRpcJson(Map<String, dynamic> json) {
    final alerts = <PsychologistAlert>[];

    // Ordem de prioridade: convites (tempo-crítico) → questionários → check-ins
    for (final item in (json['expiring_invitations'] as List? ?? [])) {
      final j = Map<String, dynamic>.from(item as Map);
      alerts.add(PsychologistAlert(
        kind: PsychologistAlertKind.expiringInvitation,
        patientName: j['patient_name'] as String,
        daysCount: (j['days_until_expiry'] as num).toInt(),
        invitationId: j['invitation_id'] as String?,
      ));
    }
    for (final item in (json['stale_questionnaires'] as List? ?? [])) {
      final j = Map<String, dynamic>.from(item as Map);
      alerts.add(PsychologistAlert(
        kind: PsychologistAlertKind.staleQuestionnaire,
        patientName: j['patient_name'] as String,
        daysCount: (j['days_waiting'] as num).toInt(),
        patientId: j['patient_id'] as String?,
      ));
    }
    for (final item in (json['missing_checkins'] as List? ?? [])) {
      final j = Map<String, dynamic>.from(item as Map);
      alerts.add(PsychologistAlert(
        kind: PsychologistAlertKind.missingCheckin,
        patientName: j['patient_name'] as String,
        daysCount: (j['days_since_checkin'] as num).toInt(),
        patientId: j['patient_id'] as String?,
      ));
    }

    return alerts;
  }
}
