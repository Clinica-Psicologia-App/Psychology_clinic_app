import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../notifications/notification_service.dart';
import '../notifications/push_token_repository.dart';
import '../../features/auth/providers/auth_providers.dart';

final pushTokenRepositoryProvider = Provider<PushTokenRepository>(
  (_) => PushTokenRepository(),
);

/// Sincroniza o token FCM com o Supabase sempre que o usuário fizer login.
/// Cancela (deleteToken) ao fazer logout.
final pushTokenSyncProvider = Provider<void>((ref) {
  final authValue = ref.watch(authControllerProvider);
  final repo = ref.read(pushTokenRepositoryProvider);

  authValue.whenData((profile) async {
    if (profile == null) return;

    // Registra o token atual.
    final token = await NotificationService.getToken();
    if (token != null) {
      await repo.upsertToken(token);
    }

    // Escuta renovações de token.
    ref.listen<void>(
      Provider<void>((innerRef) {
        NotificationService.tokenStream.listen((newToken) {
          repo.upsertToken(newToken);
        });
      }),
      (_, __) {},
    );
  });
});
