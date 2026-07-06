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
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clinical_kpi_chip.dart';
import '../../../shared/widgets/clinical_module_card.dart';
import '../../../shared/widgets/esquema_core_logo.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../patient_journey/presentation/patient_journey_routes.dart';
import '../../patient_invitations/providers/patient_invitations_providers.dart';
import '../../patient_invitations/presentation/patient_invitation_routes.dart';
import '../../patients/providers/patients_providers.dart';
import '../../patients/presentation/patient_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../../profile/domain/user_profile.dart';
import '../../questionnaires/presentation/questionnaire_routes.dart';
import '../../questionnaires/providers/questionnaires_providers.dart';
import '../providers/auth_providers.dart';

/// Acentos por finalidade no workspace (máximo três famílias de cor).
abstract final class _WorkspaceAccents {
  /// Gestão da carteira: pacientes, convites, cadastro.
  static const Color management = AppColors.blue;

  /// Instrumentos e avaliação: questionários, resultados.
  static const Color assessment = AppColors.purple;

  /// Raciocínio clínico: formulação, recursos terapêuticos.
  static const Color clinical = AppColors.turquoise;
}

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

    final content = ResponsiveContent(
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
          if (role == ProfileRole.psychologist) const _PsychologistWorkspace(),
          if (role == ProfileRole.patient) ...[
            const AppSectionHeader(
              title: 'Sua continuidade',
              subtitle: 'Veja o próximo passo do seu acompanhamento.',
            ),
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

    return content;
  }
}

class _PsychologistWorkspace extends ConsumerWidget {
  const _PsychologistWorkspace();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patients = ref.watch(patientsListProvider).valueOrNull ?? const [];
    final invitations =
        ref.watch(patientInvitationsListProvider).valueOrNull ?? const [];
    final questionnaires =
        ref.watch(psychologistQuestionnairesProvider).valueOrNull ?? const [];

    final activePatients = patients.where((patient) => patient.isActive).length;
    final pendingInvitations =
        invitations.where((invitation) => invitation.isPending).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AppSectionHeader(
          title: 'Central de trabalho',
          subtitle:
              'Acompanhe pacientes, convites, instrumentos e fluxos clínicos.',
        ),
        const SizedBox(height: AppSpacing.sm),
        MotionReveal(
          delay: const Duration(milliseconds: 80),
          child: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              ClinicalKpiChip(
                icon: Icons.people_outline,
                label: 'Pacientes ativos',
                value: activePatients.toString(),
                accentColor: _WorkspaceAccents.management,
              ),
              ClinicalKpiChip(
                icon: Icons.mark_email_unread_outlined,
                label: 'Convites pendentes',
                value: pendingInvitations.toString(),
                accentColor: _WorkspaceAccents.management,
              ),
              ClinicalKpiChip(
                icon: Icons.assignment_outlined,
                label: 'Questionários liberados',
                value: questionnaires.length.toString(),
                accentColor: _WorkspaceAccents.assessment,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const AppSectionHeader(
          title: 'Carteira de pacientes',
          subtitle: 'Cadastro, convites e plano de cuidado.',
        ),
        const SizedBox(height: AppSpacing.sm),
        MotionReveal(
          delay: const Duration(milliseconds: 120),
          child: ResponsiveGrid(
            mediumColumns: 2,
            expandedColumns: 3,
            children: [
              ClinicalModuleCard(
                icon: Icons.people_outline,
                title: 'Pacientes',
                subtitle: 'Carteira clínica, detalhes e plano de cuidado',
                accentColor: _WorkspaceAccents.management,
                onTap: () => context.push(
                  PatientRoutes.list(ProfileRole.psychologist),
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Novo paciente',
                subtitle: 'Cadastrar paciente diretamente na sua carteira',
                accentColor: _WorkspaceAccents.management,
                onTap: () => context.push(
                  PatientRoutes.create(ProfileRole.psychologist),
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.mark_email_unread_outlined,
                title: 'Convites',
                subtitle: 'Enviar convite e acompanhar aceite do paciente',
                accentColor: _WorkspaceAccents.management,
                onTap: () => context.push(
                  PatientInvitationRoutes.list(ProfileRole.psychologist),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const AppSectionHeader(
          title: 'Avaliação e instrumentos',
          subtitle: 'Questionários, liberações e resultados.',
        ),
        const SizedBox(height: AppSpacing.sm),
        MotionReveal(
          delay: const Duration(milliseconds: 160),
          child: ResponsiveGrid(
            mediumColumns: 2,
            expandedColumns: 3,
            children: [
              ClinicalModuleCard(
                icon: Icons.assignment_outlined,
                title: 'Meus questionários',
                subtitle: 'Ver instrumentos liberados pelo administrador',
                accentColor: _WorkspaceAccents.assessment,
                onTap: () => context.push(
                  QuestionnaireRoutes.psychologistCatalog,
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.fact_check_outlined,
                title: 'Liberar para paciente',
                subtitle: 'Escolha um paciente e abra Questionários',
                accentColor: _WorkspaceAccents.assessment,
                onTap: () => context.push(
                  PatientRoutes.list(ProfileRole.psychologist),
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.insights_outlined,
                title: 'Resultados',
                subtitle: 'Acompanhar respostas e revisar instrumentos',
                accentColor: _WorkspaceAccents.assessment,
                onTap: () => context.push(
                  PatientRoutes.list(ProfileRole.psychologist),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const AppSectionHeader(
          title: 'Raciocínio clínico',
          subtitle: 'Formulação de caso e materiais terapêuticos.',
        ),
        const SizedBox(height: AppSpacing.sm),
        MotionReveal(
          delay: const Duration(milliseconds: 200),
          child: ResponsiveGrid(
            mediumColumns: 2,
            expandedColumns: 3,
            children: [
              ClinicalModuleCard(
                icon: Icons.psychology_alt_outlined,
                title: 'Formulação clínica',
                subtitle: 'Mapa mental, linha do tempo, genograma e metas',
                accentColor: _WorkspaceAccents.clinical,
                onTap: () => context.push(
                  PatientRoutes.list(ProfileRole.psychologist),
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.library_books_outlined,
                title: 'Recursos terapêuticos',
                subtitle: 'Materiais e exercícios por paciente',
                accentColor: _WorkspaceAccents.clinical,
                onTap: () => context.push(
                  PatientRoutes.list(ProfileRole.psychologist),
                ),
              ),
            ],
          ),
        ),
      ],
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
        color: AppColors.surface,
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
