import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/professional_onboarding_repository.dart';
import '../domain/create_professional_account_request.dart';

final professionalOnboardingRepositoryProvider =
    Provider<ProfessionalOnboardingRepository>((ref) {
  return ProfessionalOnboardingRepository();
});

final createProfessionalAccountProvider =
    AsyncNotifierProvider<CreateProfessionalAccountNotifier, void>(
  CreateProfessionalAccountNotifier.new,
);

class CreateProfessionalAccountNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<void> submit(CreateProfessionalAccountRequest request) async {
    state = const AsyncValue.loading();
    try {
      await ref
          .read(professionalOnboardingRepositoryProvider)
          .createProfessionalAccount(request);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }
}
