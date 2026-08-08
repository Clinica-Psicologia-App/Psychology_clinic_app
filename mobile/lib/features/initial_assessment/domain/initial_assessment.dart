import 'clinical_impressions.dart';
import 'clinical_intake.dart';
import 'life_area.dart';
import 'life_area_assessment.dart';
import 'patient_basics.dart';
import 'patient_intake.dart';

/// Agregado da Tela 1 — "Conhecendo Você". Reúne, para um paciente, os dados
/// das quatro áreas (Blocos 1–4) nas duas lentes.
///
/// Campos staff-only (`clinicalIntake`, `clinicalImpressions` e os
/// `clinicalComment` das áreas) só vêm preenchidos quando o solicitante é
/// staff — a RLS garante que o paciente nunca os receba.
class InitialAssessment {
  const InitialAssessment({
    required this.patientId,
    this.basics,
    this.intake,
    this.clinicalIntake,
    this.lifeAreas = const [],
    this.clinicalImpressions,
  });

  final String patientId;

  /// Bloco 1 (paciente).
  final PatientBasics? basics;

  /// Bloco 2 (paciente).
  final PatientIntake? intake;

  /// Bloco 1 privado + Bloco 2 clínico (staff-only).
  final ClinicalIntake? clinicalIntake;

  /// Bloco 3 — sempre as 9 áreas na ordem canônica (mescladas com o que já
  /// foi avaliado). Áreas ainda não avaliadas vêm com `score == null`.
  final List<LifeAreaAssessment> lifeAreas;

  /// Bloco 4 (staff-only).
  final ClinicalImpressions? clinicalImpressions;

  /// Recupera a avaliação de uma área específica.
  LifeAreaAssessment lifeAreaFor(LifeArea area) {
    return lifeAreas.firstWhere(
      (a) => a.area == area,
      orElse: () => LifeAreaAssessment(area: area),
    );
  }

  int get ratedAreasCount => lifeAreas.where((a) => a.hasRating).length;

  /// Garante as 9 áreas na ordem canônica, preenchendo lacunas com áreas
  /// vazias. Útil para renderizar o Mapa da Vida sempre completo.
  static List<LifeAreaAssessment> mergeAllAreas(
    List<LifeAreaAssessment> existing,
  ) {
    final byArea = {for (final a in existing) a.area: a};
    return [
      for (final area in kLifeAreasInOrder)
        byArea[area] ?? LifeAreaAssessment(area: area),
    ];
  }
}
