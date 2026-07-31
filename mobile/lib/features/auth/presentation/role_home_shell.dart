import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/action_surface.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/brand_hero_card.dart';
import '../../../shared/widgets/esquema_core_logo.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../clinic_entitlements/domain/clinic_feature_entitlement.dart';
import '../../clinic_entitlements/providers/clinic_entitlements_providers.dart';
import '../../patient_journey/presentation/patient_journey_routes.dart';
import '../../patients/presentation/patient_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/profile_routes.dart';
import '../../profile/presentation/widgets/user_avatar.dart';
import '../providers/auth_providers.dart';

class RoleHomeShell extends ConsumerWidget {
  const RoleHomeShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.role,
  });

  final String title;
  final String subtitle;
  final ProfileRole role;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);
    final profile = authState.valueOrNull;

    return AppScaffold(
      title: title,
      subtitle: subtitle,
      useResponsivePadding: false,
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
      body: authState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(
            e is AppException ? userMessageFor(e) : 'Erro ao carregar perfil.',
          ),
        ),
        data: (p) {
          final user = p ?? profile;
          if (user == null) {
            return const Center(child: Text('Perfil não carregado.'));
          }
          return _HomeBody(
            profile: user,
            subtitle: subtitle,
            role: role,
            entitlementsAsync: ref.watch(currentClinicEntitlementsProvider),
          );
        },
      ),
    );
  }
}

class _HomeBody extends StatelessWidget {
  const _HomeBody({
    required this.profile,
    required this.subtitle,
    required this.role,
    required this.entitlementsAsync,
  });

  final UserProfile profile;
  final String subtitle;
  final ProfileRole role;
  final AsyncValue<ClinicFeatureEntitlements> entitlementsAsync;

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);
    final entitlements =
        entitlementsAsync.valueOrNull ?? ClinicFeatureEntitlements.empty;
    final isLoadingEntitlements = entitlementsAsync.isLoading;
    final patientsEnabled =
        !isLoadingEntitlements && entitlements.isEnabled('patients');

    return ResponsiveContent(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          if (isWide)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xl),
              child: EsquemaCoreLogo.horizontal(
                size: 44,
                showName: true,
                showTagline: true,
              ),
            ),
          MotionReveal(
            child: BrandHeroCard(
              name: profile.fullName,
              subtitle: subtitle,
              chips: [
                BrandHeroChip(
                  icon: Icons.verified_user_outlined,
                  label: profile.role.label,
                ),
                BrandHeroChip(
                  icon: Icons.mail_outline_rounded,
                  label: profile.email,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (role == ProfileRole.psychologist) ...[
            const _SectionTitle(
              title: 'Módulos de trabalho',
              subtitle: 'Acesse a operação clínica do dia a dia.',
            ),
            const SizedBox(height: AppSpacing.sm),
            MotionReveal(
              delay: const Duration(milliseconds: 90),
              child: ActionSurface(
                icon: Icons.people_outline,
                title: 'Pacientes',
                subtitle: isLoadingEntitlements
                    ? 'Validando permissões do plano da clínica...'
                    : patientsEnabled
                        ? 'Encontre, cadastre e acompanhe seus pacientes.'
                        : 'Módulo bloqueado pelo plano da clínica.',
                accentColor: AppColors.blue,
                enabled: patientsEnabled,
                statusLabel: patientsEnabled ? 'Liberado' : 'Bloqueado',
                onTap: patientsEnabled
                    ? () => context.push(PatientRoutes.list(role))
                    : null,
              ),
            ),
          ],
          if (role == ProfileRole.patient) ...[
            const _SectionTitle(
              title: 'Jornada terapêutica',
              subtitle: 'Sua trilha organizada em passos simples.',
            ),
            const SizedBox(height: AppSpacing.sm),
            MotionReveal(
              delay: const Duration(milliseconds: 90),
              child: ActionSurface(
                icon: Icons.route_outlined,
                title: 'Meu plano terapêutico',
                subtitle:
                    'Continue de onde parou: questionários, monitor diário e '
                    'seus recursos.',
                accentColor: AppColors.purple,
                statusLabel: 'Continuar',
                onTap: () => context.push(PatientJourneyRoutes.journey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 5,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.turquoise,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
