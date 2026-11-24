import 'package:flutter/material.dart';

import '../../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../data/admin_psychoeducation_repository.dart';

/// Catálogo de psicoeducação em desktop: tabela de módulos (a linha abre o
/// editor) com liga/desliga de publicação.
class DesktopPsychoCatalogView extends StatelessWidget {
  const DesktopPsychoCatalogView({
    super.key,
    required this.modules,
    required this.onOpen,
    required this.onTogglePublished,
  });

  final List<AdminPsychoModule> modules;
  final ValueChanged<AdminPsychoModule> onOpen;
  final void Function(AdminPsychoModule module, bool value) onTogglePublished;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    Widget h(String s, {double? w, bool right = false}) {
      final text = Text(s,
          maxLines: 1,
          textAlign: right ? TextAlign.right : TextAlign.left,
          style: daText(context, t,
              size: 12, weight: FontWeight.w500, color: t.tx3));
      return w == null ? Expanded(child: text) : SizedBox(width: w, child: text);
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
          m.pad, m.size == DesktopAdminSize.desktop ? 24 : 18, m.pad, 24),
      child: Container(
        decoration: BoxDecoration(
          color: t.rz,
          border: Border.all(color: t.bd2),
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          Container(
            height: 38,
            padding: const EdgeInsets.only(left: 18),
            decoration: BoxDecoration(
              color: t.side,
              border: Border(bottom: BorderSide(color: t.bd2)),
            ),
            child: Row(children: [
              h('Nº', w: 60),
              h('Módulo'),
              h('Etapa', w: 140),
              h('Cards', w: 80, right: true),
              const SizedBox(width: 24),
              h('Publicação', w: m.tablet ? 150 : 160),
              const SizedBox(width: 40),
            ]),
          ),
          Expanded(
            child: modules.isEmpty
                ? Center(
                    child: Text('Nenhum módulo cadastrado.',
                        style: daText(context, t, color: t.tx3)))
                : ListView(children: [
                    for (final mod in modules)
                      _Row(
                        module: mod,
                        m: m,
                        onOpen: () => onOpen(mod),
                        onToggle: (v) => onTogglePublished(mod, v),
                      ),
                  ]),
          ),
        ]),
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.module,
    required this.m,
    required this.onOpen,
    required this.onToggle,
  });

  final AdminPsychoModule module;
  final DesktopAdminMetrics m;
  final VoidCallback onOpen;
  final ValueChanged<bool> onToggle;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final mod = widget.module;
    final m = widget.m;
    final on = mod.isPublished;
    final color = on ? t.ok : t.tx3;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: m.row,
          padding: const EdgeInsets.only(left: 18),
          decoration: BoxDecoration(
            color: _hover ? t.hov : Colors.transparent,
            border: Border(bottom: BorderSide(color: t.bd)),
          ),
          child: Row(children: [
            SizedBox(
              width: 60,
              child: Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: 30,
                  height: 30,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: t.dark
                        ? const Color(0xFF2F2A55)
                        : const Color(0xFFF0EDFE),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('${mod.number}',
                      style: daText(context, t,
                          size: 12.5,
                          weight: FontWeight.w600,
                          color: t.dark
                              ? const Color(0xFFC4B5FD)
                              : const Color(0xFF5B3FD0))),
                ),
              ),
            ),
            Expanded(
              child: Text(mod.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: daText(context, t, weight: FontWeight.w600)),
            ),
            SizedBox(
                width: 140,
                child: Text(mod.stage,
                    style: daText(context, t, color: t.tx2))),
            SizedBox(
                width: 80,
                child: Text('${mod.cardCount}',
                    textAlign: TextAlign.right, style: daText(context, t))),
            const SizedBox(width: 24),
            SizedBox(
              width: m.tablet ? 150 : 160,
              child: Row(children: [
                DaSwitch(
                  value: on,
                  semantics: 'Publicado',
                  tablet: m.tablet,
                  onChanged: () => widget.onToggle(!on),
                ),
                const SizedBox(width: 10),
                Text(on ? 'Publicado' : 'Oculto',
                    style: daText(context, t,
                        weight: FontWeight.w500, color: color)),
              ]),
            ),
            SizedBox(
              width: 40,
              child: Opacity(
                opacity: _hover ? 1 : 0,
                child: Icon(Icons.chevron_right, size: 18, color: t.tx3),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}
