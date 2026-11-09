/// Liga cada esquema do YSQ ao card dele na Biblioteca 8 ("Conhecendo os 18
/// Esquemas"). O vínculo segue a ORDEM dos cards: se a ordem ou a quantidade
/// de cards da Biblioteca 8 mudar, esta lista precisa ser atualizada junto.
library;

/// Número da biblioteca dos 18 esquemas na jornada de psicoeducação.
const int kSchemaLibraryNumber = 8;

/// Card do primeiro esquema (os cards 1 a 3 são explicação e introdução).
const int kFirstSchemaCard = 4;

/// Códigos `YSQ_SCHEMA_*` na ordem em que os esquemas aparecem na biblioteca.
const List<String> kSchemaLibraryOrder = [
  'YSQ_SCHEMA_ABANDONMENT_INSTABILITY',
  'YSQ_SCHEMA_MISTRUST_ABUSE',
  'YSQ_SCHEMA_EMOTIONAL_DEPRIVATION',
  'YSQ_SCHEMA_DEFECTIVENESS_SHAME',
  'YSQ_SCHEMA_SOCIAL_ISOLATION',
  'YSQ_SCHEMA_DEPENDENCE_INCOMPETENCE',
  'YSQ_SCHEMA_VULNERABILITY',
  'YSQ_SCHEMA_ENMESHMENT_UNDEVELOPED_SELF',
  'YSQ_SCHEMA_FAILURE',
  'YSQ_SCHEMA_ENTITLEMENT_GRANDIOSITY',
  'YSQ_SCHEMA_INSUFFICIENT_SELF_CONTROL',
  'YSQ_SCHEMA_SUBJUGATION',
  'YSQ_SCHEMA_SELF_SACRIFICE',
  'YSQ_SCHEMA_APPROVAL_SEEKING',
  'YSQ_SCHEMA_NEGATIVISM_PESSIMISM',
  'YSQ_SCHEMA_EMOTIONAL_INHIBITION',
  'YSQ_SCHEMA_UNRELENTING_STANDARDS',
  'YSQ_SCHEMA_PUNITIVENESS',
];

/// Número do card (1 = primeiro card) do esquema na Biblioteca 8, ou nulo se
/// o código não for um dos 18 esquemas.
int? schemaLibraryCardNumber(String? schemaCode) {
  if (schemaCode == null) return null;
  final index = kSchemaLibraryOrder.indexOf(schemaCode);
  return index < 0 ? null : kFirstSchemaCard + index;
}
