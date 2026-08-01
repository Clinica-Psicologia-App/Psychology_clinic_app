import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/profile_role.dart';
import '../providers/profile_providers.dart';
import 'profile_routes.dart';
import 'widgets/user_avatar.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Tela "Meu perfil" — dados do usuário autenticado, foto e acessos.
/// Compartilhada pelos três papéis (admin, psicólogo e paciente).
class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(authControllerProvider);

    return AppScaffold(
      title: 'Meu perfil',
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Não foi possível carregar o perfil.'),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () =>
                      ref.read(authControllerProvider.notifier).loadProfile(),
                  child: const Text('Tentar novamente'),
                ),
              ],
            ),
          ),
        ),
        data: (profile) {
          if (profile == null) {
            return const Center(child: Text('Perfil não carregado.'));
          }
          return _ProfileBody(profile: profile);
        },
      ),
    );
  }
}

class _ProfileBody extends ConsumerStatefulWidget {
  const _ProfileBody({required this.profile});

  final UserProfile profile;

  @override
  ConsumerState<_ProfileBody> createState() => _ProfileBodyState();
}

class _ProfileBodyState extends ConsumerState<_ProfileBody> {
  late final TextEditingController _name;
  late final TextEditingController _phone;

  bool _dirty = false;
  bool _savingDetails = false;
  bool _busyAvatar = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.fullName)
      ..addListener(_checkDirty);
    _phone = TextEditingController(text: widget.profile.phone ?? '')
      ..addListener(_checkDirty);
    _recoverLostPhoto();
  }

  /// Recupera uma foto escolhida em uma sessão que morreu no meio do caminho.
  ///
  /// No Android o sistema pode destruir a Activity enquanto o seletor de fotos
  /// está aberto (é o caso comum sob pressão de memória). Quando isso acontece,
  /// o `await pickImage(...)` nunca completa — quem esperava por ele deixou de
  /// existir —, então a foto escolhida se perde sem erro algum: nenhum upload,
  /// nenhuma mensagem, nada. O `image_picker` guarda esse resultado e exige que
  /// o app venha buscá-lo explicitamente na volta.
  ///
  /// Só existe no Android; nas demais plataformas o método não se aplica.
  Future<void> _recoverLostPhoto() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;

    try {
      final lost = await ImagePicker().retrieveLostData();
      if (lost.isEmpty || lost.file == null || !mounted) return;

      await _uploadPickedFile(lost.file!);
    } catch (e) {
      // Recuperação é oportunista: se falhar, a tela segue utilizável e o
      // usuário pode escolher a foto de novo.
      if (mounted) showErrorBanner(context, e);
    }
  }

  @override
  void didUpdateWidget(covariant _ProfileBody old) {
    super.didUpdateWidget(old);
    // O profile foi recarregado (ex.: após salvar) — ressincroniza os campos.
    if (old.profile.fullName != widget.profile.fullName ||
        old.profile.phone != widget.profile.phone) {
      _name.text = widget.profile.fullName;
      _phone.text = widget.profile.phone ?? '';
      _checkDirty();
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  void _checkDirty() {
    final changed = _name.text.trim() != widget.profile.fullName ||
        _phone.text.trim() != (widget.profile.phone ?? '');
    if (changed != _dirty) setState(() => _dirty = changed);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.profile;

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        final discard = await _confirmDiscardChanges();
        if (discard && mounted) navigator.pop();
      },
      child: _buildBody(p),
    );
  }

  Widget _buildBody(UserProfile p) {
    return MotionReveal(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _HeaderCard(
            profile: p,
            busy: _busyAvatar,
            onEditPhoto: _busyAvatar ? null : _openPhotoSheet,
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Dados pessoais',
            icon: Icons.badge_outlined,
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nome completo',
                  prefixIcon: Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Telefone',
                  hintText: 'Opcional',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              if (_dirty) ...[
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _savingDetails ? null : _saveDetails,
                        icon: _savingDetails
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Icon(Icons.check, size: 18),
                        label: Text(
                          _savingDetails ? 'Salvando...' : 'Salvar alterações',
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _savingDetails ? null : _discard,
                      child: const Text('Descartar'),
                    ),
                  ],
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          _SectionCard(
            title: 'Conta e acessos',
            icon: Icons.shield_outlined,
            children: [
              _ReadOnlyRow(
                icon: Icons.alternate_email_rounded,
                label: 'E-mail',
                value: p.email,
                hint: 'Somente o administrador pode alterar.',
              ),
              const Divider(height: 20),
              _ReadOnlyRow(
                icon: Icons.workspace_premium_outlined,
                label: 'Perfil de acesso',
                value: p.role.label,
              ),
              const Divider(height: 20),
              _ReadOnlyRow(
                icon: p.isActive
                    ? Icons.check_circle_outline
                    : Icons.cancel_outlined,
                label: 'Situação',
                value: p.isActive ? 'Ativo' : 'Inativo',
                valueColor: p.isActive ? AppColors.success : AppColors.error,
              ),
              if (p.createdAt != null) ...[
                const Divider(height: 20),
                _ReadOnlyRow(
                  icon: Icons.event_outlined,
                  label: 'Membro desde',
                  value: _formatDate(context, p.createdAt!),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          ClayCard(
            child: ListTile(
              leading: const Icon(Icons.lock_outline),
              title: const Text('Alterar senha'),
              subtitle: const Text(
                'Você será desconectado após definir a nova senha.',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push(AppRoutes.updatePassword),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            onPressed: _confirmSignOut,
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sair da conta'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Ações ──────────────────────────────────────────────────────────────────

  void _discard() {
    _name.text = widget.profile.fullName;
    _phone.text = widget.profile.phone ?? '';
    _checkDirty();
  }

  Future<void> _saveDetails() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informe seu nome completo.')),
      );
      return;
    }
    setState(() => _savingDetails = true);
    try {
      await ref.read(editProfileProvider.notifier).updateDetails(
            fullName: _name.text,
            phone: _phone.text,
          );
      if (!mounted) return;
      setState(() => _dirty = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil atualizado.')),
      );
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _savingDetails = false);
    }
  }

  Future<bool> _confirmDiscardChanges() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text(
          'Você tem alterações não salvas no seu perfil.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _openPhotoSheet() async {
    final p = widget.profile;
    final hasPhoto = (p.photoUrl ?? '').isNotEmpty;
    final showingPhoto = p.effectiveAvatarType == AvatarType.photo;
    final hasAvatar = p.avatarConfig != null;
    final showingAvatar = p.effectiveAvatarType == AvatarType.custom;
    // A câmera não está disponível no navegador; o seletor de arquivos do
    // image_picker cobre os dois casos na web.
    final cameraAvailable = !kIsWeb;

    final action = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Escolher da galeria'),
              onTap: () => Navigator.of(ctx).pop('gallery'),
            ),
            if (cameraAvailable)
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Tirar uma foto'),
                onTap: () => Navigator.of(ctx).pop('camera'),
              ),
            // O avatar geométrico não some ao trocar para foto (e vice-versa):
            // ambos ficam guardados, então a alternância não obriga a refazer
            // nada. Só aparece o que faz sentido no estado atual.
            ListTile(
              leading: const Icon(Icons.face_retouching_natural_outlined),
              title: Text(hasAvatar ? 'Editar meu avatar' : 'Criar meu avatar'),
              onTap: () => Navigator.of(ctx).pop('avatar_editor'),
            ),
            if (hasAvatar && !showingAvatar)
              ListTile(
                leading: const Icon(Icons.emoji_emotions_outlined),
                title: const Text('Usar avatar salvo'),
                onTap: () => Navigator.of(ctx).pop('use_avatar'),
              ),
            if (hasPhoto && !showingPhoto)
              ListTile(
                leading: const Icon(Icons.image_outlined),
                title: const Text('Usar foto salva'),
                onTap: () => Navigator.of(ctx).pop('use_photo'),
              ),
            if (showingPhoto || showingAvatar)
              ListTile(
                leading: const Icon(Icons.abc_outlined),
                title: const Text('Usar minhas iniciais'),
                onTap: () => Navigator.of(ctx).pop('initials'),
              ),
            if (hasPhoto)
              ListTile(
                leading:
                    const Icon(Icons.delete_outline, color: AppColors.error),
                title: const Text(
                  'Remover foto',
                  style: TextStyle(color: AppColors.error),
                ),
                onTap: () => Navigator.of(ctx).pop('remove'),
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    switch (action) {
      case 'remove':
        await _removePhoto();
      case 'avatar_editor':
        await context.push(ProfileRoutes.avatarEditor);
      case 'use_avatar':
        await _runAvatarAction(
          () => ref
              .read(editProfileProvider.notifier)
              .selectAvatarType(AvatarType.custom),
          'Avatar reativado.',
        );
      case 'initials':
        await _runAvatarAction(
          () => ref.read(editProfileProvider.notifier).useInitials(),
          'Agora exibindo suas iniciais.',
        );
      case 'use_photo':
        await _runAvatarAction(
          () => ref
              .read(editProfileProvider.notifier)
              .selectAvatarType(AvatarType.photo),
          'Foto reativada.',
        );
      case 'camera':
        await _pickAndUpload(ImageSource.camera);
      case 'gallery':
        await _pickAndUpload(ImageSource.gallery);
    }
  }

  /// Envolve uma operação de avatar com o loading local e o feedback padrão.
  Future<void> _runAvatarAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    setState(() => _busyAvatar = true);
    try {
      await action();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(successMessage)),
      );
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _busyAvatar = false);
    }
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      final picked = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      await _uploadPickedFile(picked);
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    }
  }

  /// Envia o arquivo escolhido, venha ele do seletor agora ou de uma sessão
  /// anterior recuperada por [_recoverLostPhoto].
  Future<void> _uploadPickedFile(XFile picked) async {
    setState(() => _busyAvatar = true);
    try {
      final bytes = await picked.readAsBytes();

      await ref.read(editProfileProvider.notifier).changePhoto(
            bytes: bytes,
            fileName: picked.name,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto de perfil atualizada.')),
      );
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _busyAvatar = false);
    }
  }

  Future<void> _removePhoto() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover foto?'),
        content: const Text(
          'Sua foto será apagada e o perfil voltará a exibir suas iniciais.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _runAvatarAction(
      () => ref.read(editProfileProvider.notifier).deletePhoto(),
      'Foto removida.',
    );
  }

  Future<void> _confirmSignOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair da conta?'),
        content: const Text(
          'Você precisará entrar novamente com seu e-mail e senha.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(authControllerProvider.notifier).signOut();
  }

  String _formatDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatFullDate(date);
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _HeaderCard extends StatelessWidget {
  const _HeaderCard({
    required this.profile,
    required this.busy,
    required this.onEditPhoto,
  });

  final UserProfile profile;
  final bool busy;
  final VoidCallback? onEditPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ClayCard(
      clipBehavior: Clip.antiAlias,
      child: Container(
        width: double.infinity,
        color: AppColors.surfaceTintTurquoise,
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 22),
        child: Column(
          children: [
            Stack(
              children: [
                Opacity(
                  opacity: busy ? 0.5 : 1,
                  child: UserAvatar(profile: profile, size: 96),
                ),
                if (busy)
                  const Positioned.fill(
                    child: Center(
                      child: SizedBox(
                        width: 26,
                        height: 26,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Material(
                    color: AppColors.turquoise,
                    shape: const CircleBorder(),
                    elevation: 2,
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: onEditPhoto,
                      child: const Padding(
                        padding: EdgeInsets.all(7),
                        child: Icon(
                          Icons.photo_camera_rounded,
                          size: 17,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              profile.fullName,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              profile.email,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            _RoleBadge(role: profile.role),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  const _RoleBadge({required this.role});

  final ProfileRole role;

  Color get _color {
    switch (role) {
      case ProfileRole.platformAdmin:
        return AppColors.navy;
      case ProfileRole.psychologist:
        return AppColors.turquoise;
      case ProfileRole.patient:
        return AppColors.blue;
    }
  }

  IconData get _icon {
    switch (role) {
      case ProfileRole.platformAdmin:
        return Icons.admin_panel_settings_outlined;
      case ProfileRole.psychologist:
        return Icons.psychology_outlined;
      case ProfileRole.patient:
        return Icons.self_improvement_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, size: 14, color: _color),
          const SizedBox(width: 6),
          Text(
            role.label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: _color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Blocos
// ---------------------------------------------------------------------------

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 15, color: AppColors.turquoise),
                const SizedBox(width: 7),
                Text(
                  title.toUpperCase(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.turquoise,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _ReadOnlyRow extends StatelessWidget {
  const _ReadOnlyRow({
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 17, color: AppColors.textMuted),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w500,
                  color: valueColor,
                ),
              ),
              if (hint != null) ...[
                const SizedBox(height: 2),
                Text(
                  hint!,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
