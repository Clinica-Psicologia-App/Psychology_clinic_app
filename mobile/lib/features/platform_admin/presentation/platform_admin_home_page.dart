import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clinical_module_card.dart';
import '../../../shared/widgets/esquema_core_logo.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../auth/providers/auth_providers.dart';
import '../../clinics/presentation/clinic_routes.dart';
import '../../questionnaires/presentation/questionnaire_routes.dart';
import '../../user_management/presentation/user_management_routes.dart';

class PlatformAdminHomePage extends ConsumerWidget {
  const PlatformAdminHomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppScaffold(
      title: 'EsquemaCore',
      subtitle: 'Gestão global',
      actions: [
        IconButton(
          tooltip: 'Sair',
          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
          icon: const Icon(Icons.logout),
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
            Text(
              'Gestão global',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.sm),
            MotionReveal(
              child: ResponsiveGrid(
                mediumColumns: 2,
                expandedColumns: 2,
                children: [
                  ClinicalModuleCard(
                    icon: Icons.people_outline,
                    title: 'Pacientes',
                    subtitle: 'Visualizar, inativar e reativar pacientes.',
                    accentColor: AppColors.turquoise,
                    onTap: () => context.push('/platform/patients'),
                  ),
                  ClinicalModuleCard(
                    icon: Icons.apartment_outlined,
                    title: 'Clínicas',
                    subtitle: 'Ver clínicas, individuais, status e volumes.',
                    accentColor: AppColors.blue,
                    onTap: () => context.push(ClinicRoutes.platformList),
                  ),
                  ClinicalModuleCard(
                    icon: Icons.manage_accounts_outlined,
                    title: 'Usuários',
                    subtitle: 'Gerenciar usuários por clínica e status.',
                    accentColor: AppColors.purple,
                    onTap: () => context.push(UserManagementRoutes.platformList),
                  ),
                  ClinicalModuleCard(
                    icon: Icons.assignment_ind_outlined,
                    title: 'Acesso a questionários',
                    subtitle: 'Liberar instrumentos para cada psicólogo.',
                    accentColor: AppColors.cyan,
                    onTap: () => context.push(QuestionnaireRoutes.adminAccess),
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
