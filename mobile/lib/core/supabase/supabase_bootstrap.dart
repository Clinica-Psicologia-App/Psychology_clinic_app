import 'package:supabase_flutter/supabase_flutter.dart';

import '../config/env_config.dart';

abstract final class SupabaseBootstrap {
  static Future<void> initialize() async {
    EnvConfig.validate();
    await Supabase.initialize(
      url: EnvConfig.supabaseUrl,
      anonKey: EnvConfig.supabaseAnonKey,
      authOptions: const FlutterAuthClientOptions(
        authFlowType: AuthFlowType.pkce,
      ),
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
