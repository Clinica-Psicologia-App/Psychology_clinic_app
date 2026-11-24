import 'dart:typed_data';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';

/// Logo que a psicóloga usa nos documentos (PDF/Word da conceituação).
///
/// Vive no bucket PRIVADO `document-logos`, só do dono. Esta classe sempre
/// age sobre `auth.uid()` da sessão atual: a exportação usa a logo de quem
/// exporta, nunca a de outra psicóloga (e o banco também barra a leitura).
/// Sem logo (ou falha ao baixar) devolve null e o app usa a logo padrão do
/// EsquemaCore.
class DocumentLogoRepository {
  DocumentLogoRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const bucket = 'document-logos';
  static const allowedExtensions = {'png', 'jpg', 'jpeg', 'webp'};

  /// 2 MB, igual ao limite do bucket.
  static const maxBytes = 2 * 1024 * 1024;

  /// Path montado sempre aqui (nunca aceito da UI) e igual ao regex das
  /// policies de Storage e da CHECK de `profiles.document_logo_path`.
  @visibleForTesting
  static String pathFor(String userId, String extension) =>
      '$userId/logo.$extension';

  /// Extensão válida a partir do nome do arquivo; null se não for imagem aceita.
  @visibleForTesting
  static String? extensionOf(String fileName) {
    final dot = fileName.lastIndexOf('.');
    if (dot == -1 || dot == fileName.length - 1) return null;
    final ext = fileName.substring(dot + 1).toLowerCase();
    return allowedExtensions.contains(ext) ? ext : null;
  }

  static String _mimeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String get _requireUserId {
    final id = _client.auth.currentUser?.id;
    if (id == null) {
      throw AppException(
        code: AppExceptionCodes.unauthorized,
        message: 'Sessão não encontrada.',
      );
    }
    return id;
  }

  Future<String?> _currentPath(String userId) async {
    final row = await _client
        .from('profiles')
        .select('document_logo_path')
        .eq('id', userId)
        .maybeSingle();
    final path = row?['document_logo_path'] as String?;
    // Só aceita path da própria pasta, mesmo que o banco devolva outra coisa.
    if (path == null || !path.startsWith('$userId/')) return null;
    return path;
  }

  /// Logo da usuária logada, por download autenticado. Null = usar a padrão.
  Future<Uint8List?> downloadOwn() async {
    try {
      final userId = _requireUserId;
      final path = await _currentPath(userId);
      if (path == null) return null;
      return await _client.storage.from(bucket).download(path);
    } catch (_) {
      return null; // exportar nunca falha por causa da logo
    }
  }

  /// Envia a logo e grava o path no perfil. Remove arquivos de outra extensão
  /// da própria pasta para não deixar órfãos.
  Future<void> upload({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final userId = _requireUserId;
      final ext = extensionOf(fileName);
      if (ext == null) {
        throw AppException(
          code: AppExceptionCodes.validation,
          message: 'Use uma imagem PNG, JPG ou WebP.',
        );
      }
      if (bytes.isEmpty || bytes.length > maxBytes) {
        throw AppException(
          code: AppExceptionCodes.validation,
          message: 'A imagem deve ter até 2 MB.',
        );
      }
      final path = pathFor(userId, ext);
      await _client.storage.from(bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(upsert: true, contentType: _mimeFor(ext)),
          );
      await _client
          .from('profiles')
          .update({'document_logo_path': path}).eq('id', userId);
      await _removeOtherExtensions(userId, keep: path);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Volta à logo padrão: limpa o perfil primeiro e depois apaga o arquivo.
  Future<void> remove() async {
    try {
      final userId = _requireUserId;
      await _client
          .from('profiles')
          .update({'document_logo_path': null}).eq('id', userId);
      await _removeOtherExtensions(userId, keep: null);
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  Future<void> _removeOtherExtensions(String userId, {String? keep}) async {
    try {
      final paths = [
        for (final ext in allowedExtensions) pathFor(userId, ext),
      ]..remove(keep);
      await _client.storage.from(bucket).remove(paths);
    } catch (_) {
      // limpeza best-effort; não desfaz o que já foi gravado
    }
  }
}
