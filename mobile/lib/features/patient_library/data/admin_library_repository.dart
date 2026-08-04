import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/library_work_full.dart';

/// Curadoria do catálogo da Biblioteca (somente admin).
///
/// A RLS `library_works_admin_all` dá ao admin acesso total (inclusive às obras
/// despublicadas, que ficam ocultas para o psicólogo). A publicação é o
/// controle de liberação do catálogo para os psicólogos.
class AdminLibraryRepository {
  AdminLibraryRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _listSelect = '''
id, ficha_number, display_title, original_title, work_type, is_animation,
year, genres, duration, seasons, rating, synopsis, primary_schema, domain,
associated_schemas, themes, intensity, cover_url, is_published
''';

  /// Lista todas as obras (publicadas e despublicadas) para curadoria.
  Future<List<AdminLibraryWork>> listAll({String? query}) async {
    try {
      var q = _client.from('library_works').select(_listSelect);
      if (query != null && query.trim().isNotEmpty) {
        final term = query.trim();
        q = q.or('display_title.ilike.%$term%,original_title.ilike.%$term%');
      }
      final rows = await q.order('display_title');
      return (rows as List)
          .map((r) => AdminLibraryWork.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Detalhe completo (metadados + as duas camadas) para edição.
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

  /// Publica / despublica a obra (liberação para os psicólogos).
  Future<void> setPublished(String id, bool published) async {
    try {
      await _client
          .from('library_works')
          .update({'is_published': published}).eq('id', id);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Cria uma nova obra; retorna o id gerado.
  Future<String> createWork(Map<String, dynamic> values) async {
    try {
      final row = await _client
          .from('library_works')
          .insert(values)
          .select('id')
          .single();
      return (row as Map)['id'] as String;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Atualiza uma obra existente.
  Future<void> updateWork(String id, Map<String, dynamic> values) async {
    try {
      await _client.from('library_works').update(values).eq('id', id);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Remove a obra do catálogo.
  Future<void> deleteWork(String id) async {
    try {
      await _client.from('library_works').delete().eq('id', id);
    } catch (e) {
      throw mapToAppException(e);
    }
  }
}

/// Linha leve do catálogo para a lista de curadoria (inclui status de publicação).
class AdminLibraryWork {
  const AdminLibraryWork({
    required this.id,
    required this.displayTitle,
    required this.workType,
    required this.isPublished,
    this.fichaNumber,
    this.originalTitle,
    this.year,
    this.primarySchema,
    this.intensity,
    this.coverUrl,
  });

  final String id;
  final int? fichaNumber;
  final String displayTitle;
  final String? originalTitle;
  final String workType;
  final int? year;
  final String? primarySchema;
  final String? intensity;
  final String? coverUrl;
  final bool isPublished;

  factory AdminLibraryWork.fromJson(Map<String, dynamic> json) {
    return AdminLibraryWork(
      id: json['id'] as String,
      fichaNumber: (json['ficha_number'] as num?)?.toInt(),
      displayTitle: json['display_title'] as String? ?? 'Sem título',
      originalTitle: json['original_title'] as String?,
      workType: json['work_type'] as String? ?? 'Filme',
      year: (json['year'] as num?)?.toInt(),
      primarySchema: json['primary_schema'] as String?,
      intensity: json['intensity'] as String?,
      coverUrl: json['cover_url'] as String?,
      isPublished: json['is_published'] as bool? ?? true,
    );
  }
}
