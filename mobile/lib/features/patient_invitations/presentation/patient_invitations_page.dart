import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../shared/widgets/desktop_psychologist/desktop_psychologist_shell.dart';
import '../../patients/presentation/widgets/staff_section_header.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/created_patient_invitation.dart';
import '../domain/patient_invitation.dart';
import '../domain/patient_invitation_status.dart';
import '../providers/patient_invitations_providers.dart';
import 'create_patient_invitation_page.dart';
import 'invitation_link.dart';
import 'patient_invitation_routes.dart';
import 'widgets/desktop_invitations_view.dart';

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
    final items = listAsync.valueOrNull;

    // Derive stats when data is available.
    final pendingCount =
        items?.where((i) => i.status == PatientInvitationStatus.pending).length;
    final acceptedCount = items
        ?.where((i) => i.status == PatientInvitationStatus.accepted)
        .length;
    final totalCount = items?.length;

    final stats = items != null
        ? [
            StaffSectionStat(
              value: '$pendingCount',
              label: 'Pendentes',
              accent: const Color(0xFFFBBF24),
            ),
            StaffSectionStat(
              value: '$acceptedCount',
              label: 'Aceitos',
              accent: const Color(0xFF00D4C9),
            ),
            StaffSectionStat(
              value: '$totalCount',
              label: 'Total',
            ),
          ]
        : null;

    // Psicóloga a partir de 768 px: histórico em tabela e formulário em painel.
    if (widget.role == ProfileRole.psychologist &&
        inDesktopPsychologistShell(context)) {
      final recent = _recentInvitation;
      return DesktopInvitationsView(
        items: items,
        loading: listAsync.isLoading,
        failed: !listAsync.isLoading && listAsync.hasError,
        situation: _situation,
        expiry: _formatShort,
        recent: recent,
        onNew: _openInvitationPanel,
        onRefresh: () =>
            ref.read(patientInvitationsListProvider.notifier).refresh(),
        onCopy: () => copyInviteUrl(context, recent!.inviteUrl),
        onDismiss: () => setState(() => _recentInvitation = null),
      );
    }

    return AppCanopyScaffold(
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.read(patientInvitationsListProvider.notifier).refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: StaffSectionHeader(
                navTitle: 'Convites',
                eyebrow: 'CONVITES DE PACIENTES',
                headline: Builder(
                  builder: (ctx) {
                    final theme = Theme.of(ctx);
                    return RichText(
                      text: TextSpan(
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Convites',
                            style: TextStyle(color: Color(0xFF00D4C9)),
                          ),
                          TextSpan(text: '\nde pacientes'),
                        ],
                      ),
                    );
                  },
                ),
                onBack: () => context.pop(),
                onRefresh: () =>
                    ref.read(patientInvitationsListProvider.notifier).refresh(),
                stats: stats,
                actions: [
                  GlassActionButton(
                    icon: Icons.mark_email_unread_outlined,
                    label: 'Novo convite',
                    filled: true,
                    onPressed: _openCreateInvitation,
                  ),
                ],
              ),
            ),

            // ── Loading ───────────────────────────────────────────────────
            if (listAsync.isLoading)
              const SliverFillRemaining(
                child: Center(child: BrandLoader()),
              )
            // ── Error ─────────────────────────────────────────────────────
            else if (listAsync.hasError)
              SliverFillRemaining(
                child: ErrorStatePanel(
                  message: 'Não conseguimos carregar os convites. Tente novamente.',
                  onRetry: () =>
                      ref.read(patientInvitationsListProvider.notifier).refresh(),
                ),
              )
            // ── Data ──────────────────────────────────────────────────────
            else ...[
              // Recent invitation banner (shown after creating one)
              if (_recentInvitation != null)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      0,
                    ),
                    child: RecentInvitationCard(
                      invitation: _recentInvitation!,
                      onCopy: () =>
                          copyInviteUrl(context, _recentInvitation!.inviteUrl),
                      onDismiss: () => setState(() => _recentInvitation = null),
                    ),
                  ),
                ),

              // Section header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: AppSectionHeader(
                    title: 'Histórico de convites',
                    subtitle: 'Status dos links enviados pela clínica.',
                  ),
                ),
              ),

              // Empty state
              if (items == null || items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: AppEmptyState(
                      icon: Icons.mail_outline,
                      title: 'Nenhum convite',
                      message: 'Nenhum convite encontrado.\n'
                          'Toque em "Novo convite" para enviar o primeiro.',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    88,
                  ),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      return MotionReveal(
                        delay: staggerDelay(index),
                        child: _InvitationTile(invitation: items[index]),
                      );
                    },
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openCreateInvitation() async => _received(
        await context.push(PatientInvitationRoutes.create(widget.role)),
      );

  /// Desktop: o mesmo formulário, em painel lateral (Esc fecha).
  Future<void> _openInvitationPanel() async => _received(
        await showDesktopSlideOver<CreatedPatientInvitation>(
          context,
          title: 'Convidar paciente',
          child: CreatePatientInvitationPage(role: widget.role, embedded: true),
        ),
      );

  Future<void> _received(Object? result) async {
    if (!mounted || result is! CreatedPatientInvitation) return;
    setState(() => _recentInvitation = result);
    await copyInviteUrl(context, result.inviteUrl);
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
            Text(_situation(invitation)),
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
}

/// Frase de situação do convite (celular e desktop).
String _situation(PatientInvitation invitation) {
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

/// Data curta (dd/mm/aaaa).
String _formatShort(DateTime date) {
  final local = date.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  return '$day/$month/$year';
}
