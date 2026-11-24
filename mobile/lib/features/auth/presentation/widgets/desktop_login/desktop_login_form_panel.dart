import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_router.dart';
import '../../../../../core/theme/app_animations.dart';
import '../../../../../shared/widgets/app_motion.dart';
import 'desktop_login_tokens.dart';

/// Painel do formulário do login desktop (C2). Mesmos campos, textos e
/// validadores do formulário do celular; a lógica de entrar fica na página
/// (`onSubmit`).
class DesktopLoginFormPanel extends StatefulWidget {
  const DesktopLoginFormPanel({
    super.key,
    required this.formKey,
    required this.emailController,
    required this.passwordController,
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.redirectMsg,
    required this.isLoading,
    required this.onSubmit,
    required this.onForgotPassword,
    required this.onFillSeed,
    required this.showTestAccounts,
    required this.size,
  });

  final GlobalKey<FormState> formKey;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final String? redirectMsg;
  final bool isLoading;
  final VoidCallback onSubmit;
  final VoidCallback onForgotPassword;
  final void Function(String email) onFillSeed;
  final bool showTestAccounts;
  final DesktopLoginSize size;

  @override
  State<DesktopLoginFormPanel> createState() => _DesktopLoginFormPanelState();
}

class _DesktopLoginFormPanelState extends State<DesktopLoginFormPanel>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shake;

  @override
  void initState() {
    super.initState();
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
  }

  @override
  void dispose() {
    _shake.dispose();
    super.dispose();
  }

  /// Valida; se falhar, treme o painel (os campos mostram a mensagem).
  /// Se passar, entrega para a lógica de login da página.
  void _submit() {
    if (!widget.formKey.currentState!.validate()) {
      if (AppAnimations.shouldAnimate(context)) _shake.forward(from: 0);
      return;
    }
    widget.onSubmit();
  }

  double get _dx {
    // ±6 px em 340 ms (como o protótipo)
    final t = _shake.value;
    if (t == 0 || t == 1) return 0;
    return TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: -6), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -6, end: 5), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 5, end: -4), weight: 20),
      TweenSequenceItem(tween: Tween(begin: -4, end: 2), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 2, end: 0), weight: 20),
    ]).transform(t);
  }

  @override
  Widget build(BuildContext context) {
    final tk = DesktopLoginTokens.of(context);
    final theme = Theme.of(context);
    final size = widget.size;
    final pad = switch (size) {
      DesktopLoginSize.desktop => const EdgeInsets.fromLTRB(56, 48, 56, 40),
      DesktopLoginSize.notebook => const EdgeInsets.fromLTRB(40, 36, 40, 30),
      DesktopLoginSize.tablet => const EdgeInsets.fromLTRB(36, 28, 36, 22),
    };
    final ctl = switch (size) {
      DesktopLoginSize.desktop => 44.0,
      DesktopLoginSize.notebook => 40.0,
      DesktopLoginSize.tablet => 48.0,
    };
    final showEnter = size != DesktopLoginSize.tablet &&
        defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS;
    final h1 = size == DesktopLoginSize.desktop ? 30.0 : 26.0;

    final body = Form(
      key: widget.formKey,
      child: AutofillGroup(
        child: MotionStaggered(
          interval: const Duration(milliseconds: 70),
          children: [
            Text(
              'Bem-vindo de volta',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: tk.tx,
                fontWeight: FontWeight.w700,
                fontSize: h1,
                height: 1.1,
                letterSpacing: -.01 * h1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Entre com seu e-mail e senha para acessar sua área.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tk.tx2,
                fontSize: 13.5,
                height: 1.35,
              ),
            ),
            if (widget.redirectMsg != null) ...[
              const SizedBox(height: 12),
              MaterialBanner(
                backgroundColor: const Color(0xFFE0F2FE),
                content: Text(widget.redirectMsg!),
                actions: const [SizedBox.shrink()],
              ),
            ],
            _Label('E-mail', tk: tk, top: size == DesktopLoginSize.tablet ? 12 : 16),
            DesktopLoginField(
              fieldKey: const ValueKey('desktop_login_email'),
              controller: widget.emailController,
              enabled: !widget.isLoading,
              keyboardType: TextInputType.emailAddress,
              autofillHints: const [AutofillHints.email],
              textInputAction: TextInputAction.next,
              icon: Icons.email_outlined,
              height: ctl,
              tk: tk,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Informe o e-mail';
                if (!v.contains('@')) return 'E-mail inválido';
                return null;
              },
            ),
            _Label('Senha', tk: tk, top: size == DesktopLoginSize.tablet ? 12 : 16),
            DesktopLoginField(
              fieldKey: const ValueKey('desktop_login_password'),
              controller: widget.passwordController,
              enabled: !widget.isLoading,
              obscureText: widget.obscurePassword,
              autofillHints: const [AutofillHints.password],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              icon: Icons.lock_outline,
              height: ctl,
              tk: tk,
              suffix: Tooltip(
                message:
                    widget.obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                waitDuration: const Duration(milliseconds: 400),
                child: IconButton(
                  onPressed: widget.onTogglePassword,
                  splashRadius: 18,
                  icon: AnimatedSwitcher(
                    duration:
                        AppAnimations.resolve(context, const Duration(milliseconds: 180)),
                    transitionBuilder: (child, a) => FadeTransition(
                      opacity: a,
                      child: ScaleTransition(scale: a, child: child),
                    ),
                    child: Icon(
                      widget.obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      key: ValueKey(widget.obscurePassword),
                      size: 18,
                      color: tk.tx3,
                    ),
                  ),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Informe a senha';
                return null;
              },
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: widget.isLoading ? null : widget.onForgotPassword,
                style: TextButton.styleFrom(
                  foregroundColor: tk.lk,
                  textStyle: theme.textTheme.labelLarge
                      ?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                child: const Text('Esqueci minha senha'),
              ),
            ),
            const SizedBox(height: 4),
            _SubmitButton(
              isLoading: widget.isLoading,
              onPressed: _submit,
              height: ctl,
              showEnter: showEnter,
              tk: tk,
            ),
            const SizedBox(height: 20),
            _AccessNote(tk: tk),
            if (widget.showTestAccounts) ...[
              const SizedBox(height: 12),
              Text('Contas de teste (ambiente local)',
                  style: theme.textTheme.labelMedium),
              const SizedBox(height: 4),
              Wrap(
                spacing: 4,
                runSpacing: 4,
                children: [
                  ActionChip(
                    label: const Text('Admin'),
                    onPressed: () =>
                        widget.onFillSeed('admin@clinicateste-mvp.example'),
                  ),
                  ActionChip(
                    label: const Text('Psicólogo'),
                    onPressed: () =>
                        widget.onFillSeed('psicologo@clinicateste-mvp.example'),
                  ),
                  ActionChip(
                    label: const Text('Paciente'),
                    onPressed: () => widget
                        .onFillSeed('paciente.login@clinicateste-mvp.example'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _shake,
      builder: (_, child) =>
          Transform.translate(offset: Offset(_dx, 0), child: child),
      child: DecoratedBox(
        key: const ValueKey('desktop_login_panel'),
        decoration: BoxDecoration(
          color: tk.rz,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: tk.bd2),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0D1B3D)
                  .withValues(alpha: tk.dark ? .35 : .10),
              blurRadius: 40,
              offset: const Offset(0, 18),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            children: [
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                height: 3,
                child: DecoratedBox(
                  decoration:
                      BoxDecoration(gradient: DesktopLoginTokens.brandGradient),
                ),
              ),
              Padding(padding: pad, child: body),
            ],
          ),
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text, {required this.tk, required this.top});
  final String text;
  final DesktopLoginTokens tk;
  final double top;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(top: top, bottom: 5),
        child: Text(
          text,
          style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w500, color: tk.tx2),
        ),
      );
}

/// Campo de desktop: borda de 1 px, raio 8, rótulo acima (fora do campo),
/// anel de foco que fecha de 8 para 3 px em 450 ms.
class DesktopLoginField extends StatefulWidget {
  const DesktopLoginField({
    super.key,
    this.fieldKey,
    required this.controller,
    required this.enabled,
    required this.icon,
    required this.height,
    required this.tk,
    this.obscureText = false,
    this.keyboardType,
    this.autofillHints,
    this.textInputAction,
    this.onFieldSubmitted,
    this.suffix,
    this.validator,
  });

  final Key? fieldKey;
  final TextEditingController controller;
  final bool enabled;
  final IconData icon;
  final double height;
  final DesktopLoginTokens tk;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Widget? suffix;
  final FormFieldValidator<String>? validator;

  @override
  State<DesktopLoginField> createState() => _DesktopLoginFieldState();
}

class _DesktopLoginFieldState extends State<DesktopLoginField>
    with SingleTickerProviderStateMixin {
  final _focus = FocusNode();
  late final AnimationController _ring;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _focus.addListener(() {
      if (_focus.hasFocus && AppAnimations.shouldAnimate(context)) {
        _ring.forward(from: 0);
      } else if (_focus.hasFocus) {
        _ring.value = 1;
      } else {
        _ring.value = 0;
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    _focus.dispose();
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tk = widget.tk;
    OutlineInputBorder border(Color c, [double wd = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: c, width: wd),
        );
    return AnimatedBuilder(
      animation: _ring,
      builder: (_, child) {
        final t = Curves.easeOutCubic.transform(_ring.value);
        final spread = _focus.hasFocus ? 8 - 5 * t : 0.0;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            boxShadow: _focus.hasFocus
                ? [
                    BoxShadow(
                      color: tk.foc.withValues(alpha: .22 * (0.2 + .8 * t)),
                      spreadRadius: spread,
                    ),
                  ]
                : const [],
          ),
          child: child,
        );
      },
      child: TextFormField(
        key: widget.fieldKey,
        focusNode: _focus,
        controller: widget.controller,
        enabled: widget.enabled,
        obscureText: widget.obscureText,
        keyboardType: widget.keyboardType,
        autocorrect: false,
        autofillHints: widget.autofillHints,
        textInputAction: widget.textInputAction,
        onFieldSubmitted: widget.onFieldSubmitted,
        validator: widget.validator,
        style: TextStyle(color: tk.tx, fontSize: 14),
        decoration: InputDecoration(
          isDense: true,
          filled: true,
          fillColor: tk.rz,
          prefixIcon: Icon(widget.icon, size: 16, color: tk.tx3),
          prefixIconConstraints: const BoxConstraints(minWidth: 40),
          suffixIcon: widget.suffix,
          suffixIconConstraints: const BoxConstraints(minWidth: 40),
          contentPadding: EdgeInsets.symmetric(
              horizontal: 12, vertical: (widget.height - 20) / 2),
          constraints: BoxConstraints(minHeight: widget.height),
          enabledBorder: border(tk.bd2),
          disabledBorder: border(tk.bd),
          focusedBorder: border(tk.foc),
          errorBorder: border(tk.err),
          focusedErrorBorder: border(tk.err, 1.5),
          errorStyle: TextStyle(
              color: tk.err, fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatefulWidget {
  const _SubmitButton({
    required this.isLoading,
    required this.onPressed,
    required this.height,
    required this.showEnter,
    required this.tk,
  });

  final bool isLoading;
  final VoidCallback onPressed;
  final double height;
  final bool showEnter;
  final DesktopLoginTokens tk;

  @override
  State<_SubmitButton> createState() => _SubmitButtonState();
}

class _SubmitButtonState extends State<_SubmitButton> {
  bool _hover = false;
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final tk = widget.tk;
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Listener(
        onPointerDown: (_) => setState(() => _down = true),
        onPointerUp: (_) => setState(() => _down = false),
        onPointerCancel: (_) => setState(() => _down = false),
        child: AnimatedScale(
          scale: _down ? .985 : 1,
          duration: AppAnimations.resolve(context, const Duration(milliseconds: 100)),
          child: AnimatedContainer(
            duration: AppAnimations.resolve(context, AppAnimations.fast),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: _hover && !widget.isLoading
                  ? [
                      BoxShadow(
                        color: const Color(0xFF0D1B3D).withValues(alpha: .22),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : const [],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: double.infinity,
                  height: widget.height,
                  child: FilledButton.icon(
                    onPressed: widget.isLoading ? null : widget.onPressed,
                    style: FilledButton.styleFrom(
                      backgroundColor: tk.ac,
                      foregroundColor: tk.onAc,
                      disabledBackgroundColor: tk.ac.withValues(alpha: .88),
                      disabledForegroundColor: tk.onAc,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                      textStyle: Theme.of(context)
                          .textTheme
                          .labelLarge
                          ?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    icon: AnimatedSwitcher(
                      duration:
                          AppAnimations.resolve(context, AppAnimations.fast),
                      child: widget.isLoading
                          ? const SizedBox(
                              key: ValueKey('loading'),
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.arrow_forward_rounded,
                              key: ValueKey('arrow'), size: 16),
                    ),
                    label: Text(widget.isLoading ? 'Entrando...' : 'Entrar'),
                  ),
                ),
                if (widget.showEnter && !widget.isLoading)
                  Positioned(
                    right: 10,
                    child: IgnorePointer(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                              color: tk.onAc.withValues(alpha: .35)),
                        ),
                        child: Text(
                          'Enter',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: tk.onAc.withValues(alpha: .8),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AccessNote extends StatelessWidget {
  const _AccessNote({required this.tk});
  final DesktopLoginTokens tk;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(border: Border(top: BorderSide(color: tk.bd))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.person_add_alt_outlined, size: 16, color: tk.tq),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Novo acesso?',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: tk.tx)),
                const SizedBox(height: 2),
                Text(
                  'Profissionais entram após cadastro administrativo. Pacientes entram pelo convite recebido.',
                  style: TextStyle(fontSize: 12.5, height: 1.5, color: tk.tx2),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Rodapé de links (Termos / Privacidade) do login desktop.
class DesktopLoginLegalLinks extends StatelessWidget {
  const DesktopLoginLegalLinks({super.key, required this.tk});
  final DesktopLoginTokens tk;

  @override
  Widget build(BuildContext context) {
    final style = TextButton.styleFrom(
      foregroundColor: tk.lk,
      textStyle: Theme.of(context)
          .textTheme
          .labelLarge
          ?.copyWith(fontWeight: FontWeight.w600, fontSize: 13),
      minimumSize: const Size(48, 40),
    );
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton(
          style: style,
          onPressed: () => context.push(AppRoutes.terms),
          child: const Text('Termos'),
        ),
        TextButton(
          style: style,
          onPressed: () => context.push(AppRoutes.privacy),
          child: const Text('Privacidade'),
        ),
      ],
    );
  }
}
