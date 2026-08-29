import 'genogram_relationship.dart';
import 'genogram_relationship_type.dart';

class GenogramRelationshipInput {
  const GenogramRelationshipInput({
    required this.personAId,
    required this.personBId,
    required this.relationshipType,
    this.notes,
    this.isAdoptive = false,
    this.isSensitive = false,
  });

  final String personAId;
  final String personBId;
  final GenogramRelationshipType relationshipType;
  final String? notes;

  /// Só relevante em [GenogramRelationshipType.parentChild]: filiação adotiva.
  final bool isAdoptive;
  final bool isSensitive;

  factory GenogramRelationshipInput.fromRelationship(
    GenogramRelationship relationship,
  ) {
    return GenogramRelationshipInput(
      personAId: relationship.personAId,
      personBId: relationship.personBId,
      relationshipType: relationship.relationshipType,
      notes: relationship.notes,
      isAdoptive: relationship.isAdoptive,
      isSensitive: relationship.isSensitive,
    );
  }

  String? validate() {
    if (personAId.isEmpty || personBId.isEmpty) {
      return 'Selecione as duas pessoas.';
    }
    if (personAId == personBId) {
      return 'A relação deve ser entre duas pessoas diferentes.';
    }
    return null;
  }

  Map<String, dynamic> toInsertJson() {
    return {
      'person_a_id': personAId,
      'person_b_id': personBId,
      'relationship_type': relationshipType.storageValue,
      'notes': _nullableTrim(notes),
      // Adoção só faz sentido em pai/mãe–filho; nos demais tipos grava false.
      'is_adoptive':
          isAdoptive && relationshipType == GenogramRelationshipType.parentChild,
      'is_sensitive': isSensitive,
    };
  }

  Map<String, dynamic> toUpdateJson() => toInsertJson();

  static String? _nullableTrim(String? value) {
    if (value == null) return null;
    final t = value.trim();
    return t.isEmpty ? null : t;
  }
}
