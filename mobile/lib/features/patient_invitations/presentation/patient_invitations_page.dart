import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/created_patient_invitation.dart';
import '../domain/patient_invitation.dart';
import '../domain/patient_invitation_status.dart';
import '../providers/patient_invitations_providers.dart';
import 'patient_invitation_routes.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

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
          if (_recentInvitation != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _RecentInvitationCard(
                invitation: _recentInvitation!,
                onCopy: () => _copyInviteUrl(_recentInvitation!.inviteUrl),
                onDismiss: () => setState(() => _recentInvitation = null),
              ),
            ),
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
                  padding: const EdgeInsets.all(16),
                  itemCount: items.length,
                  itemBuilder: (context, index) {
                    final invitation = items[index];
                    return MotionReveal(
                      delay: staggerDelay(index),
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
    return ClayCard(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link_outlined),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Convite gerado',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: 'Fechar',
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(invitation.invitation.email),
            const SizedBox(height: 8),
            SelectableText(invitation.inviteUrl),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: onCopy,
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copiar link'),
            ),
          ],
        ),
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

    return ClayCard(
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
