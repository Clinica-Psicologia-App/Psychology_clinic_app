import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import 'responsive_content.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.centerBody = false,
    this.useResponsivePadding = false,
    this.accent,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool centerBody;
  final bool useResponsivePadding;

  /// Cor do módulo da tela. Quando informada, a barra ganha o tratamento
  /// "premium enxuto": uma tinta discreta do acento no fundo e um fio de luz
  /// da cor sob o título — a versão leve do canopy para telas de lista e
  /// detalhe, onde um hero de gradiente sufocaria o conteúdo. Sem [accent], a
  /// barra fica no visual neutro de sempre.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final accent = this.accent;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: subtitle == null
            ? Text(title)
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  Text(
                    subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                  ),
                ],
              ),
        actions: actions,
        backgroundColor: _accentBarBackground(accent),
        bottom: _accentBarLine(accent),
      ),
      body: SafeArea(
        child: useResponsivePadding
            ? ResponsiveContent(
                child: centerBody ? Center(child: body) : body,
              )
            : (centerBody ? Center(child: body) : body),
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Shell das telas com [AppCanopyHeader]: sem AppBar Material, para o
/// gradiente do canopy subir até o topo (atrás da status bar). O [body] é o
/// scroll do chamador, cujo primeiro item é o canopy full-bleed — ele mesmo
/// reserva o inset da status bar via `MediaQuery.paddingOf(context).top`.
/// As bordas inferior/laterais continuam protegidas por [SafeArea].
class AppCanopyScaffold extends StatelessWidget {
  const AppCanopyScaffold({
    super.key,
    required this.body,
    this.floatingActionButton,
  });

  final Widget body;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      body: SafeArea(
        top: false,
        child: body,
      ),
      floatingActionButton: floatingActionButton,
    );
  }
}

/// Shell com largura máxima para formulários e auth.
class AppFormScaffold extends StatelessWidget {
  const AppFormScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.accent,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;

  /// Cor do módulo, igual a [AppScaffold.accent]: dá o mesmo tratamento
  /// premium enxuto à barra dos formulários.
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
      appBar: AppBar(
        title: Text(title),
        actions: actions,
        backgroundColor: _accentBarBackground(accent),
        bottom: _accentBarLine(accent),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isWide ? 960 : AppSpacing.formMaxWidth,
            ),
            child: body,
          ),
        ),
      ),
    );
  }
}

/// Fundo da barra com uma tinta discreta do acento do módulo (a versão leve
/// do canopy). `null` mantém o fundo neutro padrão da barra.
Color? _accentBarBackground(Color? accent) => accent == null
    ? null
    : Color.alphaBlend(
        accent.withValues(alpha: 0.05),
        AppColors.background,
      );

/// Fio de luz do acento sob o título — brilha no centro e some nas pontas.
PreferredSizeWidget? _accentBarLine(Color? accent) => accent == null
    ? null
    : PreferredSize(
        preferredSize: const Size.fromHeight(2.5),
        child: Container(
          height: 2.5,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                accent.withValues(alpha: 0.0),
                accent.withValues(alpha: 0.85),
                accent.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      );
