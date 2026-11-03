import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clinical_module_card.dart';
import '../../../shared/widgets/neural_header_background.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../auth/providers/auth_providers.dart';
import '../../clinics/presentation/clinic_routes.dart';
import '../../clinics/providers/clinics_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/widgets/user_avatar.dart';
import '../../user_management/providers/user_management_providers.dart';
import '../../patient_library/presentation/admin_library_routes.dart';
import '../../psychoeducation/presentation/psychoeducation_routes.dart';
import '../../clinic_entitlements/presentation/admin_plans_page.dart';
import '../../profile/presentation/profile_routes.dart';
import '../../questionnaires/presentation/questionnaire_routes.dart';
import '../../user_management/presentation/user_management_routes.dart';

class PlatformAdminHomePage extends ConsumerWidget {
  const PlatformAdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(authControllerProvider).valueOrNull;
    final clinicsCount = ref.watch(clinicsProvider).valueOrNull?.length;
    final usersList = ref.watch(clinicUsersProvider).valueOrNull;
    final usersCount = usersList?.length;
    final patientsCount = usersList
        ?.where((u) => u.role == ProfileRole.psychologist)
        .fold<int>(0, (sum, u) => sum + u.assignedPatientsCount);

    return AppCanopyScaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          if (profile != null)
            _AdminHero(
              profile: profile,
              clinicsCount: clinicsCount,
              usersCount: usersCount,
              patientsCount: patientsCount,
              onProfileTap: () => context.push(ProfileRoutes.me),
            ),
          ResponsiveContent(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                0,
                AppSpacing.lg,
                0,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const AppSectionHeader(
                    title: 'Atendimento',
                    subtitle:
                        'Fluxos ligados diretamente ao cuidado dos pacientes.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ResponsiveGrid(
                    mediumColumns: 2,
                    expandedColumns: 2,
                    children: [
                      MotionReveal(
                        delay: staggerDelay(0),
                        child: ClinicalModuleCard(
                          icon: Icons.people_outline,
                          title: 'Pacientes',
                          subtitle:
                              'Visualizar, inativar e reativar pacientes.',
                          accentColor: AppColors.turquoise,
                          // Admin não lê pacientes individuais (migration
                          // 20260720120011): a RLS devolve zero linhas por
                          // decisão de privacidade clínica. A tela dele é a
                          // visão agregada por psicólogo.
                          onTap: () =>
                              context.push('/platform/patient-overview'),
                        ),
                      ),
                      MotionReveal(
                        delay: staggerDelay(1),
                        child: ClinicalModuleCard(
                          icon: Icons.groups_outlined,
                          title: 'Usuários',
                          subtitle:
                              'Psicólogos e administradores, separados por abas.',
                          accentColor: AppColors.blue,
                          onTap: () =>
                              context.push(UserManagementRoutes.platformList),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const AppSectionHeader(
                    title: 'Estrutura da plataforma',
                    subtitle:
                        'Configurações globais, acessos administrativos e instrumentos.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ResponsiveGrid(
                    mediumColumns: 2,
                    expandedColumns: 3,
                    children: [
                      MotionReveal(
                        delay: staggerDelay(2),
                        child: ClinicalModuleCard(
                          icon: Icons.apartment_outlined,
                          title: 'Clínicas',
                          subtitle:
                              'Ver clínicas, individuais, status e volumes.',
                          accentColor: AppColors.blue,
                          onTap: () => context.push(ClinicRoutes.platformList),
                        ),
                      ),
                      MotionReveal(
                        delay: staggerDelay(4),
                        child: ClinicalModuleCard(
                          icon: Icons.library_books_outlined,
                          title: 'Catálogo de questionários',
                          subtitle: 'Criar, revisar, publicar e arquivar.',
                          accentColor: AppColors.purple,
                          onTap: () =>
                              context.push(QuestionnaireRoutes.adminCatalog),
                        ),
                      ),
                      MotionReveal(
                        delay: staggerDelay(5),
                        child: ClinicalModuleCard(
                          icon: Icons.fact_check_outlined,
                          title: 'Acesso a questionários',
                          subtitle: 'Liberar instrumentos por psicólogo.',
                          accentColor: AppColors.cyan,
                          onTap: () =>
                              context.push(QuestionnaireRoutes.adminAccess),
                        ),
                      ),
                      MotionReveal(
                        delay: staggerDelay(6),
                        child: ClinicalModuleCard(
                          icon: Icons.movie_filter_outlined,
                          title: 'Catálogo da Biblioteca',
                          subtitle:
                              'Curar filmes e séries e liberar aos psicólogos.',
                          accentColor: AppColors.turquoise,
                          onTap: () => context.push(AdminLibraryRoutes.catalog),
                        ),
                      ),
                      MotionReveal(
                        delay: staggerDelay(7),
                        child: ClinicalModuleCard(
                          icon: Icons.auto_stories_outlined,
                          title: 'Psicoeducação',
                          subtitle: 'Curar os módulos da Biblioteca e liberar.',
                          accentColor: AppColors.purple,
                          onTap: () =>
                              context.push(PsychoeducationRoutes.adminCatalog),
                        ),
                      ),
                      MotionReveal(
                        delay: staggerDelay(8),
                        child: ClinicalModuleCard(
                          icon: Icons.tune_outlined,
                          title: 'Planos e permissões',
                          subtitle:
                              'Liberar módulos por clínica, fora do plano.',
                          accentColor: AppColors.blue,
                          onTap: () => context.push(AdminPlansPage.route),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _AdminHero extends StatelessWidget {
  const _AdminHero({
    required this.profile,
    required this.clinicsCount,
    required this.usersCount,
    required this.patientsCount,
    required this.onProfileTap,
  });

  final UserProfile profile;
  final int? clinicsCount;
  final int? usersCount;
  final int? patientsCount;
  final VoidCallback onProfileTap;

  static const _gradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6B4EE6), Color(0xFF8A63F0), Color(0xFF2A2A6E)],
    stops: [0.0, 0.5, 1.0],
  );

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'BOM DIA';
    if (h < 18) return 'BOA TARDE';
    return 'BOA NOITE';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final statusBarTop = MediaQuery.paddingOf(context).top;

    Widget pill(int? value, String label) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(999),
        ),
        child: RichText(
          text: TextSpan(
            style: theme.textTheme.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.92),
              fontWeight: FontWeight.w600,
            ),
            children: [
              TextSpan(
                text: value?.toString() ?? '\u2014',
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
              TextSpan(text: ' $label'),
            ],
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: const BoxDecoration(
        gradient: _gradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          const Positioned.fill(child: NeuralHeaderBackground()),
          Column(
            children: [
              SizedBox(height: statusBarTop),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.sm,
              AppSpacing.lg,
              0,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology_alt_outlined,
                  color: Colors.white,
                  size: 18,
                ),
                const SizedBox(width: 6),
                RichText(
                  text: TextSpan(
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    children: const [
                      TextSpan(
                        text: 'Esquema',
                        style: TextStyle(color: Colors.white),
                      ),
                      TextSpan(
                        text: 'Core',
                        style: TextStyle(color: Color(0xFF6FE9DF)),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'PLATAFORMA',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.lg,
              AppSpacing.lg,
            ),
            child: Column(
              children: [
                GestureDetector(
                  onTap: onProfileTap,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2,
                      ),
                    ),
                    child: UserAvatar(profile: profile, size: 72),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _greeting(),
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  profile.fullName,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Administrador da plataforma',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.82),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    pill(clinicsCount, 'cl\u00ednicas'),
                    pill(usersCount, 'usu\u00e1rios'),
                    pill(patientsCount, 'pacientes'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
        ],
      ),
    );
  }
}
