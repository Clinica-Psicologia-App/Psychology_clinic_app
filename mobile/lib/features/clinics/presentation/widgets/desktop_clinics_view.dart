import 'package:flutter/material.dart';

import '../../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../domain/clinic_summary.dart';

/// Clínicas em desktop: tabela em painel, "⋯" com Excluir cadastro e painel
/// lateral de detalhe. As ações são as mesmas do celular.
class DesktopClinicsView extends StatefulWidget {
  const DesktopClinicsView({
    super.key,
    required this.clinics,
    required this.onToggleActive,
    required this.onDelete,
  });

  final List<ClinicSummary> clinics;
  final ValueChanged<ClinicSummary> onToggleActive;
  final ValueChanged<ClinicSummary> onDelete;

  @override
  State<DesktopClinicsView> createState() => _DesktopClinicsViewState();
}

class _DesktopClinicsViewState extends State<DesktopClinicsView> {
  String? _selectedId;

  Future<void> _openDetail(ClinicSummary c) async {
    setState(() => _selectedId = c.id);
    final act = await showDesktopSlideOver<VoidCallback>(
      context,
      title: 'Detalhe da clínica',
      child: _Detail(clinic: c),
      footer: Builder(
        builder: (ctx) => Align(
          alignment: Alignment.centerRight,
          child: DaButton(
            label: 'Excluir cadastro',
            icon: Icons.delete_outline,
            danger: true,
            onPressed: () =>
                Navigator.of(ctx).pop(() => widget.onDelete(c)),
          ),
        ),
      ),
    );
    if (mounted) setState(() => _selectedId = null);
    act?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          m.pad, m.size == DesktopAdminSize.desktop ? 24 : 18, m.pad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Cadastros institucionais',
              style: daText(context, t,
                  size: m.size == DesktopAdminSize.desktop ? 16 : 15,
                  weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Text(
                'Use esta lista para ativar, inativar ou excluir cadastros sem vínculos clínicos.',
                style: daText(context, t, color: t.tx2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: t.rz,
                border: Border.all(color: t.bd2),
                borderRadius: BorderRadius.circular(12),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  const _Header(),
                  Expanded(
                    child: widget.clinics.isEmpty
                        ? Center(
                            child: Text('Nenhuma clínica encontrada.',
                                style: daText(context, t, color: t.tx3)),
                          )
                        : ListView(
                            children: [
                              for (final c in widget.clinics)
                                _Tr(
                                  key: ValueKey(c.id),
                                  clinic: c,
                                  m: m,
                                  selected: _selectedId == c.id,
                                  onOpen: () => _openDetail(c),
                                  onToggle: () => widget.onToggleActive(c),
                                  onDelete: () => widget.onDelete(c),
                                ),
                            ],
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const double _wTipo = 120;
const double _wStatus = 100;
const double _wNum = 90;
const double _wAtiva = 72;
const double _wMais = 56;

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    Widget h(String s, {double? w, bool right = false}) {
      final text = Text(s,
          maxLines: 1,
          textAlign: right ? TextAlign.right : TextAlign.left,
          style: daText(context, t,
              size: 12, weight: FontWeight.w500, color: t.tx3));
      return w == null ? Expanded(child: text) : SizedBox(width: w, child: text);
    }

    return Container(
      height: 38,
      padding: const EdgeInsets.only(left: 18),
      decoration: BoxDecoration(
        color: t.side,
        border: Border(bottom: BorderSide(color: t.bd2)),
      ),
      child: Row(
        children: [
          h('Clínica'),
          h('Tipo', w: _wTipo),
          h('Status', w: _wStatus),
          h('Usuários', w: _wNum, right: true),
          h('Pacientes', w: _wNum, right: true),
          const SizedBox(width: 14),
          h('Ativa', w: _wAtiva),
          const SizedBox(width: _wMais),
        ],
      ),
    );
  }
}

class _Tr extends StatefulWidget {
  const _Tr({
    super.key,
    required this.clinic,
    required this.m,
    required this.selected,
    required this.onOpen,
    required this.onToggle,
    required this.onDelete,
  });

  final ClinicSummary clinic;
  final DesktopAdminMetrics m;
  final bool selected;
  final VoidCallback onOpen;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  State<_Tr> createState() => _TrState();
}

class _TrState extends State<_Tr> {
  bool _hover = false;
  bool _menuOpen = false;
  final _menu = MenuController();

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final c = widget.clinic;
    final m = widget.m;
    final showMore = _hover || widget.selected || _menuOpen || m.tablet;
    Widget cell(Widget child,
            {double? w, Alignment al = Alignment.centerLeft}) =>
        w == null
            ? Expanded(child: child)
            : SizedBox(width: w, child: Align(alignment: al, child: child));
    final color = c.isActive ? t.ok : t.tx3;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: daHoverDuration(context),
          height: m.row,
          padding: const EdgeInsets.only(left: 18),
          decoration: BoxDecoration(
            color: widget.selected
                ? t.sel
                : (_hover ? t.hov : daClear(t.hov)),
            border: Border(
              bottom: BorderSide(color: t.bd),
              left: BorderSide(
                  color: widget.selected ? t.tq : daClear(t.tq),
                  width: 3),
            ),
          ),
          child: Row(
            children: [
              cell(Row(
                children: [
                  DaIconBox(
                    c.isPersonal
                        ? Icons.person_pin_circle_outlined
                        : Icons.apartment_outlined,
                    color: c.isPersonal
                        ? DesktopAdminTokens.purple
                        : DesktopAdminTokens.blue,
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(c.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: daText(context, t, weight: FontWeight.w600)),
                  ),
                ],
              )),
              cell(
                  c.isPersonal
                      ? DaTag.rx(context, c.typeLabel)
                      : DaTag.az(context, c.typeLabel),
                  w: _wTipo),
              cell(
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 7,
                        height: 7,
                        decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    Text(c.isActive ? 'Ativa' : 'Inativa',
                        style: daText(context, t,
                            weight: FontWeight.w500, color: color)),
                  ]),
                  w: _wStatus),
              cell(Text('${c.userCount}', style: daText(context, t)),
                  w: _wNum, al: Alignment.centerRight),
              cell(Text('${c.patientCount}', style: daText(context, t)),
                  w: _wNum, al: Alignment.centerRight),
              const SizedBox(width: 14),
              cell(
                  DaSwitch(
                    value: c.isActive,
                    semantics: 'Ativa',
                    tablet: m.tablet,
                    onChanged: widget.onToggle,
                  ),
                  w: _wAtiva),
              SizedBox(
                width: _wMais,
                child: AnimatedOpacity(
                  duration: daHoverDuration(context),
                  opacity: showMore ? 1 : 0,
                  child: MenuAnchor(
                    controller: _menu,
                    onOpen: () => setState(() => _menuOpen = true),
                    onClose: () => setState(() => _menuOpen = false),
                    alignmentOffset: const Offset(-180, 4),
                    style: MenuStyle(
                      backgroundColor: WidgetStatePropertyAll(t.rz),
                      surfaceTintColor:
                          const WidgetStatePropertyAll(Colors.transparent),
                      elevation: const WidgetStatePropertyAll(0),
                      padding: const WidgetStatePropertyAll(EdgeInsets.all(5)),
                      minimumSize: const WidgetStatePropertyAll(Size(220, 0)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: t.bd2),
                      )),
                    ),
                    menuChildren: [
                      MenuItemButton(
                        onPressed: widget.onDelete,
                        leadingIcon:
                            Icon(Icons.delete_outline, size: 16, color: t.err),
                        style: ButtonStyle(
                          minimumSize:
                              const WidgetStatePropertyAll(Size(210, 36)),
                          overlayColor: WidgetStatePropertyAll(t.hov),
                        ),
                        child: Text('Excluir cadastro',
                            style: daText(context, t)),
                      ),
                    ],
                    builder: (context, ctl, _) => Align(
                      child: DaButton(
                        kind: DaButtonKind.ghost,
                        icon: Icons.more_horiz,
                        tooltip: 'Mais ações',
                        onPressed: () => ctl.isOpen ? ctl.close() : ctl.open(),
                      ),
                    ),
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

class _Detail extends StatelessWidget {
  const _Detail({required this.clinic});

  final ClinicSummary clinic;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final c = clinic;
    Widget row(String k, Widget v) => Container(
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.bd))),
          child: Row(children: [
            SizedBox(
                width: 150,
                child: Text(k,
                    style: daText(context, t, size: 12.5, color: t.tx3))),
            Expanded(child: Align(alignment: Alignment.centerLeft, child: v)),
          ]),
        );
    final color = c.isActive ? t.ok : t.tx3;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            DaIconBox(
              c.isPersonal
                  ? Icons.person_pin_circle_outlined
                  : Icons.apartment_outlined,
              color: c.isPersonal
                  ? DesktopAdminTokens.purple
                  : DesktopAdminTokens.blue,
              size: 44,
              radius: 10,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.name,
                      style:
                          daText(context, t, size: 16, weight: FontWeight.w600)),
                  Text(
                      '${c.userCount} usuário${c.userCount == 1 ? '' : 's'} · '
                      '${c.patientCount} paciente${c.patientCount == 1 ? '' : 's'}',
                      style: daText(context, t, size: 12.5, color: t.tx3)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 20),
          Container(
            decoration:
                BoxDecoration(border: Border(top: BorderSide(color: t.bd))),
            child: Column(children: [
              row(
                  'Tipo',
                  c.isPersonal
                      ? DaTag.rx(context, c.typeLabel)
                      : DaTag.az(context, c.typeLabel)),
              row(
                  'Status',
                  Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: 7,
                        height: 7,
                        decoration:
                            BoxDecoration(color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 7),
                    Text(c.isActive ? 'Ativa' : 'Inativa',
                        style: daText(context, t,
                            weight: FontWeight.w500, color: color)),
                  ])),
              row('Usuários', Text('${c.userCount}', style: daText(context, t))),
              row('Pacientes',
                  Text('${c.patientCount}', style: daText(context, t))),
            ]),
          ),
        ],
      ),
    );
  }
}
