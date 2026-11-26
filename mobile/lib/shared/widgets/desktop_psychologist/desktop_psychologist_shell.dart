import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../features/patients/presentation/patient_routes.dart';
import '../desktop_admin/desktop_admin_kit.dart';
import '../desktop_admin/desktop_admin_shell.dart';
import '../leave_guard.dart';
import 'desktop_psychologist_menu.dart';

/// Endereço do Início da psicóloga (prefixo das telas dela).
const kPsychologistHomeLocation = '/psychologist';

/// Telas que já têm a barra superior de desktop ([DesktopPsychologistFrame]) e
/// animam o próprio conteúdo. As demais entram aqui nas etapas seguintes.
const desktopPsychologistFramedLocations = <String>{
  kPsychologistHomeLocation,
  '$kPsychologistHomeLocation/patients',
};

/// A tela aberta em [state] tem a barra própria? A escolha de paciente (a
/// lista aberta por um atalho, com intenção) continua sendo a do celular.
bool isDesktopPsychologistFramed(GoRouterState state) {
  final extra = state.extra;
  return desktopPsychologistFramedLocations.contains(state.matchedLocation) &&
      (extra == null || extra == PatientSelectionIntent.none);
}

bool isPsychologistLocation(String location) =>
    location == kPsychologistHomeLocation ||
    location.startsWith('$kPsychologistHomeLocation/');

/// Casca da psicóloga a partir de 768 px: o menu lateral e o fio de gradiente
/// ficam parados; só a área de conteúdo ([child], o navegador das telas dela)
/// troca.
class DesktopPsychologistShell extends StatefulWidget {
  const DesktopPsychologistShell({
    super.key,
    required this.location,
    required this.child,
  });

  /// Endereço da casca (não muda quando uma tela é empilhada).
  final String location;
  final Widget child;

  @override
  State<DesktopPsychologistShell> createState() =>
      _DesktopPsychologistShellState();
}

class _DesktopPsychologistShellState extends State<DesktopPsychologistShell> {
  /// Última tela da psicóloga aberta: a que o menu marca. Uma tela de fora
  /// (Perfil) por cima da casca não muda a marcação.
  late String _open = widget.location;

  final _content = GlobalKey();

  /// Sair da tela aberta pelo menu. Numa tela comum, executa [go]. Se ela pede
  /// confirmação ao voltar ([PopScope]), pergunta antes ([LeaveGuard]): aceita
  /// a saída, executa [leaving] (ou [go]), que tira a tela da pilha; cancelada,
  /// fica onde está. Tela travada sem [LeaveGuard] recebe só o "voltar".
  Future<void> _leave(VoidCallback go, {VoidCallback? leaving}) async {
    NavigatorState? navigator;
    void find(Element element) {
      if (navigator != null) return;
      if (element is StatefulElement && element.state is NavigatorState) {
        navigator = element.state as NavigatorState;
      } else {
        element.visitChildren(find);
      }
    }

    _content.currentContext?.visitChildElements(find);
    Route<dynamic>? top;
    // Só consulta a rota de cima: o predicado já aceita a primeira.
    navigator?.popUntil((route) {
      top = route;
      return true;
    });
    final route = top;
    if (route == null || route.popDisposition != RoutePopDisposition.doNotPop) {
      go();
      return;
    }
    final confirm = LeaveGuard.of(route);
    if (confirm == null) {
      await navigator!.maybePop();
      return;
    }
    // Se a tela já saiu por outro caminho durante a pergunta, não navega.
    if (await confirm() && mounted && route.isCurrent) (leaving ?? go)();
  }

  @override
  Widget build(BuildContext context) {
    final router = GoRouter.of(context);
    return ListenableBuilder(
      listenable: router.routerDelegate,
      builder: (context, _) {
        final matches = router.routerDelegate.currentConfiguration;
        if (matches.isNotEmpty) {
          final top = matches.last.matchedLocation;
          if (isPsychologistLocation(top)) _open = top;
        }
        return _frame(context);
      },
    );
  }

  Widget _frame(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    return Material(
      color: t.bg,
      child: SafeArea(
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DefaultTextStyle(
                  style: daText(context, t),
                  child: DesktopPsychologistMenu(
                    location: _open,
                    home: kPsychologistHomeLocation,
                    m: m,
                    leave: _leave,
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 3),
                    child: KeyedSubtree(
                      key: _content,
                      child: _PsychologistContentScope(child: widget.child),
                    ),
                  ),
                ),
              ],
            ),
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 3,
              child: DecoratedBox(
                decoration:
                    BoxDecoration(gradient: DesktopAdminTokens.brandGradient),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Marca as telas abertas dentro da área de conteúdo da casca.
class _PsychologistContentScope extends InheritedWidget {
  const _PsychologistContentScope({required super.child});

  @override
  bool updateShouldNotify(_PsychologistContentScope oldWidget) => false;
}

/// Transição das telas abertas dentro da casca: nada desliza; o conteúdo entra
/// com fade + subida curta, e a tela que sai some na hora. Devolve nulo fora da
/// casca (celular e rotas de tela cheia), que seguem a transição do app.
Widget? desktopPsychologistTransition(
  PageRoute<dynamic> route,
  BuildContext context,
  Widget child,
) {
  if (context.dependOnInheritedWidgetOfExactType<_PsychologistContentScope>() ==
      null) {
    return null;
  }
  // A tela com barra própria já anima o conteúdo e se esconde ao sair.
  if (route.settings is Page &&
      isDesktopPsychologistFramed(GoRouterState.of(context))) {
    return child;
  }
  return DesktopHideWhileLeaving(
    child: ColoredBox(
      // Fundo opaco: a tela de baixo não aparece através da que está entrando.
      color: Theme.of(context).scaffoldBackgroundColor,
      child: DesktopContentEntrance(child: child),
    ),
  );
}

/// Tela da psicóloga já em linguagem de desktop: barra superior parada e só o
/// conteúdo animado.
class DesktopPsychologistFrame extends StatelessWidget {
  const DesktopPsychologistFrame({
    super.key,
    required this.title,
    required this.body,
    this.actions = const [],
    this.subtitle,
    this.titleTrailing,
  });

  final String title;
  final String? subtitle;
  final Widget? titleTrailing;
  final List<Widget> actions;
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    return DesktopHideWhileLeaving(
      child: Scaffold(
        backgroundColor: t.bg,
        body: DefaultTextStyle(
          style: daText(context, t),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DesktopTopBar(
                m: m,
                title: title,
                subtitle: subtitle,
                titleTrailing: titleTrailing,
                actions: actions,
              ),
              Expanded(
                child: DesktopContentEntrance(
                  child: Material(
                    type: MaterialType.transparency,
                    child: body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
