import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../auth/providers/auth_providers.dart';
import '../providers/profile_providers.dart';
import 'widgets/avatar_artwork.dart';
import 'widgets/avatar_palette.dart';

/// Editor do avatar geométrico.
///
/// O estado do avatar em edição é local à tela e só toca o perfil ao salvar:
/// sair sem salvar não deixa rastro, e a foto ou avatar anterior seguem
/// intactos se o salvamento falhar.
class AvatarEditorPage extends ConsumerStatefulWidget {
  const AvatarEditorPage({super.key});

  @override
  ConsumerState<AvatarEditorPage> createState() => _AvatarEditorPageState();
}

class _AvatarEditorPageState extends ConsumerState<AvatarEditorPage> {
  late AvatarConfig _config;
  late AvatarConfig _initial;
  _EditorCategory _category = _EditorCategory.skin;
  bool _saving = false;

  bool get _hasChanges => _config != _initial;

  @override
  void initState() {
    super.initState();
    // Abre no avatar já salvo, quando existe — o editor é reabrível.
    final saved = ref.read(authControllerProvider).valueOrNull?.avatarConfig;
    _initial = saved ?? AvatarConfig.initial;
    _config = _initial;
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(editProfileProvider.notifier).saveAvatarConfig(_config);
      if (!mounted) return;
      // Só depois do sucesso o ponto de comparação muda: se falhar, a tela
      // continua sabendo que há alterações pendentes.
      setState(() => _initial = _config);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar salvo.')),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar alterações?'),
        content: const Text('As mudanças no avatar não foram salvas.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar editando'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Descartar'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_hasChanges,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard() && mounted) navigator.pop();
      },
      child: AppScaffold(
        title: 'Meu avatar',
        useResponsivePadding: true,
        actions: [
          IconButton(
            tooltip: 'Combinação aleatória',
            onPressed: _saving
                ? null
                : () => setState(() => _config = AvatarConfig.random()),
            icon: const Icon(Icons.casino_outlined),
          ),
          IconButton(
            tooltip: 'Restaurar',
            onPressed: _saving || !_hasChanges
                ? null
                : () => setState(() => _config = _initial),
            icon: const Icon(Icons.restart_alt),
          ),
        ],
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: _Preview(config: _config),
            ),
            _CategoryBar(
              selected: _category,
              onSelect: (c) => setState(() => _category = c),
            ),
            Expanded(
              child: _OptionGrid(
                category: _category,
                config: _config,
                onChange: (c) => setState(() => _config = c),
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _hasChanges && !_saving ? _save : null,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_saving ? 'Salvando...' : 'Salvar avatar'),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({required this.config});

  final AvatarConfig config;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
          boxShadow: AppShadows.clay(),
        ),
        child: AvatarArtwork(config: config, size: 132),
      ),
    );
  }
}

// ── Categorias ───────────────────────────────────────────────────────────────

enum _EditorCategory {
  skin('Pele'),
  face('Rosto'),
  hair('Cabelo'),
  hairColor('Cor do cabelo'),
  eyes('Olhos'),
  eyebrows('Sobrancelhas'),
  nose('Nariz'),
  mouth('Boca'),
  facialHair('Barba'),
  glasses('Óculos'),
  accessory('Acessórios'),
  outfit('Roupa'),
  outfitColor('Cor da roupa'),
  background('Fundo');

  const _EditorCategory(this.label);
  final String label;
}

class _CategoryBar extends StatelessWidget {
  const _CategoryBar({required this.selected, required this.onSelect});

  final _EditorCategory selected;
  final ValueChanged<_EditorCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: _EditorCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
        itemBuilder: (context, index) {
          final category = _EditorCategory.values[index];
          return Center(
            child: ChoiceChip(
              label: Text(category.label),
              selected: category == selected,
              onSelected: (_) => onSelect(category),
            ),
          );
        },
      ),
    );
  }
}

// ── Opções ───────────────────────────────────────────────────────────────────

class _OptionGrid extends StatelessWidget {
  const _OptionGrid({
    required this.category,
    required this.config,
    required this.onChange,
  });

  final _EditorCategory category;
  final AvatarConfig config;
  final ValueChanged<AvatarConfig> onChange;

  @override
  Widget build(BuildContext context) {
    final options = _optionsFor(category, config);

    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 104,
        mainAxisSpacing: AppSpacing.sm,
        crossAxisSpacing: AppSpacing.sm,
        childAspectRatio: 0.78,
      ),
      itemCount: options.length,
      itemBuilder: (context, index) {
        final option = options[index];
        return _OptionTile(
          option: option,
          selected: option.config == config,
          onTap: () => onChange(option.config),
        );
      },
    );
  }
}

/// Uma escolha possível: o rótulo, a config resultante e — quando a opção é
/// uma cor — o valor a exibir como amostra.
class _Option {
  const _Option({required this.label, required this.config, this.swatch});

  final String label;
  final AvatarConfig config;
  final Color? swatch;
}

List<_Option> _optionsFor(_EditorCategory category, AvatarConfig config) {
  return switch (category) {
    _EditorCategory.skin => [
        for (final v in AvatarSkinTone.values)
          _Option(
            label: AvatarPalette.skinLabel(v),
            config: config.copyWith(skinTone: v),
          ),
      ],
    _EditorCategory.face => [
        for (final v in AvatarFaceShape.values)
          _Option(
            label: AvatarPalette.faceShapeLabel(v),
            config: config.copyWith(faceShape: v),
          ),
      ],
    _EditorCategory.nose => [
        for (final v in AvatarNose.values)
          _Option(
            label: AvatarPalette.noseLabel(v),
            config: config.copyWith(noseStyle: v),
          ),
      ],
    _EditorCategory.mouth => [
        for (final v in AvatarMouth.values)
          _Option(
            label: AvatarPalette.mouthLabel(v),
            config: config.copyWith(mouthStyle: v),
          ),
      ],
    _EditorCategory.accessory => [
        for (final v in AvatarAccessory.values)
          _Option(
            label: AvatarPalette.accessoryLabel(v),
            config: config.copyWith(accessory: v),
          ),
      ],
    _EditorCategory.hair => [
        for (final v in AvatarHairStyle.values)
          _Option(
            label: AvatarPalette.hairStyleLabel(v),
            config: config.copyWith(hairStyle: v),
          ),
      ],
    _EditorCategory.hairColor => [
        for (final v in AvatarHairColor.values)
          _Option(
            label: AvatarPalette.hairLabel(v),
            config: config.copyWith(hairColor: v),
            swatch: AvatarPalette.hair(v),
          ),
      ],
    _EditorCategory.eyes => [
        for (final v in AvatarEyeStyle.values)
          _Option(
            label: AvatarPalette.eyeLabel(v),
            config: config.copyWith(eyeStyle: v),
          ),
      ],
    _EditorCategory.eyebrows => [
        for (final v in AvatarEyebrowStyle.values)
          _Option(
            label: AvatarPalette.eyebrowLabel(v),
            config: config.copyWith(eyebrowStyle: v),
          ),
      ],
    _EditorCategory.facialHair => [
        for (final v in AvatarFacialHair.values)
          _Option(
            label: AvatarPalette.facialHairLabel(v),
            config: config.copyWith(facialHair: v),
          ),
      ],
    _EditorCategory.glasses => [
        for (final v in AvatarGlasses.values)
          _Option(
            label: AvatarPalette.glassesLabel(v),
            config: config.copyWith(glasses: v),
          ),
      ],
    _EditorCategory.outfit => [
        for (final v in AvatarOutfit.values)
          _Option(
            label: AvatarPalette.outfitLabel(v),
            config: config.copyWith(outfit: v),
          ),
      ],
    _EditorCategory.outfitColor => [
        for (final v in AvatarPaletteColor.values)
          _Option(
            label: AvatarPalette.label(v),
            config: config.copyWith(outfitColor: v),
            swatch: AvatarPalette.of(v),
          ),
      ],
    _EditorCategory.background => [
        for (final v in AvatarPaletteColor.values)
          _Option(
            label: AvatarPalette.label(v),
            config: config.copyWith(backgroundColor: v),
            swatch: AvatarPalette.of(v),
          ),
      ],
  };
}

class _OptionTile extends StatelessWidget {
  const _OptionTile({
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final _Option option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: option.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.lgAll,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.xs),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppRadius.lgAll,
            border: Border.all(
              color: selected ? AppColors.turquoise : Colors.transparent,
              width: 2,
            ),
            boxShadow: AppShadows.clay(selected ? AppColors.turquoise : null),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Cada opção mostra o resultado aplicado ao avatar atual, em vez
              // de um ícone genérico: a escolha é feita vendo o efeito real.
              if (option.swatch != null)
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: option.swatch,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.border),
                  ),
                )
              else
                AvatarArtwork(config: option.config, size: 52),
              const SizedBox(height: AppSpacing.xxs),
              Flexible(
                child: Text(
                  option.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: selected
                        ? AppColors.turquoise
                        : AppColors.textSecondary,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
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
