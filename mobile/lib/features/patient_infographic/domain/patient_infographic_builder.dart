import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../clinical_dashboard/domain/clinical_dashboard_data.dart';
import '../../clinical_dashboard/domain/consolidated_schema_row.dart';
import '../../genogram/domain/genogram_data.dart';
import '../../genogram/domain/genogram_layout_adapter.dart';
import '../../healthy_resources/domain/healthy_resource_catalog.dart';
import '../../healthy_resources/domain/healthy_resources.dart';
import '../../initial_assessment/domain/initial_assessment.dart';
import '../../initial_assessment/domain/life_area.dart';
import '../../mental_map/domain/schema_mode_catalog.dart';
import '../../mental_map/domain/case_conceptualization.dart';
import '../../patient_problems/domain/patient_problem.dart';
import '../../patient_timeline/domain/patient_timeline_event.dart';
import '../../patients/domain/patient.dart';
import '../../personality_assessment/domain/personality_assessment.dart';
import '../../personality_assessment/domain/personality_instrument.dart';
import '../../personality_assessment/presentation/personality_domain_colors.dart';
import '../../therapy_goals/domain/therapy_goal.dart';
import 'attachment_descriptions.dart';
import 'patient_infographic_data.dart';
import 'schema_descriptions.dart';

/// Monta o [PatientInfographicData] a partir dos dados reais do paciente —
/// determinístico, sem IA. Cada seção vem do módulo onde o terapeuta a
/// preenche: Demandas, Contexto de Vida, Linha do Tempo, Genograma, Recursos
/// Saudáveis e Plano Terapêutico (Conhecer/Intervir), questionários
/// (esquemas, modos, enfrentamento, apego) e Personalidade (Avaliar).
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
  HealthyResources? healthyResources,
}) {
  final impressions = assessment?.clinicalImpressions;

  // Limites por seção — mantêm o pôster legível mesmo com muito conteúdo.
  const maxTimeline = 8;
  const maxSection = 6;

  return PatientInfographicData(
    header: _buildHeader(patient),
    reasonsInitial: _notEmptyOrNull(concept?.motivoInitial),
    reasonsCurrent: _notEmptyOrNull(concept?.motivoCurrent),
    demands: _cap(_buildDemands(problems), maxSection),
    lifeWheel: _buildLifeWheel(assessment),
    personality: _buildPersonalityDomains(personalityAssessments),
    timeline:
        _cap(_buildTimeline(timelineEvents, patient.birthDate), maxTimeline),
    genogram: _withoutSensitive(genogramData),
    genogramMembers: _cap(_buildGenogramMembers(genogramData), 10),
    schemas: _cap(_buildSchemas(dashboard, concept), maxSection),
    modes: _cap(
      _buildModes(dashboard, impressions?.modeHypothesesText, concept),
      maxSection,
    ),
    coping: _cap(_buildCoping(dashboard), maxSection),
    attachment: _buildAttachment(dashboard, attachmentStyle),
    resources: _cap(_buildResources(healthyResources), 12),
    plan: _cap(_buildPlan(dashboard.caseSummary.highlightedGoals), maxSection),
    closingLine:
        'Um retrato de apoio à formulação do caso — sempre sob leitura clínica '
        'do profissional.',
    generatedOn: DateTime.now(),
  );
}

List<T> _cap<T>(List<T> items, int max) =>
    items.length <= max ? items : items.sublist(0, max);

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

// ── Linha do tempo ─────────────────────────────────────────────────────────

/// Idade aproximada do evento, só para ordenar: data → idade pela data de
/// nascimento; idade informada; capítulo da vida (idade típica do capítulo).
double _approxAge(PatientTimelineEvent e, DateTime? birth) {
  final date = e.eventDate;
  if (date != null && birth != null) {
    return date.difference(birth).inDays / 365.25;
  }
  if (e.ageAtEvent != null) return e.ageAtEvent!.toDouble();
  const chapterAge = [0.0, 6.0, 15.0, 30.0, 55.0, 99.0];
  final order = e.lifeChapterOrder;
  if (order != null) return chapterAge[order];
  return double.infinity; // sem referência: vai para o fim
}

List<InfographicTimelineEntry> _buildTimeline(
  List<PatientTimelineEvent> events,
  DateTime? birth,
) {
  final sorted = [...events]
    ..sort((a, b) => _approxAge(a, birth).compareTo(_approxAge(b, birth)));

  const palette = [
    AppColors.cyan,
    AppColors.turquoise,
    AppColors.purple,
    AppColors.blue,
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

// ── Esquemas ───────────────────────────────────────────────────────────────

List<InfographicItem> _buildSchemas(
  ClinicalDashboardData dashboard,
  CaseConceptualization? concept,
) {
  final items = <InfographicItem>[];
  final seen = <String>{};
  final scoreByName = {
    for (final r in dashboard.activatedSchemas)
      if (!_isMode(r)) r.name.toLowerCase(): 'Média ${_avg(r.score)}',
  };

  // Prioridade: esquemas centrais da Conceitualização (mais ricos).
  if (concept != null && concept.hasCentralSchemas) {
    for (final cs in concept.centralSchemas) {
      if (cs.isEmpty) continue;
      final name = (cs.name ?? '').trim();
      if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
      items.add(InfographicItem(
        title: name,
        badge: scoreByName[name.toLowerCase()],
        description: cs.description?.trim().isNotEmpty == true
            ? cs.description!.trim()
            : schemaDescriptionFor(name),
        icon: Icons.psychology_outlined,
        accent: AppColors.purple,
      ));
    }
  }

  // Complementa com esquemas do dashboard que ainda não apareceram. Os modos
  // do YAMI também estão na lista consolidada, mas têm seção própria.
  for (final s in dashboard.activatedSchemas) {
    if (_isMode(s) || !seen.add(s.name.toLowerCase())) continue;
    items.add(InfographicItem(
      title: s.name,
      badge: 'Média ${_avg(s.score)}',
      description: schemaDescriptionFor(s.name) ?? s.severityLabel,
      icon: Icons.psychology_outlined,
      accent: AppColors.purple,
    ));
  }

  return items;
}

// ── Modos e enfrentamento (resultado dos questionários) ────────────────────

String _avg(double v) => v.toStringAsFixed(1).replaceAll('.', ',');

/// A lista consolidada mistura esquemas do YSQ e modos do YAMI.
bool _isMode(ConsolidatedSchemaRow r) =>
    '${r.instrumentCode ?? ''} ${r.code}'.toUpperCase().contains('YAMI');

/// Modos ativados no YAMI (média ≥ 4,0 ou ativação do profissional), do mais
/// alto para o mais baixo. Sem YAMI ativado, cai para a conceitualização e,
/// por último, para o texto livre das impressões.
List<InfographicItem> _buildModes(
  ClinicalDashboardData dashboard,
  String? modeText,
  CaseConceptualization? concept,
) {
  final fromQuestionnaire = [
    for (final r in dashboard.consolidatedSchemas)
      if (_isMode(r) && r.isActivated) r,
  ]..sort((a, b) => b.score.compareTo(a.score));
  if (fromQuestionnaire.isNotEmpty) {
    return [
      for (final r in fromQuestionnaire)
        InfographicItem(
          title: r.name,
          badge: 'Média ${_avg(r.score)}',
          description: schemaModeInfoForCode(r.code)?.description ??
              'Modo ativado no YAMI (média igual ou acima de 4,0).',
          icon: Icons.theater_comedy_outlined,
          accent: AppColors.turquoise,
        ),
    ];
  }
  return _conceptualizationModes(modeText, concept);
}

List<InfographicItem> _conceptualizationModes(
  String? modeText,
  CaseConceptualization? concept,
) {
  final items = <InfographicItem>[];
  final seen = <String>{};

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
    for (final pm in ma.parentalModes) {
      if (pm.isEmpty) continue;
      final name = (pm.name ?? '').trim();
      if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
      items.add(InfographicItem(
        title: name,
        description: pm.messages?.trim(),
        icon: Icons.theater_comedy_outlined,
        accent: AppColors.turquoise,
      ));
    }
  }

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

/// Estilos de enfrentamento mais altos nos questionários YCI/YRAI.
List<InfographicItem> _buildCoping(ClinicalDashboardData dashboard) {
  // YCI e YRAI só têm a apuração geral; rotulamos pelo que cada um mede.
  const meta = {
    'YCI': (
      'Compensação (YCI)',
      'Quanto a pessoa reage aos esquemas "indo contra" eles: controlando, '
          'competindo, agradando ou se afirmando em excesso.'
    ),
    'YRAI': (
      'Evitação (YRAI)',
      'Quanto a pessoa foge do que ativa os esquemas: evita situações, '
          'pensamentos, emoções ou pessoas, ou se anestesia.'
    ),
  };
  final items = <InfographicItem>[];
  for (final r in dashboard.caseSummary.topCoping) {
    final key = r.code.toUpperCase().startsWith('YRAI') ? 'YRAI' : 'YCI';
    final (title, text) = meta[key]!;
    final media = 'Média ${_avg(r.averageScore ?? r.score)}';
    final level = r.severityLabel?.trim();
    items.add(InfographicItem(
      title: title,
      badge: (level == null || level.isEmpty) ? media : '$level · $media',
      description: text,
      icon: Icons.shield_outlined,
      accent: AppColors.cyan,
    ));
  }
  return items;
}

// ── Demandas, contexto de vida, apego, recursos e plano ────────────────────

List<InfographicItem> _buildDemands(List<PatientProblem> problems) {
  return problems
      .where((p) => p.isOpen)
      .map((p) => InfographicItem(
            title: p.title,
            description: (p.description ?? '').trim().isNotEmpty
                ? p.description!.trim()
                : null,
            icon: Icons.flag_outlined,
            accent: AppColors.blue,
          ))
      .toList();
}

/// Roda da Vida: a satisfação (1–10) que o paciente deu a cada área.
Map<LifeArea, int> _buildLifeWheel(InitialAssessment? assessment) {
  if (assessment == null) return const {};
  return {
    for (final area in kLifeAreasInOrder)
      if (assessment.lifeAreaFor(area).score != null)
        area: assessment.lifeAreaFor(area).score!,
  };
}

/// Estilo dominante = maior média entre Ansioso, Seguro e Evitante do
/// questionário de apego; sem resultado, cai no rótulo vindo do Mapa Mental.
InfographicItem? _buildAttachment(
  ClinicalDashboardData dashboard,
  String? fallbackStyle,
) {
  late final String style;
  String? badge;
  final rows = [
    for (final r in dashboard.attachment?.allScores ?? const [])
      if (r.code.toUpperCase().startsWith('ATTACHMENT_')) r,
  ]..sort((a, b) => b.score.compareTo(a.score));
  if (rows.isNotEmpty) {
    style = rows.first.name;
    badge = 'Média ${_avg(rows.first.averageScore ?? rows.first.score)}';
  } else {
    // O rótulo do Mapa vem como "Nome 3,2": separa o nome da pontuação.
    final raw = fallbackStyle?.trim();
    if (raw == null || raw.isEmpty) return null;
    final m = RegExp(r'^(\D+?)\s+[\d.,]+%?$').firstMatch(raw);
    style = (m?.group(1) ?? raw).trim();
  }
  if (_normalizeKey(style).contains('geral')) return null;
  return InfographicItem(
    title: attachmentTitleFor(style),
    badge: badge,
    description: attachmentDescriptionFor(style),
    icon: Icons.link_outlined,
    accent: AppColors.purple,
  );
}

String _normalizeKey(String s) => s.toLowerCase();

List<InfographicItem> _buildResources(HealthyResources? resources) {
  if (resources == null || resources.isEmpty) return const [];
  final labels = {
    for (final c in kHealthyResourceCatalog)
      for (final i in c.items) i.id: i.label,
  };
  final names = <String>[
    for (final id in resources.selectedPredefined)
      if (labels[id] != null) labels[id]!,
    for (final custom in resources.customResources)
      if (custom.trim().isNotEmpty) custom.trim(),
  ];
  return [
    for (final n in names)
      InfographicItem(
        title: n,
        icon: Icons.spa_outlined,
        accent: AppColors.success,
      ),
  ];
}

List<InfographicItem> _buildPlan(List<TherapyGoal> goals) {
  return [
    for (final g in goals)
      if (g.isActive)
        InfographicItem(
          title: g.title,
          description: (g.description ?? '').trim().isNotEmpty
              ? g.description!.trim()
              : null,
          bullets: [if (g.progress > 0) 'Progresso: ${g.progress}%'],
          icon: Icons.flag_outlined,
          accent: AppColors.moduleGoals,
        ),
  ];
}

// ── Genograma ──────────────────────────────────────────────────────────────

/// Mesmo genograma, sem pessoas sensíveis e sem relações que as envolvam.
GenogramData? _withoutSensitive(GenogramData? data) {
  if (data == null || data.people.isEmpty) return null;
  final people = [
    for (final p in data.people)
      if (!p.isSensitive) p
  ];
  final ids = {for (final p in people) p.id};
  return withInferredStructure(GenogramData(
    people: people,
    relationships: [
      for (final r in data.relationships)
        if (ids.contains(r.personAId) && ids.contains(r.personBId)) r,
    ],
  ));
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
    (a) => a.results.domains.isNotEmpty,
    orElse: () => assessments.first,
  );
  final results = candidate.results;
  if (results.domains.isEmpty) return const [];

  final instrument = instrumentForCode(candidate.instrument);

  const domainIcons = <String, IconData>{
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
      icon: domainIcons[domainDef.code] ?? Icons.psychology_outlined,
      accent: personalityDomainColor(domainDef.code),
    ));
  }
  return domains;
}
