import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_providers.dart';
import '../data/patient_history_repository.dart';
import '../domain/life_chapter.dart';
import '../domain/patient_history.dart';
import '../domain/timeline_belief.dart';
import 'initial_assessment_providers.dart'
    show InitialAssessmentContext, filledByRoleFor;

export 'initial_assessment_providers.dart' show InitialAssessmentContext;

final patientHistoryRepositoryProvider =
    Provider<PatientHistoryRepository>((ref) {
  return PatientHistoryRepository();
});

/// `patients.id` do paciente logado (lente do paciente na Tela 2).
/// Assiste [authSessionProvider] para invalidar o cache ao trocar de usuário.
final myHistoryPatientIdProvider = FutureProvider<String>((ref) {
  ref.watch(authSessionProvider);
  return ref
      .read(patientHistoryRepositoryProvider)
      .getPatientIdForCurrentProfile();
});

/// Leitura da Tela 2 para um paciente. A lente é definida pela RLS.
final patientHistoryProvider =
    FutureProvider.family<PatientHistory, InitialAssessmentContext>((ref, ctx) {
  return ref.read(patientHistoryRepositoryProvider).load(ctx.patientId);
});

/// Mutations da Tela 2. Cada método grava e invalida o cache de leitura.
final patientHistoryMutationProvider = AsyncNotifierProvider.family<
    PatientHistoryMutationNotifier, void, InitialAssessmentContext>(
  PatientHistoryMutationNotifier.new,
);

class PatientHistoryMutationNotifier
    extends FamilyAsyncNotifier<void, InitialAssessmentContext> {
  @override
  Future<void> build(InitialAssessmentContext arg) async {}

  PatientHistoryRepository get _repo =>
      ref.read(patientHistoryRepositoryProvider);

  String get _role => filledByRoleFor(arg.role);

  Future<void> _run(Future<void> Function() action) async {
    state = const AsyncValue.loading();
    try {
      await action();
      ref.invalidate(patientHistoryProvider(arg));
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> createEntry({
    required String title,
    LifeChapter? lifeChapter,
    String? description,
    int? ageAtEvent,
    int? emotionalImpact,
    List<TimelineBelief> beliefs = const [],
    String? beliefOther,
    bool isSensitive = false,
  }) {
    return _run(() => _repo.createEntry(
          patientId: arg.patientId,
          filledByRole: _role,
          title: title,
          lifeChapter: lifeChapter,
          description: description,
          ageAtEvent: ageAtEvent,
          emotionalImpact: emotionalImpact,
          beliefs: beliefs,
          beliefOther: beliefOther,
          isSensitive: isSensitive,
        ));
  }

  Future<void> updateEntry({
    required String eventId,
    required String title,
    LifeChapter? lifeChapter,
    String? description,
    int? ageAtEvent,
    int? emotionalImpact,
    List<TimelineBelief> beliefs = const [],
    String? beliefOther,
    bool isSensitive = false,
  }) {
    return _run(() => _repo.updateEntry(
          eventId: eventId,
          filledByRole: _role,
          title: title,
          lifeChapter: lifeChapter,
          description: description,
          ageAtEvent: ageAtEvent,
          emotionalImpact: emotionalImpact,
          beliefs: beliefs,
          beliefOther: beliefOther,
          isSensitive: isSensitive,
        ));
  }

  Future<void> deleteEntry(String eventId) =>
      _run(() => _repo.deleteEntry(eventId));

  Future<void> saveEntryNote({
    required String eventId,
    String? clinicalComment,
  }) {
    return _run(() => _repo.saveEntryNote(
          patientId: arg.patientId,
          eventId: eventId,
          clinicalComment: clinicalComment,
        ));
  }
}
