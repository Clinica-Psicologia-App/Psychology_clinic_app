import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import 'neural_header_background.dart';
import 'responsive_content.dart';

/// Fundo com blobs circulares suaves nos cantos, inspirado no diagrama do
/// genograma. Quando [accent] é informado, o blob principal usa essa cor;
/// caso contrário, usa o teal padrão do app.
class AppBlobBackground extends StatelessWidget {
  const AppBlobBackground({super.key, required this.child, this.accent});

  final Widget child;
  final Color? accent;

  static const _defaultBlob = Color(0xFF0F9C90);
  static const _secondaryBlob = Color(0xFF1F7A8C);

  @override
  Widget build(BuildContext context) {
    final primary = accent ?? _defaultBlob;
    return Stack(
      children: [
        Positioned(
          top: -120,
          left: -100,
          child: _blob(340, primary.withValues(alpha: 0.10)),
        ),
        Positioned(
          bottom: -130,
          right: -110,
          child: _blob(370, _secondaryBlob.withValues(alpha: 0.09)),
        ),
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

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
    // On wide screens (web/desktop), always apply responsive max-width so
    // content doesn't stretch awkwardly across the full viewport.
    final effectiveResponsive = useResponsivePadding || AppBreakpoints.isWide(context);
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
        actions: actions,
        backgroundColor: _accentBarBackground(accent, context),
        bottom: _accentBarLine(accent),
      ),
      body: SafeArea(
        child: AppBlobBackground(
          accent: accent,
          child: effectiveResponsive
              ? ResponsiveContent(
                  child: centerBody ? Center(child: body) : body,
                )
              : (centerBody ? Center(child: body) : body),
        ),
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
        child: AppBlobBackground(child: body),
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
        backgroundColor: _accentBarBackground(accent, context),
        bottom: _accentBarLine(accent),
      ),
      body: SafeArea(
        child: AppBlobBackground(
          accent: accent,
          child: Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isWide ? 960 : AppSpacing.formMaxWidth,
              ),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

/// Fundo da barra com uma tinta discreta do acento do módulo (a versão leve
/// do canopy). `null` mantém o fundo neutro padrão da barra.
Color? _accentBarBackground(Color? accent, BuildContext context) => accent == null
    ? null
    : Color.alphaBlend(
        accent.withValues(alpha: 0.05),
        Theme.of(context).colorScheme.surfaceContainerLow,
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

// ───────────────────────────────────────────────────────────────────────────
// Header full-bleed reutilizável (padrão das telas do psicólogo).
// ───────────────────────────────────────────────────────────────────────────

/// Uma métrica exibida na barra de stats do [AppSectionScaffold].
class AppSectionStat {
  const AppSectionStat({required this.value, required this.label, this.accent});

  final String value;
  final String label;
  final Color? accent;
}

/// Scaffold de seção com header full-bleed em gradiente (nav embutida, título,
/// subtítulo, stats e ação primária), no mesmo padrão das telas do psicólogo.
/// Substituto quase drop-in do [AppScaffold] para telas de listagem/catálogo.
class AppSectionScaffold extends StatelessWidget {
  const AppSectionScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions = const [],
    this.stats = const [],
    this.primaryActionLabel,
    this.primaryActionIcon,
    this.onPrimaryAction,
    this.bottom,
    this.floatingActionButton,
    this.onBack,
  });

  final String title;
  final Widget body;
  final String? subtitle;
  final List<Widget> actions;
  final List<AppSectionStat> stats;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final VoidCallback? onPrimaryAction;

  /// Widget opcional preso ao rodapé do banner (ex.: uma [TabBar]). Quando
  /// presente, o header fica com base reta (sem a onda).
  final Widget? bottom;
  final Widget? floatingActionButton;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    return AppCanopyScaffold(
      floatingActionButton: floatingActionButton,
      body: Column(
        children: [
          _SectionBanner(
            title: title,
            subtitle: subtitle,
            actions: actions,
            stats: stats,
            primaryActionLabel: primaryActionLabel,
            primaryActionIcon: primaryActionIcon,
            onPrimaryAction: onPrimaryAction,
            bottom: bottom,
            onBack: onBack ?? () => Navigator.of(context).maybePop(),
          ),
          Expanded(child: body),
        ],
      ),
    );
  }
}

class _SectionBanner extends StatelessWidget {
  const _SectionBanner({
    required this.title,
    required this.subtitle,
    required this.actions,
    required this.stats,
    required this.primaryActionLabel,
    required this.primaryActionIcon,
    required this.onPrimaryAction,
    required this.bottom,
    required this.onBack,
  });

  final String title;
  final String? subtitle;
  final List<Widget> actions;
  final List<AppSectionStat> stats;
  final String? primaryActionLabel;
  final IconData? primaryActionIcon;
  final VoidCallback? onPrimaryAction;
  final Widget? bottom;
  final VoidCallback onBack;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1B2D5B), Color(0xFF1E4D8C), Color(0xFF0D7A75)],
    stops: [0.0, 0.55, 1.0],
  );

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isWide(context)) return _buildCompact(context);

    final theme = Theme.of(context);
    final statusBarTop = MediaQuery.paddingOf(context).top;
    final tall = stats.isNotEmpty ||
        (onPrimaryAction != null && primaryActionLabel != null);
    final hasBody = subtitle != null || tall;

    return ClipPath(
      clipper: const _SectionWaveClipper(),
      child: Container(
        decoration: const BoxDecoration(gradient: _gradient),
        child: Stack(
          children: [
            const Positioned.fill(child: NeuralHeaderBackground()),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: statusBarTop),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onBack,
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    tooltip: 'Voltar',
                  ),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (actions.isNotEmpty)
                    IconTheme(
                      data: const IconThemeData(color: Colors.white),
                      child: Row(mainAxisSize: MainAxisSize.min, children: actions),
                    ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.lg,
                hasBody ? AppSpacing.sm : 0,
                AppSpacing.lg,
                bottom != null
                    ? AppSpacing.sm
                    : (tall ? 48 : (subtitle != null ? 64 : 32)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.82),
                        height: 1.35,
                      ),
                    ),
                  if (stats.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: AppRadius.smAll,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            for (var i = 0; i < stats.length; i++) ...[
                              if (i > 0) _SectionStatDivider(),
                              _SectionStatCell(stat: stats[i]),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (onPrimaryAction != null && primaryActionLabel != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: _SectionGlassButton(
                        onPressed: onPrimaryAction!,
                        icon: primaryActionIcon ?? Icons.add,
                        label: primaryActionLabel!,
                        filled: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (bottom != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 38),
                child: bottom!,
              ),
          ],
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: const BoxDecoration(gradient: _gradient),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.white,
              size: 20,
            ),
            tooltip: 'Voltar',
          ),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                    ),
                  ),
              ],
            ),
          ),
          if (onPrimaryAction != null && primaryActionLabel != null) ...[
            const SizedBox(width: AppSpacing.md),
            _SectionGlassButton(
              onPressed: onPrimaryAction!,
              icon: primaryActionIcon ?? Icons.add,
              label: primaryActionLabel!,
              filled: true,
            ),
          ],
          if (actions.isNotEmpty) ...[
            const SizedBox(width: AppSpacing.xs),
            IconTheme(
              data: const IconThemeData(color: Colors.white),
              child: Row(mainAxisSize: MainAxisSize.min, children: actions),
            ),
          ],
        ],
      ),
          if (bottom != null) bottom!,
        ],
      ),
    );
  }
}

class _SectionStatCell extends StatelessWidget {
  const _SectionStatCell({required this.stat});

  final AppSectionStat stat;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              stat.value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: stat.accent ?? Colors.white.withValues(alpha: 0.9),
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              stat.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

class _SectionWaveClipper extends CustomClipper<Path> {
  const _SectionWaveClipper();

  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 36)
      ..cubicTo(
        size.width * 0.22,
        size.height + 2,
        size.width * 0.72,
        size.height - 30,
        size.width,
        size.height - 8,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(_SectionWaveClipper oldClipper) => false;
}

class _SectionGlassButton extends StatelessWidget {
  const _SectionGlassButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.filled = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? AppColors.turquoise
          : Colors.white.withValues(alpha: 0.12),
      borderRadius: AppRadius.smAll,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.smAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smAll,
            border: filled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: Colors.white),
              const SizedBox(width: 7),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
