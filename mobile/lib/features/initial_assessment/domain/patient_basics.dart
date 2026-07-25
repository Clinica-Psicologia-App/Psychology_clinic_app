/// Bloco 1 — "Conhecendo Você". Vive na tabela `patients` (visível ao
/// paciente). A escrita pelo paciente passa pela edge function
/// `update-patient-basics`, já que a RLS de `patients` só permite UPDATE
/// por staff.
class PatientBasics {
  const PatientBasics({
    this.fullName,
    this.preferredName,
    this.birthDate,
    this.occupation,
    this.livesWith,
    this.hasChildren,
    this.usesMedication,
    this.medicationNotes,
    this.psychiatricFollowup,
    this.psychiatristNotes,
    this.importantToKnow,
  });

  /// Somente leitura para o paciente (identidade é gerida pela equipe).
  final String? fullName;
  final String? preferredName;
  final DateTime? birthDate;
  final String? occupation;
  final String? livesWith;
  final bool? hasChildren;
  final bool? usesMedication;
  final String? medicationNotes;
  final bool? psychiatricFollowup;
  final String? psychiatristNotes;
  final String? importantToKnow;

  /// Idade derivada da data de nascimento.
  int? get age {
    final birth = birthDate;
    if (birth == null) return null;
    final now = DateTime.now();
    var years = now.year - birth.year;
    final hadBirthday =
        now.month > birth.month || (now.month == birth.month && now.day >= birth.day);
    if (!hadBirthday) years--;
    return years < 0 ? null : years;
  }

  factory PatientBasics.fromJson(Map<String, dynamic> json) {
    return PatientBasics(
      fullName: json['full_name'] as String?,
      preferredName: json['preferred_name'] as String?,
      birthDate: _parseDate(json['birth_date']),
      occupation: json['occupation'] as String?,
      livesWith: json['lives_with'] as String?,
      hasChildren: json['has_children'] as bool?,
      usesMedication: json['uses_medication'] as bool?,
      medicationNotes: json['medication_notes'] as String?,
      psychiatricFollowup: json['psychiatric_followup'] as bool?,
      psychiatristNotes: json['psychiatrist_notes'] as String?,
      importantToKnow: json['important_to_know'] as String?,
    );
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }
}
