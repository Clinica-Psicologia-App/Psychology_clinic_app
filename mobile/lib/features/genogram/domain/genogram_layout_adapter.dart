/// Adaptador **puro** entre os dados do genograma clínico (pessoas + relações
/// tipadas de B) e o motor de layout (`genogram_layout.dart`).
///
/// Mapeia gênero → sexo, converte só os vínculos ESTRUTURAIS (casamento e
/// pai/mãe–filho) em arestas, e identifica o foco (o paciente) pela pessoa cujo
/// `relationshipToPatient` é o marcador de paciente. Os vínculos emocionais
/// (conflito, próxima…) são outra camada e não entram na estrutura.
library;

import 'genogram_gender.dart';
import 'genogram_layout.dart';
import 'genogram_person.dart';
import 'genogram_relationship.dart';
import 'genogram_relationship_type.dart';

GSex _sexOf(GenogramGender? g) => switch (g) {
      GenogramGender.male => GSex.male,
      GenogramGender.female => GSex.female,
      _ => GSex.unknown,
    };

/// Entrada do motor derivada dos dados reais.
class GLayoutInput {
  final List<GPerson> people;
  final List<GEdge> edges;
  final String focusId;
  const GLayoutInput(this.people, this.edges, this.focusId);
}

/// Constrói a entrada do motor a partir das pessoas e relações de B.
/// Retorna `null` quando não há paciente identificável na lista.
GLayoutInput? buildLayoutInput({
  required List<GenogramPerson> people,
  required List<GenogramRelationship> relationships,
  String patientMarker = 'Paciente',
}) {
  String? focusId;
  for (final p in people) {
    if (p.relationshipToPatient == patientMarker) {
      focusId = p.id;
      break;
    }
  }
  if (focusId == null) return null;

  final gpeople = [
    for (final p in people) GPerson(p.id, sex: _sexOf(p.gender)),
  ];

  final edges = <GEdge>[];
  for (final r in relationships) {
    switch (r.relationshipType) {
      case GenogramRelationshipType.parentChild:
        // Convenção: personA = pai/mãe, personB = filho(a).
        edges.add(GEdge(r.personAId, r.personBId, GEdgeType.parentChild));
      case GenogramRelationshipType.spouse:
        edges.add(GEdge(r.personAId, r.personBId, GEdgeType.spouse));
      case GenogramRelationshipType.exSpouse:
        edges.add(GEdge(r.personAId, r.personBId, GEdgeType.exSpouse));
      case GenogramRelationshipType.sibling:
      case GenogramRelationshipType.conflict:
      case GenogramRelationshipType.distant:
      case GenogramRelationshipType.neutral:
      case GenogramRelationshipType.close:
      case GenogramRelationshipType.ruptured:
      case GenogramRelationshipType.other:
        break; // não-estrutural: ignorado aqui.
    }
  }

  return GLayoutInput(gpeople, edges, focusId);
}

/// Pipeline completo: dados reais → topologia → coordenadas.
/// Retorna `null` quando não há paciente identificável.
GDiagram? buildGenogramDiagram({
  required List<GenogramPerson> people,
  required List<GenogramRelationship> relationships,
  String patientMarker = 'Paciente',
  double colWidth = 120,
  double rowHeight = 150,
  double margin = 40,
}) {
  final input = buildLayoutInput(
    people: people,
    relationships: relationships,
    patientMarker: patientMarker,
  );
  if (input == null) return null;
  final layout = buildGenogramStructure(
    people: input.people,
    edges: input.edges,
    focusId: input.focusId,
  );
  return positionGenogram(
    layout,
    colWidth: colWidth,
    rowHeight: rowHeight,
    margin: margin,
  );
}
