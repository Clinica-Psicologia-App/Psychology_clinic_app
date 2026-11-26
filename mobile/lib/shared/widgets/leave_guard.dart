import 'package:flutter/widgets.dart';

/// Diz a quem sai sem ser pelo "voltar" (menu lateral) como pedir licença à
/// tela: [confirmLeave] faz a mesma pergunta de descarte e responde se pode
/// sair, **sem** tirar a tela da pilha — quem perguntou segue para o destino.
///
/// Vai junto do [PopScope] da tela, que continua cuidando do "voltar".
class LeaveGuard extends StatefulWidget {
  const LeaveGuard({
    super.key,
    required this.confirmLeave,
    required this.child,
  });

  /// `true` = pode sair (nada pendente ou a pessoa confirmou).
  final Future<bool> Function() confirmLeave;
  final Widget child;

  static final _guards = Expando<_LeaveGuardState>();

  /// A pergunta registrada pela tela de [route], se houver.
  static Future<bool> Function()? of(Route<dynamic> route) {
    final state = _guards[route];
    return state == null ? null : () => state.widget.confirmLeave();
  }

  @override
  State<LeaveGuard> createState() => _LeaveGuardState();
}

class _LeaveGuardState extends State<LeaveGuard> {
  Route<dynamic>? _route;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == _route) return;
    _unregister();
    _route = route;
    if (route != null) LeaveGuard._guards[route] = this;
  }

  void _unregister() {
    final route = _route;
    if (route != null && LeaveGuard._guards[route] == this) {
      LeaveGuard._guards[route] = null;
    }
  }

  @override
  void dispose() {
    _unregister();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
