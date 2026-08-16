import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/created_patient_invitation.dart';
import '../domain/patient_invitation.dart';
import '../domain/patient_invitation_status.dart';
import '../providers/patient_invitations_providers.dart';
import 'patient_invitation_routes.dart';

class PatientInvitationsPage extends ConsumerStatefulWidget {
  const PatientInvitationsPage({
    super.key,
    required this.role,
  });

  final ProfileRole role;

  @override
  ConsumerState<PatientInvitationsPage> createState() =>
      _PatientInvitationsPageState();
}

class _PatientInvitationsPageState
    extends ConsumerState<PatientInvitationsPage> {
  CreatedPatientInvitation? _recentInvitation;

  @override
  Widget build(BuildContext context) {
    final listAsync = ref.watch(patientInvitationsListProvider);

    return AppScaffold(
      title: 'Convites de pacientes',
      accent: AppColors.blue,
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.read(patientInvitationsListProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: Column(
        children: [
          Expanded(
            child: AsyncStateBody<List<PatientInvitation>>(
              asyncValue: listAsync,
              onRetry: () =>
                  ref.read(patientInvitationsListProvider.notifier).refresh(),
              emptyMessage: 'Nenhum convite encontrado.',
              emptyIcon: Icons.mail_outline,
              dataBuilder: (items) => RefreshIndicator(
                onRefresh: () =>
                    ref.read(patientInvitationsListProvider.notifier).refresh(),
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.md,
                    AppSpacing.md,
                    88,
                  ),
                  itemCount:
                      items.length + 2 + (_recentInvitation != null ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                        child: AppPageHeader(
                          title: 'Convites de pacientes',
                          subtitle:
                              'Envie convites de primeiro acesso e acompanhe o status de aceite.',
                          icon: Icons.mark_email_unread_outlined,
                          metadata: [
                            Chip(label: Text('${items.length} convites')),
                          ],
                        ),
                      );
                    }

                    if (_recentInvitation != null && index == 1) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                        child: _RecentInvitationCard(
                          invitation: _recentInvitation!,
                          onCopy: () =>
                              _copyInviteUrl(_recentInvitation!.inviteUrl),
                          onDismiss: () =>
                              setState(() => _recentInvitation = null),
                        ),
                      );
                    }

                    final sectionIndex = _recentInvitation != null ? 2 : 1;
                    if (index == sectionIndex) {
                      return const Padding(
                        padding: EdgeInsets.only(bottom: AppSpacing.sm),
                        child: AppSectionHeader(
                          title: 'Histórico de convites',
                          subtitle: 'Status dos links enviados pela clínica.',
                        ),
                      );
                    }

                    final itemIndex = index - sectionIndex - 1;
                    final invitation = items[itemIndex];
                    return MotionReveal(
                      delay: staggerDelay(itemIndex),
                      child: _InvitationTile(invitation: invitation),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateInvitation,
        icon: const Icon(Icons.mark_email_unread_outlined),
        label: const Text('Convidar paciente'),
      ),
    );
  }

  Future<void> _openCreateInvitation() async {
    final result = await context.push(
      PatientInvitationRoutes.create(widget.role),
    );

    if (!mounted || result is! CreatedPatientInvitation) return;
    setState(() => _recentInvitation = result);
    await _copyInviteUrl(result.inviteUrl);
  }

  Future<void> _copyInviteUrl(String inviteUrl) async {
    await Clipboard.setData(ClipboardData(text: inviteUrl));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Link do convite copiado.'),
      ),
    );
  }
}

class _RecentInvitationCard extends StatelessWidget {
  const _RecentInvitationCard({
    required this.invitation,
    required this.onCopy,
    required this.onDismiss,
  });

  final CreatedPatientInvitation invitation;
  final VoidCallback onCopy;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return AppInfoCard(
      title: 'Convite gerado',
      body: invitation.invitation.email,
      icon: Icons.link_outlined,
      tone: AppInfoCardTone.success,
      action: IconButton(
        tooltip: 'Fechar',
        onPressed: onDismiss,
        icon: const Icon(Icons.close),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(invitation.inviteUrl),
          const SizedBox(height: AppSpacing.sm),
          FilledButton.icon(
            onPressed: onCopy,
            icon: const Icon(Icons.copy_outlined),
            label: const Text('Copiar link'),
          ),
        ],
      ),
    );
  }
}

class _InvitationTile extends StatelessWidget {
  const _InvitationTile({required this.invitation});

  final PatientInvitation invitation;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final status = invitation.status;
    final statusColor = switch (status) {
      PatientInvitationStatus.pending => colors.primary,
      PatientInvitationStatus.accepted => Colors.green,
      PatientInvitationStatus.expired => colors.error,
      PatientInvitationStatus.revoked => colors.outline,
    };

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withValues(alpha: 0.14),
          child: Icon(Icons.mail_outline, color: statusColor),
        ),
        title: Text(invitation.fullName ?? invitation.email),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(invitation.email),
            if (invitation.responsiblePsychologistName != null)
              Text(
                'Responsavel: ${invitation.responsiblePsychologistName}',
              ),
            Text(_subtitle(invitation)),
          ],
        ),
        trailing: DecoratedBox(
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            child: Text(
              status.label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: statusColor,
                  ),
            ),
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  String _subtitle(PatientInvitation invitation) {
    switch (invitation.status) {
      case PatientInvitationStatus.pending:
        return 'Expira em ${_formatShort(invitation.expiresAt)}';
      case PatientInvitationStatus.accepted:
        return invitation.acceptedAt == null
            ? 'Convite aceito'
            : 'Aceito em ${_formatShort(invitation.acceptedAt!)}';
      case PatientInvitationStatus.expired:
        return 'Expirou em ${_formatShort(invitation.expiresAt)}';
      case PatientInvitationStatus.revoked:
        return 'Convite revogado';
    }
  }

  String _formatShort(DateTime date) {
    final local = date.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final year = local.year.toString();
    return '$day/$month/$year';
  }
}
