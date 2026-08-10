import 'consolidated_schema_row.dart';

/// Um domínio de Young com seus esquemas, para o card "Perfil Esquemático
/// Consolidado".
///
/// Os domínios não competem entre si — não há ranking nem score agregado de
/// domínio. O que interessa clinicamente é, dentro de cada domínio, quantos
/// esquemas ativaram: um ativado aponta uma necessidade parcialmente não
/// atendida; todos ativados apontam um quadro consistente naquele eixo.
class ConsolidatedDomainGroup {
  const ConsolidatedDomainGroup({
    required this.code,
    required this.name,
    required this.numeral,
    required this.coreNeed,
    required this.order,
    required this.schemas,
  });

  final String code;
  final String name;

  /// Numeral romano do domínio (I…V).
  final String numeral;

  /// Necessidade emocional central do domínio.
  final String coreNeed;

  final int order;

  /// Esquemas em ordem canônica — sequência clínica, não pontuação.
  final List<ConsolidatedSchemaRow> schemas;

  int get totalCount => schemas.length;

  int get activatedCount => schemas.where((s) => s.isActivated).length;

  bool get hasActivated => activatedCount > 0;

  /// Rótulo de leitura do domínio: "2 de 4 ativados".
  String get activationLabel => '$activatedCount de $totalCount ativados';
}

/// Linhas que não pertencem a nenhum domínio do YSQ — os modos do YAMI.
/// Ficam num bloco próprio: modos não se organizam nos 5 domínios.
class ConsolidatedModeGroup {
  const ConsolidatedModeGroup({required this.rows});

  final List<ConsolidatedSchemaRow> rows;

  bool get isEmpty => rows.isEmpty;

  int get activatedCount => rows.where((r) => r.isActivated).length;
}
