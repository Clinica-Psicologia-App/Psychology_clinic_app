/// Taxonomia canônica dos 18 esquemas de Young e seus 5 domínios.
///
/// Fonte: planilha "QuestionárioS de EsquemaS" (abas `Resultado GERAL` e
/// `Resultado RNE`) mais a validação da psicóloga responsável em ago/2026.
///
/// Por que viver em Dart e não só no banco: a ordem e os nomes são conteúdo de
/// manual — não mudam por clínica nem por paciente. Além disso o nome exibido
/// vem do `snapshot` JSONB, que é congelado no momento em que a resposta é
/// concluída; respostas antigas carregam nomes desatualizados. Resolver o nome
/// por código aqui corrige a exibição retroativamente, sem reescrever snapshots.
///
/// A ordem dentro do domínio NÃO é por pontuação: é a sequência clínica que a
/// psicóloga usa na leitura do perfil.
library;

/// Um dos 5 domínios de esquemas.
class YsqDomain {
  const YsqDomain({
    required this.code,
    required this.name,
    required this.order,
    required this.coreNeed,
  });

  final String code;

  /// Nome curto, sem o numeral — a UI compõe "I · Desconexão e rejeição".
  final String name;

  /// Ordem canônica (0–4), correspondente aos domínios I a V.
  final int order;

  /// Necessidade emocional central cuja não satisfação origina os esquemas
  /// deste domínio. Uma por domínio.
  final String coreNeed;

  /// Numeral romano do domínio (I…V).
  String get numeral => const ['I', 'II', 'III', 'IV', 'V'][order];
}

/// Um dos 18 esquemas.
class YsqSchema {
  const YsqSchema({
    required this.code,
    required this.name,
    required this.domainCode,
    required this.order,
    required this.unmetNeed,
  });

  final String code;

  /// Nome canônico para exibição.
  final String name;

  final String domainCode;

  /// Ordem dentro do domínio.
  final int order;

  /// Necessidade específica não atendida associada a este esquema.
  final String unmetNeed;
}

const kYsqDomainDisconnection = 'YSQ_DOMAIN_DISCONNECTION_REJECTION';
const kYsqDomainAutonomy = 'YSQ_DOMAIN_IMPAIRED_AUTONOMY';
const kYsqDomainLimits = 'YSQ_DOMAIN_IMPAIRED_LIMITS';
const kYsqDomainOtherDirected = 'YSQ_DOMAIN_OTHER_DIRECTEDNESS';
const kYsqDomainOvervigilance = 'YSQ_DOMAIN_OVERVIGILANCE_INHIBITION';

const List<YsqDomain> kYsqDomains = [
  YsqDomain(
    code: kYsqDomainDisconnection,
    name: 'Desconexão e rejeição',
    order: 0,
    coreNeed: 'Vínculos seguros',
  ),
  YsqDomain(
    code: kYsqDomainAutonomy,
    name: 'Autonomia e desempenho prejudicados',
    order: 1,
    coreNeed: 'Autonomia e competência',
  ),
  YsqDomain(
    code: kYsqDomainLimits,
    name: 'Limites prejudicados',
    order: 2,
    coreNeed: 'Limites realistas',
  ),
  YsqDomain(
    code: kYsqDomainOtherDirected,
    name: 'Orientação para o outro',
    order: 3,
    coreNeed: 'Liberdade de expressão',
  ),
  YsqDomain(
    code: kYsqDomainOvervigilance,
    name: 'Hipervigilância e inibição',
    order: 4,
    coreNeed: 'Espontaneidade e lazer',
  ),
];

const List<YsqSchema> kYsqSchemas = [
  // ── Domínio I — Desconexão e rejeição ──────────────────────────────────
  YsqSchema(
    code: 'YSQ_SCHEMA_ABANDONMENT_INSTABILITY',
    name: 'Abandono/Instabilidade',
    domainCode: kYsqDomainDisconnection,
    order: 0,
    unmetNeed: 'Estabilidade',
  ),
  YsqSchema(
    code: 'YSQ_SCHEMA_MISTRUST_ABUSE',
    name: 'Desconfiança/Abuso',
    domainCode: kYsqDomainDisconnection,
    order: 1,
    unmetNeed: 'Segurança e proteção',
  ),
  YsqSchema(
    code: 'YSQ_SCHEMA_EMOTIONAL_DEPRIVATION',
    name: 'Privação emocional',
    domainCode: kYsqDomainDisconnection,
    order: 2,
    unmetNeed: 'Cuidado e/ou afeto',
  ),
  YsqSchema(
    code: 'YSQ_SCHEMA_DEFECTIVENESS_SHAME',
    name: 'Defectividade/Vergonha',
    domainCode: kYsqDomainDisconnection,
    order: 3,
    unmetNeed: 'Amor e/ou aceitação',
  ),
  YsqSchema(
    code: 'YSQ_SCHEMA_SOCIAL_ISOLATION',
    name: 'Isolamento social/Alienação',
    domainCode: kYsqDomainDisconnection,
    order: 4,
    unmetNeed: 'Pertencimento',
  ),

  // ── Domínio II — Autonomia e desempenho prejudicados ───────────────────
  YsqSchema(
    code: 'YSQ_SCHEMA_DEPENDENCE_INCOMPETENCE',
    name: 'Dependência/Incompetência',
    domainCode: kYsqDomainAutonomy,
    order: 0,
    unmetNeed: 'Validação de ações independentes',
  ),
  YsqSchema(
    code: 'YSQ_SCHEMA_VULNERABILITY',
    name: 'Vulnerabilidade ao dano ou à doença',
    domainCode: kYsqDomainAutonomy,
    order: 1,
    unmetNeed: 'Segurança e/ou força pessoal',
  ),
  YsqSchema(
    code: 'YSQ_SCHEMA_ENMESHMENT_UNDEVELOPED_SELF',
    name: 'Emaranhamento/Self subdesenvolvido',
    domainCode: kYsqDomainAutonomy,
    order: 2,
    unmetNeed: 'Individualização',
  ),
  YsqSchema(
    code: 'YSQ_SCHEMA_FAILURE',
    name: 'Fracasso',
    domainCode: kYsqDomainAutonomy,
    order: 3,
    unmetNeed: 'Orientação e/ou suporte',
  ),

  // ── Domínio III — Limites prejudicados ─────────────────────────────────
  YsqSchema(
    code: 'YSQ_SCHEMA_ENTITLEMENT_GRANDIOSITY',
    name: 'Arrogo/Grandiosidade',
    domainCode: kYsqDomainLimits,
    order: 0,
    unmetNeed: 'Limites realistas e/ou considerações empáticas',
  ),
  YsqSchema(
    code: 'YSQ_SCHEMA_INSUFFICIENT_SELF_CONTROL',
    name: 'Autocontrole/Autodisciplina insuficiente',
    domainCode: kYsqDomainLimits,
    order: 1,
    unmetNeed: 'Respeito de regras e/ou disciplina',
  ),

  // ── Domínio IV — Orientação para o outro ───────────────────────────────
  YsqSchema(
    code: 'YSQ_SCHEMA_SUBJUGATION',
    name: 'Subjugação',
    domainCode: kYsqDomainOtherDirected,
    order: 0,
    unmetNeed: 'Validação de inclinações naturais',
  ),
  YsqSchema(
    code: 'YSQ_SCHEMA_SELF_SACRIFICE',
    name: 'Autossacrifício',
    domainCode: kYsqDomainOtherDirected,
    order: 1,
    unmetNeed: 'Aceitação incondicional',
  ),
  YsqSchema(
    code: 'YSQ_SCHEMA_APPROVAL_SEEKING',
    name: 'Busca de aprovação/Reconhecimento',
    domainCode: kYsqDomainOtherDirected,
    order: 2,
    unmetNeed: 'Validação das próprias necessidades',
  ),

  // ── Domínio V — Hipervigilância e inibição ─────────────────────────────
  YsqSchema(
    code: 'YSQ_SCHEMA_NEGATIVISM_PESSIMISM',
    name: 'Negativismo/Pessimismo',
    domainCode: kYsqDomainOvervigilance,
    order: 0,
    unmetNeed: 'Relaxamento',
  ),
  YsqSchema(
    code: 'YSQ_SCHEMA_EMOTIONAL_INHIBITION',
    name: 'Inibição emocional',
    domainCode: kYsqDomainOvervigilance,
    order: 1,
    unmetNeed: 'Espontaneidade',
  ),
  YsqSchema(
    code: 'YSQ_SCHEMA_UNRELENTING_STANDARDS',
    name: 'Padrões inflexíveis/Crítica exagerada',
    domainCode: kYsqDomainOvervigilance,
    order: 2,
    unmetNeed: 'Lazer e/ou prazer',
  ),
  YsqSchema(
    code: 'YSQ_SCHEMA_PUNITIVENESS',
    name: 'Postura punitiva',
    domainCode: kYsqDomainOvervigilance,
    order: 3,
    unmetNeed: 'Compaixão e/ou perdão',
  ),
];

final Map<String, YsqSchema> _schemasByCode = {
  for (final s in kYsqSchemas) s.code: s,
};

final Map<String, YsqDomain> _domainsByCode = {
  for (final d in kYsqDomains) d.code: d,
};

/// Esquema pelo código do catálogo; `null` se não for um esquema do YSQ
/// (modos do YAMI, por exemplo).
YsqSchema? ysqSchemaByCode(String? code) =>
    code == null ? null : _schemasByCode[code];

/// Domínio pelo código do catálogo.
YsqDomain? ysqDomainByCode(String? code) =>
    code == null ? null : _domainsByCode[code];
