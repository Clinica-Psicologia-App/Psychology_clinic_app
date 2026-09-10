enum GenogramRelationshipType {
  parentChild,
  spouse,
  exSpouse,

  /// Separação conjugal (uma barra "/") — distinto do divórcio (duas barras).
  separation,
  sibling,
  twin,
  conflict,
  distant,
  neutral,
  close,

  /// Relação próxima e conflituosa (linha dupla + zigzag).
  closeAndConflict,
  ruptured,
  other,
}

extension GenogramRelationshipTypeX on GenogramRelationshipType {
  String get storageValue {
    switch (this) {
      case GenogramRelationshipType.parentChild:
        return 'parent_child';
      case GenogramRelationshipType.spouse:
        return 'spouse';
      case GenogramRelationshipType.exSpouse:
        return 'ex_spouse';
      case GenogramRelationshipType.separation:
        return 'separation';
      case GenogramRelationshipType.sibling:
        return 'sibling';
      case GenogramRelationshipType.twin:
        return 'twin';
      case GenogramRelationshipType.conflict:
        return 'conflict';
      case GenogramRelationshipType.distant:
        return 'distant';
      case GenogramRelationshipType.neutral:
        return 'neutral';
      case GenogramRelationshipType.close:
        return 'close';
      case GenogramRelationshipType.closeAndConflict:
        return 'close_and_conflict';
      case GenogramRelationshipType.ruptured:
        return 'ruptured';
      case GenogramRelationshipType.other:
        return 'other';
    }
  }

  String get label {
    switch (this) {
      case GenogramRelationshipType.parentChild:
        return 'Pai/mãe - filho(a)';
      case GenogramRelationshipType.spouse:
        return 'Cônjuge';
      case GenogramRelationshipType.exSpouse:
        return 'Ex-cônjuge (divórcio)';
      case GenogramRelationshipType.separation:
        return 'Separados';
      case GenogramRelationshipType.sibling:
        return 'Irmão(ã)';
      case GenogramRelationshipType.twin:
        return 'Gêmeos(as)';
      case GenogramRelationshipType.conflict:
        return 'Conflituosa';
      case GenogramRelationshipType.distant:
        return 'Distante';
      case GenogramRelationshipType.neutral:
        return 'Neutra';
      case GenogramRelationshipType.close:
        return 'Próxima';
      case GenogramRelationshipType.closeAndConflict:
        return 'Próxima e conflituosa';
      case GenogramRelationshipType.ruptured:
        return 'Rompida';
      case GenogramRelationshipType.other:
        return 'Outro';
    }
  }
}

GenogramRelationshipType genogramRelationshipTypeFromStorage(String? value) {
  if (value == null || value.isEmpty) return GenogramRelationshipType.other;
  return GenogramRelationshipType.values.firstWhere(
    (t) => t.storageValue == value,
    orElse: () => GenogramRelationshipType.other,
  );
}
