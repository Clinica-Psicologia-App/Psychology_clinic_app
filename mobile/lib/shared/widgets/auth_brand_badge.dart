import 'package:flutter/material.dart';

/// Selo circular com ícone, usado no topo das telas de autenticação
/// (recuperar/criar senha) para um visual de marca consistente.
class AuthBrandBadge extends StatelessWidget {
  const AuthBrandBadge({
    super.key,
    required this.icon,
    this.size = 84,
  });

  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return SizedBox(
      width: size * 1.5,
      height: size * 1.5,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 1.5,
            height: size * 1.5,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.06),
            ),
          ),
          Container(
            width: size * 1.18,
            height: size * 1.18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: primary.withValues(alpha: 0.12),
            ),
          ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primary, primary.withValues(alpha: 0.78)],
              ),
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.30),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Icon(icon, size: size * 0.46, color: Colors.white),
          ),
        ],
      ),
    );
  }
}
