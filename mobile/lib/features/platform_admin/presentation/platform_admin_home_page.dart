import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/brand_hero_card.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../auth/providers/auth_providers.dart';
import '../../clinics/presentation/clinic_routes.dart';
import '../../profile/presentation/profile_routes.dart';
import '../../profile/presentation/widgets/user_avatar.dart';
import '../../questionnaires/presentation/questionnaire_routes.dart';
import '../../user_management/presentation/user_management_routes.dart';

class PlatformAdminHomePage extends ConsumerWidget {
  const PlatformAdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).valueOrNull;

    return AppScaffold(
      title: 'EsquemaCore',
      subtitle: 'Gestão global',
      actions: [
        if (profile != null)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.sm),
            child: Tooltip(
              message: 'Meu perfil',
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => context.push(ProfileRoutes.me),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: UserAvatar(profile: profile, size: 32),
                ),
              ),
            ),
          ),
      ],
      body: ResponsiveContent(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.xxl,
          ),
          children: [
            MotionReveal(
              child: BrandHeroCard(
                name: profile?.fullName ?? 'Painel administrativo',
                subtitle: 'Gestão central da plataforma EsquemaCore.',
                dense: true,
                chips: const [
                  BrandHeroChip(
                    icon: Icons.admin_panel_settings_outlined,
                    label: 'Administrador da plataforma',
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionHeader(
              title: 'Operação principal',
              subtitle: 'Acompanhe cadastros, permissões e estrutura.',
            ),
            const SizedBox(height: AppSpacing.md),
            ResponsiveGrid(
              mediumColumns: 2,
              expandedColumns: 2,
              spacing: AppSpacing.sm,
              children: [
                MotionReveal(
                  delay: staggerDelay(0),
                  child: _AdminModuleTile(
                    icon: Icons.people_alt_outlined,
                    title: 'Pacientes',
                    subtitle: 'Distribuição por psicólogo e capacidade.',
                    accentColor: AppColors.turquoise,
                    onTap: () => context.push('/platform/patient-overview'),
                  ),
                ),
                MotionReveal(
                  delay: staggerDelay(1),
                  child: _AdminModuleTile(
                    icon: Icons.apartment_rounded,
                    title: 'Clínicas',
                    subtitle: 'Gerenciar clínicas, individuais e volumes.',
                    accentColor: AppColors.blue,
                    onTap: () => context.push(ClinicRoutes.platformList),
                  ),
                ),
                MotionReveal(
                  delay: staggerDelay(2),
                  child: _AdminModuleTile(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Usuários',
                    subtitle: 'Administradores, psicólogos e status.',
                    accentColor: AppColors.purple,
                    onTap: () =>
                        context.push(UserManagementRoutes.platformList),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const _SectionHeader(
              title: 'Governança clínica',
              subtitle: 'Controle os instrumentos liberados na plataforma.',
            ),
            const SizedBox(height: AppSpacing.md),
            ResponsiveGrid(
              mediumColumns: 2,
              expandedColumns: 2,
              spacing: AppSpacing.sm,
              children: [
                MotionReveal(
                  delay: staggerDelay(3),
                  child: _AdminModuleTile(
                    icon: Icons.library_books_outlined,
                    title: 'Catálogo de questionários',
                    subtitle: 'Criar, revisar, publicar e arquivar.',
                    accentColor: AppColors.purple,
                    onTap: () => context.push(QuestionnaireRoutes.adminCatalog),
                  ),
                ),
                MotionReveal(
                  delay: staggerDelay(4),
                  child: _AdminModuleTile(
                    icon: Icons.assignment_ind_outlined,
                    title: 'Acesso a questionários',
                    subtitle: 'Liberar instrumentos por psicólogo.',
                    accentColor: AppColors.cyan,
                    onTap: () => context.push(QuestionnaireRoutes.adminAccess),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: textTheme.titleMedium?.copyWith(
            color: AppColors.navy,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
            height: 1.25,
          ),
        ),
      ],
    );
  }
}

class _AdminModuleTile extends StatelessWidget {
  const _AdminModuleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final radius = BorderRadius.circular(AppRadius.xl);

    return MotionSurface(
      onTap: onTap,
      borderRadius: radius,
      hoverScale: 1.003,
      pressedScale: 0.996,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Ink(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: radius,
              border:
                  Border.all(color: AppColors.border.withValues(alpha: 0.9)),
            ),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: accentColor,
                    borderRadius: AppRadius.lgAll,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.45),
                        blurRadius: 4,
                        offset: const Offset(-2, -2),
                      ),
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.38),
                        blurRadius: 10,
                        offset: const Offset(3, 5),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: Colors.white, size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: textTheme.titleSmall?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                          height: 1.28,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withValues(alpha: 0.10),
                  ),
                  child: Icon(
                    Icons.arrow_forward_rounded,
                    color: accentColor,
                    size: 16,
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
