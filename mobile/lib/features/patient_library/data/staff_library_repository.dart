import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/library_work_full.dart';

class StaffLibraryRepository {
  StaffLibraryRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  // Lista leve (sem as camadas JSONB) para navegação do catálogo.
  static const _listSelect = '''
id, ficha_number, display_title, original_title, work_type, is_animation,
year, genres, duration, seasons, rating, synopsis, primary_schema, domain,
associated_schemas, themes, intensity, cover_url
''';

  Future<List<LibraryWorkFull>> listWorks({
    String? schema,
    String? query,
  }) async {
    try {
      var q = _client
          .from('library_works')
          .select(_listSelect)
          .eq('is_published', true);

      if (schema != null && schema.trim().isNotEmpty) {
        // Esquema principal OU associado (array contém).
        q = q.or('primary_schema.eq.$schema,associated_schemas.cs.{"$schema"}');
      }
      if (query != null && query.trim().isNotEmpty) {
        final term = query.trim();
        q = q.or('display_title.ilike.%$term%,original_title.ilike.%$term%');
      }

      final rows = await q.order('display_title');
      return (rows as List)
          .map((r) => LibraryWorkFull.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Detalhe completo (inclui as duas camadas).
  Future<LibraryWorkFull?> getWork(String id) async {
    try {
      final row = await _client
          .from('library_works')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return LibraryWorkFull.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Esquemas distintos presentes no catálogo (para os filtros).
  Future<List<String>> listSchemas() async {
    try {
      final rows = await _client
          .from('library_works')
          .select('primary_schema')
          .eq('is_published', true);
      final set = <String>{};
      for (final r in rows as List) {
        final s = (r as Map)['primary_schema'] as String?;
        if (s != null && s.trim().isNotEmpty) set.add(s.trim());
      }
      final list = set.toList()..sort();
      return list;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Indica a obra ao paciente (RPC staff-only).
  Future<void> indicateWork({
    required String patientId,
    required String workId,
    String? objective,
    String? scope,
  }) async {
    try {
      await _client.rpc('indicate_library_work', params: {
        'p_patient_id': patientId,
        'p_work_id': workId,
        'p_objective': objective,
        'p_scope': scope,
      });
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}
