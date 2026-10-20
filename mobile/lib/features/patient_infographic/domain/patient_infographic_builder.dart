import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../clinical_dashboard/domain/clinical_dashboard_data.dart';
import '../../genogram/domain/genogram_data.dart';
import '../../initial_assessment/domain/clinical_impressions.dart';
import '../../initial_assessment/domain/initial_assessment.dart';
import '../../mental_map/domain/case_conceptualization.dart';
import '../../patient_problems/domain/patient_problem.dart';
import '../../patient_timeline/domain/patient_timeline_event.dart';
import '../../patients/domain/patient.dart';
import '../../personality_assessment/domain/personality_assessment.dart';
import '../../personality_assessment/domain/personality_instrument.dart';
import '../../personality_assessment/presentation/personality_domain_colors.dart';
import 'patient_infographic_data.dart';
import 'schema_descriptions.dart';

/// Monta o [PatientInfographicData] a partir dos dados reais do paciente —
/// determinístico, sem IA. Usa o que o psicólogo já registrou (esquemas
/// ativados no dashboard, textos da conceitualização, linha do tempo, cadastro)
/// e completa esquemas com descrições psicoeducativas do catálogo.
PatientInfographicData buildPatientInfographic({
  required Patient patient,
  required ClinicalDashboardData dashboard,
  required InitialAssessment? assessment,
  required List<PatientTimelineEvent> timelineEvents,
  List<PersonalityAssessment> personalityAssessments = const [],
  CaseConceptualization? concept,
  List<PatientProblem> problems = const [],
  String? attachmentStyle,
  GenogramData? genogramData,
}) {
  final impressions = assessment?.clinicalImpressions;

  // Limites por seção — mantêm o pôster legível mesmo com muito conteúdo.
  const maxTimeline = 8;
  const maxSection = 6;

  // Quote: prefere motivo atual da Conceitualização, fallback para temperamento.
  final quote = _notEmptyOrNull(concept?.motivoCurrent) ??
      _notEmptyOrNull(concept?.motivoInitial) ??
      _firstSentence(impressions?.observedTemperament);

  return PatientInfographicData(
    header: _buildHeader(patient),
    quote: quote,
    timeline: _cap(_buildTimeline(timelineEvents), maxTimeline),
    personality: _buildPersonalityDomains(personalityAssessments),
    schemas: _cap(_buildSchemas(dashboard, concept), maxSection),
    needs: _cap(_buildNeeds(impressions, concept), maxSection),
    modes: _cap(_buildModes(impressions?.modeHypothesesText, concept), maxSection),
    strengths: _cap(
      _itemsFrom(impressions?.resources,
          icon: Icons.star_outline, accent: AppColors.turquoise),
      maxSection,
    ),
    challenges: _cap(_buildChallenges(impressions, concept), maxSection),
    directions: _cap(_buildDirections(impressions, concept), maxSection),
    resources: _cap(
      _splitLines(impressions?.resources)
          .map((r) => InfographicItem(
                title: r,
                icon: Icons.star_outline,
                accent: AppColors.success,
              ))
          .toList(),
      8,
    ),
    demands: _cap(_buildDemands(problems), maxSection),
    lifeAreas: _buildLifeAreas(concept?.functioning),
    attachmentStyle: attachmentStyle,
    genogramMembers: _cap(_buildGenogramMembers(genogramData), 10),
    closingLine:
        'Um retrato de apoio à formulação do caso — sempre sob leitura clínica '
        'do profissional.',
    generatedOn: DateTime.now(),
  );
}

List<T> _cap<T>(List<T> items, int max) =>
    items.length <= max ? items : items.sublist(0, max);

List<InfographicItem> _itemsFrom(
  String? text, {
  required IconData icon,
  required Color accent,
}) {
  return _splitLines(text)
      .map((line) => _asTitleDescription(line, icon: icon, accent: accent))
      .toList();
}

/// Converte "Título: descrição" ou "Título — descrição" num item com título
/// em destaque + descrição; se não houver separador, vira só título.
InfographicItem _asTitleDescription(
  String line, {
  required IconData icon,
  required Color accent,
}) {
  final match = RegExp(r'^(.{3,60}?)\s*[:–—-]\s+(.+)$').firstMatch(line);
  if (match != null) {
    return InfographicItem(
      title: match.group(1)!.trim(),
      description: match.group(2)!.trim(),
      icon: icon,
      accent: accent,
    );
  }
  return InfographicItem(title: line, icon: icon, accent: accent);
}

String? _firstSentence(String? text) {
  if (text == null || text.trim().isEmpty) return null;
  final t = text.trim();
  final end = t.indexOf(RegExp(r'[.!?]'));
  final sentence = end == -1 ? t : t.substring(0, end + 1);
  return sentence.length > 160 ? '${sentence.substring(0, 157)}…' : sentence;
}

InfographicHeader _buildHeader(Patient patient) {
  final facts = <InfographicFact>[
    if (_ageOf(patient.birthDate) != null)
      InfographicFact(
          Icons.person_outline, '${_ageOf(patient.birthDate)} anos'),
    if (_notEmpty(patient.displayEducationLevel))
      InfographicFact(Icons.school_outlined, patient.displayEducationLevel!),
    if (_birthPlace(patient) != null)
      InfographicFact(
          Icons.place_outlined, 'Natural de ${_birthPlace(patient)}'),
    if (_notEmpty(patient.displayRelationshipStatus))
      InfographicFact(
          Icons.favorite_border, patient.displayRelationshipStatus!),
    if (_notEmpty(patient.occupation))
      InfographicFact(Icons.work_outline, patient.occupation!),
    if (patient.hasChildren != null)
      InfographicFact(Icons.child_care_outlined,
          patient.hasChildren! ? 'Tem filhos' : 'Sem filhos'),
  ];

  return InfographicHeader(
    name: patient.fullName,
    avatarInitials: _initialsOf(patient.fullName),
    avatarType: patient.avatarType,
    photoUrl: patient.photoUrl,
    avatarConfig: patient.avatarConfig,
    facts: facts,
  );
}

List<InfographicTimelineEntry> _buildTimeline(
    List<PatientTimelineEvent> events) {
  // Ordena por data quando disponível (mais antigo → mais recente).
  final sorted = [...events]..sort((a, b) {
      final da = a.eventDate;
      final db = b.eventDate;
      if (da == null && db == null) return 0;
      if (da == null) return 1;
      if (db == null) return -1;
      return da.compareTo(db);
    });

  const palette = [
    AppColors.cyan,
    AppColors.turquoise,
    AppColors.purple,
    AppColors.warning,
  ];

  return [
    for (var i = 0; i < sorted.length; i++)
      InfographicTimelineEntry(
        periodLabel: sorted[i].dateLabel,
        description: sorted[i].title,
        icon: sorted[i].isSensitive
            ? Icons.lock_outline
            : Icons.event_note_outlined,
        accent: palette[i % palette.length],
      ),
  ];
}

List<InfographicItem> _buildSchemas(
  ClinicalDashboardData dashboard,
  CaseConceptualization? concept,
) {
  final items = <InfographicItem>[];
  final seen = <String>{};

  // Prioridade: esquemas centrais da Conceitualização (mais ricos).
  if (concept != null && concept.hasCentralSchemas) {
    for (final cs in concept.centralSchemas) {
      if (cs.isEmpty) continue;
      final name = (cs.name ?? '').trim();
      if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
      items.add(InfographicItem(
        title: name,
        description: cs.description?.trim().isNotEmpty == true
            ? cs.description!.trim()
            : schemaDescriptionFor(name),
        icon: Icons.psychology_outlined,
        accent: AppColors.purple,
      ));
    }
  }

  // Complementa com esquemas do dashboard que ainda não apareceram.
  for (final s in dashboard.activatedSchemas) {
    if (!seen.add(s.name.toLowerCase())) continue;
    items.add(InfographicItem(
      title: s.name,
      description: schemaDescriptionFor(s.name) ?? s.severityLabel,
      icon: Icons.psychology_outlined,
      accent: AppColors.purple,
    ));
  }

  return items;
}

List<InfographicNeed> _buildNeeds(
  ClinicalImpressions? impressions,
  CaseConceptualization? concept,
) {
  final items = <InfographicNeed>[];
  final seen = <String>{};

  // Necessidades da Conceitualização (estruturadas por necessidade central).
  if (concept != null && concept.hasAnyNeed) {
    for (final need in kCoreNeeds) {
      final u = concept.needFor(need.key);
      if (u.isEmpty) continue;
      if (!seen.add(need.key)) continue;
      final detail = [
        if ((u.rating ?? '').trim().isNotEmpty) u.rating!.trim(),
        if ((u.origin ?? '').trim().isNotEmpty) u.origin!.trim(),
      ].join(' — ');
      items.add(InfographicNeed(
        need: need.label,
        relatedEvents: detail.isNotEmpty ? detail : null,
        accent: AppColors.error,
      ));
    }
  }

  // Fallback: texto livre das impressões clínicas.
  if (items.isEmpty) {
    for (final n in _splitLines(impressions?.emotionalNeedsText as String?)) {
      if (seen.add(n.toLowerCase())) {
        items.add(InfographicNeed(need: n, accent: AppColors.error));
      }
    }
  }

  return items;
}

List<InfographicItem> _buildModes(
  String? modeText,
  CaseConceptualization? concept,
) {
  final items = <InfographicItem>[];
  final seen = <String>{};

  // Modos de enfrentamento da Conceitualização.
  if (concept != null && concept.hasModeAssessment) {
    final ma = concept.modeAssessment;
    for (final cm in ma.copingModes) {
      if (cm.isEmpty) continue;
      final name = (cm.name ?? cm.category ?? '').trim();
      if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
      items.add(InfographicItem(
        title: name,
        description: (cm.consequences ?? cm.example)?.trim(),
        icon: Icons.theater_comedy_outlined,
        accent: AppColors.turquoise,
      ));
    }
    // Modos parentais.
    for (final pm in ma.parentalModes) {
      if (pm.isEmpty) continue;
      final name = (pm.name ?? '').trim();
      if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
      items.add(InfographicItem(
        title: name,
        description: pm.messages?.trim(),
        icon: Icons.theater_comedy_outlined,
        accent: AppColors.warning,
      ));
    }
  }

  // Fallback: texto livre.
  if (items.isEmpty) {
    return _splitLines(modeText)
        .map((m) => _asTitleDescription(
              m,
              icon: Icons.theater_comedy_outlined,
              accent: AppColors.turquoise,
            ))
        .toList();
  }

  return items;
}

List<InfographicItem> _buildChallenges(
  ClinicalImpressions? impressions,
  CaseConceptualization? concept,
) {
  final items = <InfographicItem>[];
  final seen = <String>{};

  // Problemas de vida da Conceitualização.
  if (concept != null) {
    final probs = [
      concept.lifeProblems.problem1,
      concept.lifeProblems.problem2,
      concept.lifeProblems.problem3,
      concept.lifeProblems.problem4,
    ].where((p) => (p ?? '').trim().isNotEmpty).cast<String>();
    for (final p in probs) {
      if (seen.add(p.toLowerCase())) {
        items.add(InfographicItem(
          title: p.trim(),
          icon: Icons.report_problem_outlined,
          accent: AppColors.warning,
        ));
      }
    }
  }

  // Complementa com vulnerabilidades das impressões.
  for (final v
      in _itemsFrom(impressions?.vulnerabilities,
          icon: Icons.report_problem_outlined, accent: AppColors.warning)) {
    if (seen.add(v.title.toLowerCase())) items.add(v);
  }

  return items;
}

List<InfographicItem> _buildDirections(
  ClinicalImpressions? impressions,
  CaseConceptualization? concept,
) {
  final items = <InfographicItem>[];
  final seen = <String>{};

  // Objetivos de terapia da Conceitualização.
  if (concept != null && concept.hasTherapyObjectives) {
    for (final obj in concept.therapyObjectives) {
      if (obj.isEmpty) continue;
      final goal = (obj.goal ?? '').trim();
      if (goal.isEmpty || !seen.add(goal.toLowerCase())) continue;
      items.add(InfographicItem(
        title: goal,
        description: obj.healthyBehaviors?.trim(),
        icon: Icons.check_circle_outline,
        accent: AppColors.cyan,
      ));
    }
  }

  // Fallback: prioridades terapêuticas das impressões.
  if (items.isEmpty) {
    return _itemsFrom(impressions?.therapeuticPriorities as String?,
        icon: Icons.check_circle_outline, accent: AppColors.cyan);
  }

  return items;
}

// ── Novas seções (Luciana) ─────────────────────────────────────────────────

List<InfographicItem> _buildDemands(List<PatientProblem> problems) {
  return problems
      .where((p) => p.isOpen)
      .map((p) => InfographicItem(
            title: p.title,
            description: (p.description ?? '').trim().isNotEmpty
                ? p.description!.trim()
                : null,
            icon: Icons.flag_outlined,
            accent: AppColors.error,
          ))
      .toList();
}

/// Funcionamento atual — Seção 5 da Conceitualização, avaliada pelo terapeuta.
/// Escala 1–6 (1 = Não Funcional … 6 = Excelente).
List<InfographicLifeArea> _buildLifeAreas(FunctioningAssessment? functioning) {
  if (functioning == null || functioning.isEmpty) return const [];
  return [
    for (final area in kFunctioningAreas)
      if (!(functioning.entryFor(area.key).isEmpty))
        InfographicLifeArea(
          label: area.label,
          score: functioning.entryFor(area.key).rating ?? 0,
          maxScore: 6,
          accent: _functioningColor(functioning.entryFor(area.key).rating ?? 0),
        ),
  ];
}

Color _functioningColor(int score) {
  if (score <= 2) return AppColors.error;
  if (score <= 4) return AppColors.warning;
  return AppColors.success;
}

List<InfographicGenogramMember> _buildGenogramMembers(GenogramData? data) {
  if (data == null || data.people.isEmpty) return const [];
  return data.people
      .where((p) => !p.isSensitive)
      .map((p) => InfographicGenogramMember(
            name: p.fullName,
            relationship: p.relationshipToPatient,
            isDeceased: p.isDeceased,
          ))
      .toList();
}

// ── utils ──────────────────────────────────────────────────────────────────

/// Quebra um texto livre em itens: por linha, por ";" ou por bullets.
List<String> _splitLines(String? text) {
  if (text == null || text.trim().isEmpty) return const [];
  return text
      .split(RegExp(r'[\n;•]'))
      .map((l) => l.replaceAll(RegExp(r'^[\s\-–—•]+'), '').trim())
      .where((l) => l.isNotEmpty)
      .toList();
}

int? _ageOf(DateTime? birthDate) {
  if (birthDate == null) return null;
  final now = DateTime.now();
  var age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age >= 0 ? age : null;
}

String? _birthPlace(Patient patient) {
  final parts = [patient.stateBirth, patient.countryBirth]
      .where((v) => v != null && v.trim().isNotEmpty)
      .cast<String>();
  if (parts.isEmpty) return null;
  return parts.join(' / ');
}

bool _notEmpty(String? value) => value != null && value.trim().isNotEmpty;

String? _notEmptyOrNull(String? value) {
  final t = value?.trim();
  return (t == null || t.isEmpty) ? null : t;
}

String _initialsOf(String fullName) {
  final parts =
      fullName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}

List<InfographicPersonalityDomain> _buildPersonalityDomains(
  List<PersonalityAssessment> assessments,
) {
  if (assessments.isEmpty) return const [];
  // Usa o registro mais recente que tenha resultados integrados.
  final candidate = assessments.firstWhere(
    (a) => a.results != null && a.results!.domains.isNotEmpty,
    orElse: () => assessments.first,
  );
  final results = candidate.results;
  if (results == null || results.domains.isEmpty) return const [];

  final instrument = instrumentForCode(candidate.instrument);

  const _domainIcons = <String, IconData>{
    'neuroticism': Icons.mood_bad_outlined,
    'extraversion': Icons.people_outline,
    'openness': Icons.explore_outlined,
    'agreeableness': Icons.handshake_outlined,
    'conscientiousness': Icons.assignment_turned_in_outlined,
  };

  final domains = <InfographicPersonalityDomain>[];
  for (final domainDef in instrument.domains) {
    final entry = results.domains[domainDef.code];
    if (entry == null) continue;
    final score = entry.overall.score?.toDouble() ?? 0;
    domains.add(InfographicPersonalityDomain(
      name: domainDef.label,
      score: score,
      classification: entry.overall.level?.label,
      icon: _domainIcons[domainDef.code] ?? Icons.psychology_outlined,
      accent: personalityDomainColor(domainDef.code),
    ));
  }
  return domains;
}
