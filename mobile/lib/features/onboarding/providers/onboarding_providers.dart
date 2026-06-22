import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/onboarding_store.dart';

final onboardingStoreProvider = Provider<OnboardingStore>((ref) {
  return const OnboardingStore();
});

/// Estado do onboarding: `AsyncLoading` enquanto lê o disco, depois
/// `AsyncData(true|false)` indicando se já foi visto.
final onboardingSeenProvider =
    StateNotifierProvider<OnboardingController, AsyncValue<bool>>((ref) {
  return OnboardingController(ref.read(onboardingStoreProvider))..load();
});

class OnboardingController extends StateNotifier<AsyncValue<bool>> {
  OnboardingController(this._store) : super(const AsyncValue.loading());

  final OnboardingStore _store;

  Future<void> load() async {
    final seen = await _store.hasSeen();
    if (mounted) state = AsyncValue.data(seen);
  }

  Future<void> markSeen() async {
    await _store.markSeen();
    if (mounted) state = const AsyncValue.data(true);
  }
}
