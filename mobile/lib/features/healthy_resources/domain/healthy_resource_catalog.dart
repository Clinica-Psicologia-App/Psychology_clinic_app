/// Catálogo de recursos saudáveis predefinidos, organizados por categoria.
/// Os IDs são estáveis e persistidos no banco (não use labels como IDs).
class HealthyResourceCategory {
  const HealthyResourceCategory({required this.label, required this.items});
  final String label;
  final List<HealthyResourceItem> items;
}

class HealthyResourceItem {
  const HealthyResourceItem({required this.id, required this.label});
  final String id;
  final String label;
}

const kHealthyResourceCatalog = [
  HealthyResourceCategory(
    label: 'Pessoais e cognitivos',
    items: [
      HealthyResourceItem(id: 'pc_creativity',    label: 'Criatividade'),
      HealthyResourceItem(id: 'pc_reflective',    label: 'Capacidade reflexiva'),
      HealthyResourceItem(id: 'pc_autonomy',      label: 'Autonomia'),
      HealthyResourceItem(id: 'pc_flexibility',   label: 'Flexibilidade cognitiva'),
      HealthyResourceItem(id: 'pc_learning',      label: 'Capacidade de aprendizagem'),
      HealthyResourceItem(id: 'pc_resilience',    label: 'Resiliência'),
      HealthyResourceItem(id: 'pc_selfawareness', label: 'Autoconhecimento'),
      HealthyResourceItem(id: 'pc_humor',         label: 'Senso de humor'),
    ],
  ),
  HealthyResourceCategory(
    label: 'Emocionais',
    items: [
      HealthyResourceItem(id: 'em_selfregulation', label: 'Autorregulação emocional'),
      HealthyResourceItem(id: 'em_selfcompassion',  label: 'Autocompaixão'),
      HealthyResourceItem(id: 'em_hope',            label: 'Esperança'),
      HealthyResourceItem(id: 'em_frustration',     label: 'Tolerância à frustração'),
      HealthyResourceItem(id: 'em_askhelp',         label: 'Capacidade de pedir ajuda'),
      HealthyResourceItem(id: 'em_expression',      label: 'Expressão emocional'),
    ],
  ),
  HealthyResourceCategory(
    label: 'Relacionais',
    items: [
      HealthyResourceItem(id: 'rel_social',    label: 'Apoio social'),
      HealthyResourceItem(id: 'rel_bonds',     label: 'Vínculos satisfatórios'),
      HealthyResourceItem(id: 'rel_skills',    label: 'Habilidades sociais'),
      HealthyResourceItem(id: 'rel_family',    label: 'Rede familiar de apoio'),
      HealthyResourceItem(id: 'rel_capacity',  label: 'Capacidade de estabelecer vínculos'),
      HealthyResourceItem(id: 'rel_affective', label: 'Relacionamento afetivo seguro'),
    ],
  ),
  HealthyResourceCategory(
    label: 'Propósito e realização',
    items: [
      HealthyResourceItem(id: 'pr_purpose',       label: 'Propósito de vida'),
      HealthyResourceItem(id: 'pr_values',         label: 'Valores pessoais'),
      HealthyResourceItem(id: 'pr_professional',   label: 'Competências profissionais'),
      HealthyResourceItem(id: 'pr_hobbies',        label: 'Interesses e hobbies'),
      HealthyResourceItem(id: 'pr_persistence',    label: 'Persistência'),
      HealthyResourceItem(id: 'pr_spirituality',   label: 'Espiritualidade'),
    ],
  ),
];

/// Label para um ID predefinido (null se não encontrado).
String? labelForResourceId(String id) {
  for (final cat in kHealthyResourceCatalog) {
    for (final item in cat.items) {
      if (item.id == id) return item.label;
    }
  }
  return null;
}
