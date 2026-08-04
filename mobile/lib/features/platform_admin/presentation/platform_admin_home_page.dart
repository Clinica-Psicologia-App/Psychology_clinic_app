import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clinical_module_card.dart';
import '../../../shared/widgets/esquema_core_logo.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../auth/providers/auth_providers.dart';
import '../../clinics/presentation/clinic_routes.dart';
import '../../patient_library/presentation/admin_library_routes.dart';
import '../../psychoeducation/presentation/psychoeducation_routes.dart';
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
          padding: const EdgeInsets.all(AppSpacing.xl),
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.xl),
              child: EsquemaCoreLogo.horizontal(
                size: 44,
                showName: true,
                showTagline: true,
              ),
            ),
            const AppPageHeader(
              icon: Icons.admin_panel_settings_outlined,
              title: 'Gestão global',
              subtitle:
                  'Administre operação, equipe e instrumentos clínicos com separação clara entre atendimento e estrutura da plataforma.',
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(
              title: 'Atendimento',
              subtitle: 'Fluxos ligados diretamente ao cuidado dos pacientes.',
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
                    subtitle: 'Visualizar, inativar e reativar pacientes.',
                    accentColor: AppColors.turquoise,
                    // Admin não lê pacientes individuais (migration
                    // 20260720120011): a RLS devolve zero linhas por
                    // decisão de privacidade clínica. A tela dele é a
                    // visão agregada por psicólogo.
                    onTap: () => context.push('/platform/patient-overview'),
                  ),
                ),
                MotionReveal(
                  delay: staggerDelay(1),
                  child: ClinicalModuleCard(
                    icon: Icons.psychology_alt_outlined,
                    title: 'Psicólogos',
                    subtitle: 'Gerenciar profissionais, CRP, clínica e vagas.',
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
              expandedColumns: 2,
              children: [
                MotionReveal(
                  delay: staggerDelay(2),
                  child: ClinicalModuleCard(
                    icon: Icons.apartment_outlined,
                    title: 'Clínicas',
                    subtitle: 'Ver clínicas, individuais, status e volumes.',
                    accentColor: AppColors.blue,
                    onTap: () => context.push(ClinicRoutes.platformList),
                  ),
                ),
                MotionReveal(
                  delay: staggerDelay(3),
                  child: ClinicalModuleCard(
                    icon: Icons.admin_panel_settings_outlined,
                    title: 'Administradores',
                    subtitle: 'Gerenciar acessos administrativos globais.',
                    accentColor: AppColors.purple,
                    onTap: () =>
                        context.push(UserManagementRoutes.platformList),
                  ),
                ),
                MotionReveal(
                  delay: staggerDelay(4),
                  child: ClinicalModuleCard(
                    icon: Icons.library_books_outlined,
                    title: 'Catálogo de questionários',
                    subtitle: 'Criar, revisar, publicar e arquivar.',
                    accentColor: AppColors.purple,
                    onTap: () => context.push(QuestionnaireRoutes.adminCatalog),
                  ),
                ),
                MotionReveal(
                  delay: staggerDelay(5),
                  child: ClinicalModuleCard(
                    icon: Icons.fact_check_outlined,
                    title: 'Acesso a questionários',
                    subtitle: 'Liberar instrumentos por psicólogo.',
                    accentColor: AppColors.cyan,
                    onTap: () => context.push(QuestionnaireRoutes.adminAccess),
                  ),
                ),
                MotionReveal(
                  delay: staggerDelay(6),
                  child: ClinicalModuleCard(
                    icon: Icons.movie_filter_outlined,
                    title: 'Catálogo da Biblioteca',
                    subtitle: 'Curar filmes e séries e liberar aos psicólogos.',
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
                    onTap: () => context.push(PsychoeducationRoutes.adminCatalog),
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
