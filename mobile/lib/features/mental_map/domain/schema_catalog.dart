/// Catálogo dos 18 Esquemas Iniciais Desadaptativos (Young) para enriquecer a
/// seção 8 da Conceitualização de caso. Chaveado por `schemas.code`
/// (`YSQ_SCHEMA_*`), estável — os nomes no banco têm grafias inconsistentes,
/// então normalizamos aqui. Par do [kSchemaModeCatalog] (modos, seção 9).
library;

/// Um dos 5 domínios de esquema de Young, com rótulo e chave de cor.
enum SchemaDomain {
  disconnection('Desconexão e rejeição', 'error'),
  autonomy('Autonomia e desempenho prejudicados', 'warning'),
  limits('Limites prejudicados', 'purple'),
  otherDirected('Orientação para o outro', 'blue'),
  overvigilance('Supervigilância e inibição', 'cyan');

  const SchemaDomain(this.label, this.colorKey);

  final String label;

  /// 'error' | 'warning' | 'purple' | 'blue' | 'cyan' — resolvido em UI/PDF.
  final String colorKey;
}

/// Nome canônico + domínio + descrição curta de um esquema.
class SchemaInfo {
  const SchemaInfo(this.name, this.domain, this.description);

  final String name;
  final SchemaDomain domain;

  /// Descrição em uma frase, no sentido clássico da Terapia do Esquema.
  final String description;
}

const Map<String, SchemaInfo> kSchemaCatalog = {
  // Domínio 1 — Desconexão e rejeição
  'YSQ_SCHEMA_ABANDONMENT_INSTABILITY': SchemaInfo(
    'Abandono/Instabilidade',
    SchemaDomain.disconnection,
    'Medo de que vínculos importantes se rompam ou não permaneçam.',
  ),
  'YSQ_SCHEMA_MISTRUST_ABUSE': SchemaInfo(
    'Desconfiança/Abuso',
    SchemaDomain.disconnection,
    'Expectativa de ser magoado, usado ou humilhado pelos outros.',
  ),
  'YSQ_SCHEMA_EMOTIONAL_DEPRIVATION': SchemaInfo(
    'Privação emocional',
    SchemaDomain.disconnection,
    'Sente que as necessidades de afeto e cuidado não serão atendidas.',
  ),
  'YSQ_SCHEMA_DEFECTIVENESS_SHAME': SchemaInfo(
    'Defectividade/Vergonha',
    SchemaDomain.disconnection,
    'Sensação de ser inadequado, defeituoso ou indigno de amor.',
  ),
  'YSQ_SCHEMA_SOCIAL_ISOLATION': SchemaInfo(
    'Isolamento social/Alienação',
    SchemaDomain.disconnection,
    'Sente-se diferente e sem pertencer a grupos ou vínculos.',
  ),

  // Domínio 2 — Autonomia e desempenho prejudicados
  'YSQ_SCHEMA_DEPENDENCE_INCOMPETENCE': SchemaInfo(
    'Dependência/Incompetência',
    SchemaDomain.autonomy,
    'Sente-se incapaz de lidar com o dia a dia sem apoio dos outros.',
  ),
  'YSQ_SCHEMA_VULNERABILITY': SchemaInfo(
    'Vulnerabilidade ao dano ou doença',
    SchemaDomain.autonomy,
    'Medo intenso de que uma catástrofe aconteça a qualquer momento.',
  ),
  'YSQ_SCHEMA_ENMESHMENT_UNDEVELOPED_SELF': SchemaInfo(
    'Emaranhamento/Self subdesenvolvido',
    SchemaDomain.autonomy,
    'Vínculos fundidos, com identidade própria pouco desenvolvida.',
  ),
  'YSQ_SCHEMA_FAILURE': SchemaInfo(
    'Fracasso',
    SchemaDomain.autonomy,
    'Crença de ser incapaz ou inferior no desempenho frente aos outros.',
  ),

  // Domínio 3 — Limites prejudicados
  'YSQ_SCHEMA_ENTITLEMENT_GRANDIOSITY': SchemaInfo(
    'Merecimento/Grandiosidade',
    SchemaDomain.limits,
    'Sente-se especial, acima das regras e dos limites comuns.',
  ),
  'YSQ_SCHEMA_INSUFFICIENT_SELF_CONTROL': SchemaInfo(
    'Autocontrole/Autodisciplina insuficientes',
    SchemaDomain.limits,
    'Dificuldade de tolerar frustração e de conter impulsos.',
  ),

  // Domínio 4 — Orientação para o outro
  'YSQ_SCHEMA_SUBJUGATION': SchemaInfo(
    'Subjugação',
    SchemaDomain.otherDirected,
    'Cede o controle aos outros para evitar conflito ou punição.',
  ),
  'YSQ_SCHEMA_SELF_SACRIFICE': SchemaInfo(
    'Autossacrifício',
    SchemaDomain.otherDirected,
    'Prioriza as necessidades alheias em detrimento das próprias.',
  ),
  'YSQ_SCHEMA_APPROVAL_SEEKING': SchemaInfo(
    'Busca de aprovação/Reconhecimento',
    SchemaDomain.otherDirected,
    'Busca reconhecimento externo para sustentar o próprio valor.',
  ),

  // Domínio 5 — Supervigilância e inibição
  'YSQ_SCHEMA_NEGATIVISM_PESSIMISM': SchemaInfo(
    'Negativismo/Pessimismo',
    SchemaDomain.overvigilance,
    'Foco no que pode dar errado; dificuldade de sustentar esperança.',
  ),
  'YSQ_SCHEMA_EMOTIONAL_INHIBITION': SchemaInfo(
    'Inibição emocional',
    SchemaDomain.overvigilance,
    'Contém emoções e impulsos espontâneos para manter o controle.',
  ),
  'YSQ_SCHEMA_UNRELENTING_STANDARDS': SchemaInfo(
    'Padrões inflexíveis/Crítica exagerada',
    SchemaDomain.overvigilance,
    'Autocobrança elevada e rigidez com regras e desempenho.',
  ),
  'YSQ_SCHEMA_PUNITIVENESS': SchemaInfo(
    'Postura punitiva',
    SchemaDomain.overvigilance,
    'Tendência a punir a si e aos outros com dureza pelos erros.',
  ),
};

/// Descrição de um esquema pelo código; `null` se o código for desconhecido.
SchemaInfo? schemaInfoForCode(String? code) {
  if (code == null) return null;
  return kSchemaCatalog[code.trim().toUpperCase()];
}
