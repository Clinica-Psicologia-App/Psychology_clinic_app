import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile_role.dart';
import '../data/genogram_repository.dart';
import '../domain/genogram_data.dart';
import '../domain/genogram_person.dart';
import '../domain/genogram_relationship.dart';

final genogramRepositoryProvider = Provider<GenogramRepository>((ref) {
  return GenogramRepository();
});

final myGenogramProvider =
    AsyncNotifierProvider<MyGenogramNotifier, GenogramData>(
  MyGenogramNotifier.new,
);

class MyGenogramNotifier extends AsyncNotifier<GenogramData> {
  @override
  Future<GenogramData> build() async {
    return ref.read(genogramRepositoryProvider).loadMyGenogram();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(genogramRepositoryProvider).loadMyGenogram(),
    );
  }
}

class StaffGenogramContext {
  const StaffGenogramContext({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffGenogramContext &&
          role == other.role &&
          patientId == other.patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

final staffGenogramProvider =
    FutureProvider.family<GenogramData, StaffGenogramContext>(
  (ref, ctx) {
    return ref.read(genogramRepositoryProvider).loadForPatient(ctx.patientId);
  },
);

final genogramPersonDetailProvider =
    FutureProvider.family<GenogramPerson?, String>((ref, id) {
  return ref.read(genogramRepositoryProvider).getPersonById(id);
});

final genogramRelationshipDetailProvider =
    FutureProvider.family<GenogramRelationship?, String>((ref, id) {
  return ref.read(genogramRepositoryProvider).getRelationshipById(id);
});
