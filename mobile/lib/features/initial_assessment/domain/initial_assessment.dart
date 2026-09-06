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

  // ── Progresso da trilha ("Conhecendo você") ─────────────────────────────
  //
  // Bloco 1: 8 campos fixos + campos condicionais (medicationNotes só conta
  // quando usesMedication=true; psychiatristNotes só quando
  // psychiatricFollowup=true). Bloco 2: 5 campos. Bloco 3: 9 áreas.
  // O total é dinâmico para não travar o progresso em pacientes que não
  // usam medicação ou não têm acompanhamento psiquiátrico.

  static const int block2FieldTotal = 5;

  /// Total aplicável ao paciente — varia conforme respostas condicionais do Bloco 1.
  int get totalFieldCount {
    var total = 8 + block2FieldTotal + 9; // 8 campos fixos do Bloco 1
    if (basics?.usesMedication == true) total++; // medicationNotes aplicável
    if (basics?.psychiatricFollowup == true) total++; // psychiatristNotes aplicável
    return total;
  }

  int get filledBlock1Count {
    final b = basics;
    if (b == null) return 0;
    var count = 0;
    if ((b.preferredName ?? '').trim().isNotEmpty) count++;
    if (b.birthDate != null) count++;
    if ((b.occupation ?? '').trim().isNotEmpty) count++;
    if ((b.livesWith ?? '').trim().isNotEmpty) count++;
    if (b.hasChildren != null) count++;
    if (b.usesMedication != null) count++;
    if (b.usesMedication == true &&
        (b.medicationNotes ?? '').trim().isNotEmpty) {
      count++;
    }
    if (b.psychiatricFollowup != null) count++;
    if (b.psychiatricFollowup == true &&
        (b.psychiatristNotes ?? '').trim().isNotEmpty) {
      count++;
    }
    if ((b.importantToKnow ?? '').trim().isNotEmpty) count++;
    return count;
  }

  int get filledBlock2Count {
    final i = intake;
    if (i == null) return 0;
    var count = 0;
    if ((i.reasonForSeeking ?? '').trim().isNotEmpty) count++;
    if ((i.problemDuration ?? '').trim().isNotEmpty) count++;
    if ((i.mainDiscomfort ?? '').trim().isNotEmpty) count++;
    if ((i.expectations ?? '').trim().isNotEmpty) count++;
    if ((i.relatedEvent ?? '').trim().isNotEmpty) count++;
    return count;
  }

  /// Fração [0.0, 1.0] de campos preenchidos nos 3 blocos do paciente —
  /// alimenta o anel de progresso do nó "Conhecendo você" na trilha.
  double get completionFraction =>
      (filledBlock1Count + filledBlock2Count + ratedAreasCount) /
      totalFieldCount;

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
