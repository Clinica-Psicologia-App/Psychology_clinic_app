import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile_role.dart';
import '../data/results_repository.dart';
import '../domain/patient_response_summary.dart';
import '../domain/patient_result_detail.dart';

final resultsRepositoryProvider = Provider<ResultsRepository>((ref) {
  return ResultsRepository();
});

class PatientResultsContext {
  const PatientResultsContext({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  bool operator ==(Object other) =>
      other is PatientResultsContext &&
      other.role == role &&
      other.patientId == patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

final patientResultsListProvider = AsyncNotifierProvider.family<
    PatientResultsListNotifier,
    List<PatientResponseSummary>,
    PatientResultsContext>(PatientResultsListNotifier.new);

class PatientResultsListNotifier extends FamilyAsyncNotifier<
    List<PatientResponseSummary>, PatientResultsContext> {
  @override
  Future<List<PatientResponseSummary>> build(PatientResultsContext arg) =>
      _load();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<PatientResponseSummary>> _load() {
    return ref
        .read(resultsRepositoryProvider)
        .listPatientResponses(arg.patientId);
  }
}

final patientResultDetailProvider =
    FutureProvider.family<PatientResultDetail?, String>((ref, responseId) {
  return ref.read(resultsRepositoryProvider).getResponseDetail(responseId);
});

final reviewQuestionnaireResponseProvider = AsyncNotifierProvider.family<
    ReviewQuestionnaireResponseNotifier, void, String>(
  ReviewQuestionnaireResponseNotifier.new,
);

class ReviewQuestionnaireResponseNotifier
    extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String arg) async {}

  Future<void> submit({
    required bool reviewed,
    String? reviewNotes,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(resultsRepositoryProvider).setResponseReviewed(
            responseId: arg,
            reviewed: reviewed,
            reviewNotes: reviewNotes,
          );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
