import 'package:flutter/material.dart';

import '../desktop_admin/desktop_admin_kit.dart';

/// Painel de tabela das telas da psicóloga: cabeçalho parado e o conteúdo
/// (linhas, esqueleto ou aviso) rolando dentro. A altura acompanha o conteúdo.
class DesktopTablePanel extends StatelessWidget {
  const DesktopTablePanel({
    super.key,
    required this.header,
    required this.child,
  });

  final Widget header;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Container(
      decoration: BoxDecoration(
        color: t.rz,
        borderRadius: BorderRadius.circular(12),
      ),
      // Por cima, para os cantos não ficarem cobertos pelo cabeçalho.
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: t.bd2),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [header, Flexible(child: child)],
      ),
    );
  }
}

/// Faixa de cabeçalho da tabela.
class DesktopTableHeader extends StatelessWidget {
  const DesktopTableHeader({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: 18, right: 10),
      decoration: BoxDecoration(
        color: t.side,
        border: Border(bottom: BorderSide(color: t.bd2)),
      ),
      child: Row(children: children),
    );
  }
}

/// Título de coluna; sem [width], ocupa o resto.
Widget desktopColumnTitle(BuildContext context, String label, {double? width}) {
  final t = DesktopAdminTokens.of(context);
  final text = Text(label,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style:
          daText(context, t, size: 12, weight: FontWeight.w500, color: t.tx3));
  return width == null
      ? Expanded(child: text)
      : SizedBox(width: width, child: text);
}

/// Lista vazia ou busca sem resultado, dentro do painel.
class DesktopTableEmpty extends StatelessWidget {
  const DesktopTableEmpty({
    super.key,
    required this.icon,
    required this.title,
    required this.lines,
    this.action,
  });

  final IconData icon;
  final String title;
  final List<String> lines;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return SingleChildScrollView(
      child: Container(
        constraints: const BoxConstraints(minHeight: 300),
        padding: const EdgeInsets.all(24),
        alignment: Alignment.center,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: t.bd2),
              ),
              child: Icon(icon, size: 24, color: t.tq),
            ),
            const SizedBox(height: 14),
            Text(title,
                style: daText(context, t, size: 15, weight: FontWeight.w600)),
            for (final line in lines)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(line,
                    textAlign: TextAlign.center,
                    style: daText(context, t, color: t.tx2)),
              ),
            if (action != null) ...[
              const SizedBox(height: 16),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
