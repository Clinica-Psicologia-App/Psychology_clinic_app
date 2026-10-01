import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../supabase/supabase_bootstrap.dart';

class PushTokenRepository {
  SupabaseClient get _client => SupabaseBootstrap.client;

  Future<void> upsertToken(String token) async {
    final platform = Platform.isIOS
        ? 'ios'
        : Platform.isAndroid
            ? 'android'
            : 'web';

    await _client.from('device_tokens').upsert(
      {
        'profile_id': _client.auth.currentUser?.id,
        'token': token,
        'platform': platform,
      },
      onConflict: 'profile_id,token',
    );
  }

  Future<void> deleteToken(String token) async {
    await _client
        .from('device_tokens')
        .delete()
        .eq('token', token)
        .eq('profile_id', _client.auth.currentUser?.id ?? '');
  }
}
