import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/error_mapper.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/psychoeducation_module.dart';

/// Curadoria dos módulos de psicoeducação (somente admin).
class AdminPsychoeducationRepository {
  AdminPsychoeducationRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  /// Lista todos os módulos (publicados e ocultos) para curadoria.
  Future<List<AdminPsychoModule>> listAll() async {
    try {
      final rows = await _client
          .from('psychoeducation_modules')
          .select('id, number, stage, title, cards, is_published')
          .order('number');
      return (rows as List)
          .map((r) => AdminPsychoModule.fromJson(Map<String, dynamic>.from(r)))
          .toList();
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Módulo completo (inclui texto do terapeuta nos cards) para edição.
  Future<PsychoeducationModule?> getModule(String id) async {
    try {
      final row = await _client
          .from('psychoeducation_modules')
          .select()
          .eq('id', id)
          .maybeSingle();
      if (row == null) return null;
      return PsychoeducationModule.fromJson(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> setPublished(String id, bool published) async {
    try {
      await _client
          .from('psychoeducation_modules')
          .update({'is_published': published}).eq('id', id);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<String> createModule(Map<String, dynamic> values) async {
    try {
      final row = await _client
          .from('psychoeducation_modules')
          .insert(values)
          .select('id')
          .single();
      return (row as Map)['id'] as String;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> updateModule(String id, Map<String, dynamic> values) async {
    try {
      await _client.from('psychoeducation_modules').update(values).eq('id', id);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> deleteModule(String id) async {
    try {
      await _client.from('psychoeducation_modules').delete().eq('id', id);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  // Reaproveita o bucket público da Biblioteca, com prefixo próprio.
  static const _coversBucket = 'library-covers';
  static const _coverExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  /// Envia a capa de um módulo e devolve a URL pública.
  Future<String> uploadCover({
    required String baseName,
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final ext = _extensionOf(fileName);
      final objectPath = 'psychoeducation/$baseName.$ext';
      await _client.storage.from(_coversBucket).uploadBinary(
            objectPath,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: _mimeFor(ext)),
          );
      final url = _client.storage.from(_coversBucket).getPublicUrl(objectPath);
      return '$url?v=${DateTime.now().millisecondsSinceEpoch}';
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  String _extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final ext =
        dot == -1 ? '' : fileName.substring(dot + 1).toLowerCase().trim();
    if (!_coverExtensions.contains(ext)) {
      throw AppException(
        code: AppExceptionCodes.validation,
        message: 'Formato não suportado. Use JPG, PNG ou WEBP.',
      );
    }
    return ext;
  }

  String _mimeFor(String ext) => switch (ext) {
        'png' => 'image/png',
        'webp' => 'image/webp',
        _ => 'image/jpeg',
      };
}

/// Linha leve para a lista de curadoria (inclui status de publicação).
class AdminPsychoModule {
  const AdminPsychoModule({
    required this.id,
    required this.number,
    required this.stage,
    required this.title,
    required this.cardCount,
    required this.isPublished,
  });

  final String id;
  final int number;
  final String stage;
  final String title;
  final int cardCount;
  final bool isPublished;

  factory AdminPsychoModule.fromJson(Map<String, dynamic> json) {
    final cards = json['cards'];
    return AdminPsychoModule(
      id: json['id'] as String,
      number: (json['number'] as num?)?.toInt() ?? 0,
      stage: json['stage'] as String? ?? 'Compreender',
      title: json['title'] as String? ?? 'Sem título',
      cardCount: cards is List ? cards.length : 0,
      isPublished: json['is_published'] as bool? ?? true,
    );
  }
}
