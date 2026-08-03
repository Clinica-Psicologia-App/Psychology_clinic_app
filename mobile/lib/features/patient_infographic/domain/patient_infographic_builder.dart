import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../clinical_dashboard/domain/clinical_dashboard_data.dart';
import '../../initial_assessment/domain/initial_assessment.dart';
import '../../patient_timeline/domain/patient_timeline_event.dart';
import '../../patients/domain/patient.dart';
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
}) {
  final impressions = assessment?.clinicalImpressions;

  return PatientInfographicData(
    header: _buildHeader(patient),
    quote: _firstSentence(impressions?.observedTemperament),
    timeline: _buildTimeline(timelineEvents),
    schemas: _buildSchemas(dashboard),
    needs: _splitLines(impressions?.emotionalNeedsText)
        .map((n) => InfographicNeed(need: n, accent: AppColors.error))
        .toList(),
    modes: _buildModes(impressions?.modeHypothesesText),
    strengths: _itemsFrom(
      impressions?.resources,
      icon: Icons.star_outline,
      accent: AppColors.turquoise,
    ),
    challenges: _itemsFrom(
      impressions?.vulnerabilities,
      icon: Icons.report_problem_outlined,
      accent: AppColors.warning,
    ),
    directions: _itemsFrom(
      impressions?.therapeuticPriorities,
      icon: Icons.check_circle_outline,
      accent: AppColors.cyan,
    ),
    resources: _splitLines(impressions?.resources)
        .map((r) => InfographicItem(
              title: r,
              icon: Icons.star_outline,
              accent: AppColors.success,
            ))
        .toList(),
    closingLine:
        'Um retrato de apoio à formulação do caso — sempre sob leitura clínica '
        'do profissional.',
  );
}

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
      InfographicFact(Icons.person_outline, '${_ageOf(patient.birthDate)} anos'),
    if (_notEmpty(patient.displayEducationLevel))
      InfographicFact(Icons.school_outlined, patient.displayEducationLevel!),
    if (_birthPlace(patient) != null)
      InfographicFact(Icons.place_outlined, 'Natural de ${_birthPlace(patient)}'),
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

List<InfographicTimelineEntry> _buildTimeline(List<PatientTimelineEvent> events) {
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

List<InfographicItem> _buildSchemas(ClinicalDashboardData dashboard) {
  return [
    for (final s in dashboard.activatedSchemas)
      InfographicItem(
        title: s.name,
        description: schemaDescriptionFor(s.name) ?? s.severityLabel,
        icon: Icons.psychology_outlined,
        accent: AppColors.purple,
      ),
  ];
}

List<InfographicItem> _buildModes(String? modeText) {
  return _splitLines(modeText)
      .map((m) => _asTitleDescription(
            m,
            icon: Icons.theater_comedy_outlined,
            accent: AppColors.turquoise,
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

String _initialsOf(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((p) => p.isNotEmpty)
      .toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
      .toUpperCase();
}
