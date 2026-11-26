import 'package:flutter/material.dart';

import '../../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../profile/domain/profile_role.dart';
import '../../../profile/presentation/widgets/user_avatar.dart';
import '../../domain/clinic_user.dart';

/// Ações de uma linha (as mesmas do menu "⋯" do celular).
class DesktopUserActions {
  const DesktopUserActions({
    required this.toggleActive,
    required this.updateAccess,
    required this.changeRole,
    required this.delete,
  });

  final ValueChanged<ClinicUser> toggleActive;
  final ValueChanged<ClinicUser> updateAccess;
  final ValueChanged<ClinicUser> changeRole;
  final ValueChanged<ClinicUser> delete;
}

enum _Filter { all, psychologists, admins }

class _Group {
  _Group(this.id, this.first);
  final String id;
  final ClinicUser first;
  final List<ClinicUser> users = [];
}

/// Usuários em desktop: controle segmentado, busca, tabela em painel com duas
/// seções (blocos de clínica que abrem e fecham; consultórios individuais em
/// uma linha por pessoa), "⋯" e painel lateral de detalhe.
class DesktopUsersView extends StatefulWidget {
  const DesktopUsersView({
    super.key,
    required this.users,
    required this.currentProfileId,
    required this.isPlatformAdmin,
    required this.actions,
  });

  final List<ClinicUser> users;
  final String? currentProfileId;
  final bool isPlatformAdmin;
  final DesktopUserActions actions;

  @override
  State<DesktopUsersView> createState() => _DesktopUsersViewState();
}

class _DesktopUsersViewState extends State<DesktopUsersView> {
  _Filter _filter = _Filter.all;
  String _query = '';
  String? _selectedId;

  /// Clínicas fechadas (todas começam abertas).
  final Set<String> _collapsed = {};

  List<_Group> _groups(List<ClinicUser> users) {
    final map = <String, _Group>{};
    for (final u in users) {
      map.putIfAbsent(u.clinicId, () => _Group(u.clinicId, u)).users.add(u);
    }
    final groups = map.values.toList();
    for (final g in groups) {
      g.users.sort((a, b) {
        final r = a.role.index.compareTo(b.role.index);
        return r != 0 ? r : a.fullName.compareTo(b.fullName);
      });
    }
    groups.sort((a, b) {
      final ta = a.first.isPersonalClinic, tb = b.first.isPersonalClinic;
      if (ta != tb) return ta ? 1 : -1;
      return a.first.clinicName.compareTo(b.first.clinicName);
    });
    return groups;
  }

  bool _matches(ClinicUser u) {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return u.fullName.toLowerCase().contains(q) ||
        u.email.toLowerCase().contains(q);
  }

  Widget _row(ClinicUser u, DesktopAdminMetrics m) => _UserTr(
        key: ValueKey(u.id),
        user: u,
        m: m,
        selected: _selectedId == u.id,
        isMe: u.id == widget.currentProfileId,
        canDelete: u.canBeDeletedBy(
          currentProfileId: widget.currentProfileId,
          actorIsPlatformAdmin: widget.isPlatformAdmin,
        ),
        actions: widget.actions,
        onOpen: () => _openDetail(u),
      );

  /// Bloco de uma clínica. O "X/Y ativos" é da clínica inteira, não só das
  /// pessoas que o filtro deixou à mostra.
  Widget _clinicBlock(_Group g, DesktopAdminMetrics m) {
    final members = widget.users.where((u) => u.clinicId == g.id);
    final open = !_collapsed.contains(g.id);
    return Column(
      key: ValueKey('clinica-${g.id}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ClinicHeader(
          name: g.first.clinicName,
          active: members.where((u) => u.isActive).length,
          total: members.length,
          clinicIsActive: g.first.clinicIsActive,
          open: open,
          onTap: () => setState(
              () => open ? _collapsed.add(g.id) : _collapsed.remove(g.id)),
        ),
        _Collapsible(
          open: open,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [for (final u in g.users) _row(u, m)],
          ),
        ),
      ],
    );
  }

  Future<void> _openDetail(ClinicUser user) async {
    setState(() => _selectedId = user.id);
    final a = widget.actions;
    final isMe = user.id == widget.currentProfileId;
    final canDelete = user.canBeDeletedBy(
      currentProfileId: widget.currentProfileId,
      actorIsPlatformAdmin: widget.isPlatformAdmin,
    );
    final act = await showDesktopSlideOver<VoidCallback>(
      context,
      title: 'Detalhe do usuário',
      child: _Detail(user: user),
      footer: Builder(
        builder: (ctx) {
          void run(VoidCallback f) => Navigator.of(ctx).pop(f);
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.end,
            children: [
              DaButton(
                label: user.isActive ? 'Inativar' : 'Ativar',
                onPressed: isMe ? null : () => run(() => a.toggleActive(user)),
              ),
              if (user.role == ProfileRole.psychologist)
                DaButton(
                  label: 'Configurar acessos',
                  onPressed: () => run(() => a.updateAccess(user)),
                ),
              if (!isMe &&
                  (user.role == ProfileRole.psychologist ||
                      user.role == ProfileRole.platformAdmin))
                DaButton(
                  label: user.role == ProfileRole.psychologist
                      ? 'Promover a administrador'
                      : 'Rebaixar a psicólogo',
                  onPressed: () => run(() => a.changeRole(user)),
                ),
              DaButton(
                label: 'Excluir',
                danger: true,
                onPressed: !isMe && canDelete ? () => run(() => a.delete(user)) : null,
              ),
            ],
          );
        },
      ),
    );
    if (mounted) setState(() => _selectedId = null);
    act?.call();
  }

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final users = widget.users;
    final psy = users.where((u) => u.role == ProfileRole.psychologist).length;
    final adm = users.where((u) => u.role == ProfileRole.platformAdmin).length;
    final filtered = users.where((u) {
      final byRole = switch (_filter) {
        _Filter.all => true,
        _Filter.psychologists => u.role == ProfileRole.psychologist,
        _Filter.admins => u.role == ProfileRole.platformAdmin,
      };
      return byRole && _matches(u);
    }).toList();
    final clinics =
        _groups(filtered.where((u) => !u.isPersonalClinic).toList());
    // Consultórios na mesma ordem de antes (pelo nome do consultório).
    final practices =
        _groups(filtered.where((u) => u.isPersonalClinic).toList());

    return Padding(
      padding: EdgeInsets.fromLTRB(m.pad, m.size == DesktopAdminSize.desktop ? 24 : 18, m.pad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Separação por vínculo',
              style: daText(context, t,
                  size: m.size == DesktopAdminSize.desktop ? 16 : 15,
                  weight: FontWeight.w600)),
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 860),
              child: Text(
                'Clínicas aparecem em blocos com seus profissionais; '
                'consultórios individuais, um por linha.',
                style: daText(context, t, color: t.tx2),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              DaSegmented<_Filter>(
                value: _filter,
                items: [
                  DaSegment(_Filter.all, 'Todos', count: users.length),
                  DaSegment(_Filter.psychologists, 'Psicólogos', count: psy),
                  DaSegment(_Filter.admins, 'Admins', count: adm),
                ],
                onChanged: (f) => setState(() => _filter = f),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 300),
                    child: DaSearchField(
                      hint: 'Buscar por nome ou e-mail',
                      onChanged: (v) => setState(() => _query = v),
                    ),
                  ),
                ),
              ),
            ],
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
                  _HeaderRow(m: m),
                  Expanded(
                    child: filtered.isEmpty
                        ? Center(
                            child: Text('Nenhum resultado',
                                style: daText(context, t, color: t.tx3)),
                          )
                        : ListView(
                            children: [
                              if (clinics.isNotEmpty) ...[
                                _SectionTitle('Clínicas (${clinics.length})'),
                                for (final g in clinics) _clinicBlock(g, m),
                              ],
                              if (practices.isNotEmpty) ...[
                                _SectionTitle(
                                    'Consultórios individuais (${practices.length})'),
                                for (final g in practices)
                                  for (final u in g.users) _row(u, m),
                              ],
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

const double _wMais = 56;
double _wPapel(DesktopAdminMetrics m) => m.tablet ? 112 : 140;
double _wPacientes(DesktopAdminMetrics m) => m.tablet ? 128 : 170;
double _wAtivo(DesktopAdminMetrics m) => m.tablet ? 112 : 116;

/// Abrir e fechar um bloco de clínica.
const _kCollapseDuration = Duration(milliseconds: 170);

Duration _collapseDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : _kCollapseDuration;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow({required this.m});

  final DesktopAdminMetrics m;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    Widget h(String s, {double? w}) {
      final text = Text(s,
          maxLines: 1,
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
          h('Nome'),
          h('Papel', w: _wPapel(m)),
          h('Pacientes', w: _wPacientes(m)),
          h('Ativo', w: _wAtivo(m)),
          const SizedBox(width: _wMais),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Container(
      height: 42,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration:
          BoxDecoration(border: Border(bottom: BorderSide(color: t.bd2))),
      child: Semantics(
        header: true,
        child: Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: daText(context, t, weight: FontWeight.w700)),
      ),
    );
  }
}

class _ClinicHeader extends StatefulWidget {
  const _ClinicHeader({
    required this.name,
    required this.active,
    required this.total,
    required this.clinicIsActive,
    required this.open,
    required this.onTap,
  });

  final String name;
  final int active;
  final int total;
  final bool clinicIsActive;
  final bool open;
  final VoidCallback onTap;

  @override
  State<_ClinicHeader> createState() => _ClinicHeaderState();
}

class _ClinicHeaderState extends State<_ClinicHeader> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        expanded: widget.open,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: daHoverDuration(context),
            height: 46,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _hover ? t.hov : t.bg,
              border: Border(bottom: BorderSide(color: t.bd2)),
            ),
            child: Row(
              children: [
                AnimatedRotation(
                  // ▾ aberto, ▸ fechado.
                  turns: widget.open ? 0 : -0.25,
                  duration: _collapseDuration(context),
                  child: Icon(Icons.arrow_drop_down, size: 24, color: t.tx2),
                ),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: daText(context, t, weight: FontWeight.w600)),
                ),
                const SizedBox(width: 10),
                DaTag('${widget.active}/${widget.total} ativos', bg: t.hov2),
                if (!widget.clinicIsActive) ...[
                  const SizedBox(width: 8),
                  DaTag('Inativa', bg: t.hov2, fg: t.err),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Altura que abre e fecha; fechado, o conteúdo sai da árvore.
class _Collapsible extends StatefulWidget {
  const _Collapsible({required this.open, required this.child});

  final bool open;
  final Widget child;

  @override
  State<_Collapsible> createState() => _CollapsibleState();
}

class _CollapsibleState extends State<_Collapsible>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, value: widget.open ? 1 : 0);
  late final CurvedAnimation _curved =
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _controller.duration = _collapseDuration(context);
  }

  @override
  void didUpdateWidget(_Collapsible old) {
    super.didUpdateWidget(old);
    if (old.open != widget.open) {
      widget.open ? _controller.forward() : _controller.reverse();
    }
  }

  @override
  void dispose() {
    _curved.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      child: widget.child,
      builder: (context, child) {
        if (!widget.open && _controller.isDismissed) {
          return const SizedBox.shrink();
        }
        return ClipRect(
          child: Align(
            alignment: Alignment.topCenter,
            heightFactor: _curved.value,
            child: IgnorePointer(ignoring: !widget.open, child: child),
          ),
        );
      },
    );
  }
}

class _UserTr extends StatefulWidget {
  const _UserTr({
    super.key,
    required this.user,
    required this.m,
    required this.selected,
    required this.isMe,
    required this.canDelete,
    required this.actions,
    required this.onOpen,
  });

  final ClinicUser user;
  final DesktopAdminMetrics m;
  final bool selected;
  final bool isMe;
  final bool canDelete;
  final DesktopUserActions actions;
  final VoidCallback onOpen;

  @override
  State<_UserTr> createState() => _UserTrState();
}

class _UserTrState extends State<_UserTr> {
  bool _hover = false;
  bool _menuOpen = false;
  final _menu = MenuController();

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final u = widget.user;
    final m = widget.m;
    final psy = u.role == ProfileRole.psychologist;
    final showMore = _hover || widget.selected || _menuOpen || m.tablet;
    final a = widget.actions;

    Widget cell(Widget child, {double? w, Alignment al = Alignment.centerLeft}) =>
        w == null
            ? Expanded(child: child)
            : SizedBox(width: w, child: Align(alignment: al, child: child));

    // Pacientes e convites já reservados, junto do limite.
    final slots = u.reservedPatientSlots;
    final patients = !psy
        ? '—'
        : !u.canReceivePatients
            ? '$slots · novos bloqueados'
            : (u.patientAssignmentLimit == null
                ? '$slots · sem limite'
                : '$slots de ${u.patientAssignmentLimit}');
    final practiceOff = u.isPersonalClinic && !u.clinicIsActive;
    final practiceTag = DaTag('Consultório inativo', bg: t.hov2, fg: t.err);
    final email = Text(u.email,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: daText(context, t, size: 12, color: t.tx3));

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onOpen,
        child: AnimatedContainer(
          duration: daHoverDuration(context),
          // No tablet o selo do consultório ganha uma 3ª linha.
          height: practiceOff && m.tablet ? m.row + 24 : m.row,
          padding: const EdgeInsets.only(left: 18),
          decoration: BoxDecoration(
            color: widget.selected
                ? t.sel
                : (_hover ? t.hov : daClear(t.hov)),
            border: Border(
              bottom: BorderSide(color: t.bd),
              left: BorderSide(
                  color: widget.selected ? t.tq : daClear(t.tq), width: 3),
            ),
          ),
          child: Row(
            children: [
              cell(
                Row(
                  children: [
                    UserAvatar.parts(
                      fullName: u.fullName,
                      initials: u.initials,
                      role: u.role,
                      avatarType: u.avatarType,
                      photoUrl: u.photoUrl,
                      avatarConfig: u.avatarConfig,
                      size: 30,
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(u.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: daText(context, t, weight: FontWeight.w600)),
                          email,
                          if (practiceOff && m.tablet) practiceTag,
                        ],
                      ),
                    ),
                    if (practiceOff && !m.tablet) ...[
                      const SizedBox(width: 12),
                      practiceTag,
                    ],
                    const SizedBox(width: 10),
                  ],
                ),
              ),
              cell(
                psy ? DaTag.az(context, u.role.label) : DaTag.rx(context, u.role.label),
                w: _wPapel(m),
              ),
              cell(
                Text(patients,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: daText(context, t, color: psy ? t.tx : t.tx3)),
                w: _wPacientes(m),
              ),
              cell(
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DaSwitch(
                      value: u.isActive,
                      semantics: 'Ativo',
                      tablet: m.tablet,
                      onChanged: widget.isMe ? null : () => a.toggleActive(u),
                    ),
                    if (!u.isActive) ...[
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('Inativo',
                            maxLines: 1,
                            style: daText(context, t,
                                weight: FontWeight.w500, color: t.tx3)),
                      ),
                    ],
                  ],
                ),
                w: _wAtivo(m),
              ),
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
                      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
                      elevation: const WidgetStatePropertyAll(0),
                      shadowColor: WidgetStatePropertyAll(
                          const Color(0xFF0D1B3D).withValues(alpha: 0.22)),
                      padding: const WidgetStatePropertyAll(EdgeInsets.all(5)),
                      minimumSize: const WidgetStatePropertyAll(Size(220, 0)),
                      shape: WidgetStatePropertyAll(RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: t.bd2),
                      )),
                    ),
                    menuChildren: [
                      _item(context, t, u.isActive ? 'Inativar' : 'Ativar',
                          widget.isMe ? null : () => a.toggleActive(u)),
                      if (psy)
                        _item(context, t, 'Configurar acessos',
                            () => a.updateAccess(u)),
                      if (!widget.isMe &&
                          (psy || u.role == ProfileRole.platformAdmin))
                        _item(
                            context,
                            t,
                            psy ? 'Promover a administrador' : 'Rebaixar a psicólogo',
                            () => a.changeRole(u)),
                      _item(context, t, 'Excluir',
                          !widget.isMe && widget.canDelete ? () => a.delete(u) : null),
                    ],
                    builder: (context, c, _) => Align(
                      alignment: Alignment.center,
                      child: DaButton(
                        kind: DaButtonKind.ghost,
                        icon: Icons.more_horiz,
                        tooltip: 'Mais ações',
                        onPressed: () => c.isOpen ? c.close() : c.open(),
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

  Widget _item(BuildContext context, DesktopAdminTokens t, String label,
      VoidCallback? onTap) {
    return MenuItemButton(
      onPressed: onTap,
      style: ButtonStyle(
        minimumSize: const WidgetStatePropertyAll(Size(210, 36)),
        padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 10)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(6))),
        overlayColor: WidgetStatePropertyAll(t.hov),
      ),
      child: Text(label,
          style: daText(context, t,
              color: onTap == null ? t.tx3 : t.tx)),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.active});

  final bool active;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final c = active ? t.ok : t.tx3;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
        const SizedBox(width: 7),
        Text(active ? 'Ativo' : 'Inativo',
            style: daText(context, t, weight: FontWeight.w500, color: c)),
      ],
    );
  }
}

class _Detail extends StatelessWidget {
  const _Detail({required this.user});

  final ClinicUser user;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final psy = user.role == ProfileRole.psychologist;
    Widget row(String k, Widget v) => Container(
          constraints: const BoxConstraints(minHeight: 44),
          decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: t.bd))),
          child: Row(
            children: [
              SizedBox(
                width: 150,
                child: Text(k,
                    style: daText(context, t, size: 12.5, color: t.tx3)),
              ),
              Expanded(
                child: Align(alignment: Alignment.centerLeft, child: v),
              ),
            ],
          ),
        );
    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              UserAvatar.parts(
                fullName: user.fullName,
                initials: user.initials,
                role: user.role,
                avatarType: user.avatarType,
                photoUrl: user.photoUrl,
                avatarConfig: user.avatarConfig,
                size: 44,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user.fullName,
                        style: daText(context, t,
                            size: 16, weight: FontWeight.w600)),
                    Text(user.email,
                        style: daText(context, t, size: 12.5, color: t.tx3)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            decoration: BoxDecoration(
                border: Border(top: BorderSide(color: t.bd))),
            child: Column(
              children: [
                row('Papel',
                    psy ? DaTag.az(context, user.role.label) : DaTag.rx(context, user.role.label)),
                row('Status', _StatusDot(active: user.isActive)),
                row(
                  'Vínculo',
                  Wrap(
                    spacing: 10,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(user.clinicName,
                          style: daText(context, t, weight: FontWeight.w500)),
                      DaTag(user.clinicTypeLabel),
                    ],
                  ),
                ),
                if (psy)
                  row(
                    'Pacientes/convites',
                    Text(user.patientAccessSummary,
                        style: daText(context, t, weight: FontWeight.w500)),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
