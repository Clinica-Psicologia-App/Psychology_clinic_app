import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/patient_family_repository.dart';
import '../domain/genogram_enums.dart';
import '../domain/patient_family.dart';
import 'initial_assessment_providers.dart'
    show InitialAssessmentContext, filledByRoleFor;

export 'initial_assessment_providers.dart' show InitialAssessmentContext;

final patientFamilyRepositoryProvider =
    Provider<PatientFamilyRepository>((ref) {
  return PatientFamilyRepository();
});

/// `patients.id` do paciente logado (lente do paciente na Tela 3).
final myFamilyPatientIdProvider = FutureProvider<String>((ref) {
  return ref
      .read(patientFamilyRepositoryProvider)
      .getPatientIdForCurrentProfile();
});

/// Leitura da Tela 3 para um paciente. A lente é definida pela RLS.
final patientFamilyProvider =
    FutureProvider.family<PatientFamily, InitialAssessmentContext>((ref, ctx) {
  return ref.read(patientFamilyRepositoryProvider).load(ctx.patientId);
});

/// Mutations da Tela 3. Cada método grava e invalida o cache de leitura.
final patientFamilyMutationProvider = AsyncNotifierProvider.family<
    PatientFamilyMutationNotifier, void, InitialAssessmentContext>(
  PatientFamilyMutationNotifier.new,
);

class PatientFamilyMutationNotifier
    extends FamilyAsyncNotifier<void, InitialAssessmentContext> {
  @override
  Future<void> build(InitialAssessmentContext arg) async {}

  PatientFamilyRepository get _repo =>
      ref.read(patientFamilyRepositoryProvider);

  String get _role => filledByRoleFor(arg.role);

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
      ref.invalidate(patientFamilyProvider(arg));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> createPerson({
    required String fullName,
    String? relationshipToPatient,
    String? gender,
    int? birthYear,
    int? deathYear,
    bool isDeceased = false,
    bool? isCaregiver,
    BondQuality? bondQuality,
    int? emotionalPresence,
    List<CaregiverTrait> caregiverTraits = const [],
    String? caregiverTraitsOther,
    List<CaregiverNeed> feltNeeds = const [],
    List<CaregiverNeed> wishedNeeds = const [],
    List<LinkedEvent> linkedEvents = const [],
    String? linkedEventsOther,
  }) {
    return _run(() => _repo.createPerson(
          patientId: arg.patientId,
          filledByRole: _role,
          fullName: fullName,
          relationshipToPatient: relationshipToPatient,
          gender: gender,
          birthYear: birthYear,
          deathYear: deathYear,
          isDeceased: isDeceased,
          isCaregiver: isCaregiver,
          bondQuality: bondQuality,
          emotionalPresence: emotionalPresence,
          caregiverTraits: caregiverTraits,
          caregiverTraitsOther: caregiverTraitsOther,
          feltNeeds: feltNeeds,
          wishedNeeds: wishedNeeds,
          linkedEvents: linkedEvents,
          linkedEventsOther: linkedEventsOther,
        ));
  }

  Future<void> updatePerson({
    required String personId,
    required String fullName,
    String? relationshipToPatient,
    String? gender,
    int? birthYear,
    int? deathYear,
    bool isDeceased = false,
    bool? isCaregiver,
    BondQuality? bondQuality,
    int? emotionalPresence,
    List<CaregiverTrait> caregiverTraits = const [],
    String? caregiverTraitsOther,
    List<CaregiverNeed> feltNeeds = const [],
    List<CaregiverNeed> wishedNeeds = const [],
    List<LinkedEvent> linkedEvents = const [],
    String? linkedEventsOther,
  }) {
    return _run(() => _repo.updatePerson(
          personId: personId,
          filledByRole: _role,
          fullName: fullName,
          relationshipToPatient: relationshipToPatient,
          gender: gender,
          birthYear: birthYear,
          deathYear: deathYear,
          isDeceased: isDeceased,
          isCaregiver: isCaregiver,
          bondQuality: bondQuality,
          emotionalPresence: emotionalPresence,
          caregiverTraits: caregiverTraits,
          caregiverTraitsOther: caregiverTraitsOther,
          feltNeeds: feltNeeds,
          wishedNeeds: wishedNeeds,
          linkedEvents: linkedEvents,
          linkedEventsOther: linkedEventsOther,
        ));
  }

  Future<void> deletePerson(String personId) =>
      _run(() => _repo.deletePerson(personId));

  Future<void> saveFamilyContext({
    List<FamilyClimateTrait> familyClimate = const [],
    String? familyClimateOther,
    List<TransgenerationalPattern> patterns = const [],
    String? patternsOther,
  }) {
    return _run(() => _repo.saveFamilyContext(
          patientId: arg.patientId,
          filledByRole: _role,
          familyClimate: familyClimate,
          familyClimateOther: familyClimateOther,
          patterns: patterns,
          patternsOther: patternsOther,
        ));
  }

  Future<void> savePersonNote({
    required String personId,
    String? clinicalComment,
  }) {
    return _run(() => _repo.savePersonNote(
          patientId: arg.patientId,
          personId: personId,
          clinicalComment: clinicalComment,
        ));
  }
}
