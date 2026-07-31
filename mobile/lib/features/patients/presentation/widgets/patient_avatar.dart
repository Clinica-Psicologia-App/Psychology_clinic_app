import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Avatar do paciente diferenciado por gênero:
/// masculino (ícone masculino, azul), feminino (ícone feminino, rosé),
/// não binário (roxo) e, quando não informado, a inicial do nome.
class PatientAvatar extends StatelessWidget {
  const PatientAvatar({
    super.key,
    required this.fullName,
    this.gender,
    this.size = 48,
  });

  final String fullName;
  final String? gender;
  final double size;

  /// Rosé para o feminino (não faz parte da paleta de marca).
  static const Color _rose = Color(0xFFE0519A);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _styleFor(gender);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: style.color,
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.45),
            blurRadius: 4,
            offset: const Offset(-2, -2),
          ),
          BoxShadow(
            color: style.color.withValues(alpha: 0.38),
            blurRadius: 10,
            offset: const Offset(3, 5),
          ),
        ],
      ),
      child: style.icon != null
          ? Icon(style.icon, color: Colors.white, size: size * 0.58)
          : Text(
              _initial(fullName),
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: size * 0.36,
              ),
            ),
    );
  }

  String _initial(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return '?';
    return trimmed.characters.first.toUpperCase();
  }

  static ({Color color, IconData? icon}) _styleFor(String? gender) {
    switch (gender?.trim().toLowerCase()) {
      case 'male':
      case 'masculino':
        return (color: AppColors.blue, icon: Icons.man);
      case 'female':
      case 'feminino':
        return (color: _rose, icon: Icons.woman);
      case 'non_binary':
      case 'nao_binario':
      case 'nao-binario':
        return (color: AppColors.purple, icon: Icons.transgender);
      default:
        // Sem gênero informado → mantém a inicial do nome.
        return (color: AppColors.blue, icon: null);
    }
  }
}
