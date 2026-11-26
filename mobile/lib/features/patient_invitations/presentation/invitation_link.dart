import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/desktop_psychologist/desktop_psychologist_shell.dart';
import '../domain/created_patient_invitation.dart';
import 'widgets/desktop_invitations_view.dart';

/// Copia o link do convite e avisa.
Future<void> copyInviteUrl(BuildContext context, String inviteUrl) async {
  await Clipboard.setData(ClipboardData(text: inviteUrl));
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Link do convite copiado.'),
    ),
  );
}

/// Convite aberto fora da tela Convites (Pacientes e ficha): mostra o mesmo
/// cartão "Convite gerado" e já copia o link, como lá. [result] é o que a tela
/// do formulário devolveu; sem convite, não faz nada.
Future<void> showCreatedInvitation(BuildContext context, Object? result) async {
  if (result is! CreatedPatientInvitation || !context.mounted) return;
  // O diálogo fica fora da casca: o tamanho se decide por quem chamou.
  final desktop = inDesktopPsychologistShell(context);
  showDialog<void>(
    context: context,
    // O link só aparece uma vez: um toque fora não fecha.
    barrierDismissible: false,
    builder: (dialog) {
      void copy() => copyInviteUrl(context, result.inviteUrl);
      void close() => Navigator.of(dialog).pop();
      return Dialog(
        insetPadding: const EdgeInsets.all(AppSpacing.md),
        backgroundColor:
            desktop ? Colors.transparent : Theme.of(dialog).colorScheme.surface,
        elevation: desktop ? 0 : null,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: SingleChildScrollView(
            child: desktop
                ? DesktopRecentInvitation(
                    invitation: result,
                    onCopy: copy,
                    onDismiss: close,
                  )
                : RecentInvitationCard(
                    invitation: result,
                    onCopy: copy,
                    onDismiss: close,
                  ),
          ),
        ),
      );
    },
  );
  await copyInviteUrl(context, result.inviteUrl);
}

/// Cartão "Convite gerado" do celular.
class RecentInvitationCard extends StatelessWidget {
  const RecentInvitationCard({
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
