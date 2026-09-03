import 'personality_instrument.dart';

/// Validade do protocolo (informada pelo relatório oficial, não calculada).
enum ProtocolValidity {
  appropriate('appropriate', 'Apropriado para avaliação'),
  caution('caution', 'Interpretar com cautela'),
  invalidated('invalidated', 'Invalidado');

  const ProtocolValidity(this.code, this.label);
  final String code;
  final String label;

  static ProtocolValidity? fromCode(String? code) {
    if (code == null) return null;
    for (final v in ProtocolValidity.values) {
      if (v.code == code) return v;
    }
    return null;
  }
}

/// Resultado de um domínio ou faceta: número (livre) + classificação.
class ScoreEntry {
  const ScoreEntry({this.score, this.level});

  final num? score;
  final PersonalityLevel? level;

  bool get isEmpty => score == null && level == null;

  factory ScoreEntry.fromJson(Map<String, dynamic> j) => ScoreEntry(
        score: j['score'] as num?,
        level: PersonalityLevel.fromCode(j['classification'] as String?),
      );

  Map<String, dynamic> toJson() => {
        if (score != null) 'score': score,
        if (level != null) 'classification': level!.code,
      };
}

/// Resultado de um domínio: escore geral + facetas (por código).
class DomainResult {
  const DomainResult({this.overall = const ScoreEntry(), this.facets = const {}});

  final ScoreEntry overall;
  final Map<String, ScoreEntry> facets;

  ScoreEntry facet(String code) => facets[code] ?? const ScoreEntry();

  bool get isEmpty => overall.isEmpty && facets.values.every((f) => f.isEmpty);

  factory DomainResult.fromJson(Map<String, dynamic> j) {
    final f = <String, ScoreEntry>{};
    final raw = (j['facets'] as Map?) ?? const {};
    raw.forEach((k, v) {
      if (v is Map) f['$k'] = ScoreEntry.fromJson(Map<String, dynamic>.from(v));
    });
    return DomainResult(
      overall: ScoreEntry.fromJson(j),
      facets: f,
    );
  }

  Map<String, dynamic> toJson() {
    final f = <String, dynamic>{};
    facets.forEach((k, v) {
      if (!v.isEmpty) f[k] = v.toJson();
    });
    return {
      ...overall.toJson(),
      if (f.isNotEmpty) 'facets': f,
    };
  }
}

/// Todos os resultados de uma avaliação, por código de domínio.
class PersonalityResults {
  const PersonalityResults({this.domains = const {}});

  final Map<String, DomainResult> domains;

  DomainResult forDomain(String code) =>
      domains[code] ?? const DomainResult();

  bool get isEmpty => domains.values.every((d) => d.isEmpty);

  factory PersonalityResults.fromJson(Map<String, dynamic> j) {
    final d = <String, DomainResult>{};
    final raw = (j['domains'] as Map?) ?? const {};
    raw.forEach((k, v) {
      if (v is Map) {
        d['$k'] = DomainResult.fromJson(Map<String, dynamic>.from(v));
      }
    });
    return PersonalityResults(domains: d);
  }

  Map<String, dynamic> toJson() {
    final d = <String, dynamic>{};
    domains.forEach((k, v) {
      if (!v.isEmpty) d[k] = v.toJson();
    });
    return {'domains': d};
  }
}

/// Uma avaliação de personalidade registrada (um instrumento aplicado).
class PersonalityAssessment {
  const PersonalityAssessment({
    required this.id,
    required this.patientId,
    required this.instrument,
    required this.results,
    required this.createdAt,
    required this.updatedAt,
    this.appliedOn,
    this.applicationForm,
    this.protocolValidity,
    this.sharedWithPatient = false,
  });

  final String id;
  final String patientId;
  final String instrument;
  final PersonalityResults results;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? appliedOn;
  final String? applicationForm;
  final ProtocolValidity? protocolValidity;
  final bool sharedWithPatient;

  PersonalityInstrument get instrumentDef => instrumentForCode(instrument);

  factory PersonalityAssessment.fromJson(Map<String, dynamic> j) {
    DateTime? date(dynamic v) => v == null ? null : DateTime.parse(v as String);
    return PersonalityAssessment(
      id: j['id'] as String,
      patientId: j['patient_id'] as String,
      instrument: (j['instrument'] as String?) ?? 'NEO_PI_R',
      results: PersonalityResults.fromJson(
        Map<String, dynamic>.from((j['results'] as Map?) ?? const {}),
      ),
      createdAt: date(j['created_at'])!.toLocal(),
      updatedAt: date(j['updated_at'])!.toLocal(),
      appliedOn: date(j['applied_on']),
      applicationForm: j['application_form'] as String?,
      protocolValidity: ProtocolValidity.fromCode(j['protocol_validity'] as String?),
      sharedWithPatient: (j['shared_with_patient'] as bool?) ?? false,
    );
  }
}
