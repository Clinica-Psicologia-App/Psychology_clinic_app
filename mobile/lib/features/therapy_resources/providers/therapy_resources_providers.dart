import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../mental_map/providers/mental_map_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../data/therapy_resources_repository.dart';
import '../domain/patient_resource_access.dart';
import '../domain/therapy_resource.dart';
import '../domain/therapy_resource_input.dart';
import '../domain/therapy_resource_recommendation.dart';
import '../domain/therapy_resource_recommendation_engine.dart';

final therapyResourcesRepositoryProvider =
    Provider<TherapyResourcesRepository>((ref) {
  return TherapyResourcesRepository();
});

class StaffTherapyContext {
  const StaffTherapyContext({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  bool operator ==(Object other) =>
      other is StaffTherapyContext &&
      other.role == role &&
      other.patientId == patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

final clinicResourcesProvider = FutureProvider<List<TherapyResource>>((ref) {
  return ref.read(therapyResourcesRepositoryProvider).listClinicResources();
});

final therapyResourceDetailProvider =
    FutureProvider.family<TherapyResource?, String>((ref, resourceId) {
  return ref.read(therapyResourcesRepositoryProvider).getResourceById(
        resourceId,
      );
});

final patientResourceAccessProvider =
    FutureProvider.family<List<PatientResourceAccess>, String>(
        (ref, patientId) {
  return ref
      .read(therapyResourcesRepositoryProvider)
      .listAccessForPatient(patientId);
});

final staffTherapyBundleProvider =
    FutureProvider.family<StaffTherapyBundle, StaffTherapyContext>(
        (ref, ctx) async {
  final repo = ref.read(therapyResourcesRepositoryProvider);
  final library = await repo.listClinicResources();
  final assigned = await repo.listAccessForPatient(ctx.patientId);
  return StaffTherapyBundle(library: library, assigned: assigned);
});

class StaffTherapyBundle {
  const StaffTherapyBundle({
    required this.library,
    required this.assigned,
  });

  final List<TherapyResource> library;
  final List<PatientResourceAccess> assigned;

  Set<String> get assignedResourceIds =>
      assigned.where((a) => a.isActive).map((a) => a.resourceId).toSet();
}

final staffResourceRecommendationsProvider = FutureProvider.family<
    List<TherapyResourceRecommendation>, StaffTherapyContext>(
  (ref, ctx) async {
    final bundle = await ref.watch(staffTherapyBundleProvider(ctx).future);
    final mentalMap = await ref.watch(
      staffMentalMapProvider(
        StaffMentalMapContext(role: ctx.role, patientId: ctx.patientId),
      ).future,
    );

    return buildTherapyResourceRecommendations(
      mentalMap: mentalMap,
      library: bundle.library,
      assigned: bundle.assigned,
    );
  },
);

final myReleasedResourcesProvider = AsyncNotifierProvider<
    MyReleasedResourcesNotifier, List<PatientResourceAccess>>(
  MyReleasedResourcesNotifier.new,
);

class MyReleasedResourcesNotifier
    extends AsyncNotifier<List<PatientResourceAccess>> {
  @override
  Future<List<PatientResourceAccess>> build() => _load();

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_load);
  }

  Future<List<PatientResourceAccess>> _load() {
    return ref
        .read(therapyResourcesRepositoryProvider)
        .listMyReleasedResources();
  }
}

final resourceAccessDetailProvider =
    FutureProvider.family<PatientResourceAccess?, String>((ref, accessId) {
  return ref.read(therapyResourcesRepositoryProvider).getAccessById(accessId);
});

final assignResourceProvider = AsyncNotifierProvider.family<
    AssignResourceNotifier, void, AssignResourceArgs>(
  AssignResourceNotifier.new,
);

class AssignResourceArgs {
  const AssignResourceArgs({
    required this.role,
    required this.patientId,
    required this.resourceId,
  });

  final ProfileRole role;
  final String patientId;
  final String resourceId;

  @override
  bool operator ==(Object other) =>
      other is AssignResourceArgs &&
      other.role == role &&
      other.patientId == patientId &&
      other.resourceId == resourceId;

  @override
  int get hashCode => Object.hash(role, patientId, resourceId);
}

final therapyResourceFormProvider = AsyncNotifierProvider.family<
    TherapyResourceFormNotifier, void, TherapyResourceFormArgs>(
  TherapyResourceFormNotifier.new,
);

class TherapyResourceFormArgs {
  const TherapyResourceFormArgs({
    required this.role,
    required this.patientId,
    this.resourceId,
  });

  final ProfileRole role;
  final String patientId;
  final String? resourceId;

  @override
  bool operator ==(Object other) =>
      other is TherapyResourceFormArgs &&
      other.role == role &&
      other.patientId == patientId &&
      other.resourceId == resourceId;

  @override
  int get hashCode => Object.hash(role, patientId, resourceId);
}

class TherapyResourceFormNotifier
    extends FamilyAsyncNotifier<void, TherapyResourceFormArgs> {
  @override
  Future<void> build(TherapyResourceFormArgs arg) async {}

  Future<TherapyResource> save(TherapyResourceInput input) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(therapyResourcesRepositoryProvider);
      final saved = arg.resourceId == null
          ? await repo.createResource(input)
          : await repo.updateResource(
              resourceId: arg.resourceId!,
              input: input,
            );

      state = const AsyncValue.data(null);
      _invalidateResourceCaches(saved.id);
      return saved;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void _invalidateResourceCaches(String resourceId) {
    ref.invalidate(clinicResourcesProvider);
    ref.invalidate(therapyResourceDetailProvider(resourceId));
    ref.invalidate(patientResourceAccessProvider(arg.patientId));
    ref.invalidate(
      staffTherapyBundleProvider(
        StaffTherapyContext(role: arg.role, patientId: arg.patientId),
      ),
    );
    ref.invalidate(
      staffResourceRecommendationsProvider(
        StaffTherapyContext(role: arg.role, patientId: arg.patientId),
      ),
    );
  }
}

class AssignResourceNotifier
    extends FamilyAsyncNotifier<void, AssignResourceArgs> {
  @override
  Future<void> build(AssignResourceArgs arg) async {}

  Future<PatientResourceAccess> assign() async {
    state = const AsyncValue.loading();
    try {
      final access =
          await ref.read(therapyResourcesRepositoryProvider).assignResource(
                patientId: arg.patientId,
                resourceId: arg.resourceId,
              );
      state = const AsyncValue.data(null);
      ref.invalidate(patientResourceAccessProvider(arg.patientId));
      ref.invalidate(
        staffTherapyBundleProvider(
          StaffTherapyContext(role: arg.role, patientId: arg.patientId),
        ),
      );
      return access;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
