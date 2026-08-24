import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_canopy_header.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/clinical_module_card.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../clinic_entitlements/domain/clinic_feature_entitlement.dart';
import '../../clinic_entitlements/providers/clinic_entitlements_providers.dart';
import '../../daily_monitors/presentation/daily_monitor_routes.dart';
import '../../mental_map/presentation/mental_map_routes.dart';
import '../../patient_check_ins/presentation/patient_check_in_routes.dart';
import '../../patient_check_ins/providers/patient_check_ins_providers.dart';
import '../../patient_journey/presentation/patient_journey_routes.dart';
import '../../patient_invitations/domain/patient_invitation.dart';
import '../../patient_invitations/providers/patient_invitations_providers.dart';
import '../../patient_invitations/presentation/patient_invitation_routes.dart';
import '../../patients/domain/psychologist_alert.dart';
import '../../patients/providers/patients_providers.dart';
import '../../patients/presentation/patient_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../../profile/domain/user_profile.dart';
import '../../profile/presentation/profile_routes.dart';
import '../../questionnaires/domain/questionnaire_patient_status.dart';
import '../../questionnaires/presentation/questionnaire_routes.dart';
import '../../questionnaires/providers/questionnaires_providers.dart';
import '../../results/providers/results_providers.dart';
import '../../therapy_goals/domain/therapy_goal_status.dart';
import '../../therapy_goals/presentation/therapy_goal_routes.dart';
import '../../therapy_goals/providers/therapy_goals_providers.dart';
import '../../therapy_resources/presentation/therapy_resource_routes.dart';
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

    return AppCanopyScaffold(
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
    // Canopy full-bleed no topo (ele reserva o inset da status bar); o
    // conteúdo flui abaixo, com a largura máxima responsiva de sempre.
    final header = role == ProfileRole.patient
        ? _PatientGreetingHeader(profile: profile)
        : _ProfileHeader(profile: profile);

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        header,
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
                if (role == ProfileRole.psychologist)
                  const _PsychologistWorkspace(),
                if (role == ProfileRole.patient) ...[
                  const MotionReveal(
                    delay: Duration(milliseconds: 60),
                    child: _PatientNextStep(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const AppSectionHeader(
                    title: 'Seu progresso',
                    subtitle: 'Um resumo simples de como você está indo.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const MotionReveal(
                    delay: Duration(milliseconds: 100),
                    child: _PatientProgressSummary(),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const AppSectionHeader(
                    title: 'Seus espaços',
                    subtitle: 'Escolha por onde continuar agora.',
                    accentColor: _WorkspaceAccents.clinical,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MotionReveal(
                    delay: const Duration(milliseconds: 140),
                    // Coluna única no celular: com 3 cards e 2 colunas, um deles
                    // sempre fica sozinho numa linha, ocupando só metade da
                    // largura — o mesmo problema de item órfão já corrigido antes
                    // nesta sessão para o resumo do profissional. Em telas largas
                    // os 3 cabem numa linha só.
                    child: ResponsiveGrid(
                      compactColumns: 1,
                      mediumColumns: 3,
                      expandedColumns: 3,
                      children: [
                        _PatientExploreCard(
                          icon: Icons.hub_outlined,
                          title: 'Mapa mental',
                          subtitle: 'Uma visão geral do que já conversamos.',
                          accentColor: _WorkspaceAccents.clinical,
                          onTap: () =>
                              context.push(MentalMapRoutes.patientList),
                        ),
                        _PatientExploreCard(
                          icon: Icons.menu_book_outlined,
                          title: 'Biblioteca',
                          subtitle:
                              'Materiais e exercícios pensados para você.',
                          accentColor: _WorkspaceAccents.clinical,
                          onTap: () =>
                              context.push(TherapyResourceRoutes.patientList),
                        ),
                        _PatientExploreCard(
                          icon: Icons.monitor_heart_outlined,
                          title: 'Monitor diário',
                          subtitle: 'Humor, rotina e como você tem se sentido.',
                          accentColor: _WorkspaceAccents.management,
                          onTap: () =>
                              context.push(DailyMonitorRoutes.patientList),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const AppSectionHeader(
                    title: 'Sua continuidade',
                    subtitle:
                        'O caminho completo do seu acompanhamento, no seu ritmo.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MotionReveal(
                    delay: const Duration(milliseconds: 180),
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
          ),
        ),
      ],
    );
  }
}

class _PsychologistWorkspace extends ConsumerWidget {
  const _PsychologistWorkspace();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // O resumo da carteira ("Central de trabalho") agora flutua no canopy
        // (ver _ProfileHeader.footer); aqui fica só o painel de notificações e
        // os grupos de módulos.
        const _PsychologistAlertsCard(),
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
          title: 'Avaliação e recursos',
          subtitle: 'Questionários, liberações, resultados e materiais.',
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
              ClinicalModuleCard(
                icon: Icons.library_books_outlined,
                title: 'Recursos terapêuticos',
                subtitle: 'Materiais e exercícios por paciente',
                accentColor: _WorkspaceAccents.assessment,
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

// ---------------------------------------------------------------------------
// Alertas clínicos do psicólogo
// ---------------------------------------------------------------------------

/// Painel de atenções: convites expirando, check-ins em falta,
/// questionários parados. Só aparece quando há ao menos um alerta.
class _PsychologistAlertsCard extends ConsumerWidget {
  const _PsychologistAlertsCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(psychologistAlertsProvider);

    return alertsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (alerts) {
        if (alerts.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: _AlertsPanel(alerts: alerts),
        );
      },
    );
  }
}

class _AlertsPanel extends StatefulWidget {
  const _AlertsPanel({required this.alerts});

  final List<PsychologistAlert> alerts;

  @override
  State<_AlertsPanel> createState() => _AlertsPanelState();
}

class _AlertsPanelState extends State<_AlertsPanel> {
  static const _initialCount = 3;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final alerts = widget.alerts;
    final hasMore = alerts.length > _initialCount;
    final visible = _expanded ? alerts : alerts.take(_initialCount).toList();

    return ClayCard(
      accentColor: AppColors.warning,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 17,
                  color: AppColors.warning,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Notificações',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.navy,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${alerts.length}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.warning,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          for (final alert in visible) ...[
            const Divider(height: 1, thickness: 0.5, color: AppColors.border),
            _AlertRow(alert: alert),
          ],
          if (hasMore) ...[
            const Divider(height: 1, thickness: 0.5, color: AppColors.border),
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(AppRadius.xl),
                bottomRight: Radius.circular(AppRadius.xl),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _expanded
                          ? 'Mostrar menos'
                          : 'Ver todos (${alerts.length})',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.warning,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      _expanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 16,
                      color: AppColors.warning,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Ícone e par de cores (traço/pílula × fundo claro) por tipo de alerta —
/// convite expirando é tempo-crítico (vermelho), questionário parado pede
/// atenção mas não é urgente (âmbar), check-in ausente é informativo
/// (azul). Antes os três usavam a mesma cor e não se distinguiam.
({IconData icon, Color fg, Color bg}) _alertStyle(PsychologistAlertKind kind) {
  switch (kind) {
    case PsychologistAlertKind.expiringInvitation:
      return (
        icon: Icons.mark_email_unread_outlined,
        fg: AppColors.error,
        bg: AppColors.errorContainer,
      );
    case PsychologistAlertKind.staleQuestionnaire:
      return (
        icon: Icons.assignment_late_outlined,
        fg: AppColors.warning,
        bg: AppColors.warningContainer,
      );
    case PsychologistAlertKind.missingCheckin:
      return (
        icon: Icons.event_busy_outlined,
        fg: AppColors.info,
        bg: AppColors.infoContainer,
      );
    case PsychologistAlertKind.pendingResultsRelease:
      // Verde: é a única categoria cuja ação é positiva — o trabalho clínico
      // já terminou, falta só o clique de liberar.
      return (
        icon: Icons.fact_check_outlined,
        fg: AppColors.success,
        bg: AppColors.successContainer,
      );
  }
}

class _AlertRow extends StatelessWidget {
  const _AlertRow({required this.alert});

  final PsychologistAlert alert;

  @override
  Widget build(BuildContext context) {
    final style = _alertStyle(alert.kind);
    final theme = Theme.of(context);

    return Semantics(
      // A leitura visual divide nome, subtítulo e prazo em três textos; o
      // leitor de tela continua ouvindo a frase completa de uma vez.
      // `excludeSemantics` impede que os textos dos filhos vazem e se
      // concatenem com este rótulo. A ação de toque vive no próprio nó (o
      // `excludeSemantics` descartaria a do InkWell): sem ela, o nó não é
      // focável e é mesclado ao conteúdo vizinho pelo leitor de tela.
      label: alert.message,
      excludeSemantics: true,
      button: true,
      onTap: () => _navigate(context),
      child: InkWell(
        onTap: () => _navigate(context),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 10,
          ),
          child: Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(style.icon, size: 15, color: style.fg),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      alert.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.navy,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      alert.subtitleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: style.bg,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  alert.pillLabel,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: style.fg,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: AppColors.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext context) {
    switch (alert.kind) {
      case PsychologistAlertKind.missingCheckin:
        if (alert.patientId != null) {
          context.push(
            PatientRoutes.detail(ProfileRole.psychologist, alert.patientId!),
          );
        }
      case PsychologistAlertKind.expiringInvitation:
        context.push(PatientInvitationRoutes.list(ProfileRole.psychologist));
      case PsychologistAlertKind.staleQuestionnaire:
        if (alert.patientId != null) {
          context.push(
            PatientRoutes.detail(ProfileRole.psychologist, alert.patientId!),
          );
        }
      case PsychologistAlertKind.pendingResultsRelease:
        // Leva à tela de Questionários do paciente (aba Panorama), onde agora
        // vive o botão de liberar resultados — poupa um toque a mais.
        if (alert.patientId != null) {
          context.push(
            QuestionnaireRoutes.list(
              role: ProfileRole.psychologist,
              patientId: alert.patientId!,
            ),
          );
        }
    }
  }
}

/// Cabeçalho acolhedor da home do paciente: saudação pelo nome e
/// período do dia, no lugar do cartão de perfil institucional.
class _PatientGreetingHeader extends StatelessWidget {
  const _PatientGreetingHeader({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final firstName = profile.fullName.trim().split(RegExp(r'\s+')).first;
    return AppCanopyHeader(
      profile: profile,
      accent: AppColors.blue,
      name: firstName,
      areaLabel: 'Meu espaço',
      contextLine: 'Que bom te ver por aqui. Este é o seu espaço de cuidado.',
      watermarkIcon: Icons.spa_outlined,
      onProfileTap: () => context.push(ProfileRoutes.me),
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

    // Mesma sombra clay dos dois estados acima (ClinicalModuleCard já a usa)
    // — antes este era o único card da tela com borda simples em vez de
    // sombra, e destoava do resto.
    return ClayCard(
      accentColor: AppColors.turquoise,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.lgAll),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.turquoise.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline,
                color: AppColors.turquoise,
                size: 24,
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
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Você já cuidou do que precisava por hoje. Volte quando '
                    'quiser — sem pressa.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.4,
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

/// Atalho de exploração da home do paciente: selo circular colorido no
/// topo, título e descrição abaixo — um "tile" de app, não uma linha de
/// lista. Widget próprio (e não [ClinicalModuleCard], usado no resto do
/// app): a tela do paciente pediu um tratamento mais amigável, e mudar o
/// card compartilhado afetaria a home do profissional também.
class _PatientExploreCard extends StatelessWidget {
  const _PatientExploreCard({
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
    final theme = Theme.of(context);

    return MotionSurface(
      onTap: onTap,
      borderRadius: AppRadius.xlAll,
      child: ClayCard(
        accentColor: accentColor,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.xlAll,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            // Ícone à esquerda, texto à direita: a mesma disposição se
            // adapta bem tanto à largura inteira (celular, coluna única)
            // quanto a uma célula de grade mais estreita (tablet e
            // desktop) — um layout empilhado (ícone em cima) sobra vazio
            // demais quando esticado à largura inteira do celular.
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accentColor, size: 26),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        subtitle,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
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

/// Resumo do progresso do paciente: metas ativas, check-ins da semana e
/// resultados liberados. Os números são reais (nada de dado fictício) e
/// cada um leva à tela correspondente.
///
/// A renderização é própria ([_PatientMetricsPanel]), não a
/// [_WorkspaceSummary] do profissional — mesma lógica de dados, visual
/// mais caloroso (selo circular colorido atrás do ícone) sem arriscar a
/// home do profissional, que reusa o painel original.
class _PatientProgressSummary extends ConsumerWidget {
  const _PatientProgressSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const listContext = QuestionnaireListContext(role: ProfileRole.patient);
    final patientId =
        ref.watch(questionnairePatientIdProvider(listContext)).valueOrNull;

    final goals = ref.watch(myTherapyGoalsProvider).valueOrNull;
    final checkIns = ref.watch(myPatientCheckInsProvider).valueOrNull;
    final results = patientId == null
        ? null
        : ref
            .watch(
              patientResultsListProvider(
                PatientResultsContext(
                  role: ProfileRole.patient,
                  patientId: patientId,
                ),
              ),
            )
            .valueOrNull;

    // Mesmo padrão do _PatientNextStep: enquanto os dados carregam, não
    // mostra nada em vez de piscar zeros antes do valor real.
    if (goals == null || checkIns == null || results == null) {
      return const SizedBox.shrink();
    }

    final activeGoals =
        goals.where((g) => g.status == TherapyGoalStatus.active).length;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final recentCheckIns =
        checkIns.where((c) => c.checkedInAt.isAfter(weekAgo)).length;

    return _PatientMetricsPanel(
      metrics: [
        _WorkspaceMetric(
          icon: Icons.flag_outlined,
          label: 'Metas ativas',
          value: activeGoals,
          accent: AppColors.purple,
          onTap: () => context.push(TherapyGoalRoutes.patientList),
        ),
        _WorkspaceMetric(
          icon: Icons.fact_check_outlined,
          label: 'Check-ins na semana',
          value: recentCheckIns,
          accent: AppColors.turquoise,
          onTap: () => context.push(PatientCheckInRoutes.patientList),
        ),
        _WorkspaceMetric(
          icon: Icons.analytics_outlined,
          label: 'Resultados',
          value: results.length,
          accent: AppColors.blue,
          // Mesma rota usada pela trilha para o passo "Meus resultados".
          onTap: () => context.push('/patient/results'),
        ),
      ],
    );
  }
}

/// Painel de métricas com selo circular colorido atrás do ícone — a mesma
/// estrutura de colunas do [_WorkspaceSummary], com um acabamento mais
/// caloroso para a home do paciente.
class _PatientMetricsPanel extends StatelessWidget {
  const _PatientMetricsPanel({required this.metrics});

  final List<_WorkspaceMetric> metrics;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs,
          vertical: AppSpacing.md,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < metrics.length; i++) ...[
              if (i > 0)
                Container(width: 1, height: 64, color: AppColors.border),
              Expanded(child: _PatientMetricCell(metric: metrics[i])),
            ],
          ],
        ),
      ),
    );
  }
}

class _PatientMetricCell extends StatelessWidget {
  const _PatientMetricCell({required this.metric});

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
            horizontal: AppSpacing.xxs,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 36,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: metric.accent.withValues(alpha: 0.14),
                  shape: BoxShape.circle,
                ),
                child: Icon(metric.icon, size: 18, color: metric.accent),
              ),
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
    final firstName = profile.fullName.trim().split(RegExp(r'\s+')).first;
    final patients = ref.watch(patientsListProvider).valueOrNull;
    final invitations = ref.watch(patientInvitationsListProvider).valueOrNull;
    final questionnaires =
        ref.watch(psychologistQuestionnairesProvider).valueOrNull ?? const [];

    final activePatients =
        (patients ?? const []).where((patient) => patient.isActive).length;
    final pendingInvitations = (invitations ?? const [])
        .where((invitation) => invitation.isPending)
        .length;

    return AppCanopyHeader(
      profile: profile,
      accent: _WorkspaceAccents.clinical,
      name: firstName,
      areaLabel: 'Profissional',
      contextLine: _contextLine(
        patients == null ? null : activePatients,
        invitations,
      ),
      watermarkIcon: Icons.psychology_alt_outlined,
      onProfileTap: () => context.push(ProfileRoutes.me),
      // Resumo da carteira flutuando sobre a base do canopy — o antigo bloco
      // "Central de trabalho", promovido ao cabeçalho.
      footer: _WorkspaceSummary(
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
            onTap: () => context.push(QuestionnaireRoutes.psychologistCatalog),
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
