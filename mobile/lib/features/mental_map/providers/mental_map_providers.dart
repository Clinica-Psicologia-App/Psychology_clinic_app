import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile_role.dart';
import '../data/mental_map_repository.dart';
import '../domain/mental_map_data.dart';

final mentalMapRepositoryProvider = Provider<MentalMapRepository>((ref) {
  return MentalMapRepository();
});

final myMentalMapProvider =
    AsyncNotifierProvider<MyMentalMapNotifier, MentalMapData>(
  MyMentalMapNotifier.new,
);

class MyMentalMapNotifier extends AsyncNotifier<MentalMapData> {
  @override
  Future<MentalMapData> build() async {
    return ref.read(mentalMapRepositoryProvider).loadMyMentalMap();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(mentalMapRepositoryProvider).loadMyMentalMap(),
    );
  }
}

class StaffMentalMapContext {
  const StaffMentalMapContext({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffMentalMapContext &&
          role == other.role &&
          patientId == other.patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

final staffMentalMapProvider =
    FutureProvider.family<MentalMapData, StaffMentalMapContext>(
  (ref, ctx) {
    return ref
        .read(mentalMapRepositoryProvider)
        .loadForPatient(ctx.patientId);
  },
);
