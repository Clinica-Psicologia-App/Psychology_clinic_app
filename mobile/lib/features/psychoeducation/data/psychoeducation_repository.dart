import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/psychoeducation_module.dart';

/// Acesso do PACIENTE à jornada de psicoeducação (via RPC SECURITY DEFINER que
/// remove o texto do terapeuta).
class PsychoeducationRepository {
  PsychoeducationRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  Future<List<PsychoeducationModule>> getJourney() async {
    try {
      final data = await _client.rpc('get_psychoeducation_journey');
      final list = data is List ? data : const [];
      return list
          .whereType<Map>()
          .map((m) =>
              PsychoeducationModule.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
