import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../features/profile/domain/profile_role.dart';
import '../../../../features/profile/presentation/widgets/user_avatar.dart';
import '../../domain/patient.dart';
import '../../providers/patients_providers.dart';

/// Cabeçalho padronizado para todas as telas de detalhe de paciente
/// (lado do psicólogo/admin). Carrega o paciente via [patientId] e aproveita
/// o cache do Riverpod — sem requisição extra quando vindo da ficha.
///
/// Uso:
/// ```dart
/// PatientContextHeader(
///   patientId: patientId,
///   pageTitle: 'LINHA DO TEMPO',
///   role: role,
/// )
/// ```
///
/// Para botões de ação opcionais, passe [actions] como lista de widgets
/// expandidos numa Row (ex.: "Editar", "Histórico").
class PatientContextHeader extends ConsumerWidget {
  const PatientContextHeader({
    super.key,
    required this.patientId,
    required this.pageTitle,
    required this.role,
    this.actions,
    this.accentColor,
    this.onBack,
  });

  /// Substitui o "voltar" padrão (ex.: para confirmar alterações não salvas).
  final VoidCallback? onBack;

  final String patientId;

  /// Rótulo da breadcrumb acima do nome (ex.: 'LINHA DO TEMPO').
  final String pageTitle;

  final ProfileRole role;

  /// Botões de ação opcionais — exibidos como Row expandida abaixo das chips.
  /// Se null ou vazio, a barra de ações é omitida.
  final List<Widget>? actions;

  /// Quando fornecida, substitui a cor baseada no gênero do paciente.
  /// Use para módulos com identidade própria (ex.: roxo para Intervir).
  final Color? accentColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patientAsync = ref.watch(patientDetailProvider(patientId));

    return patientAsync.when(
      loading: () => _PatientHeaderSkeleton(
          pageTitle: pageTitle, accentColor: accentColor, onBack: onBack),
      error: (_, __) => _PatientHeaderSkeleton(
          pageTitle: pageTitle, accentColor: accentColor, onBack: onBack),
      data: (patient) => patient == null
          ? _PatientHeaderSkeleton(
              pageTitle: pageTitle, accentColor: accentColor, onBack: onBack)
          : _PatientHeaderContent(
              patient: patient,
              pageTitle: pageTitle,
              actions: actions,
              accentColor: accentColor,
              onBack: onBack,
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conteúdo completo do header

class _PatientHeaderContent extends StatelessWidget {
  const _PatientHeaderContent({
    required this.patient,
    required this.pageTitle,
    this.actions,
    this.accentColor,
    this.onBack,
  });

  final VoidCallback? onBack;
  final Patient patient;
  final String pageTitle;
  final List<Widget>? actions;
  final Color? accentColor;

  static String _initialsOf(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1))
        .toUpperCase();
  }

  static bool _isMale(String? gender) {
    final g = gender?.toLowerCase();
    return g == 'masculino' || g == 'male';
  }

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isWide(context)) return _buildCompact(context);

    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final accessLabel = patient.accessStatus?.label;
    final male = _isMale(patient.gender);
    final headerColor = accentColor != null
        ? Color.lerp(accentColor, Colors.black, 0.55)!
        : (male ? const Color(0xFF0A3A5E) : const Color(0xFF4A1528));
    final blobColor1 = accentColor != null
        ? Color.lerp(accentColor, Colors.white, 0.15)!
        : (male ? const Color(0xFF00B2A9) : const Color(0xFFDB2777));
    final blobColor2 = accentColor != null
        ? Color.lerp(accentColor, Colors.blue.shade900, 0.4)!
        : (male ? const Color(0xFF3D3F8F) : const Color(0xFF9D174D));
    final hasActions = actions != null && actions!.isNotEmpty;

    return Container(
      width: double.infinity,
      color: headerColor,
      child: Stack(
        children: [
          // Blobs de luz ambiente
          Positioned(
            right: -30,
            top: -20,
            child: _blob(200, blobColor1.withValues(alpha: 0.33)),
          ),
          Positioned(
            left: -40,
            bottom: 30,
            child: _blob(160, blobColor2.withValues(alpha: 0.27)),
          ),
          // Anel geométrico decorativo
          Positioned(
            right: -18,
            top: topInset + 30,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.05),
                  width: 24,
                ),
              ),
            ),
          ),

          // Conteúdo principal
          Padding(
            padding: EdgeInsets.fromLTRB(0, topInset, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nav row
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, 0),
                  child: Row(
                    children: [
                      _NavBtn(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: onBack ?? () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          pageTitle,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Avatar + info
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 2.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 16,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: UserAvatar.parts(
                          fullName: patient.fullName,
                          initials: _initialsOf(patient.fullName),
                          role: ProfileRole.patient,
                          avatarType: patient.avatarType,
                          photoUrl: patient.photoUrl,
                          avatarConfig: patient.avatarConfig,
                          size: 72,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              patient.isActive
                                  ? 'PACIENTE ATIVO'
                                  : 'PACIENTE INATIVO',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: patient.isActive
                                    ? const Color(0xFF00D4C9)
                                    : Colors.white.withValues(alpha: 0.5),
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                fontSize: 9,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              patient.fullName,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                height: 1.1,
                                letterSpacing: -0.3,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Wrap(
                              spacing: 5,
                              runSpacing: 4,
                              children: [
                                if (accessLabel != null &&
                                    accessLabel.trim().isNotEmpty)
                                  _HeroChip(
                                    label: accessLabel,
                                    isGreen: patient.accessStatus ==
                                        PatientAccessStatus.active,
                                  ),
                                if (patient.responsiblePsychologistName !=
                                        null &&
                                    patient.responsiblePsychologistName!
                                        .trim()
                                        .isNotEmpty)
                                  _HeroChip(
                                    label:
                                        patient.responsiblePsychologistName!,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.md),

                // Action bar (opcional)
                if (hasActions) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg),
                    child: Row(
                      children: [
                        for (int i = 0; i < actions!.length; i++) ...[
                          if (i > 0) const SizedBox(width: AppSpacing.sm),
                          Expanded(child: actions![i]),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ] else
                  const SizedBox(height: AppSpacing.xs),

                // Cantos arredondados na base
                Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerLow,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);
    final male = _isMale(patient.gender);
    final headerColor =
        male ? const Color(0xFF0A3A5E) : const Color(0xFF4A1528);
    final accentColor =
        male ? const Color(0xFF00D4C9) : const Color(0xFFDB2777);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      color: headerColor,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _NavBtn(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack ?? () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: AppSpacing.md),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: UserAvatar.parts(
              fullName: patient.fullName,
              initials: _initialsOf(patient.fullName),
              role: ProfileRole.patient,
              avatarType: patient.avatarType,
              photoUrl: patient.photoUrl,
              avatarConfig: patient.avatarConfig,
              size: 48,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  patient.isActive ? 'PACIENTE ATIVO' : 'PACIENTE INATIVO',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: patient.isActive
                        ? accentColor
                        : Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.0,
                    fontSize: 9,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  patient.fullName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                  ),
                ),
                if (patient.responsiblePsychologistName != null &&
                    patient.responsiblePsychologistName!.trim().isNotEmpty)
                  Text(
                    patient.responsiblePsychologistName!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.65),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Skeleton de carregamento

class _PatientHeaderSkeleton extends StatelessWidget {
  const _PatientHeaderSkeleton(
      {required this.pageTitle, this.accentColor, this.onBack});

  final VoidCallback? onBack;
  final String pageTitle;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final theme = Theme.of(context);
    final bgColor = accentColor != null
        ? Color.lerp(accentColor, Colors.black, 0.55)!
        : const Color(0xFF0A3A5E);

    return Container(
      width: double.infinity,
      color: bgColor,
      padding: EdgeInsets.fromLTRB(
        AppSpacing.sm,
        topInset + AppSpacing.xs,
        AppSpacing.sm,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _NavBtn(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack ?? () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                pageTitle,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.5),
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: Row(
              children: [
                // Avatar placeholder
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(18),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 8,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 20,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 20,
                        width: 80,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerLow,
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sub-widgets reutilizáveis

class _NavBtn extends StatelessWidget {
  const _NavBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, color: Colors.white, size: 16),
        ),
      );
}

class _HeroChip extends StatelessWidget {
  const _HeroChip({required this.label, this.isGreen = false});
  final String label;
  final bool isGreen;

  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: isGreen
              ? const Color(0x401A9B6C)
              : Colors.white.withValues(alpha: 0.13),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isGreen
                ? const Color(0x601A9B6C)
                : Colors.white.withValues(alpha: 0.15),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: isGreen
                ? const Color(0xFF4DEBB5)
                : Colors.white.withValues(alpha: 0.9),
          ),
        ),
      );
}

/// Botão de ação padrão para usar dentro de [PatientContextHeader.actions].
class PatientHeaderActionBtn extends StatelessWidget {
  const PatientHeaderActionBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
    this.solid = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;

  /// Quando true, botão fica preenchido de branco (destaque principal).
  final bool solid;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: solid
                ? Colors.white
                : Colors.white.withValues(alpha: 0.13),
            borderRadius: BorderRadius.circular(11),
            border: solid
                ? null
                : Border.all(
                    color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: solid
                    ? const Color(0xFF0A3A5E)
                    : Colors.white,
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: solid
                      ? const Color(0xFF0A3A5E)
                      : Colors.white,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      );
}
