import 'genogram_person.dart';
import 'genogram_relationship.dart';

class GenogramData {
  const GenogramData({
    required this.people,
    required this.relationships,
  });

  final List<GenogramPerson> people;
  final List<GenogramRelationship> relationships;

  bool get isEmpty => people.isEmpty && relationships.isEmpty;

  bool get hasContent => people.isNotEmpty || relationships.isNotEmpty;

  String personNameById(String id) {
    for (final p in people) {
      if (p.id == id) return p.displayName;
    }
    return 'Pessoa';
  }
}
