import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_shadows.dart';

/// Substituto do [Card] no visual claymorphism: em vez da sombra Material
/// única + borda sólida, usa a sombra dupla de [AppShadows.clay] (destaque
/// claro + sombra funda) e sem borda — a superfície parece extrudada do
/// fundo, não apenas empilhada sobre ele.
///
/// Aceita os mesmos parâmetros mais usados de [Card] no projeto (`color`,
/// `margin`, `shape`, `clipBehavior`) para ser um substituto direto nos
/// call sites existentes. `shape` é lido apenas para extrair `borderRadius`
/// e `side` (quando os cards já tingem a borda por identidade de acento);
/// a sombra clay nunca é substituída pela elevação do Material.
class ClayCard extends StatelessWidget {
  const ClayCard({
    super.key,
    required this.child,
    this.color,
    this.margin,
    this.shape,
    this.clipBehavior = Clip.antiAlias,
    this.accentColor,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? margin;
  final RoundedRectangleBorder? shape;
  final Clip clipBehavior;

  /// Cor da sombra clay quando o card carrega identidade própria (ex.:
  /// card de um módulo específico). Sem isto, a sombra é neutra (navy).
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final borderRadius =
        shape?.borderRadius as BorderRadius? ?? AppRadius.lgAll;
    final side = shape?.side;
    final hasBorder = side != null && side != BorderSide.none;

    return Container(
      margin: margin,
      clipBehavior: clipBehavior,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: borderRadius,
        border: hasBorder ? Border.fromBorderSide(side) : null,
        boxShadow: AppShadows.clay(accentColor),
      ),
      // O Container pinta um fundo próprio, e isso esconderia o splash de
      // toque de widgets Material colocados dentro (ListTile avisa sobre isso
      // no console). Um Material transparente devolve a superfície de tinta
      // sem alterar a cor nem a sombra do card.
      child: Material(
        type: MaterialType.transparency,
        child: child,
      ),
    );
  }
}
