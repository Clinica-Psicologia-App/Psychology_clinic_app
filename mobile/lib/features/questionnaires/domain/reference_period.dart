/// Período de referência temporal configurado em `questionnaire_versions.reference_period`.
enum ReferencePeriod {
  unspecified,
  lastMonth,
  lastYear,
  lifetime,
}

extension ReferencePeriodParsing on ReferencePeriod {
  /// Valor persistido no Postgres (`questionnaire_versions.reference_period`).
  String get storageValue => switch (this) {
        ReferencePeriod.unspecified => 'unspecified',
        ReferencePeriod.lastMonth => 'last_month',
        ReferencePeriod.lastYear => 'last_year',
        ReferencePeriod.lifetime => 'lifetime',
      };

  /// Texto exibido ao paciente antes de iniciar; `null` se [unspecified].
  String? get patientOrientationMessage => switch (this) {
        ReferencePeriod.unspecified => null,
        ReferencePeriod.lastYear =>
          'Responda considerando suas experiências, emoções e comportamentos durante os últimos 12 meses.',
        ReferencePeriod.lastMonth =>
          'Responda considerando suas experiências, emoções e comportamentos durante o último mês.',
        ReferencePeriod.lifetime =>
          'Responda considerando toda a sua história de vida.',
      };

  bool get showsPatientOrientation => patientOrientationMessage != null;
}

ReferencePeriod referencePeriodFromStorage(String? value) {
  switch (value) {
    case 'last_month':
      return ReferencePeriod.lastMonth;
    case 'last_year':
      return ReferencePeriod.lastYear;
    case 'lifetime':
      return ReferencePeriod.lifetime;
    case 'unspecified':
    case null:
    case '':
      return ReferencePeriod.unspecified;
    default:
      return ReferencePeriod.unspecified;
  }
}

/// Extrai o período da versão ativa retornada pelo Supabase (lista ou detalhe).
ReferencePeriod referencePeriodFromQuestionnaireJson(
    Map<String, dynamic> json) {
  final versions = json['questionnaire_versions'];
  if (versions is List && versions.isNotEmpty) {
    final first = versions.first;
    if (first is Map<String, dynamic>) {
      return referencePeriodFromStorage(first['reference_period'] as String?);
    }
    if (first is Map) {
      return referencePeriodFromStorage(first['reference_period'] as String?);
    }
  }
  if (versions is Map<String, dynamic>) {
    return referencePeriodFromStorage(versions['reference_period'] as String?);
  }
  final direct = json['reference_period'] as String?;
  if (direct != null) {
    return referencePeriodFromStorage(direct);
  }
  return ReferencePeriod.unspecified;
}
