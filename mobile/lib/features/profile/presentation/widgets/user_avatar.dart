import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/avatar_type.dart';
import '../../domain/profile_role.dart';
import '../../domain/user_profile.dart';
import 'avatar_artwork.dart';

/// Avatar do usuário autenticado.
///
/// Resolve a fonte por [UserProfile.effectiveAvatarType], que já degrada para
/// iniciais quando a foto ou a configuração não estão disponíveis. Qualquer
/// falha de carregamento também cai nas iniciais — o usuário nunca vê ícone de
/// imagem quebrada.
class UserAvatar extends StatelessWidget {
  const UserAvatar({
    super.key,
    required this.profile,
    this.size = 44,
  });

  final UserProfile profile;
  final double size;

  Color get _accent {
    switch (profile.role) {
      case ProfileRole.platformAdmin:
        return AppColors.navy;
      case ProfileRole.psychologist:
        return AppColors.turquoise;
      case ProfileRole.patient:
        return AppColors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Foto de perfil de ${profile.fullName}',
      image: true,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _accent,
          boxShadow: [
            BoxShadow(
              color: _accent.withValues(alpha: 0.32),
              blurRadius: size * 0.18,
              offset: Offset(0, size * 0.07),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: _content(),
      ),
    );
  }

  Widget _content() {
    // O avatar geométrico é desenhado no cliente a partir de `avatarConfig`:
    // não há arquivo no Storage, nem rede envolvida, então também não há
    // estado de carregamento nem de erro para tratar aqui.
    if (profile.effectiveAvatarType == AvatarType.custom) {
      final config = profile.avatarConfig;
      if (config != null) return AvatarArtwork(config: config, size: size);
      return _initials();
    }

    if (profile.effectiveAvatarType == AvatarType.photo) {
      return Image.network(
        profile.photoUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _initials(),
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return Center(
            child: SizedBox(
              width: size * 0.34,
              height: size * 0.34,
              child: const CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            ),
          );
        },
      );
    }

    return _initials();
  }

  Widget _initials() {
    return Center(
      child: Text(
        profile.initials,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
          height: 1,
        ),
      ),
    );
  }
}
