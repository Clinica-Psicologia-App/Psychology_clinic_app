import 'package:flutter/material.dart';

import '../app_motion.dart';
import '../desktop_admin/desktop_admin_kit.dart';

/// Peças dos formulários da psicóloga em desktop: campos com rótulo acima em 2
/// colunas, blocos em cartão e a ação principal parada no pé.

/// Largura máxima da coluna de formulário.
const double kDesktopFormMaxWidth = 860;

/// Decoração de um campo (o rótulo fica acima, em [DaLabeled]).
InputDecoration desktopFieldDecoration(
  BuildContext context, {
  String? hint,
  String? helper,
  Widget? suffix,
}) {
  final t = DesktopAdminTokens.of(context);
  return daInputDecoration(t, hint: hint).copyWith(
    helperText: helper,
    helperStyle: daText(context, t, size: 11.5, color: t.tx3),
    hintStyle: daText(context, t, color: t.tx3),
    errorStyle: daText(context, t, size: 12, color: t.err),
    suffixIcon: suffix,
  );
}

/// Texto digitado e opção escolhida no tamanho do desktop (o campo usa
/// bodyLarge; o menu suspenso, titleMedium).
ThemeData desktopFieldTheme(BuildContext context) {
  final theme = Theme.of(context);
  final text = daText(context, DesktopAdminTokens.of(context));
  return theme.copyWith(
    textTheme: theme.textTheme.copyWith(bodyLarge: text, titleMedium: text),
  );
}

/// Corpo rolável em coluna de largura limitada, com a barra de ação no pé.
class DesktopFormBody extends StatelessWidget {
  const DesktopFormBody({
    super.key,
    required this.children,
    required this.actions,
    this.controller,
    this.busy = false,
    this.leading,
  });

  final List<Widget> children;
  final List<Widget> actions;
  final ScrollController? controller;

  /// Gravando: indicador ao lado da ação.
  final bool busy;

  /// Coluna fixa à esquerda (índice das seções).
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final scroll = SingleChildScrollView(
      controller: controller,
      padding: EdgeInsets.fromLTRB(
          m.pad, m.size == DesktopAdminSize.desktop ? 24 : 18, m.pad, 32),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: kDesktopFormMaxWidth),
          // Todos os campos ficam montados: a validação vale para todos.
          child: MotionReveal(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
    final fields = desktopFieldTheme(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: leading == null
              ? Theme(data: fields, child: scroll)
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    leading!,
                    Expanded(child: Theme(data: fields, child: scroll)),
                  ],
                ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: m.pad, vertical: 12),
          decoration: BoxDecoration(
            color: t.bg,
            border: Border(top: BorderSide(color: t.bd)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (busy) ...[
                SizedBox(
                  width: 18,
                  height: 18,
                  child:
                      CircularProgressIndicator(strokeWidth: 2, color: t.tq),
                ),
                const SizedBox(width: 12),
              ],
              for (var i = 0; i < actions.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                actions[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Bloco em cartão: ponto colorido, título, selo e ação à direita.
class DesktopFormCard extends StatelessWidget {
  const DesktopFormCard({
    super.key,
    required this.title,
    required this.child,
    this.dot = DesktopAdminTokens.blue,
    this.badge,
    this.trailing,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final Widget? child;
  final Color dot;
  final Widget? badge;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
      decoration: BoxDecoration(
        color: t.rz,
        border: Border.all(color: t.bd2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 32),
            child: Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration:
                      BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 10),
                Text(title,
                    style: daText(context, t,
                        size: 14.5, weight: FontWeight.w600)),
                if (badge != null) ...[const SizedBox(width: 10), badge!],
                const Spacer(),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          if (subtitle != null)
            Text(subtitle!, style: daText(context, t, color: t.tx2)),
          if (child != null) ...[const SizedBox(height: 12), child!],
        ],
      ),
    );
  }
}

/// Seção do editar: título turquesa e o conteúdo.
class DesktopFormSection extends StatelessWidget {
  const DesktopFormSection({
    super.key,
    required this.title,
    required this.child,
  });

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(title,
              style: daText(context, t,
                  size: 14, weight: FontWeight.w600, color: t.tq)),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

/// Campos em 2 colunas (1 no tablet ou em coluna estreita).
class DesktopFormGrid extends StatelessWidget {
  const DesktopFormGrid({
    super.key,
    required this.children,
    this.runSpacing = 14,
  });

  final List<Widget> children;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    final tablet =
        DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width).tablet;
    return LayoutBuilder(
      builder: (context, box) {
        final one = tablet || box.maxWidth < 520;
        final width = one ? box.maxWidth : (box.maxWidth - 16) / 2;
        return Wrap(
          spacing: 16,
          runSpacing: runSpacing,
          children: [
            for (final child in children)
              SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}

/// Selo de situação no alto do formulário.
class DesktopFormTags extends StatelessWidget {
  const DesktopFormTags({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) =>
      Wrap(spacing: 8, runSpacing: 8, children: children);
}
