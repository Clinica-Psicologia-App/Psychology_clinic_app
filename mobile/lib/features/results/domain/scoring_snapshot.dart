import 'scoring_domain_result.dart';
import 'scoring_item_result.dart';
import 'scoring_schema_result.dart';
import 'scoring_summary.dart';

/// Dados estruturados do motor DEMO dentro do JSONB `snapshot`.
class ScoringSnapshot {
  const ScoringSnapshot({
    this.questionnaireVersionLabel,
    this.scoringMethod,
    this.scaleMin,
    this.scaleMax,
    this.completedAt,
    this.summary = ScoringSummary.empty,
    this.domains = const [],
    this.schemas = const [],
    this.items = const [],
  });

  static const demoVersion = 'scoring-demo-1';

  final String? questionnaireVersionLabel;
  final String? scoringMethod;
  final int? scaleMin;
  final int? scaleMax;
  final DateTime? completedAt;
  final ScoringSummary summary;
  final List<ScoringDomainResult> domains;
  final List<ScoringSchemaResult> schemas;
  final List<ScoringItemResult> items;

  static const empty = ScoringSnapshot();

  factory ScoringSnapshot.fromJsonMap(Map<String, dynamic> map) {
    final versionObj = map['questionnaire_version'];
    Map<String, dynamic>? versionMap;
    if (versionObj is Map) {
      versionMap = Map<String, dynamic>.from(versionObj);
    }

    final domainsRaw = map['domains'] as List? ?? [];
    final domains = <ScoringDomainResult>[];
    for (final entry in domainsRaw) {
      if (entry is Map) {
        domains.add(
          ScoringDomainResult.fromJson(Map<String, dynamic>.from(entry)),
        );
      }
    }

    final schemasRaw = map['schemas'] as List? ?? [];
    final schemas = <ScoringSchemaResult>[];
    for (final entry in schemasRaw) {
      if (entry is Map) {
        schemas.add(
          ScoringSchemaResult.fromJson(Map<String, dynamic>.from(entry)),
        );
      }
    }

    final itemsRaw = map['items'] as List? ?? [];
    final items = <ScoringItemResult>[];
    for (final entry in itemsRaw) {
      if (entry is Map) {
        items.add(
          ScoringItemResult.fromJson(Map<String, dynamic>.from(entry)),
        );
      }
    }

    return ScoringSnapshot(
      questionnaireVersionLabel: versionMap?['version'] as String?,
      scoringMethod: versionMap?['scoring_method'] as String?,
      scaleMin: _scaleInt(versionMap?['scale_min']),
      scaleMax: _scaleInt(versionMap?['scale_max']),
      completedAt: _parseDateTime(map['completed_at']),
      summary: ScoringSummary.fromJson(map['summary']),
      domains: domains,
      schemas: schemas,
      items: items,
    );
  }

  bool get hasEngineData =>
      summary.hasContent ||
      domains.isNotEmpty ||
      schemas.isNotEmpty ||
      items.isNotEmpty;

  static bool isDemoVersion(String? version) => version == demoVersion;
}

int? _scaleInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
