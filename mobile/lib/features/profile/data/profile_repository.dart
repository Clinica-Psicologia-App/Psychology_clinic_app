import 'dart:typed_data';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/supabase/supabase_bootstrap.dart';
import '../domain/avatar_config.dart';
import '../domain/avatar_type.dart';
import '../domain/user_profile.dart';

/// Leitura e edição do próprio profile (RLS restringe à linha do usuário).
class ProfileRepository {
  ProfileRepository({SupabaseClient? client})
      : _client = client ?? SupabaseBootstrap.client;

  final SupabaseClient _client;

  static const _avatarBucket = 'avatars';

  /// Extensões aceitas pelo bucket e pela policy de Storage.
  static const _allowedExtensions = {'jpg', 'jpeg', 'png', 'webp'};

  static const _profileSelect = '''
id, clinic_id, role, full_name, email, phone, is_active, created_at,
avatar_type, avatar_path, avatar_url, avatar_config, avatar_updated_at
''';

  String get _requireUserId {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw AppException(
        code: AppExceptionCodes.unauthorized,
        message: 'Sessão não encontrada.',
      );
    }
    return userId;
  }

  /// Path da foto no bucket. Montado sempre aqui — nunca aceito da UI — e
  /// casando exatamente com o regex da policy de Storage.
  String _photoPathFor(String userId, String extension) =>
      '$userId/profile/photo.$extension';

  UserProfile _mapProfile(Map<String, dynamic> row) {
    return UserProfile.fromJson(
      row,
      publicUrlOf: (path) =>
          _client.storage.from(_avatarBucket).getPublicUrl(path),
    );
  }

  Future<UserProfile> fetchCurrentProfile() async {
    try {
      final userId = _requireUserId;

      final data = await _client
          .from('profiles')
          .select(_profileSelect)
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

      return _mapProfile(Map<String, dynamic>.from(data));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Atualiza os campos que o próprio usuário pode editar.
  /// `role`, `clinic_id` e `is_active` são bloqueados por trigger no banco.
  Future<UserProfile> updateOwnProfile({
    String? fullName,
    String? phone,
  }) async {
    try {
      final userId = _requireUserId;
      final payload = <String, dynamic>{};

      final name = _normalizeName(fullName);
      if (name != null) payload['full_name'] = name;

      if (phone != null) {
        final trimmed = phone.trim();
        payload['phone'] = trimmed.isEmpty ? null : trimmed;
      }

      if (payload.isEmpty) return fetchCurrentProfile();

      final row = await _client
          .from('profiles')
          .update(payload)
          .eq('id', userId)
          .select(_profileSelect)
          .single();

      return _mapProfile(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Envia a foto e ativa `avatar_type = photo`.
  ///
  /// Recebe bytes (e não `File`) para funcionar também no Flutter Web.
  /// O upload acontece antes da escrita no banco: se o banco falhar, o perfil
  /// segue apontando para a imagem anterior e o arquivo novo fica sobrescrito
  /// no mesmo path — sem estado parcial visível para o usuário.
  Future<UserProfile> uploadPhoto({
    required Uint8List bytes,
    required String fileName,
  }) async {
    try {
      final userId = _requireUserId;
      final ext = _extensionOf(fileName);
      final path = _photoPathFor(userId, ext);

      await _client.storage.from(_avatarBucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              upsert: true,
              contentType: _mimeTypeFor(ext),
            ),
          );

      // O carimbo vai explícito, e não pela trigger: ao trocar de foto pela
      // segunda vez, `avatar_type` e `avatar_path` chegam com os mesmos
      // valores que já estavam na linha (o path é fixo e o upload é upsert),
      // então a trigger — que só dispara quando algum valor muda — não vê
      // diferença alguma. Sem carimbo novo a URL fica idêntica e o usuário
      // continua vendo a foto antiga vinda do cache. Só o app sabe que os
      // bytes mudaram, então é o app que precisa marcar a versão.
      final row = await _client
          .from('profiles')
          .update({
            'avatar_type': AvatarType.photo.key,
            'avatar_path': path,
            'avatar_updated_at': DateTime.now().toUtc().toIso8601String(),
          })
          .eq('id', userId)
          .select(_profileSelect)
          .single();

      return _mapProfile(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Salva a configuração do avatar geométrico e o ativa.
  /// Não toca no Storage: o avatar é desenhado no cliente a partir da config,
  /// então trocar entre foto e avatar não apaga a foto guardada.
  Future<UserProfile> saveAvatarConfig(AvatarConfig config) async {
    try {
      final userId = _requireUserId;

      final row = await _client
          .from('profiles')
          .update({
            'avatar_type': AvatarType.custom.key,
            'avatar_config': config.toJson(),
          })
          .eq('id', userId)
          .select(_profileSelect)
          .single();

      return _mapProfile(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Volta a exibir as iniciais, preservando foto e configuração para que o
  /// usuário possa reativá-las depois sem refazer nada.
  Future<UserProfile> useInitials() async {
    try {
      final userId = _requireUserId;

      final row = await _client
          .from('profiles')
          .update({'avatar_type': AvatarType.initials.key})
          .eq('id', userId)
          .select(_profileSelect)
          .single();

      return _mapProfile(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Reativa uma fonte já existente sem reenviar nada.
  Future<UserProfile> selectAvatarType(AvatarType type) async {
    if (type == AvatarType.initials) return useInitials();

    try {
      final userId = _requireUserId;

      final row = await _client
          .from('profiles')
          .update({'avatar_type': type.key})
          .eq('id', userId)
          .select(_profileSelect)
          .single();

      return _mapProfile(Map<String, dynamic>.from(row));
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Apaga a foto do Storage e limpa as referências.
  ///
  /// A ordem importa: o banco é limpo primeiro, então o perfil nunca aponta
  /// para um arquivo inexistente. Se a remoção física falhar depois disso, o
  /// resultado é um arquivo órfão — invisível para o usuário e sobrescrito no
  /// próximo upload, já que o path é determinístico.
  Future<UserProfile> deletePhoto() async {
    try {
      final userId = _requireUserId;

      final row = await _client
          .from('profiles')
          .update({
            'avatar_path': null,
            'avatar_url': null,
            'avatar_type': AvatarType.initials.key,
          })
          .eq('id', userId)
          .select(_profileSelect)
          .single();

      final profile = _mapProfile(Map<String, dynamic>.from(row));

      await _removeStoredPhotos(userId);

      return profile;
    } catch (e) {
      throw mapToAppException(e);
    }
  }

  /// Limpeza best-effort. Cobre também arquivos gravados sob a convenção antiga
  /// (`{uid}/avatar.ext`), por isso lista as duas pastas.
  Future<void> _removeStoredPhotos(String userId) async {
    for (final folder in ['$userId/profile', userId]) {
      try {
        final files = await _client.storage.from(_avatarBucket).list(
              path: folder,
            );
        // Entradas sem extensão são subpastas (ex.: `profile/`), não arquivos.
        final paths = [
          for (final f in files)
            if (f.name.contains('.')) '$folder/${f.name}',
        ];
        if (paths.isNotEmpty) {
          await _client.storage.from(_avatarBucket).remove(paths);
        }
      } catch (_) {
        // Falha na limpeza não pode reverter a alteração já persistida.
      }
    }
  }

  String? _normalizeName(String? value) {
    if (value == null) return null;
    // Colapsa espaços internos sem alterar a capitalização escolhida pelo
    // usuário — nomes compostos e caracteres acentuados são preservados.
    final normalized = value.trim().replaceAll(RegExp(r'\s+'), ' ');
    return normalized.isEmpty ? null : normalized;
  }

  String _extensionOf(String path) {
    final dot = path.lastIndexOf('.');
    if (dot == -1 || dot == path.length - 1) return 'jpg';
    final ext = path.substring(dot + 1).toLowerCase();
    return _allowedExtensions.contains(ext) ? ext : 'jpg';
  }

  String _mimeTypeFor(String ext) {
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }
}
