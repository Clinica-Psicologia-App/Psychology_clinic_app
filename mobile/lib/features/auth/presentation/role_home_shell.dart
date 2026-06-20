import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clinical_module_card.dart';
import '../../../shared/widgets/esquema_core_logo.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../patient_journey/presentation/patient_journey_routes.dart';
import '../../patients/presentation/patient_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../../profile/domain/user_profile.dart';
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
        IconButton(
          tooltip: 'Sair',
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          icon: const Icon(Icons.logout),
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
          return _HomeBody(profile: user, subtitle: subtitle, role: role);
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
  });

  final UserProfile profile;
  final String subtitle;
  final ProfileRole role;

  @override
  Widget build(BuildContext context) {
    final isWide = AppBreakpoints.isWide(context);

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
            child: _ProfileHeader(profile: profile, subtitle: subtitle),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (role == ProfileRole.psychologist) ...[
            Text('Módulos', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            MotionReveal(
              delay: const Duration(milliseconds: 90),
              child: ResponsiveGrid(
                mediumColumns: 2,
                expandedColumns: 2,
                children: [
                  ClinicalModuleCard(
                    icon: Icons.people_outline,
                    title: 'Pacientes',
                    subtitle: 'Listar, cadastrar e ver detalhes',
                    accentColor: AppColors.blue,
                    onTap: () => context.push(PatientRoutes.list(role)),
                  ),
                ],
              ),
            ),
          ],
          if (role == ProfileRole.patient) ...[
            Text('Jornada', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.sm),
            MotionReveal(
              delay: const Duration(milliseconds: 90),
              child: ClinicalModuleCard(
                icon: Icons.route_outlined,
                title: 'Meu plano terapêutico',
                subtitle:
                    'Trilha com questionários, monitor, biblioteca e próximos módulos.',
                accentColor: AppColors.purple,
                onTap: () => context.push(PatientJourneyRoutes.journey),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.profile,
    required this.subtitle,
  });

  final UserProfile profile;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.surface,
            AppColors.turquoise.withValues(alpha: 0.055),
          ],
        ),
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Row(
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: AppColors.turquoise.withValues(alpha: 0.15),
              child: Text(
                profile.fullName[0].toUpperCase(),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.fullName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    subtitle,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${profile.role.label} · ${profile.email}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
