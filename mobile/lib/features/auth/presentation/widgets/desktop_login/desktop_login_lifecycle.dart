import 'package:flutter/widgets.dart';

/// Pausa as animações do login desktop quando o app sai de `resumed`
/// (aba/janela em segundo plano). Comum ao fundo, ao título e à vitrine.
///
/// Uso: `with ..., WidgetsBindingObserver, DesktopLoginLifecycle` e implementar
/// [syncAnimation] (liga/desliga o controller conforme [inBackground]).
/// Chamar [attachLifecycle] no `initState` e [detachLifecycle] no `dispose`.
mixin DesktopLoginLifecycle<T extends StatefulWidget>
    on State<T>, WidgetsBindingObserver {
  bool _inBackground = false;

  /// Verdadeiro quando o app não está em primeiro plano.
  bool get inBackground => _inBackground;

  /// Liga/desliga o controller (considera reduzir movimento, hover etc.).
  void syncAnimation();

  void attachLifecycle() => WidgetsBinding.instance.addObserver(this);

  void detachLifecycle() => WidgetsBinding.instance.removeObserver(this);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    _inBackground = state != AppLifecycleState.resumed;
    if (mounted) syncAnimation();
  }
}
