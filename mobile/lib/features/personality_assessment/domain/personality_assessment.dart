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

/// Síntese clínica do terapeuta sobre o perfil (campos livres). Fase 2.
class ClinicalSynthesis {
  const ClinicalSynthesis({
    this.understanding,
    this.relevant,
    this.resources,
    this.vulnerabilities,
    this.hypotheses,
  });

  /// O que este perfil ajuda a compreender sobre o paciente?
  final String? understanding;

  /// Aspectos que parecem clinicamente relevantes.
  final String? relevant;

  /// Recursos identificados.
  final String? resources;

  /// Vulnerabilidades identificadas.
  final String? vulnerabilities;

  /// Hipóteses a explorar em sessão.
  final String? hypotheses;

  bool get isEmpty =>
      [understanding, relevant, resources, vulnerabilities, hypotheses]
          .every((v) => (v ?? '').trim().isEmpty);

  factory ClinicalSynthesis.fromJson(Map<String, dynamic> j) =>
      ClinicalSynthesis(
        understanding: j['understanding'] as String?,
        relevant: j['relevant'] as String?,
        resources: j['resources'] as String?,
        vulnerabilities: j['vulnerabilities'] as String?,
        hypotheses: j['hypotheses'] as String?,
      );

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (t(understanding) != null) 'understanding': t(understanding),
      if (t(relevant) != null) 'relevant': t(relevant),
      if (t(resources) != null) 'resources': t(resources),
      if (t(vulnerabilities) != null) 'vulnerabilities': t(vulnerabilities),
      if (t(hypotheses) != null) 'hypotheses': t(hypotheses),
    };
  }
}

/// Se/como o perfil se relaciona com a conceitualização do paciente. Fase 2.
enum IntegrationStatus {
  yes('yes', 'Sim'),
  notYet('not_yet', 'Ainda não'),
  notRelevant('not_relevant', 'Não considero relevante neste momento');

  const IntegrationStatus(this.code, this.label);
  final String code;
  final String label;

  static IntegrationStatus? fromCode(String? code) {
    if (code == null) return null;
    for (final s in IntegrationStatus.values) {
      if (s.code == code) return s;
    }
    return null;
  }
}

/// A que aspectos da conceitualização o perfil se relaciona.
enum IntegrationLink {
  history('history', 'História de vida'),
  temperament('temperament', 'Temperamento/predisposições'),
  schemas('schemas', 'Esquemas'),
  modes('modes', 'Modos'),
  coping('coping', 'Estratégias de enfrentamento'),
  interpersonal('interpersonal', 'Padrões interpessoais'),
  resources('resources', 'Recursos do paciente'),
  goals('goals', 'Objetivos terapêuticos');

  const IntegrationLink(this.code, this.label);
  final String code;
  final String label;

  static IntegrationLink? fromCode(String? code) {
    for (final l in IntegrationLink.values) {
      if (l.code == code) return l;
    }
    return null;
  }
}

class ConceptualizationIntegration {
  const ConceptualizationIntegration({
    this.status,
    this.links = const {},
    this.note,
  });

  final IntegrationStatus? status;
  final Set<IntegrationLink> links;
  final String? note;

  bool get isEmpty =>
      status == null && links.isEmpty && (note ?? '').trim().isEmpty;

  factory ConceptualizationIntegration.fromJson(Map<String, dynamic> j) {
    final raw = (j['links'] as List?) ?? const [];
    return ConceptualizationIntegration(
      status: IntegrationStatus.fromCode(j['status'] as String?),
      links: {
        for (final e in raw)
          if (IntegrationLink.fromCode(e?.toString()) != null)
            IntegrationLink.fromCode(e.toString())!,
      },
      note: j['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    String? t(String? v) => (v ?? '').trim().isEmpty ? null : v!.trim();
    return {
      if (status != null) 'status': status!.code,
      if (links.isNotEmpty) 'links': [for (final l in links) l.code],
      if (t(note) != null) 'note': t(note),
    };
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
    this.synthesis = const ClinicalSynthesis(),
    this.integration = const ConceptualizationIntegration(),
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
  final ClinicalSynthesis synthesis;
  final ConceptualizationIntegration integration;

  PersonalityInstrument get instrumentDef => instrumentForCode(instrument);

  bool get hasSynthesis => !synthesis.isEmpty;
  bool get hasIntegration => !integration.isEmpty;

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
      synthesis: ClinicalSynthesis.fromJson(
        Map<String, dynamic>.from((j['clinical_synthesis'] as Map?) ?? const {}),
      ),
      integration: ConceptualizationIntegration.fromJson(
        Map<String, dynamic>.from(
            (j['conceptualization_integration'] as Map?) ?? const {}),
      ),
    );
  }
}
