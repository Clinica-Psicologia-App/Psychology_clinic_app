import 'package:flutter/material.dart';

import '../../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../data/admin_library_repository.dart';
import 'library_cover.dart';

const _seriesFallback = [Color(0xFF2E7D6B), Color(0xFF11808F)];
const _movieFallback = [Color(0xFF3B2F8F), Color(0xFF7C6A9C)];

/// Catálogo da Biblioteca em desktop: busca + tabela com miniatura da capa,
/// liberação e liga/desliga de publicação na linha.
class DesktopLibraryCatalogView extends StatelessWidget {
  const DesktopLibraryCatalogView({
    super.key,
    required this.onSearch,
    required this.body,
  });

  final ValueChanged<String> onSearch;

  /// Conteúdo abaixo da busca (carregando / erro / tabela).
  final Widget body;

  @override
  Widget build(BuildContext context) {
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          m.pad, m.size == DesktopAdminSize.desktop ? 24 : 18, m.pad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 300,
              child: DaSearchField(hint: 'Buscar por título…', onChanged: onSearch),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class DesktopLibraryTable extends StatelessWidget {
  const DesktopLibraryTable({
    super.key,
    required this.items,
    required this.onOpen,
    required this.onTogglePublished,
  });

  final List<AdminLibraryWork> items;
  final ValueChanged<AdminLibraryWork> onOpen;
  final void Function(AdminLibraryWork work, bool value) onTogglePublished;

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

    return Container(
      decoration: BoxDecoration(
        color: t.rz,
        border: Border.all(color: t.bd2),
        borderRadius: BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Container(
            height: 38,
            padding: const EdgeInsets.only(left: 18),
            decoration: BoxDecoration(
              color: t.side,
              border: Border(bottom: BorderSide(color: t.bd2)),
            ),
            child: Row(children: [
              h('Obra'),
              h('Tipo', w: 100),
              h('Ano', w: 70, right: true),
              const SizedBox(width: 16),
              if (!m.tablet)
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: h('Intensidade', w: 120),
                ),
              if (!m.tablet) h('Esquema', w: 160),
              h('Liberação', w: m.tablet ? 130 : 140),
              h('Publicação', w: m.tablet ? 150 : 160),
              const SizedBox(width: 40),
            ]),
          ),
          Expanded(
            child: items.isEmpty
                ? Center(
                    child: Text('Nenhuma obra encontrada.',
                        style: daText(context, t, color: t.tx3)))
                : ListView(children: [
                    for (final w in items)
                      _Row(
                        work: w,
                        m: m,
                        onOpen: () => onOpen(w),
                        onToggle: (v) => onTogglePublished(w, v),
                      ),
                  ]),
          ),
        ],
      ),
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.work,
    required this.m,
    required this.onOpen,
    required this.onToggle,
  });

  final AdminLibraryWork work;
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
    final w = widget.work;
    final m = widget.m;
    final series = w.workType == 'Série' || w.workType == 'Minissérie';
    final on = w.isPublished;
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
          height: m.row + 8,
          padding: const EdgeInsets.only(left: 18),
          decoration: BoxDecoration(
            color: _hover ? t.hov : Colors.transparent,
            border: Border(bottom: BorderSide(color: t.bd)),
          ),
          child: Row(children: [
            Expanded(
              child: Row(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: SizedBox(
                    width: 28,
                    height: 40,
                    child: LibraryCover(
                      gradient: series ? _seriesFallback : _movieFallback,
                      url: w.coverUrl,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Flexible(
                  child: Text(w.displayTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: daText(context, t, weight: FontWeight.w600)),
                ),
              ]),
            ),
            SizedBox(
                width: 100,
                child: Text(w.workType,
                    maxLines: 1, style: daText(context, t, color: t.tx2))),
            SizedBox(
                width: 70,
                child: Text(w.year?.toString() ?? '—',
                    textAlign: TextAlign.right,
                    style: daText(context, t, color: t.tx2))),
            const SizedBox(width: 16),
            if (!m.tablet)
              SizedBox(
                  width: 136,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(w.intensity ?? '—',
                        style: daText(context, t, color: t.tx3)),
                  )),
            if (!m.tablet)
              SizedBox(
                  width: 160,
                  child: Text(w.primarySchema ?? '—',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: daText(context, t, color: t.tx3))),
            SizedBox(
              width: m.tablet ? 130 : 140,
              child: Align(
                alignment: Alignment.centerLeft,
                child: on
                    ? DaTag(
                        'Liberada',
                        icon: Icons.visibility_outlined,
                        bg: t.dark
                            ? const Color(0xFF0F3B30)
                            : const Color(0xFFD1FAE5),
                        fg: t.dark
                            ? const Color(0xFF6EE7B7)
                            : const Color(0xFF065F46),
                      )
                    : const DaTag('Não liberada',
                        icon: Icons.visibility_off_outlined),
              ),
            ),
            SizedBox(
              width: m.tablet ? 150 : 160,
              child: Row(children: [
                DaSwitch(
                  value: on,
                  semantics: 'Publicada',
                  tablet: m.tablet,
                  onChanged: () => widget.onToggle(!on),
                ),
                const SizedBox(width: 10),
                Text(on ? 'Publicada' : 'Oculta',
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
