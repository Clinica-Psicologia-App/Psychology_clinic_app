import '../../results/domain/schema_activation.dart';

/// Linha de esquema consolidada, unindo scores de todos os instrumentos
/// com o status de ativação (auto pelo sistema ou psi pelo profissional).
///
/// Usada no card "Perfil Esquemático Consolidado" do Dashboard Clínico —
/// uma visão única de todos os esquemas/modos de todos os questionários,
/// em vez de navegar por instrumento.
class ConsolidatedSchemaRow {
  const ConsolidatedSchemaRow({
    required this.name,
    required this.code,
    required this.score,
    required this.responseId,
    required this.isAutoActivated,
    this.isPsiActivated = false,
    this.psiObservation,
    this.instrumentName,
    this.instrumentCode,
    this.severityLabel,
    this.severityColorKey,
    this.scaleMax,
    this.domainCode,
    this.domainOrder,
    this.schemaOrder,
    this.unmetNeed,
  });

  final String name;
  final String code;
  final double score;

  /// Domínio de Young ao qual o esquema pertence. `null` para linhas que não
  /// são esquemas do YSQ — os modos do YAMI, por exemplo.
  final String? domainCode;

  /// Ordem canônica do domínio (0–4). `null` fora do YSQ.
  final int? domainOrder;

  /// Ordem canônica dentro do domínio — sequência clínica, não pontuação.
  final int? schemaOrder;

  /// Necessidade emocional específica associada ao esquema.
  final String? unmetNeed;

  bool get hasDomain => domainCode != null;

  /// ID da resposta de origem — necessário para abrir o sheet de ativação.
  final String responseId;

  /// Score ≥ 4.0 — ativado automaticamente pelo sistema (símbolo ●).
  final bool isAutoActivated;

  /// Abaixo do limiar mas ativado manualmente pelo profissional (símbolo ◎).
  final bool isPsiActivated;

  final String? psiObservation;
  final String? instrumentName;
  final String? instrumentCode;
  final String? severityLabel;
  final String? severityColorKey;

  /// Escala máxima do instrumento de origem; fallback 6.0 se ausente.
  final double? scaleMax;

  bool get isActivated => isAutoActivated || isPsiActivated;

  double get barMax =>
      (scaleMax != null && scaleMax! > 0) ? scaleMax! : kSchemaActivationThreshold * 1.5;

  /// Proporção 0–1 para renderizar a barra de score.
  double get barFraction => (score / barMax).clamp(0.0, 1.0);
}
