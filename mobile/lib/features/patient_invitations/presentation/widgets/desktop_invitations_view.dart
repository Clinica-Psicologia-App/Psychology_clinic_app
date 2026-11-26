import 'package:flutter/material.dart';

import '../../../../shared/widgets/app_motion.dart';
import '../../../../shared/widgets/async_state_body.dart';
import '../../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../../shared/widgets/desktop_psychologist/desktop_psychologist_shell.dart';
import '../../../../shared/widgets/desktop_psychologist/desktop_table.dart';
import '../../../../shared/widgets/loading_skeleton.dart';
import '../../domain/created_patient_invitation.dart';
import '../../domain/patient_invitation.dart';
import '../../domain/patient_invitation_status.dart';

/// Convites da psicóloga a partir de 768 px: "Novo convite" na barra, o convite
/// recém-gerado e o histórico em tabela. Os convites não têm ação na linha.
class DesktopInvitationsView extends StatelessWidget {
  const DesktopInvitationsView({
    super.key,
    required this.items,
    required this.loading,
    required this.failed,
    required this.situation,
    required this.expiry,
    required this.recent,
    required this.onNew,
    required this.onRefresh,
    required this.onCopy,
    required this.onDismiss,
  });

  /// Nulo enquanto carrega ou com erro.
  final List<PatientInvitation>? items;
  final bool loading;
  final bool failed;

  /// Frase de situação do cartão do celular ("Aceito em ...").
  final String Function(PatientInvitation) situation;

  /// Data de validade (dd/mm/aaaa).
  final String Function(DateTime) expiry;
  final CreatedPatientInvitation? recent;
  final VoidCallback onNew;
  final VoidCallback onRefresh;
  final VoidCallback onCopy;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final big = m.size == DesktopAdminSize.desktop;
    final list = items;
    int count(PatientInvitationStatus s) =>
        list!.where((i) => i.status == s).length;
    final recentInvitation = recent;

    return DesktopPsychologistFrame(
      title: 'Convites',
      subtitle: 'Convites de pacientes',
      actions: [
        DaButton(
          label: 'Novo convite',
          icon: Icons.mark_email_unread_outlined,
          kind: DaButtonKind.primary,
          onPressed: onNew,
        ),
        DaButton(
          icon: Icons.refresh,
          tooltip: 'Atualizar',
          kind: DaButtonKind.ghost,
          onPressed: onRefresh,
        ),
      ],
      body: failed
          ? ErrorStatePanel(
              message: 'Não conseguimos carregar os convites. Tente novamente.',
              onRetry: onRefresh,
            )
          : Padding(
              padding: EdgeInsets.fromLTRB(
                  m.pad, big ? 24 : 18, m.pad, big ? 32 : 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (!loading && recentInvitation != null) ...[
                    DesktopRecentInvitation(
                      invitation: recentInvitation,
                      onCopy: onCopy,
                      onDismiss: onDismiss,
                    ),
                    const SizedBox(height: 14),
                  ],
                  DesktopTableHeading(
                    title: 'Histórico de convites',
                    subtitle: 'Status dos links enviados pela clínica.',
                    counts: [
                      if (list != null) ...[
                        (count(PatientInvitationStatus.pending), 'Pendentes'),
                        (count(PatientInvitationStatus.accepted), 'Aceitos'),
                        (list.length, 'Total'),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: MotionReveal(
                      delay: staggerDelay(1),
                      child: Align(
                        alignment: Alignment.topCenter,
                        child: _table(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _table(BuildContext context) {
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final list = items;
    return LayoutBuilder(
      builder: (context, box) {
        final narrow = box.maxWidth < 700;
        final expiryWidth = narrow ? 170.0 : 220.0;
        final statusWidth = narrow ? 100.0 : 140.0;
        final Widget content;
        if (loading) {
          content = ListView(
            shrinkWrap: true,
            children: [
              for (var i = 0; i < 3; i++)
                _SkeletonRow(
                    m: m, expiryWidth: expiryWidth, statusWidth: statusWidth),
            ],
          );
        } else if (list == null || list.isEmpty) {
          content = const DesktopTableEmpty(
            icon: Icons.mail_outline,
            title: 'Nenhum convite',
            lines: [
              'Nenhum convite encontrado.',
              'Use "Novo convite" para enviar o primeiro.',
            ],
          );
        } else {
          content = ListView.builder(
            shrinkWrap: true,
            itemCount: list.length,
            itemBuilder: (context, i) => _Row(
              key: ValueKey(list[i].id),
              invitation: list[i],
              situation: situation(list[i]),
              expiry: expiry(list[i].expiresAt),
              expiryWidth: expiryWidth,
              statusWidth: statusWidth,
              m: m,
              last: i == list.length - 1,
            ),
          );
        }
        return DesktopTablePanel(
          header: DesktopTableHeader(
            children: [
              desktopColumnTitle(context, 'Destinatário'),
              desktopColumnTitle(context, 'Expira em', width: expiryWidth),
              desktopColumnTitle(context, 'Status', width: statusWidth),
            ],
          ),
          child: content,
        );
      },
    );
  }
}

DaTag _statusTag(BuildContext context, PatientInvitationStatus status) {
  final dark = DesktopAdminTokens.of(context).dark;
  return switch (status) {
    PatientInvitationStatus.pending => DaTag(
        status.label,
        bg: dark ? const Color(0xFF0F3B3A) : const Color(0xFFCCFBF1),
        fg: dark ? const Color(0xFF5EEAD4) : const Color(0xFF0F766E),
      ),
    PatientInvitationStatus.accepted => DaTag.ok(context, status.label),
    PatientInvitationStatus.expired => DaTag(
        status.label,
        bg: dark ? const Color(0xFF4A1D1D) : const Color(0xFFFEE2E2),
        fg: dark ? const Color(0xFFFCA5A5) : const Color(0xFFB91C1C),
      ),
    PatientInvitationStatus.revoked => DaTag(status.label),
  };
}

class _Row extends StatefulWidget {
  const _Row({
    super.key,
    required this.invitation,
    required this.situation,
    required this.expiry,
    required this.expiryWidth,
    required this.statusWidth,
    required this.m,
    required this.last,
  });

  final PatientInvitation invitation;
  final String situation;
  final String expiry;
  final double expiryWidth;
  final double statusWidth;
  final DesktopAdminMetrics m;
  final bool last;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final i = widget.invitation;
    final responsible = i.responsiblePsychologistName;
    // Pendente: só a data (a coluna já diz o que é); os demais, a frase.
    final when = i.status == PatientInvitationStatus.pending
        ? widget.expiry
        : widget.situation;
    Widget sub(String text) => Text(text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: daText(context, t, size: 12, color: t.tx3));

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: daHoverDuration(context),
        constraints: BoxConstraints(minHeight: widget.m.row),
        padding: const EdgeInsets.fromLTRB(18, 8, 10, 8),
        decoration: BoxDecoration(
          color: _hover ? t.hov : daClear(t.hov),
          border: Border(
            bottom: BorderSide(color: widget.last ? daClear(t.bd) : t.bd),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  const DaIconBox(Icons.mail_outline, color: Color(0xFF00A39B)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(i.fullName ?? i.email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: daText(context, t, weight: FontWeight.w600)),
                        sub(i.email),
                        if (responsible != null)
                          sub('Responsavel: $responsible'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
              ),
            ),
            SizedBox(
              width: widget.expiryWidth,
              child: Text(when,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: daText(context, t)),
            ),
            SizedBox(
              width: widget.statusWidth,
              child: Align(
                alignment: Alignment.centerLeft,
                child: _statusTag(context, i.status),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkeletonRow extends StatelessWidget {
  const _SkeletonRow({
    required this.m,
    required this.expiryWidth,
    required this.statusWidth,
  });

  final DesktopAdminMetrics m;
  final double expiryWidth;
  final double statusWidth;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    Widget bar(double width, double column) => SizedBox(
          width: column,
          child: Align(
            alignment: Alignment.centerLeft,
            child: LoadingSkeleton(height: 10, width: width),
          ),
        );
    return Container(
      height: m.row,
      padding: const EdgeInsets.only(left: 18, right: 10),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.bd))),
      child: Row(
        children: [
          const Expanded(
            child: Row(
              children: [
                LoadingSkeleton(height: 32, width: 32),
                SizedBox(width: 12),
                LoadingSkeleton(height: 10, width: 160),
              ],
            ),
          ),
          bar(80, expiryWidth),
          bar(60, statusWidth),
        ],
      ),
    );
  }
}

/// "Convite gerado": o link para copiar.
class DesktopRecentInvitation extends StatelessWidget {
  const DesktopRecentInvitation({
    super.key,
    required this.invitation,
    required this.onCopy,
    required this.onDismiss,
  });

  final CreatedPatientInvitation invitation;
  final VoidCallback onCopy;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 10, 14),
      decoration: BoxDecoration(
        color: t.rz,
        border: Border.all(color: t.ok),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DaIconBox(Icons.link_outlined, color: t.ok, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Convite gerado',
                    style: daText(context, t, weight: FontWeight.w600)),
                Text(invitation.invitation.email,
                    style: daText(context, t, size: 12.5, color: t.tx2)),
                const SizedBox(height: 8),
                SelectableText(invitation.inviteUrl, style: daText(context, t)),
                const SizedBox(height: 10),
                DaButton(
                  label: 'Copiar link',
                  icon: Icons.copy_outlined,
                  kind: DaButtonKind.primary,
                  onPressed: onCopy,
                ),
              ],
            ),
          ),
          DaButton(
            icon: Icons.close,
            tooltip: 'Fechar',
            kind: DaButtonKind.ghost,
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
