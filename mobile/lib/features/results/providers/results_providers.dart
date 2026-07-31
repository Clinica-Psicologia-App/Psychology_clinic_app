import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile_role.dart';
import '../data/results_repository.dart'
    show
        ResultsRepository,
        AnswerAdjustmentInput,
        SchemaAdjustmentInput,
        ResultAdjustmentInput;
import '../domain/patient_response_summary.dart';
import '../domain/patient_result_detail.dart';
import '../domain/schema_activation.dart';

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
    return ref.read(resultsRepositoryProvider).listPatientResponses(
          arg.patientId,
          onlyReviewed: arg.role == ProfileRole.patient,
        );
  }
}

class PatientResultDetailContext {
  const PatientResultDetailContext({
    required this.role,
    required this.responseId,
  });

  final ProfileRole role;
  final String responseId;

  @override
  bool operator ==(Object other) =>
      other is PatientResultDetailContext &&
      other.role == role &&
      other.responseId == responseId;

  @override
  int get hashCode => Object.hash(role, responseId);
}

final patientResultDetailProvider =
    FutureProvider.family<PatientResultDetail?, PatientResultDetailContext>((
  ref,
  context,
) {
  return ref.read(resultsRepositoryProvider).getResponseDetail(
        context.responseId,
        requireReviewed: context.role == ProfileRole.patient,
      );
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
    List<AnswerAdjustmentInput> adjustments = const [],
    List<SchemaAdjustmentInput> schemaAdjustments = const [],
    List<ResultAdjustmentInput> resultAdjustments = const [],
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(resultsRepositoryProvider).setResponseReviewed(
            responseId: arg,
            reviewed: reviewed,
            reviewNotes: reviewNotes,
            adjustments: adjustments,
            schemaAdjustments: schemaAdjustments,
            resultAdjustments: resultAdjustments,
          );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}

// ── Schema activations (régua manual) ──────────────────────────────────────

class SchemaActivationsContext {
  const SchemaActivationsContext({
    required this.responseId,
    required this.isStaff,
  });

  final String responseId;
  final bool isStaff;

  @override
  bool operator ==(Object other) =>
      other is SchemaActivationsContext &&
      other.responseId == responseId &&
      other.isStaff == isStaff;

  @override
  int get hashCode => Object.hash(responseId, isStaff);
}

final schemaActivationsProvider =
    FutureProvider.family<List<SchemaActivation>, SchemaActivationsContext>(
        (ref, ctx) {
  return ref.read(resultsRepositoryProvider).listSchemaActivations(
        ctx.responseId,
        includeObservation: ctx.isStaff,
      );
});

final manageSchemaActivationProvider =
    AsyncNotifierProvider.family<ManageSchemaActivationNotifier, void, String>(
  ManageSchemaActivationNotifier.new,
);

class ManageSchemaActivationNotifier extends FamilyAsyncNotifier<void, String> {
  @override
  Future<void> build(String responseId) async {}

  Future<void> activate(
    String schemaCode,
    String schemaName, {
    String? observation,
  }) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(resultsRepositoryProvider).saveSchemaActivation(
            responseId: arg,
            schemaCode: schemaCode,
            schemaName: schemaName,
            psiObservation: observation,
          );
      ref.invalidate(
        schemaActivationsProvider(
          SchemaActivationsContext(responseId: arg, isStaff: true),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  Future<void> deactivate(String schemaCode) async {
    state = const AsyncValue.loading();
    try {
      await ref.read(resultsRepositoryProvider).deleteSchemaActivation(
            responseId: arg,
            schemaCode: schemaCode,
          );
      ref.invalidate(
        schemaActivationsProvider(
          SchemaActivationsContext(responseId: arg, isStaff: true),
        ),
      );
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
