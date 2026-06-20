import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../profile/domain/profile_role.dart';
import '../data/daily_monitors_repository.dart';
import '../domain/daily_monitor.dart';

final dailyMonitorsRepositoryProvider =
    Provider<DailyMonitorsRepository>((ref) => DailyMonitorsRepository());

final myPatientIdProvider = FutureProvider<String>((ref) async {
  return ref
      .read(dailyMonitorsRepositoryProvider)
      .getPatientIdForCurrentProfile();
});

final myDailyMonitorsProvider =
    AsyncNotifierProvider<MyDailyMonitorsNotifier, List<DailyMonitor>>(
  MyDailyMonitorsNotifier.new,
);

class MyDailyMonitorsNotifier extends AsyncNotifier<List<DailyMonitor>> {
  @override
  Future<List<DailyMonitor>> build() async {
    return ref.read(dailyMonitorsRepositoryProvider).listMyMonitors();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(dailyMonitorsRepositoryProvider).listMyMonitors(),
    );
  }
}

class StaffMonitorHistoryContext {
  const StaffMonitorHistoryContext({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StaffMonitorHistoryContext &&
          role == other.role &&
          patientId == other.patientId;

  @override
  int get hashCode => Object.hash(role, patientId);
}

final staffPatientMonitorsProvider =
    FutureProvider.family<List<DailyMonitor>, StaffMonitorHistoryContext>(
        (ref, ctx) {
  return ref
      .read(dailyMonitorsRepositoryProvider)
      .listForPatient(ctx.patientId);
});

final dailyMonitorDetailProvider =
    FutureProvider.family<DailyMonitor?, String>((ref, id) {
  return ref.read(dailyMonitorsRepositoryProvider).getById(id);
});
