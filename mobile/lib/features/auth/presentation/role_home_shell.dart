import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/clinical_module_card.dart';
import '../../../shared/widgets/esquema_core_logo.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../clinic_entitlements/domain/clinic_feature_entitlement.dart';
import '../../clinic_entitlements/providers/clinic_entitlements_providers.dart';
import '../../patient_check_ins/presentation/patient_check_in_routes.dart';
import '../../patient_check_ins/providers/patient_check_ins_providers.dart';
import '../../patient_journey/presentation/patient_journey_routes.dart';
import '../../patient_invitations/domain/patient_invitation.dart';
import '../../patient_invitations/providers/patient_invitations_providers.dart';
import '../../patient_invitations/presentation/patient_invitation_routes.dart';
import '../../patients/providers/patients_providers.dart';
import '../../patients/presentation/patient_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/profile_routes.dart';
import '../../profile/presentation/widgets/user_avatar.dart';
import '../../questionnaires/domain/questionnaire_patient_status.dart';
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
    required this.role,
    required this.entitlementsAsync,
  });

  final UserProfile profile;
  final ProfileRole role;
  final AsyncValue<ClinicFeatureEntitlements> entitlementsAsync;

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
            child: role == ProfileRole.patient
                ? _PatientGreetingHeader(profile: profile)
                : _ProfileHeader(profile: profile),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (role == ProfileRole.psychologist) const _PsychologistWorkspace(),
          if (role == ProfileRole.patient) ...[
            const MotionReveal(
              delay: Duration(milliseconds: 60),
              child: _PatientNextStep(),
            ),
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(
              title: 'Sua continuidade',
              subtitle: 'Veja o próximo passo do seu acompanhamento.',
            ),
            const SizedBox(height: AppSpacing.sm),
            MotionReveal(
              delay: const Duration(milliseconds: 120),
              child: ClinicalModuleCard(
                icon: Icons.route_outlined,
                title: 'Meu plano terapêutico',
                subtitle:
                    'Continue de onde parou: questionários, monitor diário e '
                    'seus recursos.',
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
          subtitle: 'Toque em um número para abrir a tela correspondente.',
        ),
        const SizedBox(height: AppSpacing.sm),
        MotionReveal(
          delay: const Duration(milliseconds: 80),
          child: _WorkspaceSummary(
            metrics: [
              _WorkspaceMetric(
                icon: Icons.people_outline,
                label: 'Pacientes',
                value: activePatients,
                accent: _WorkspaceAccents.management,
                onTap: () => context.push(
                  PatientRoutes.list(ProfileRole.psychologist),
                ),
              ),
              _WorkspaceMetric(
                icon: Icons.mark_email_unread_outlined,
                label: 'Convites',
                value: pendingInvitations,
                // Convite parado é a única métrica aqui que pede ação: por
                // isso ganha cor de alerta enquanto houver algum na fila.
                accent: pendingInvitations > 0
                    ? AppColors.warning
                    : _WorkspaceAccents.management,
                onTap: () => context.push(
                  PatientInvitationRoutes.list(ProfileRole.psychologist),
                ),
              ),
              _WorkspaceMetric(
                icon: Icons.assignment_outlined,
                label: 'Questionários',
                value: questionnaires.length,
                accent: _WorkspaceAccents.assessment,
                onTap: () =>
                    context.push(QuestionnaireRoutes.psychologistCatalog),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const AppSectionHeader(
          title: 'Carteira de pacientes',
          subtitle: 'Cadastro, convites e plano de cuidado.',
          accentColor: _WorkspaceAccents.management,
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
          accentColor: _WorkspaceAccents.assessment,
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
                  extra: PatientSelectionIntent.questionnaires,
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.insights_outlined,
                title: 'Resultados',
                subtitle: 'Acompanhar respostas e revisar instrumentos',
                accentColor: _WorkspaceAccents.assessment,
                onTap: () => context.push(
                  PatientRoutes.list(ProfileRole.psychologist),
                  extra: PatientSelectionIntent.results,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const AppSectionHeader(
          title: 'Raciocínio clínico',
          subtitle: 'Formulação de caso e materiais terapêuticos.',
          accentColor: _WorkspaceAccents.clinical,
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
                  extra: PatientSelectionIntent.formulation,
                ),
              ),
              ClinicalModuleCard(
                icon: Icons.library_books_outlined,
                title: 'Recursos terapêuticos',
                subtitle: 'Materiais e exercícios por paciente',
                accentColor: _WorkspaceAccents.clinical,
                onTap: () => context.push(
                  PatientRoutes.list(ProfileRole.psychologist),
                  extra: PatientSelectionIntent.therapyResources,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Cabeçalho acolhedor da home do paciente: saudação pelo nome e
/// período do dia, no lugar do cartão de perfil institucional.
class _PatientGreetingHeader extends StatelessWidget {
  const _PatientGreetingHeader({required this.profile});

  final UserProfile profile;

  static String greetingForHour(int hour) {
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  @override
  Widget build(BuildContext context) {
    final firstName = profile.fullName.trim().split(RegExp(r'\s+')).first;
    final greeting = greetingForHour(DateTime.now().hour);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlAll,
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$greeting, $firstName',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.navy,
                  fontWeight: FontWeight.w600,
                ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Que bom te ver por aqui. Este é o seu espaço de cuidado.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}

/// Próximo passo concreto do paciente: questionário aguardando resposta,
/// check-in do dia ainda não feito, ou reconhecimento de que está em dia.
class _PatientNextStep extends ConsumerWidget {
  const _PatientNextStep();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const listContext = QuestionnaireListContext(role: ProfileRole.patient);

    final questionnaires =
        ref.watch(questionnairesListProvider(listContext)).valueOrNull;
    final patientId =
        ref.watch(questionnairePatientIdProvider(listContext)).valueOrNull;
    final statuses = patientId == null
        ? null
        : ref.watch(questionnairePatientStatusProvider(patientId)).valueOrNull;
    final todayCheckIn = ref.watch(todayCheckInProvider);

    // Enquanto os dados carregam, não mostra nada — a home continua útil
    // e o cartão surge sem "pulo" de layout graças ao MotionReveal.
    if (questionnaires == null || statuses == null || todayCheckIn.isLoading) {
      return const SizedBox.shrink();
    }

    final pendingCount = questionnaires
        .where(
          (q) => statuses[q.id] != QuestionnairePatientStatus.completed,
        )
        .length;

    if (pendingCount > 0) {
      final label = pendingCount == 1
          ? 'Você tem 1 questionário aguardando'
          : 'Você tem $pendingCount questionários aguardando';
      return ClinicalModuleCard(
        icon: Icons.assignment_outlined,
        title: label,
        subtitle: 'Responder agora ajuda seu acompanhamento a ficar em dia.',
        accentColor: AppColors.purple,
        onTap: () =>
            context.push(QuestionnaireRoutes.list(role: ProfileRole.patient)),
      );
    }

    if (todayCheckIn.valueOrNull == null) {
      return ClinicalModuleCard(
        icon: Icons.favorite_border,
        title: 'Como você está hoje?',
        subtitle:
            'Seu check-in de hoje ainda não foi feito — leva menos de um minuto.',
        accentColor: AppColors.turquoise,
        onTap: () => context.push(PatientCheckInRoutes.patientCreate),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.turquoise.withValues(alpha: 0.12),
              borderRadius: AppRadius.mdAll,
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: AppColors.turquoise,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tudo em dia por hoje',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  'Você já cuidou do que precisava. Volte quando quiser.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Uma métrica do resumo da home do profissional.
class _WorkspaceMetric {
  const _WorkspaceMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final int value;
  final Color accent;
  final VoidCallback onTap;
}

/// Resumo da carteira em um painel único de colunas iguais.
///
/// Antes eram três cartões soltos num `Wrap`: no celular cabiam dois na
/// primeira linha e o terceiro ficava órfão embaixo, com um vazio ao lado.
/// Como painel único, as três colunas dividem a largura por igual em
/// qualquer tela e os números se comparam lado a lado.
class _WorkspaceSummary extends StatelessWidget {
  const _WorkspaceSummary({required this.metrics});

  final List<_WorkspaceMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
        // Altura fixa nas divisórias em vez de `CrossAxisAlignment.stretch`:
        // dentro de um ListView a altura do Row é ilimitada, e esticar filhos
        // nesse contexto quebra o layout da tela inteira.
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < metrics.length; i++) ...[
              if (i > 0)
                Container(
                  width: 1,
                  height: 56,
                  color: AppColors.border,
                ),
              Expanded(child: _WorkspaceMetricCell(metric: metrics[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _WorkspaceMetricCell extends StatelessWidget {
  const _WorkspaceMetricCell({required this.metric});

  final _WorkspaceMetric metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final duration = AppAnimations.resolve(
      context,
      const Duration(milliseconds: 320),
    );

    return Semantics(
      button: true,
      label: '${metric.label}: ${metric.value}',
      child: InkWell(
        onTap: metric.onTap,
        borderRadius: AppRadius.mdAll,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xs,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(metric.icon, size: 20, color: metric.accent),
              const SizedBox(height: AppSpacing.xs),
              TweenAnimationBuilder<int>(
                duration: duration,
                curve: AppAnimations.standardCurve,
                tween: IntTween(begin: 0, end: metric.value),
                builder: (context, animated, _) {
                  return Text(
                    '$animated',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w700,
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                metric.label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Cabeçalho da home do profissional: saudação pelo primeiro nome e uma
/// linha de contexto vinda dos dados reais da carteira.
///
/// Substitui o antigo cartão institucional (nome completo + papel + e-mail),
/// que repetia o subtítulo da AppBar e gastava a área mais nobre da tela com
/// informação que o profissional já sabe sobre si mesmo.
class _ProfileHeader extends ConsumerWidget {
  const _ProfileHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final firstName = profile.fullName.trim().split(RegExp(r'\s+')).first;
    final greeting = _PatientGreetingHeader.greetingForHour(
      DateTime.now().hour,
    );

    final patients = ref.watch(patientsListProvider).valueOrNull;
    final invitations = ref.watch(patientInvitationsListProvider).valueOrNull;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlAll,
        boxShadow: AppShadows.clay(),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.turquoise.withValues(alpha: 0.14),
              boxShadow: AppShadows.clay(AppColors.turquoise),
            ),
            child: Text(
              profile.fullName.trim().characters.first.toUpperCase(),
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.turquoise,
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
                  '$greeting, $firstName',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _contextLine(patients?.length, invitations),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Uma frase sobre o estado real da carteira. Enquanto os dados carregam,
  /// mostra uma linha neutra em vez de números piscando de 0 para o total.
  static String _contextLine(
    int? patientCount,
    List<PatientInvitation>? invitations,
  ) {
    if (patientCount == null || invitations == null) {
      return 'Seu espaço de trabalho clínico.';
    }
    final pending = invitations.where((i) => i.isPending).length;
    if (pending > 0) {
      final label = pending == 1
          ? '1 convite aguardando aceite'
          : '$pending convites aguardando aceite';
      return '$label. Bom trabalho por aqui.';
    }
    if (patientCount == 0) {
      return 'Comece cadastrando ou convidando seu primeiro paciente.';
    }
    final label = patientCount == 1
        ? '1 paciente na sua carteira'
        : '$patientCount pacientes na sua carteira';
    return '$label. Tudo em dia por aqui.';
  }
}
