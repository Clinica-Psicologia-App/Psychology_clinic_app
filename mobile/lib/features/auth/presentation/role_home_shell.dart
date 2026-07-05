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
            const AppSectionHeader(
              title: 'Central de trabalho',
              subtitle:
                  'Acompanhe pacientes, convites, instrumentos e fluxos clínicos.',
            ),
            const SizedBox(height: AppSpacing.sm),
            const _PsychologistWorkspace(),
          ],
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
        MotionReveal(
          delay: const Duration(milliseconds: 80),
          child: _SummaryStrip(
            items: [
              _SummaryItem(
                icon: Icons.people_outline,
                label: 'Pacientes ativos',
                value: activePatients.toString(),
                color: AppColors.blue,
              ),
              _SummaryItem(
                icon: Icons.mark_email_unread_outlined,
                label: 'Convites pendentes',
                value: pendingInvitations.toString(),
                color: AppColors.cyan,
              ),
              _SummaryItem(
                icon: Icons.assignment_outlined,
                label: 'Questionários liberados',
                value: questionnaires.length.toString(),
                color: AppColors.purple,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        MotionReveal(
          delay: const Duration(milliseconds: 120),
          child: ResponsiveGrid(
            mediumColumns: 2,
            expandedColumns: 2,
            children: [
              ClinicalModuleCard(
                icon: Icons.people_outline,
                title: 'Pacientes',
                subtitle: 'Carteira clínica, detalhes e plano de cuidado',
                accentColor: AppColors.blue,
                onTap: () => context.push(
                  PatientRoutes.list(ProfileRole.psychologist),
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.person_add_alt_1_outlined,
                title: 'Novo paciente',
                subtitle: 'Cadastrar paciente diretamente na sua carteira',
                accentColor: AppColors.turquoise,
                onTap: () => context.push(
                  PatientRoutes.create(ProfileRole.psychologist),
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.mark_email_unread_outlined,
                title: 'Convites',
                subtitle: 'Enviar convite e acompanhar aceite do paciente',
                accentColor: AppColors.cyan,
                onTap: () => context.push(
                  PatientInvitationRoutes.list(ProfileRole.psychologist),
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.assignment_outlined,
                title: 'Meus questionários',
                subtitle: 'Ver instrumentos liberados pelo administrador',
                accentColor: AppColors.purple,
                onTap: () => context.push(
                  QuestionnaireRoutes.psychologistCatalog,
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.fact_check_outlined,
                title: 'Liberar para paciente',
                subtitle: 'Escolha um paciente e abra Questionários',
                accentColor: AppColors.moduleQuestionnaires,
                onTap: () => context.push(
                  PatientRoutes.list(ProfileRole.psychologist),
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.psychology_alt_outlined,
                title: 'Formulação clínica',
                subtitle: 'Mapa mental, linha do tempo, genograma e metas',
                accentColor: AppColors.moduleMentalMap,
                onTap: () => context.push(
                  PatientRoutes.list(ProfileRole.psychologist),
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.insights_outlined,
                title: 'Resultados',
                subtitle: 'Acompanhar respostas e revisar instrumentos',
                accentColor: AppColors.moduleDashboard,
                onTap: () => context.push(
                  PatientRoutes.list(ProfileRole.psychologist),
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.library_books_outlined,
                title: 'Recursos terapêuticos',
                subtitle: 'Materiais e exercícios por paciente',
                accentColor: AppColors.moduleResources,
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

class _SummaryStrip extends StatelessWidget {
  const _SummaryStrip({required this.items});

  final List<_SummaryItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 560;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: items
              .map(
                (item) => SizedBox(
                  width: compact
                      ? constraints.maxWidth
                      : (constraints.maxWidth - AppSpacing.sm * 2) / 3,
                  child: _SummaryTile(item: item),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.item});

  final _SummaryItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: item.color.withValues(alpha: 0.12),
                borderRadius: AppRadius.mdAll,
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    item.label,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
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

class _SummaryItem {
  const _SummaryItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
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
