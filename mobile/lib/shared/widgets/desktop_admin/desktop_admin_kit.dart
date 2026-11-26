import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Tokens do admin em linguagem de desktop (≥ 768 px). Cores = identidade do
/// app (CONTEXTO.md); o escuro segue o protótipo `desktop_v2/admin.css`.
class DesktopAdminTokens {
  const DesktopAdminTokens({
    required this.bg,
    required this.side,
    required this.rz,
    required this.hov,
    required this.hov2,
    required this.sel,
    required this.bd,
    required this.bd2,
    required this.tx,
    required this.tx2,
    required this.tx3,
    required this.ac,
    required this.onAc,
    required this.foc,
    required this.tq,
    required this.ok,
    required this.err,
    required this.dark,
  });

  final Color bg, side, rz, hov, hov2, sel, bd, bd2;
  final Color tx, tx2, tx3, ac, onAc, foc, tq, ok, err;
  final bool dark;

  static const light = DesktopAdminTokens(
    bg: Color(0xFFFDFDFF),
    side: Color(0xFFF4F6FC),
    rz: Color(0xFFFFFFFF),
    hov: Color(0xFFEFF3FC),
    hov2: Color(0xFFE2E9F6),
    sel: Color(0xFFE6F7F6),
    bd: Color(0xFFE2E9F6),
    bd2: Color(0xFFCBD7EC),
    tx: Color(0xFF0D1B3D),
    tx2: Color(0xFF4A5568),
    tx3: Color(0xFF718096),
    ac: Color(0xFF0D1B3D),
    onAc: Color(0xFFFFFFFF),
    foc: Color(0xFF0EA5A0),
    tq: Color(0xFF00A39B),
    ok: Color(0xFF059669),
    err: Color(0xFFDC2626),
    dark: false,
  );

  static const darkTheme = DesktopAdminTokens(
    bg: Color(0xFF1A2130),
    side: Color(0xFF151B28),
    rz: Color(0xFF232D3F),
    hov: Color(0xFF2A3449),
    hov2: Color(0xFF33405A),
    sel: Color(0xFF1F3B45),
    bd: Color(0xFF2D3B55),
    bd2: Color(0xFF3D4D6C),
    tx: Color(0xFFEDF1FA),
    tx2: Color(0xFFB0BDD5),
    tx3: Color(0xFF7C8CA8),
    ac: Color(0xFFEDF1FA),
    onAc: Color(0xFF0D1B3D),
    foc: Color(0xFF0EA5A0),
    tq: Color(0xFF4FD1C5),
    ok: Color(0xFF34D399),
    err: Color(0xFFF87171),
    dark: true,
  );

  static DesktopAdminTokens of(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark ? darkTheme : light;

  static const teal = Color(0xFF00B2A9);
  static const blue = Color(0xFF3B82F6);
  static const purple = Color(0xFF7B5CF6);
  static const cyan = Color(0xFF0096D6);

  /// Fio de 3 px no topo da casca.
  static const brandGradient = LinearGradient(colors: [teal, blue, purple]);
}

/// Medidas por faixa de largura (tablet 768–1023, notebook, desktop ≥ 1440).
class DesktopAdminMetrics {
  const DesktopAdminMetrics._(this.size, this.ctl, this.row, this.tb, this.sb,
      this.pad, this.font);

  final DesktopAdminSize size;
  final double ctl; // altura de campo e botão
  final double row; // linha de tabela
  final double tb; // barra superior
  final double sb; // menu lateral expandido
  final double pad; // margem do conteúdo
  final double font; // corpo

  bool get tablet => size == DesktopAdminSize.tablet;

  static DesktopAdminMetrics of(double width) {
    if (width >= 1440) {
      return const DesktopAdminMetrics._(
          DesktopAdminSize.desktop, 44, 56, 64, 256, 32, 14);
    }
    if (width >= 1024) {
      return const DesktopAdminMetrics._(
          DesktopAdminSize.notebook, 40, 52, 56, 232, 24, 13);
    }
    return const DesktopAdminMetrics._(
        DesktopAdminSize.tablet, 48, 60, 60, 76, 20, 14);
  }
}

enum DesktopAdminSize { tablet, notebook, desktop }

/// Largura mínima em que o admin usa a linguagem de desktop.
const double kDesktopAdminMinWidth = 768;

bool isDesktopAdminWidth(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= kDesktopAdminMinWidth;

/// Estilo de texto do admin desktop (Poppins vem do tema do app).
TextStyle daText(BuildContext context, DesktopAdminTokens t,
    {double? size, FontWeight weight = FontWeight.w400, Color? color}) {
  final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
  final base = Theme.of(context).textTheme.bodyMedium ?? const TextStyle();
  return base.copyWith(
    fontSize: size ?? m.font,
    fontWeight: weight,
    color: color ?? t.tx,
    height: 1.4,
  );
}

enum DaButtonKind { primary, outline, ghost }

/// Realce de hover (linhas e botões dentro delas).
const kDaHoverDuration = Duration(milliseconds: 140);

/// Instantâneo com "reduzir movimento".
Duration daHoverDuration(BuildContext context) =>
    MediaQuery.disableAnimationsOf(context) ? Duration.zero : kDaHoverDuration;

/// A mesma cor, invisível. [Colors.transparent] é preto com alfa 0: animar dele
/// para uma cor clara passa por um cinza escuro (a "piscada" no hover).
Color daClear(Color color) => color.withValues(alpha: 0);

/// Botão de desktop: altura de controle, raio 8, hover e foco visíveis.
class DaButton extends StatefulWidget {
  const DaButton({
    super.key,
    this.label,
    this.icon,
    this.onPressed,
    this.kind = DaButtonKind.outline,
    this.tooltip,
    this.danger = false,
    this.expand = false,
  });

  final String? label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final DaButtonKind kind;
  final String? tooltip;
  final bool danger;
  final bool expand;

  @override
  State<DaButton> createState() => _DaButtonState();
}

class _DaButtonState extends State<DaButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final enabled = widget.onPressed != null;
    final primary = widget.kind == DaButtonKind.primary;
    final ghost = widget.kind == DaButtonKind.ghost;
    final fg = widget.danger
        ? t.err
        : primary
            ? t.onAc
            : (ghost ? t.tx2 : t.tx);
    final bg = primary
        ? t.ac
        : _hover
            ? (ghost ? t.hov2 : t.hov)
            : (ghost ? daClear(t.hov2) : t.rz);
    final border = primary
        ? t.ac
        : ghost
            ? daClear(t.bd2)
            : (_hover ? t.tx3 : t.bd2);
    final iconOnly = widget.label == null;

    Widget child = AnimatedContainer(
      duration: daHoverDuration(context),
      height: m.ctl,
      width: iconOnly ? m.ctl : null,
      padding: iconOnly ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (widget.icon != null)
            Icon(widget.icon, size: 16, color: fg),
          if (widget.icon != null && widget.label != null)
            const SizedBox(width: 8),
          if (widget.label != null)
            Flexible(
              child: Text(
                widget.label!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: daText(context, t,
                    weight: primary ? FontWeight.w600 : FontWeight.w500,
                    color: fg),
              ),
            ),
        ],
      ),
    );
    child = Opacity(opacity: enabled ? 1 : 0.45, child: child);
    child = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
      child: Semantics(
        button: true,
        enabled: enabled,
        label: widget.tooltip ?? widget.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onPressed,
          child: child,
        ),
      ),
    );
    if (widget.tooltip != null) {
      child = Tooltip(
          message: widget.tooltip!,
          waitDuration: const Duration(milliseconds: 400),
          child: child);
    }
    return child;
  }
}

/// Etiqueta (papel, tipo, status de grupo).
class DaTag extends StatelessWidget {
  const DaTag(this.label, {super.key, this.fg, this.bg, this.icon});

  final String label;
  final Color? fg;
  final Color? bg;
  final IconData? icon;

  factory DaTag.ok(BuildContext c, String label) {
    final d = DesktopAdminTokens.of(c).dark;
    return DaTag(label,
        bg: d ? const Color(0xFF0F3B30) : const Color(0xFFD1FAE5),
        fg: d ? const Color(0xFF6EE7B7) : const Color(0xFF065F46));
  }

  factory DaTag.az(BuildContext c, String label, {IconData? icon}) {
    final d = DesktopAdminTokens.of(c).dark;
    return DaTag(label,
        icon: icon,
        bg: d ? const Color(0xFF12384F) : const Color(0xFFE0F2FE),
        fg: d ? const Color(0xFF7DD3FC) : const Color(0xFF075985));
  }

  factory DaTag.rx(BuildContext c, String label) {
    final d = DesktopAdminTokens.of(c).dark;
    return DaTag(label,
        bg: d ? const Color(0xFF2F2A55) : const Color(0xFFF0EDFE),
        fg: d ? const Color(0xFFC4B5FD) : const Color(0xFF5B3FD0));
  }

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final f = fg ?? t.tx2;
    return Container(
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: bg ?? t.hov,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: f),
            const SizedBox(width: 5),
          ],
          Text(label,
              maxLines: 1,
              style: daText(context, t,
                  size: 11.5, weight: FontWeight.w600, color: f)),
        ],
      ),
    );
  }
}

/// Avatar de iniciais (turquesa), como no protótipo.
class DaInitials extends StatelessWidget {
  const DaInitials(this.initials, {super.key, this.size = 30});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
          color: Color(0xFF00A39B), shape: BoxShape.circle),
      child: Text(initials,
          style: daText(context, t,
              size: size >= 40 ? 15 : 11,
              weight: FontWeight.w600,
              color: Colors.white)),
    );
  }
}

/// Quadrado de ícone com borda (32 px por padrão).
class DaIconBox extends StatelessWidget {
  const DaIconBox(this.icon,
      {super.key, required this.color, this.size = 32, this.radius = 8});

  final IconData icon;
  final Color color;
  final double size;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: t.rz,
        border: Border.all(color: t.bd2),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, size: size * 0.5, color: color),
    );
  }
}

/// Painel lateral (slide-over) de 440 px (500 ≥ 1440): fundo escurecido, Esc e
/// toque fora fecham. Conteúdo rola; o rodapé fica fixo.
Future<T?> showDesktopSlideOver<T>(
  BuildContext context, {
  required String title,
  required Widget child,
  Widget? footer,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Fechar painel',
    barrierColor: const Color(0xFF0D1B3D).withValues(alpha: 0.24),
    transitionDuration: const Duration(milliseconds: 250),
    pageBuilder: (ctx, _, __) {
      final t = DesktopAdminTokens.of(ctx);
      final w = MediaQuery.sizeOf(ctx).width;
      final m = DesktopAdminMetrics.of(w);
      final width = (w >= 1440 ? 500.0 : 440.0).clamp(0.0, w);
      return Align(
        alignment: Alignment.centerRight,
        child: Material(
          color: t.bg,
          elevation: 0,
          child: Container(
            width: width,
            decoration: BoxDecoration(
              color: t.bg,
              border: Border(left: BorderSide(color: t.bd2)),
              boxShadow: [
                BoxShadow(
                    color: (t.dark ? Colors.black : const Color(0xFF0D1B3D))
                        .withValues(alpha: t.dark ? 0.5 : 0.14),
                    blurRadius: 32,
                    offset: const Offset(0, 12)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  height: m.tb + 3,
                  padding: const EdgeInsets.fromLTRB(22, 3, 12, 0),
                  decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: t.bd))),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(title,
                            style: daText(ctx, t,
                                size: 15, weight: FontWeight.w600)),
                      ),
                      DaButton(
                        kind: DaButtonKind.ghost,
                        icon: Icons.close,
                        tooltip: 'Fechar',
                        // maybePop: o conteúdo pode segurar o fechamento.
                        onPressed: () => Navigator.of(ctx).maybePop(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                    child: Material(
                        type: MaterialType.transparency, child: child)),
                if (footer != null)
                  Container(
                    padding: const EdgeInsets.fromLTRB(22, 12, 22, 12),
                    decoration: BoxDecoration(
                        border: Border(top: BorderSide(color: t.bd))),
                    child: footer,
                  ),
              ],
            ),
          ),
        ),
      );
    },
    transitionBuilder: (ctx, anim, _, c) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween(begin: const Offset(1, 0), end: Offset.zero)
            .animate(curved),
        child: c,
      );
    },
  );
}

/// Switch de desktop: 36×20 (48×28 no tablet).
class DaSwitch extends StatelessWidget {
  const DaSwitch({
    required this.value,
    required this.onChanged,
    required this.semantics,
    required this.tablet,
  });

  final bool value;
  final VoidCallback? onChanged;
  final String semantics;
  final bool tablet;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final w = tablet ? 48.0 : 36.0;
    final h = tablet ? 28.0 : 20.0;
    final knob = h - 4;
    return Semantics(
      toggled: value,
      enabled: onChanged != null,
      label: semantics,
      child: MouseRegion(
        cursor: onChanged == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onChanged,
          child: Opacity(
            opacity: onChanged == null ? 0.5 : 1,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: w,
              height: h,
              decoration: BoxDecoration(
                color: value ? const Color(0xFF00A39B) : t.bd2,
                borderRadius: BorderRadius.circular(h / 2),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                curve: Curves.easeOutCubic,
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.all(2),
                  width: knob,
                  height: knob,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Color(0x4D0D1B3D), blurRadius: 2, offset: Offset(0, 1)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}


/// Campo de busca de desktop (lupa, foco turquesa). Com [onClear] e
/// [controller], mostra "Limpar busca" quando há texto (Esc também limpa).
class DaSearchField extends StatefulWidget {
  const DaSearchField({
    super.key,
    required this.onChanged,
    required this.hint,
    this.controller,
    this.onClear,
  });

  final ValueChanged<String> onChanged;
  final String hint;
  final TextEditingController? controller;
  final VoidCallback? onClear;

  @override
  State<DaSearchField> createState() => _DaSearchFieldState();
}

class _DaSearchFieldState extends State<DaSearchField> {
  final _focus = FocusNode();
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    final focused = _focus.hasFocus;
    final controller = widget.controller;
    final onClear = widget.onClear;
    final Widget field = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        height: m.ctl,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: t.rz,
          border: Border.all(
              color: focused ? t.foc : (_hover ? t.tx3 : t.bd2)),
          borderRadius: BorderRadius.circular(8),
          boxShadow: focused
              ? [BoxShadow(color: t.foc.withValues(alpha: 0.22), spreadRadius: 3)]
              : null,
        ),
        child: Row(
          children: [
            Icon(Icons.search, size: 16, color: t.tx3),
            const SizedBox(width: 10),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: _focus,
                onChanged: widget.onChanged,
                style: daText(context, t),
                cursorColor: t.foc,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  filled: false,
                  hintText: widget.hint,
                  hintStyle: daText(context, t, color: t.tx3),
                ),
              ),
            ),
            if (controller != null && onClear != null)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? const SizedBox.shrink()
                    : IconButton(
                        tooltip: 'Limpar busca',
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints.tightFor(
                            width: 28, height: 28),
                        iconSize: 16,
                        color: t.tx3,
                        onPressed: () {
                          onClear();
                          _focus.requestFocus();
                        },
                        icon: const Icon(Icons.close),
                      ),
              ),
          ],
        ),
      ),
    );
    if (onClear == null) return field;
    return CallbackShortcuts(
      bindings: {const SingleActivator(LogicalKeyboardKey.escape): onClear},
      child: field,
    );
  }
}

/// Uma opção do [DaSegmented].
class DaSegment<T> {
  const DaSegment(this.value, this.label, {this.count, this.icon});

  final T value;
  final String label;
  final int? count;
  final IconData? icon;
}

/// Controle segmentado: a opção marcada ganha fundo e borda.
class DaSegmented<T> extends StatelessWidget {
  const DaSegmented({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final T value;
  final List<DaSegment<T>> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    return Container(
      height: m.ctl,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: t.hov,
        border: Border.all(color: t.bd2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final it in items)
            Semantics(
              button: true,
              selected: it.value == value,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onChanged(it.value),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: AnimatedContainer(
                    duration: daHoverDuration(context),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: it.value == value ? t.rz : daClear(t.rz),
                      border: Border.all(
                          color: it.value == value ? t.bd2 : daClear(t.bd2)),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        if (it.icon != null) ...[
                          Icon(it.icon,
                              size: 16,
                              color: it.value == value ? t.tx : t.tx2),
                          const SizedBox(width: 8),
                        ],
                        Text(it.label,
                            style: daText(context, t,
                                weight: it.value == value
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                                color: it.value == value ? t.tx : t.tx2)),
                        if (it.count != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 7),
                            height: 18,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: it.value == value ? t.sel : t.hov2,
                              borderRadius: BorderRadius.circular(9),
                            ),
                            child: Text('${it.count}',
                                style: daText(context, t,
                                    size: 11,
                                    weight: FontWeight.w600,
                                    color: it.value == value ? t.tq : t.tx3)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}




/// Decoração de campo de desktop (borda 1 px, raio 8, foco turquesa).
InputDecoration daInputDecoration(DesktopAdminTokens t, {String? hint}) {
  OutlineInputBorder b(Color c, [double w = 1]) => OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: c, width: w));
  return InputDecoration(
    isDense: true,
    filled: true,
    fillColor: t.rz,
    hintText: hint,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
    border: b(t.bd2),
    enabledBorder: b(t.bd2),
    disabledBorder: b(t.bd),
    focusedBorder: b(t.foc, 1.5),
    errorBorder: b(t.err),
    focusedErrorBorder: b(t.err, 1.5),
  );
}

/// Rótulo acima do campo.
class DaLabeled extends StatelessWidget {
  const DaLabeled(this.label, {super.key, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(label,
              style: daText(context, t,
                  size: 12.5, weight: FontWeight.w500, color: t.tx2)),
        ),
        child,
      ],
    );
  }
}

/// Campo de texto com rótulo acima.
class DaTextField extends StatelessWidget {
  const DaTextField(
    this.label,
    this.controller, {
    super.key,
    this.required = false,
    this.number = false,
    this.lines = 1,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final bool required;
  final bool number;
  final int lines;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return DaLabeled(
      label,
      child: TextFormField(
        controller: controller,
        maxLines: lines,
        keyboardType: number ? TextInputType.number : null,
        inputFormatters:
            number ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: daText(context, t),
        cursorColor: t.foc,
        decoration: daInputDecoration(t, hint: hint),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null
            : null,
      ),
    );
  }
}

/// Lista suspensa com rótulo acima.
class DaDropdown<T> extends StatelessWidget {
  const DaDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return DaLabeled(
      label,
      child: DropdownButtonFormField<T>(
        initialValue: value,
        isExpanded: true,
        decoration: daInputDecoration(t),
        style: daText(context, t),
        items: items,
        onChanged: onChanged,
      ),
    );
  }
}

/// Grade de 2 colunas; `(widget, true)` ocupa a linha inteira.
class DaGrid extends StatelessWidget {
  const DaGrid(this.cells, {super.key});

  final List<(Widget, bool)> cells;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, c) {
          final half = (c.maxWidth - 16) / 2;
          return Wrap(
            spacing: 16,
            runSpacing: 14,
            children: [
              for (final cell in cells)
                SizedBox(
                    width: cell.$2 || c.maxWidth < 520 ? c.maxWidth : half,
                    child: cell.$1),
            ],
          );
        },
      );
}

/// Item do índice lateral dos editores.
class DaIndexItem extends StatefulWidget {
  const DaIndexItem(
      {super.key,
      required this.label,
      required this.active,
      required this.onTap});

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  State<DaIndexItem> createState() => _DaIndexItemState();
}

class _DaIndexItemState extends State<DaIndexItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: daHoverDuration(context),
          height: 36,
          alignment: Alignment.centerLeft,
          margin: const EdgeInsets.only(bottom: 2),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: widget.active
                ? t.rz
                : (_hover ? t.hov2 : daClear(t.hov2)),
            border:
                Border.all(color: widget.active ? t.bd2 : daClear(t.bd2)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(widget.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: daText(context, t,
                  weight: widget.active ? FontWeight.w600 : FontWeight.w500,
                  color: widget.active ? t.tx : t.tx2)),
        ),
      ),
    );
  }
}

/// Diálogo de confirmação de desktop (440 px); botão de ação vermelho quando
/// [danger]. Devolve true ao confirmar.
Future<bool> showDaConfirm(
  BuildContext context, {
  required String title,
  required String body,
  required String confirmLabel,
  bool danger = false,
}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      constraints: const BoxConstraints(maxWidth: 440),
      title: Text(title),
      content: Text(body),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(backgroundColor: const Color(0xFFDC2626))
              : null,
          onPressed: () => Navigator.of(ctx).pop(true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return r ?? false;
}
