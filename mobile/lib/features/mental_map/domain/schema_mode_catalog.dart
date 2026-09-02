/// Catálogo de modos esquemáticos (Terapia do Esquema) para enriquecer a
/// seção 9 da Conceitualização de caso. Chaveado pelo código do YAMI
/// (`YAMI_MODE_NN` = `schema.code`), que é estável — os nomes no banco têm
/// grafias inconsistentes (espaços duplos, typos), então normalizamos aqui.
library;

/// Categoria clínica de um modo, com rótulo e chave de cor (mapeada em UI/PDF).
enum SchemaModeCategory {
  child('Criança', 'blue'),
  coping('Enfrentamento', 'warning'),
  parent('Parental disfuncional', 'error'),
  healthyAdult('Adulto Saudável', 'success');

  const SchemaModeCategory(this.label, this.colorKey);

  final String label;

  /// 'blue' | 'warning' | 'error' | 'success' — resolvido para AppColors/PdfColors.
  final String colorKey;
}

/// Nome canônico + categoria + descrição curta (função) de um modo.
class SchemaModeInfo {
  const SchemaModeInfo(this.name, this.category, this.description);

  final String name;
  final SchemaModeCategory category;

  /// Função/descrição em uma frase, no sentido clássico da Terapia do Esquema.
  final String description;
}

const _vulneravel = SchemaModeInfo(
  'Criança Vulnerável',
  SchemaModeCategory.child,
  'Sente-se desamparada, sozinha ou não amada; carrega a dor das necessidades não atendidas.',
);
const _feliz = SchemaModeInfo(
  'Criança Feliz',
  SchemaModeCategory.child,
  'Sente-se amada, conectada e segura, com as necessidades essenciais atendidas.',
);
const _autoconfortador = SchemaModeInfo(
  'Autoconfortador Desligado',
  SchemaModeCategory.coping,
  'Busca conforto ou estímulo (trabalho, comida, telas) para anestesiar as emoções.',
);

/// Catálogo por código YAMI_MODE_NN (inclui grafias/typos como sinônimos).
const Map<String, SchemaModeInfo> kSchemaModeCatalog = {
  'YAMI_MODE_01': SchemaModeInfo(
    'Intimidação e Ataque',
    SchemaModeCategory.coping,
    'Hipercompensa atacando ou intimidando para se proteger de ameaças percebidas.',
  ),
  'YAMI_MODE_02': _feliz,
  'YAMI_MODE_03': SchemaModeInfo(
    'Pais Punitivos',
    SchemaModeCategory.parent,
    'Voz interna que pune, culpa e critica com dureza por erros ou necessidades.',
  ),
  'YAMI_MODE_04': _vulneravel,
  'YAMI_MODE_05': SchemaModeInfo(
    'Pais Exigentes e Críticos',
    SchemaModeCategory.parent,
    'Voz interna que impõe padrões altíssimos e pressão constante por desempenho.',
  ),
  'YAMI_MODE_06': SchemaModeInfo(
    'Vencido Submisso',
    SchemaModeCategory.coping,
    'Rende-se, cede e se submete aos outros para evitar conflito ou punição.',
  ),
  'YAMI_MODE_07': SchemaModeInfo(
    'Auto Engrandecedor',
    SchemaModeCategory.coping,
    'Hipercompensa sentindo-se superior e exigindo reconhecimento ou controle.',
  ),
  'YAMI_MODE_08': SchemaModeInfo(
    'Criança Impulsiva',
    SchemaModeCategory.child,
    'Age por impulso para satisfazer desejos imediatos, sem pesar consequências.',
  ),
  'YAMI_MODE_09': SchemaModeInfo(
    'Criança Indisciplinada',
    SchemaModeCategory.child,
    'Tem dificuldade em tolerar frustração ou concluir tarefas rotineiras e chatas.',
  ),
  'YAMI_MODE_10': SchemaModeInfo(
    'Criança Raivosa',
    SchemaModeCategory.child,
    'Reage com raiva ou revolta quando as necessidades são frustradas.',
  ),
  'YAMI_MODE_11': _feliz,
  'YAMI_MODE_12': SchemaModeInfo(
    'Adulto Saudável',
    SchemaModeCategory.healthyAdult,
    'Cuida, valida e regula os demais modos, agindo com equilíbrio e valores.',
  ),
  'YAMI_MODE_13': SchemaModeInfo(
    'Criança Zangada',
    SchemaModeCategory.child,
    'Expressa raiva de forma intensa diante de necessidades não atendidas.',
  ),
  'YAMI_MODE_14': SchemaModeInfo(
    'Protetor Desligado',
    SchemaModeCategory.coping,
    'Desconecta-se de emoções e pessoas para evitar a dor; distanciamento e vazio.',
  ),
  'YAMI_MODE_15': _autoconfortador,
  'YAMI_MODE_16': _autoconfortador,
  'YAMI_MODE_17': _autoconfortador,
  'YAMI_MODE_18': _vulneravel,
  'YAMI_MODE_19': _feliz,
};

/// Descrição de um modo pelo código; `null` se o código for desconhecido.
SchemaModeInfo? schemaModeInfoForCode(String? code) {
  if (code == null) return null;
  return kSchemaModeCatalog[code.trim().toUpperCase()];
}
