import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_providers.dart';
import '../../clinics/domain/clinic_summary.dart';
import '../../clinics/providers/clinics_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/clinic_user.dart';
import '../domain/create_clinic_user_request.dart';
import '../providers/user_management_providers.dart';

class UserManagementPage extends ConsumerWidget {
  const UserManagementPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersState = ref.watch(clinicUsersProvider);
    final profile = ref.watch(authControllerProvider).valueOrNull;
    final isPlatformAdmin = profile?.role == ProfileRole.platformAdmin;

    return AppScaffold(
      title: 'Equipe e permissões',
      subtitle: isPlatformAdmin
          ? 'Psicólogos e administradores da plataforma'
          : 'Gestão da equipe da clínica',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.read(clinicUsersProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: usersState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              e is AppException
                  ? userMessageFor(e)
                  : 'Erro ao carregar usuários.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (users) => _UsersList(
          users: users,
          currentProfileId: profile?.id,
          isPlatformAdmin: isPlatformAdmin,
          onToggleActive: (user) => _toggleActive(context, ref, user),
          onUpdateAccess: (user) =>
              _updatePsychologistAccess(context, ref, user),
          onChangeRole: (user) => _changeRole(context, ref, user),
          onDelete: (user) => _deleteUser(context, ref, user),
          onCreate: () => _showCreateUserSheet(context, ref),
        ),
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    ClinicUser user,
  ) async {
    final nextActive = !user.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${nextActive ? 'Ativar' : 'Inativar'} usuário'),
        content: Text(
          'Deseja ${nextActive ? 'ativar' : 'inativar'} ${user.fullName}? '
          'Essa ação altera o acesso ao aplicativo.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(nextActive ? 'Ativar' : 'Inativar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(clinicUsersProvider.notifier).setActive(
            profileId: user.id,
            isActive: nextActive,
          );
    } catch (e) {
      if (!context.mounted) return;
      _showActionError(context, e);
      return;
    }

    if (!context.mounted) return;
    _showProviderResult(
      context,
      ref,
      successMessage:
          'Usuário ${nextActive ? 'ativado' : 'inativado'} com sucesso.',
    );
  }

  Future<void> _deleteUser(
    BuildContext context,
    WidgetRef ref,
    ClinicUser user,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir usuário'),
        content: Text(
          'Deseja excluir definitivamente ${user.fullName}? '
          'O acesso será removido do Supabase e não poderá ser recuperado. '
          'Os registros de auditoria existentes serão preservados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excluindo usuário...')),
    );

    try {
      await ref.read(clinicUsersProvider.notifier).deleteUser(user.id);
    } catch (e) {
      if (!context.mounted) return;
      _showActionError(context, e);
      return;
    }

    if (!context.mounted) return;
    _showProviderResult(
      context,
      ref,
      successMessage: 'Usuário excluído com sucesso.',
    );
  }

  Future<void> _updatePsychologistAccess(
    BuildContext context,
    WidgetRef ref,
    ClinicUser user,
  ) async {
    final settings = await showDialog<_PsychologistAccessSettings>(
      context: context,
      builder: (context) => _PsychologistAccessDialog(user: user),
    );

    if (settings == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Atualizando acessos do psicólogo...')),
    );

    try {
      await ref.read(clinicUsersProvider.notifier).updatePsychologistAccess(
            profileId: user.id,
            canReceivePatients: settings.canReceivePatients,
            patientAssignmentLimit: settings.patientAssignmentLimit,
          );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(userMessageFor(mapToAppException(e)))),
      );
      return;
    }

    if (!context.mounted) return;
    _showProviderResult(
      context,
      ref,
      successMessage: 'Acessos do psicólogo atualizados com sucesso.',
    );
  }

  Future<void> _changeRole(
    BuildContext context,
    WidgetRef ref,
    ClinicUser user,
  ) async {
    final isPsychologist = user.role == ProfileRole.psychologist;
    final targetRole =
        isPsychologist ? ProfileRole.platformAdmin : ProfileRole.psychologist;
    final targetLabel = targetRole.label;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Alterar papel para $targetLabel'),
        content: Text(
          'Deseja alterar o papel de ${user.fullName} para $targetLabel?\n\n'
          '${targetRole == ProfileRole.platformAdmin ? 'O usuário terá acesso total de gestão da plataforma.' : 'O usuário perderá o acesso administrativo.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Alterar para $targetLabel'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await ref.read(clinicUsersProvider.notifier).updateUserRole(
            profileId: user.id,
            newRole: targetRole,
          );
    } catch (e) {
      if (!context.mounted) return;
      _showActionError(context, e);
      return;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Papel alterado para $targetLabel com sucesso.')),
    );
  }

  Future<void> _showCreateUserSheet(BuildContext context, WidgetRef ref) async {
    final isPlatformAdmin =
        ref.read(authControllerProvider).valueOrNull?.role ==
            ProfileRole.platformAdmin;
    final request = await showModalBottomSheet<CreateClinicUserRequest>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.navy.withValues(alpha: 0.36),
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: _CreateUserSheet(isPlatformAdmin: isPlatformAdmin),
      ),
    );

    if (request == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Criando usuário...')),
    );

    try {
      await ref.read(clinicUsersProvider.notifier).create(request);
    } catch (e) {
      if (!context.mounted) return;
      _showActionError(context, e);
      return;
    }

    if (!context.mounted) return;
    _showProviderResult(
      context,
      ref,
      successMessage: 'Usuário criado com sucesso.',
    );
  }

  void _showProviderResult(
    BuildContext context,
    WidgetRef ref, {
    required String successMessage,
  }) {
    final error = ref.read(clinicUsersProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? successMessage
              : userMessageFor(mapToAppException(error)),
        ),
      ),
    );
  }

  void _showActionError(BuildContext context, Object error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(userMessageFor(mapToAppException(error)))),
    );
  }
}

class _UsersList extends StatelessWidget {
  const _UsersList({
    required this.users,
    required this.currentProfileId,
    required this.isPlatformAdmin,
    required this.onToggleActive,
    required this.onUpdateAccess,
    required this.onChangeRole,
    required this.onDelete,
    required this.onCreate,
  });

  final List<ClinicUser> users;
  final String? currentProfileId;
  final bool isPlatformAdmin;
  final ValueChanged<ClinicUser> onToggleActive;
  final ValueChanged<ClinicUser> onUpdateAccess;
  final ValueChanged<ClinicUser> onChangeRole;
  final ValueChanged<ClinicUser> onDelete;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final groups = _groupUsersByClinic(users);
    final active = users.where((user) => user.isActive).length;
    final inactive = users.length - active;
    final platformAdmins = users
        .where(
          (user) => user.role == ProfileRole.platformAdmin && user.isActive,
        )
        .length;
    final psychologists =
        users.where((user) => user.role == ProfileRole.psychologist).length;
    final personal = users.where((user) => user.isPersonalClinic).length;

    return ResponsiveContent(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl + 40,
        ),
        children: [
          AppPageHeader(
            icon: Icons.manage_accounts_outlined,
            title: 'Psicólogos e administradores',
            subtitle:
                'Gerencie quem acessa a plataforma. Psicólogos ficam separados por clínica ou consultório individual; administradores aparecem com permissão global.',
            metadata: [
              StatusChip(
                label: '${users.length} acesso(s)',
                tone: AppStatusTone.info,
                icon: Icons.badge_outlined,
              ),
              StatusChip(
                label: '$psychologists psicólogo(s)',
                tone: AppStatusTone.success,
                icon: Icons.psychology_outlined,
              ),
              StatusChip(
                label: '$platformAdmins admin(s)',
                tone: AppStatusTone.neutral,
                icon: Icons.admin_panel_settings_outlined,
              ),
              StatusChip(
                label: '$active ativo(s)',
                tone: AppStatusTone.completed,
                icon: Icons.check_circle_outline,
              ),
              if (inactive > 0)
                StatusChip(
                  label: '$inactive inativo(s)',
                  tone: AppStatusTone.warning,
                  icon: Icons.pause_circle_outline,
                ),
              if (personal > 0)
                StatusChip(
                  label: '$personal individual(is)',
                  tone: AppStatusTone.info,
                  icon: Icons.person_pin_circle_outlined,
                ),
            ],
            primaryAction: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.person_add_alt_1_outlined),
              label: const Text('Novo acesso'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppSectionHeader(
            title: 'Separação por vínculo',
            subtitle:
                'Cada bloco representa uma clínica ou um consultório individual. Dentro dele ficam os profissionais vinculados.',
            action: StatusChip(
              label: '${groups.length} grupo(s)',
              tone: AppStatusTone.neutral,
              icon: Icons.account_tree_outlined,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (users.isEmpty)
            const _EmptyUsersCard()
          else
            MotionStaggered(
              children: [
                for (final group in groups)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: _ClinicGroupCard(
                      group: group,
                      currentProfileId: currentProfileId,
                      isPlatformAdmin: isPlatformAdmin,
                      onToggleActive: onToggleActive,
                      onUpdateAccess: onUpdateAccess,
                      onChangeRole: onChangeRole,
                      onDelete: onDelete,
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ClinicGroupCard extends StatelessWidget {
  const _ClinicGroupCard({
    required this.group,
    required this.currentProfileId,
    required this.isPlatformAdmin,
    required this.onToggleActive,
    required this.onUpdateAccess,
    required this.onChangeRole,
    required this.onDelete,
  });

  final _ClinicUserGroup group;
  final String? currentProfileId;
  final bool isPlatformAdmin;
  final ValueChanged<ClinicUser> onToggleActive;
  final ValueChanged<ClinicUser> onUpdateAccess;
  final ValueChanged<ClinicUser> onChangeRole;
  final ValueChanged<ClinicUser> onDelete;

  @override
  Widget build(BuildContext context) {
    final active = group.users.where((user) => user.isActive).length;
    final accent = group.isPersonal ? AppColors.purple : AppColors.blue;

    return MotionSurface(
      borderRadius: AppRadius.xlAll,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.xlAll,
          border: Border.all(color: AppColors.border),
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: AppRadius.mdAll,
                    ),
                    child: Icon(
                      group.isPersonal
                          ? Icons.person_pin_circle_outlined
                          : Icons.apartment_outlined,
                      color: accent,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          group.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Wrap(
                          spacing: AppSpacing.xs,
                          runSpacing: AppSpacing.xxs,
                          children: [
                            _TinyStatusChip(
                                label: group.typeLabel, color: accent),
                            _TinyStatusChip(
                              label: group.isActive ? 'Ativa' : 'Inativa',
                              color: group.isActive
                                  ? AppColors.success
                                  : AppColors.disabled,
                            ),
                            _TinyStatusChip(
                              label: '$active/${group.users.length} ativos',
                              color: AppColors.cyan,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            ...group.users.map(
              (user) => _UserRow(
                user: user,
                isCurrentUser: user.id == currentProfileId,
                canDelete: user.canBeDeletedBy(
                  currentProfileId: currentProfileId,
                  actorIsPlatformAdmin: isPlatformAdmin,
                ),
                onToggleActive: () => onToggleActive(user),
                onUpdateAccess: () => onUpdateAccess(user),
                onChangeRole: () => onChangeRole(user),
                onDelete: () => onDelete(user),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  const _UserRow({
    required this.user,
    required this.isCurrentUser,
    required this.canDelete,
    required this.onToggleActive,
    required this.onUpdateAccess,
    required this.onChangeRole,
    required this.onDelete,
  });

  final ClinicUser user;
  final bool isCurrentUser;
  final bool canDelete;
  final VoidCallback onToggleActive;
  final VoidCallback onUpdateAccess;
  final VoidCallback onChangeRole;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final isCompact = AppBreakpoints.isCompact(context);
    final accent = switch (user.role) {
      ProfileRole.platformAdmin => AppColors.navy,
      ProfileRole.psychologist => AppColors.blue,
      ProfileRole.patient => AppColors.disabled,
    };

    final initials = user.fullName.trim().isEmpty
        ? '?'
        : user.fullName.trim().characters.first.toUpperCase();

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: isCompact ? 18 : 20,
            backgroundColor: accent.withValues(alpha: 0.12),
            foregroundColor: accent,
            child: Text(initials),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        user.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    if (!isCompact) ...[
                      const SizedBox(width: AppSpacing.xs),
                      _TinyStatusChip(label: user.role.label, color: accent),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  user.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xxs,
                  children: [
                    if (isCompact)
                      _TinyStatusChip(label: user.role.label, color: accent),
                    _TinyStatusChip(
                      label: user.isActive ? 'Ativo' : 'Inativo',
                      color: user.isActive
                          ? AppColors.success
                          : AppColors.disabled,
                    ),
                    _TinyStatusChip(
                      label: _formatDate(user.createdAt),
                      color: AppColors.info,
                    ),
                    if (user.crp != null && user.crp!.isNotEmpty)
                      _TinyStatusChip(
                        label: 'CRP ${user.crp}',
                        color: AppColors.cyan,
                      ),
                    if (user.role == ProfileRole.psychologist)
                      _TinyStatusChip(
                        label: user.patientAccessSummary,
                        color: user.canReceivePatients &&
                                !user.reachedPatientAssignmentLimit
                            ? AppColors.success
                            : AppColors.error,
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          Transform.scale(
            scale: 0.84,
            child: Switch.adaptive(
              value: user.isActive,
              onChanged: isCurrentUser ? null : (_) => onToggleActive(),
            ),
          ),
          PopupMenuButton<_UserAction>(
            tooltip: 'Ações',
            padding: EdgeInsets.zero,
            icon: const Icon(Icons.more_vert, size: 20),
            onSelected: (action) {
              switch (action) {
                case _UserAction.toggleActive:
                  onToggleActive();
                case _UserAction.updateAccess:
                  onUpdateAccess();
                case _UserAction.changeRole:
                  onChangeRole();
                case _UserAction.delete:
                  onDelete();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: _UserAction.toggleActive,
                enabled: !isCurrentUser,
                child: Text(user.isActive ? 'Inativar' : 'Ativar'),
              ),
              if (user.role == ProfileRole.psychologist)
                const PopupMenuItem(
                  value: _UserAction.updateAccess,
                  child: Text('Configurar acessos'),
                ),
              if (!isCurrentUser &&
                  (user.role == ProfileRole.psychologist ||
                      user.role == ProfileRole.platformAdmin))
                PopupMenuItem(
                  value: _UserAction.changeRole,
                  child: Text(
                    user.role == ProfileRole.psychologist
                        ? 'Promover a administrador'
                        : 'Rebaixar a psicólogo',
                  ),
                ),
              PopupMenuItem(
                value: _UserAction.delete,
                enabled: !isCurrentUser && canDelete,
                child: const Text('Excluir'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TinyStatusChip extends StatelessWidget {
  const _TinyStatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.20)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color == AppColors.disabled ? AppColors.textMuted : color,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
      ),
    );
  }
}

class _EmptyUsersCard extends StatelessWidget {
  const _EmptyUsersCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          children: [
            const Icon(
              Icons.people_alt_outlined,
              color: AppColors.textMuted,
              size: 42,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Nenhum acesso de equipe encontrado.',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Crie psicólogos ou administradores para começar.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _PsychologistAccessSettings {
  const _PsychologistAccessSettings({
    required this.canReceivePatients,
    required this.patientAssignmentLimit,
  });

  final bool canReceivePatients;
  final int? patientAssignmentLimit;
}

class _PsychologistAccessDialog extends StatefulWidget {
  const _PsychologistAccessDialog({required this.user});

  final ClinicUser user;

  @override
  State<_PsychologistAccessDialog> createState() =>
      _PsychologistAccessDialogState();
}

class _PsychologistAccessDialogState extends State<_PsychologistAccessDialog> {
  late bool _canReceivePatients;
  late final TextEditingController _limitController;

  @override
  void initState() {
    super.initState();
    _canReceivePatients = widget.user.canReceivePatients;
    _limitController = TextEditingController(
      text: widget.user.patientAssignmentLimit?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _limitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final usedSlots = widget.user.reservedPatientSlots;

    return AlertDialog(
      title: const Text('Acessos do psicólogo'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.user.fullName),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '$usedSlots paciente(s)/convite(s) já ocupam vagas.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.md),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _canReceivePatients,
            title: const Text('Pode receber novos pacientes'),
            subtitle: const Text('Bloqueia novos cadastros e convites.'),
            onChanged: (value) => setState(() => _canReceivePatients = value),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _limitController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Limite de pacientes',
              hintText: 'Sem limite',
              helperText: 'Deixe em branco para não limitar.',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: const Text('Salvar'),
        ),
      ],
    );
  }

  void _submit() {
    final rawLimit = _limitController.text.trim();
    final parsedLimit = rawLimit.isEmpty ? null : int.tryParse(rawLimit);
    if (rawLimit.isNotEmpty && (parsedLimit == null || parsedLimit < 0)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Informe um limite inteiro maior ou igual a zero.'),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _PsychologistAccessSettings(
        canReceivePatients: _canReceivePatients,
        patientAssignmentLimit: parsedLimit,
      ),
    );
  }
}

class _CreateUserSheet extends ConsumerStatefulWidget {
  const _CreateUserSheet({required this.isPlatformAdmin});

  @override
  ConsumerState<_CreateUserSheet> createState() => _CreateUserSheetState();

  final bool isPlatformAdmin;
}

class _CreateUserSheetState extends ConsumerState<_CreateUserSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _crpController = TextEditingController();
  final _passwordController = TextEditingController();
  ProfileRole _role = ProfileRole.psychologist;
  bool _isIndividual = false;
  String? _clinicId;
  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _crpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight = mediaQuery.size.height - mediaQuery.padding.top;

    return AnimatedPadding(
      duration: AppAnimations.fast,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight * 0.92),
          child: Material(
            color: AppColors.surface,
            elevation: 18,
            shadowColor: AppColors.navy.withValues(alpha: 0.18),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Novo usuário',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Escolha a clínica e crie o acesso do psicólogo.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      if (widget.isPlatformAdmin) ...[
                        _RolePicker(
                          role: _role,
                          onChanged: (value) {
                            setState(() {
                              _role = value;
                              // Admin sempre vincula a uma clínica existente
                              if (value == ProfileRole.platformAdmin) {
                                _isIndividual = false;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        if (_role == ProfileRole.psychologist) ...[
                          _ClinicTypePicker(
                            isIndividual: _isIndividual,
                            onChanged: (value) =>
                                setState(() => _isIndividual = value),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                        if (!_isIndividual) ...[
                          _ClinicPicker(
                            selectedClinicId: _clinicId,
                            onChanged: (value) =>
                                setState(() => _clinicId = value),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],
                      ],
                      TextFormField(
                        controller: _nameController,
                        decoration:
                            const InputDecoration(labelText: 'Nome completo'),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Informe o nome.'
                                : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                            labelText: 'E-mail de acesso'),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (value) {
                          final text = value?.trim() ?? '';
                          if (text.isEmpty) return 'Informe o e-mail.';
                          if (!text.contains('@')) {
                            return 'Informe um e-mail válido.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                            labelText: 'Telefone opcional'),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _crpController,
                        decoration:
                            const InputDecoration(labelText: 'CRP opcional'),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _passwordController,
                        decoration:
                            const InputDecoration(labelText: 'Senha inicial'),
                        obscureText: true,
                        validator: (value) =>
                            validateClinicUserPassword(value ?? ''),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.check),
                          label: const Text('Criar usuário'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final needsClinic = widget.isPlatformAdmin && !_isIndividual;
    if (needsClinic && (_clinicId == null || _clinicId!.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione uma clínica.')),
      );
      return;
    }

    Navigator.of(context).pop(
      CreateClinicUserRequest(
        email: _emailController.text,
        password: _passwordController.text,
        fullName: _nameController.text,
        phone: _phoneController.text,
        crp: _role == ProfileRole.psychologist ? _crpController.text : null,
        role: _role,
        isIndividual: widget.isPlatformAdmin &&
            _role == ProfileRole.psychologist &&
            _isIndividual,
        clinicId: needsClinic ? _clinicId : null,
      ),
    );
  }
}

class _RolePicker extends StatelessWidget {
  const _RolePicker({required this.role, required this.onChanged});

  final ProfileRole role;
  final ValueChanged<ProfileRole> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Papel',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<ProfileRole>(
          segments: const [
            ButtonSegment(
              value: ProfileRole.psychologist,
              icon: Icon(Icons.psychology_outlined),
              label: Text('Psicólogo'),
            ),
            ButtonSegment(
              value: ProfileRole.platformAdmin,
              icon: Icon(Icons.admin_panel_settings_outlined),
              label: Text('Administrador'),
            ),
          ],
          selected: {role},
          onSelectionChanged: (s) => onChanged(s.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
          ),
        ),
      ],
    );
  }
}

class _ClinicTypePicker extends StatelessWidget {
  const _ClinicTypePicker({
    required this.isIndividual,
    required this.onChanged,
  });

  final bool isIndividual;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Tipo de vínculo',
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
        ),
        const SizedBox(height: AppSpacing.xs),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(
              value: false,
              icon: Icon(Icons.apartment_outlined),
              label: Text('Clínica existente'),
            ),
            ButtonSegment(
              value: true,
              icon: Icon(Icons.person_pin_circle_outlined),
              label: Text('Profissional individual'),
            ),
          ],
          selected: {isIndividual},
          onSelectionChanged: (selection) => onChanged(selection.first),
          style: const ButtonStyle(
            visualDensity: VisualDensity.compact,
          ),
        ),
        if (isIndividual) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Uma clínica individual será criada automaticamente com o nome do profissional.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ],
    );
  }
}

class _ClinicPicker extends ConsumerWidget {
  const _ClinicPicker({
    required this.selectedClinicId,
    required this.onChanged,
  });

  final String? selectedClinicId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicsState = ref.watch(clinicsProvider);

    return clinicsState.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => Text(
        e is AppException ? userMessageFor(e) : 'Erro ao carregar clínicas.',
      ),
      data: (clinics) {
        return DropdownButtonFormField<String>(
          initialValue: selectedClinicId,
          isExpanded: true,
          menuMaxHeight: 320,
          decoration: const InputDecoration(
            labelText: 'Clínica',
            prefixIcon: Icon(Icons.apartment_outlined),
          ),
          selectedItemBuilder: (context) => clinics
              .map(
                (clinic) => _ClinicPickerValue(
                  label: _clinicLabel(clinic),
                ),
              )
              .toList(),
          hint: const Text('Selecione uma clínica'),
          items: clinics.map(_clinicItem).toList(),
          validator: (value) =>
              value == null || value.isEmpty ? 'Selecione uma clínica.' : null,
          onChanged: onChanged,
        );
      },
    );
  }

  DropdownMenuItem<String> _clinicItem(ClinicSummary clinic) {
    return DropdownMenuItem<String>(
      value: clinic.id,
      child: _ClinicPickerValue(label: _clinicLabel(clinic)),
    );
  }

  String _clinicLabel(ClinicSummary clinic) {
    return '${clinic.name} · ${clinic.typeLabel}';
  }
}

class _ClinicPickerValue extends StatelessWidget {
  const _ClinicPickerValue({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }
}

enum _UserAction { toggleActive, updateAccess, changeRole, delete }

class _ClinicUserGroup {
  const _ClinicUserGroup({
    required this.id,
    required this.name,
    required this.typeLabel,
    required this.isPersonal,
    required this.isActive,
    required this.users,
  });

  final String id;
  final String name;
  final String typeLabel;
  final bool isPersonal;
  final bool isActive;
  final List<ClinicUser> users;
}

List<_ClinicUserGroup> _groupUsersByClinic(List<ClinicUser> users) {
  final grouped = <String, List<ClinicUser>>{};
  for (final user in users) {
    grouped.putIfAbsent(user.clinicId, () => []).add(user);
  }

  final groups = grouped.entries.map((entry) {
    final first = entry.value.first;
    final orderedUsers = [...entry.value]..sort((a, b) {
        final roleOrder = a.role.index.compareTo(b.role.index);
        if (roleOrder != 0) return roleOrder;
        return a.fullName.compareTo(b.fullName);
      });

    return _ClinicUserGroup(
      id: entry.key,
      name: first.clinicName,
      typeLabel: first.clinicTypeLabel,
      isPersonal: first.isPersonalClinic,
      isActive: first.clinicIsActive,
      users: orderedUsers,
    );
  }).toList();

  groups.sort((a, b) {
    final typeOrder =
        a.isPersonal == b.isPersonal ? 0 : (a.isPersonal ? 1 : -1);
    if (typeOrder != 0) return typeOrder;
    return a.name.compareTo(b.name);
  });

  return groups;
}

String _formatDate(DateTime? date) {
  if (date == null) return 'Sem data';
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  return '$day/$month/${date.year}';
}
