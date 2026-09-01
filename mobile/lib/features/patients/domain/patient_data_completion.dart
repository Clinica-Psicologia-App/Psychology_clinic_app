/// Preenchimento da avaliação inicial ("Conhecer") + questionários de um
/// paciente, agregado pelo RPC `get_patients_data_completion`. Alimenta o anel
/// de progresso no card da lista de pacientes.
class PatientDataCompletion {
  const PatientDataCompletion({
    required this.patientId,
    required this.perfil,
    required this.queixa,
    required this.areas,
    required this.historia,
    required this.familia,
    required this.questionarios,
  });

  final String patientId;
  final bool perfil;
  final bool queixa;
  final bool areas;
  final bool historia;
  final bool familia;
  final bool questionarios;

  /// Seções na ordem de exibição (rótulo + preenchido?).
  List<({String label, bool done})> get sections => [
        (label: 'Perfil', done: perfil),
        (label: 'Queixa', done: queixa),
        (label: 'Áreas', done: areas),
        (label: 'História', done: historia),
        (label: 'Família', done: familia),
        (label: 'Questionários', done: questionarios),
      ];

  int get totalSections => sections.length;

  int get filledSections => sections.where((s) => s.done).length;

  /// Fração 0.0–1.0 para o anel.
  double get fraction =>
      totalSections == 0 ? 0 : filledSections / totalSections;

  /// Porcentagem inteira (0–100) para o rótulo central.
  int get percent => (fraction * 100).round();

  bool get isComplete => filledSections == totalSections;

  factory PatientDataCompletion.fromJson(Map<String, dynamic> json) {
    bool b(String key) => json[key] == true;
    return PatientDataCompletion(
      patientId: json['patient_id'] as String,
      perfil: b('perfil'),
      queixa: b('queixa'),
      areas: b('areas'),
      historia: b('historia'),
      familia: b('familia'),
      questionarios: b('questionarios'),
    );
  }
}
