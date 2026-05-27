import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/user_profile.dart';

/// Apenas leitura do próprio profile (RLS).
class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  Future<UserProfile> fetchCurrentProfile() async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        throw AppException(
          code: AppExceptionCodes.unauthorized,
          message: 'Sessão não encontrada.',
        );
      }

      final data = await _client
          .from('profiles')
          .select('id, clinic_id, role, full_name, email, is_active')
          .eq('id', userId)
          .maybeSingle();

      if (data == null) {
        throw AppException(
          code: AppExceptionCodes.profileNotFound,
          message: 'Perfil não encontrado. Contate o administrador da clínica.',
        );
      }

      if (data['is_active'] != true) {
        throw AppException(
          code: AppExceptionCodes.unauthorized,
          message: 'Perfil inativo.',
        );
      }

      return UserProfile.fromJson(Map<String, dynamic>.from(data));
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
