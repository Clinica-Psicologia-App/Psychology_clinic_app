import 'family_context.dart';
import 'genogram_person_entry.dart';

/// Agregado da Tela 3 — as pessoas do genograma (camada emocional) e o
/// contexto familiar (clima + padrões) de um paciente.
class PatientFamily {
  const PatientFamily({
    required this.patientId,
    this.people = const [],
    this.context = const FamilyContext(),
  });

  final String patientId;
  final List<GenogramPersonEntry> people;
  final FamilyContext context;

  int get peopleCount => people.length;

  /// Figuras de apego (cuidadores) destacadas.
  List<GenogramPersonEntry> get caregivers =>
      people.where((p) => p.isCaregiver == true).toList();
}
