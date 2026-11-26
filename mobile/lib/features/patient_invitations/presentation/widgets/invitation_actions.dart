import 'package:flutter/material.dart';

import '../../../profile/domain/profile_role.dart';

/// Ações de um convite pendente.
enum InvitationAction { cancel, resend }

/// "Reenviar" cria um convite novo: só para quem pode criar.
bool canResendInvitation(ProfileRole role) =>
    role == ProfileRole.psychologist || role == ProfileRole.platformAdmin;

/// Menu ⋯ do convite pendente (celular e desktop).
class InvitationMenu extends StatelessWidget {
  const InvitationMenu({
    super.key,
    required this.canResend,
    required this.busy,
    required this.enabled,
    required this.onSelected,
  });

  final bool canResend;

  /// A ação deste convite está em andamento.
  final bool busy;

  /// Falso enquanto qualquer ação está em andamento.
  final bool enabled;
  final ValueChanged<InvitationAction> onSelected;

  @override
  Widget build(BuildContext context) {
    if (busy) {
      return const Center(
        widthFactor: 1,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 10),
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }
    return PopupMenuButton<InvitationAction>(
      icon: const Icon(Icons.more_horiz),
      iconSize: 20,
      padding: EdgeInsets.zero,
      enabled: enabled,
      onSelected: onSelected,
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: InvitationAction.cancel,
          child: Text('Cancelar convite'),
        ),
        if (canResend)
          const PopupMenuItem(
            value: InvitationAction.resend,
            child: Text('Reenviar convite'),
          ),
      ],
    );
  }
}

/// Pergunta antes de agir. "Voltar" (ou tocar fora) não faz nada.
Future<bool> confirmInvitationAction(
  BuildContext context,
  InvitationAction action,
  String email,
) async {
  final (question, confirm) = switch (action) {
    InvitationAction.cancel => (
        'Cancelar este convite? O link enviado para $email deixa de funcionar.',
        'Cancelar convite',
      ),
    InvitationAction.resend => (
        'Reenviar o convite? O link anterior deixa de funcionar e um novo e-mail é enviado para $email.',
        'Reenviar',
      ),
  };
  final answer = await showDialog<bool>(
    context: context,
    builder: (dialog) => AlertDialog(
      constraints: const BoxConstraints(minWidth: 280, maxWidth: 440),
      content: Text(question),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialog).pop(false),
          child: const Text('Voltar'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialog).pop(true),
          child: Text(confirm),
        ),
      ],
    ),
  );
  return answer ?? false;
}
