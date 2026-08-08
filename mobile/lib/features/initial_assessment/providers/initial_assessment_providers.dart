import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../data/initial_assessment_repository.dart';
import '../domain/assessment_catalog_item.dart';
import '../domain/functioning_level.dart';
import '../domain/initial_assessment.dart';
import '../domain/life_area.dart';
import '../domain/life_area_assessment.dart';

final initialAssessmentRepositoryProvider =
    Provider<InitialAssessmentRepository>((ref) {
  return InitialAssessmentRepository();
});

/// `patients.id` do paciente logado (para a lente do paciente resolver a si).
/// Assiste [authSessionProvider] para que o cache seja invalidado ao trocar de
/// usuário — sem isso, dados de um paciente anterior vazam para a próxima sessão.
final myAssessmentPatientIdProvider = FutureProvider<String>((ref) {
  ref.watch(authSessionProvider);
  return ref
      .read(initialAssessmentRepositoryProvider)
      .getPatientIdForCurrentProfile();
});

/// `filled_by_role` correspondente ao papel do usuário logado.
String filledByRoleFor(ProfileRole role) => switch (role) {
      ProfileRole.patient => 'patient',
      ProfileRole.psychologist => 'psychologist',
      ProfileRole.platformAdmin => 'admin',
    };

/// Contexto de uma avaliação: papel do solicitante + paciente alvo.
class InitialAssessmentContext {
  const InitialAssessmentContext({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  bool operator ==(Object other) =>
      other is InitialAssessmentContext &&
      other.role == role &&
      other.patientId == patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

/// Leitura da Tela 1 para um paciente. A lente é definida pela RLS.
final initialAssessmentProvider =
    FutureProvider.family<InitialAssessment, InitialAssessmentContext>(
        (ref, ctx) {
  return ref.read(initialAssessmentRepositoryProvider).load(ctx.patientId);
});

/// Catálogo de esquemas (YSQ) e modos (YAMI) para os checklists do Bloco 4.
final schemaModeCatalogProvider = FutureProvider<
    ({
      List<AssessmentCatalogItem> schemas,
      List<AssessmentCatalogItem> modes,
    })>((ref) {
  return ref
      .read(initialAssessmentRepositoryProvider)
      .loadSchemaAndModeCatalog();
});

/// Catálogo das necessidades emocionais centrais.
final emotionalNeedsCatalogProvider =
    FutureProvider<List<AssessmentCatalogItem>>((ref) {
  return ref.read(initialAssessmentRepositoryProvider).loadEmotionalNeeds();
});

/// Mutations da Tela 1. Cada método grava e invalida o cache de leitura.
final initialAssessmentMutationProvider = AsyncNotifierProvider.family<
    InitialAssessmentMutationNotifier, void, InitialAssessmentContext>(
  InitialAssessmentMutationNotifier.new,
);

class InitialAssessmentMutationNotifier
    extends FamilyAsyncNotifier<void, InitialAssessmentContext> {
  @override
  Future<void> build(InitialAssessmentContext arg) async {}

  InitialAssessmentRepository get _repo =>
      ref.read(initialAssessmentRepositoryProvider);

  String get _role => filledByRoleFor(arg.role);

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
      ref.invalidate(initialAssessmentProvider(arg));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  // ── Lente do paciente ──────────────────────────────────────────────────
  Future<void> savePatientBasics({
    String? preferredName,
    DateTime? birthDate,
    String? occupation,
    String? livesWith,
    bool? hasChildren,
    bool? usesMedication,
    String? medicationNotes,
    bool? psychiatricFollowup,
    String? psychiatristNotes,
    String? importantToKnow,
  }) {
    return _run(() => _repo.savePatientBasics(
          patientId: arg.patientId,
          preferredName: preferredName,
          birthDate: birthDate,
          occupation: occupation,
          livesWith: livesWith,
          hasChildren: hasChildren,
          usesMedication: usesMedication,
          medicationNotes: medicationNotes,
          psychiatricFollowup: psychiatricFollowup,
          psychiatristNotes: psychiatristNotes,
          importantToKnow: importantToKnow,
        ));
  }

  Future<void> saveIntake({
    String? reasonForSeeking,
    String? problemDuration,
    String? mainDiscomfort,
    String? expectations,
    String? relatedEvent,
    bool markCompleted = false,
  }) {
    return _run(() => _repo.saveIntake(
          patientId: arg.patientId,
          filledByRole: _role,
          reasonForSeeking: reasonForSeeking,
          problemDuration: problemDuration,
          mainDiscomfort: mainDiscomfort,
          expectations: expectations,
          relatedEvent: relatedEvent,
          markCompleted: markCompleted,
        ));
  }

  Future<void> saveLifeArea({
    required LifeArea area,
    int? score,
    int? suffering,
    String? guidedAnswer,
  }) {
    return _run(() => _repo.saveLifeArea(
          patientId: arg.patientId,
          filledByRole: _role,
          area: area,
          score: score,
          suffering: suffering,
          guidedAnswer: guidedAnswer,
        ));
  }

  Future<void> saveLifeAreas(List<LifeAreaAssessment> areas) {
    return _run(() => _repo.saveLifeAreasBulk(
          patientId: arg.patientId,
          filledByRole: _role,
          areas: areas,
        ));
  }

  // ── Lente do terapeuta (staff-only) ────────────────────────────────────
  Future<void> saveClinicalIntake({
    String? initialObservations,
    String? mainComplaint,
    String? currentProblem,
    String? precipitatingFactors,
    String? patientGoals,
    String? motivation,
    String? initialHypotheses,
  }) {
    return _run(() => _repo.saveClinicalIntake(
          patientId: arg.patientId,
          initialObservations: initialObservations,
          mainComplaint: mainComplaint,
          currentProblem: currentProblem,
          precipitatingFactors: precipitatingFactors,
          patientGoals: patientGoals,
          motivation: motivation,
          initialHypotheses: initialHypotheses,
        ));
  }

  Future<void> saveLifeAreaNote({
    required LifeArea area,
    String? clinicalComment,
  }) {
    return _run(() => _repo.saveLifeAreaNote(
          patientId: arg.patientId,
          area: area,
          clinicalComment: clinicalComment,
        ));
  }

  Future<void> saveClinicalImpressions({
    String? observedTemperament,
    String? therapeuticBond,
    String? resources,
    String? vulnerabilities,
    String? hypotheses,
    String? previousDiagnoses,
    String? differentialDiagnosis,
    FunctioningLevel? functioningLevel,
    String? therapeuticPriorities,
  }) {
    return _run(() => _repo.saveClinicalImpressions(
          patientId: arg.patientId,
          observedTemperament: observedTemperament,
          therapeuticBond: therapeuticBond,
          resources: resources,
          vulnerabilities: vulnerabilities,
          hypotheses: hypotheses,
          previousDiagnoses: previousDiagnoses,
          differentialDiagnosis: differentialDiagnosis,
          functioningLevel: functioningLevel,
          therapeuticPriorities: therapeuticPriorities,
        ));
  }

  Future<void> setSchemaHypotheses(List<String> ids) =>
      _run(() => _repo.setSchemaHypotheses(arg.patientId, ids));

  Future<void> setModeHypotheses(List<String> ids) =>
      _run(() => _repo.setModeHypotheses(arg.patientId, ids));

  Future<void> setEmotionalNeeds(List<String> ids) =>
      _run(() => _repo.setEmotionalNeeds(arg.patientId, ids));
}
