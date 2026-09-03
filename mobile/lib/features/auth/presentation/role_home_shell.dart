import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_canopy_header.dart';
import '../../../shared/widgets/brand_brain_mark.dart';
import '../../profile/presentation/widgets/user_avatar.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/clinical_module_card.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../clinic_entitlements/domain/clinic_feature_entitlement.dart';
import '../../clinic_entitlements/providers/clinic_entitlements_providers.dart';
import '../../coach/domain/coach_step.dart';
import '../../coach/domain/coach_tour.dart';
import '../../coach/providers/coach_providers.dart';
import '../../daily_monitors/presentation/daily_monitor_routes.dart';
import '../../mental_map/presentation/mental_map_routes.dart';
import '../../patient_check_ins/presentation/patient_check_in_routes.dart';
import '../../patient_check_ins/providers/patient_check_ins_providers.dart';
import '../../patient_journey/presentation/patient_journey_routes.dart';
import '../../personality_assessment/presentation/personality_assessment_routes.dart';
import '../../personality_assessment/providers/personality_assessment_providers.dart';
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
import '../../../shared/widgets/brand_loading.dart';

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
        loading: () => const BrandLoader(),
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

class _HomeBody extends ConsumerStatefulWidget {
  const _HomeBody({
    required this.profile,
    required this.role,
    required this.entitlementsAsync,
  });

  final UserProfile profile;
  final ProfileRole role;
  final AsyncValue<ClinicFeatureEntitlements> entitlementsAsync;

  @override
  ConsumerState<_HomeBody> createState() => _HomeBodyState();
}

class _HomeBodyState extends ConsumerState<_HomeBody> {
  final _headerSummaryKey = GlobalKey();
  final _patientsCardKey = GlobalKey();
  final _assessmentSectionKey = GlobalKey();
  final _patientNextStepKey = GlobalKey();
  final _patientSpacesKey = GlobalKey();
  final _patientPlanKey = GlobalKey();
  bool _autoTourRequested = false;

  CoachTour? _homeTour() {
    switch (widget.role) {
      case ProfileRole.psychologist:
        return _psychologistHomeTour();
      case ProfileRole.patient:
        return _patientHomeTour();
      case ProfileRole.platformAdmin:
        return null;
    }
  }

  Future<void> _startAutoTour() async {
    if (!mounted) return;
    final tour = _homeTour();
    if (tour == null) return;
    await ref.read(coachControllerProvider.notifier).startTour(context, tour);
  }

  Future<void> _replayTour() async {
    final tour = _homeTour();
    if (tour == null) return;
    await ref
        .read(coachControllerProvider.notifier)
        .startTour(context, tour, force: true);
  }

  CoachTour _patientHomeTour() {
    return CoachTour(
      id: 'tour_home_paciente',
      steps: [
        CoachStep(
          id: 'ola',
          text:
              'Oi! Eu sou o guia do EsquemaCore. Vou te mostrar seu espaço rapidinho.',
          pose: MascotPose.wave,
          targetKey: _patientNextStepKey,
        ),
        CoachStep(
          id: 'plano',
          text:
              'Aqui você continua seu acompanhamento de onde parou: questionários, monitor diário e seus recursos.',
          pose: MascotPose.point,
          targetKey: _patientPlanKey,
        ),
        CoachStep(
          id: 'espacos',
          text:
              'E por aqui você explora o mapa mental, a biblioteca e o monitor diário. Fico por perto se precisar. 🙂',
          pose: MascotPose.celebrate,
          targetKey: _patientSpacesKey,
        ),
      ],
    );
  }

  CoachTour _psychologistHomeTour() {
    return CoachTour(
      id: 'tour_home_psicologo',
      steps: [
        CoachStep(
          id: 'boas-vindas',
          text:
              'Este resumo mostra sua carteira ativa, convites pendentes e instrumentos em uso.',
          pose: MascotPose.wave,
          targetKey: _headerSummaryKey,
        ),
        CoachStep(
          id: 'pacientes',
          text:
              'Comece por Pacientes para abrir detalhes clinicos, plano de cuidado e acompanhamento.',
          pose: MascotPose.point,
          targetKey: _patientsCardKey,
        ),
        CoachStep(
          id: 'avaliacao-recursos',
          text:
              'Aqui ficam questionarios, resultados e recursos terapeuticos para apoiar suas decisoes.',
          pose: MascotPose.celebrate,
          targetKey: _assessmentSectionKey,
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tour do psicólogo: os 3 widgets-alvo são sempre renderizados → dispara
    // assim que o build ocorre pela primeira vez.
    if (widget.role == ProfileRole.psychologist && !_autoTourRequested) {
      _autoTourRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoTour());
    }

    // Tour do paciente: _PatientNextStep retorna SizedBox.shrink() enquanto
    // os providers não resolvem. Aguarda todos antes de disparar.
    if (widget.role == ProfileRole.patient && !_autoTourRequested) {
      const listCtx = QuestionnaireListContext(role: ProfileRole.patient);
      final patientIdAsync = ref.watch(questionnairePatientIdProvider(listCtx));
      final questReady = ref.watch(questionnairesListProvider(listCtx)).hasValue;
      final checkInReady = !ref.watch(todayCheckInProvider).isLoading;
      final patientId = patientIdAsync.valueOrNull;
      final statusReady = patientId == null
          ? false
          : ref.watch(questionnairePatientStatusProvider(patientId)).hasValue;
      if (patientIdAsync.hasValue && questReady && checkInReady && statusReady) {
        _autoTourRequested = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _startAutoTour());
      }
    }

    // Card de Personalidade só aparece se o terapeuta já compartilhou algo.
    final hasSharedPersonality = widget.role == ProfileRole.patient &&
        ref.watch(patientSharedPersonalityProvider).maybeWhen(
              data: (list) => list.isNotEmpty,
              orElse: () => false,
            );

    // Canopy full-bleed no topo (ele reserva o inset da status bar); o
    // conteúdo flui abaixo, com a largura máxima responsiva de sempre.
    final header = widget.role == ProfileRole.patient
        ? _PatientGreetingHeader(
            profile: widget.profile,
            onHelpTap: _replayTour,
          )
        : _ProfileHeader(
            profile: widget.profile,
            summaryKey: _headerSummaryKey,
            onHelpTap: _replayTour,
          );

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
                if (widget.role == ProfileRole.psychologist)
                  _PsychologistWorkspace(
                    patientsCardKey: _patientsCardKey,
                    assessmentSectionKey: _assessmentSectionKey,
                  ),
                if (widget.role == ProfileRole.patient) ...[
                  const MotionReveal(
                    delay: Duration(milliseconds: 40),
                    child: _PatientMoodPulse(),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  MotionReveal(
                    delay: const Duration(milliseconds: 60),
                    child: KeyedSubtree(
                      key: _patientNextStepKey,
                      child: const _PatientNextStep(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const MotionReveal(
                    delay: Duration(milliseconds: 130),
                    child: AppSectionHeader(
                      title: 'Seu progresso',
                      subtitle: 'Um resumo simples de como você está indo.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const _PatientProgressSummary(),
                  const SizedBox(height: AppSpacing.xl),
                  MotionReveal(
                    delay: const Duration(milliseconds: 300),
                    child: AppSectionHeader(
                      key: _patientSpacesKey,
                      title: 'Seus espaços',
                      subtitle: 'Escolha por onde continuar agora.',
                      accentColor: _WorkspaceAccents.clinical,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  // Coluna única no celular: com 3 cards e 2 colunas, um deles
                  // sempre fica sozinho numa linha, ocupando só metade da
                  // largura — problema de item órfão já corrigido nesta sessão.
                  // Em telas largas os 3 cabem numa linha só. Cada card entra
                  // com um pequeno atraso em cascata.
                  ResponsiveGrid(
                    compactColumns: 1,
                    mediumColumns: 3,
                    expandedColumns: 3,
                    children: [
                      MotionReveal(
                        delay: const Duration(milliseconds: 340),
                        child: _PatientExploreCard(
                          icon: Icons.hub_outlined,
                          title: 'Mapa mental',
                          subtitle: 'Uma visão geral do que já conversamos.',
                          accentColor: AppColors.purple,
                          onTap: () =>
                              context.push(MentalMapRoutes.patientList),
                        ),
                      ),
                      MotionReveal(
                        delay: const Duration(milliseconds: 400),
                        child: _PatientExploreCard(
                          icon: Icons.menu_book_outlined,
                          title: 'Biblioteca',
                          subtitle:
                              'Materiais e exercícios pensados para você.',
                          accentColor: const Color(0xFF1D9E75),
                          onTap: () =>
                              context.push(TherapyResourceRoutes.patientList),
                        ),
                      ),
                      MotionReveal(
                        delay: const Duration(milliseconds: 460),
                        child: _PatientExploreCard(
                          icon: Icons.monitor_heart_outlined,
                          title: 'Monitor diário',
                          subtitle:
                              'Humor, rotina e como você tem se sentido.',
                          accentColor: AppColors.cyan,
                          onTap: () =>
                              context.push(DailyMonitorRoutes.patientList),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  MotionReveal(
                    delay: const Duration(milliseconds: 520),
                    child: AppSectionHeader(
                      key: _patientPlanKey,
                      title: 'Sua continuidade',
                      subtitle:
                          'O caminho completo do seu acompanhamento, no seu ritmo.',
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  MotionReveal(
                    delay: const Duration(milliseconds: 560),
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
                  if (hasSharedPersonality) ...[
                    const SizedBox(height: AppSpacing.sm),
                    MotionReveal(
                      delay: const Duration(milliseconds: 600),
                      child: ClinicalModuleCard(
                        icon: Icons.psychology_alt_outlined,
                        title: 'Personalidade',
                        subtitle:
                            'Resultados que seu psicólogo compartilhou com você.',
                        accentColor: AppColors.purple,
                        onTap: () => context
                            .push(PersonalityAssessmentRoutes.patientShared),
                      ),
                    ),
                  ],
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
  const _PsychologistWorkspace({
    required this.patientsCardKey,
    required this.assessmentSectionKey,
  });

  final GlobalKey patientsCardKey;
  final GlobalKey assessmentSectionKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // O resumo da carteira ("Central de trabalho") agora flutua no canopy
        // (ver _ProfileHeader.footer); aqui fica só o painel de notificações e
        // os grupos de módulos.
        const _PsychologistAlertsCard(),
        KeyedSubtree(
          key: patientsCardKey,
          child: const AppSectionHeader(
            title: 'Carteira de pacientes',
            subtitle: 'Cadastro, convites e plano de cuidado.',
            accentColor: _WorkspaceAccents.management,
          ),
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
        KeyedSubtree(
          key: assessmentSectionKey,
          child: const AppSectionHeader(
            title: 'Avaliação e recursos',
            subtitle: 'Questionários, liberações, resultados e materiais.',
            accentColor: _WorkspaceAccents.assessment,
          ),
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
                    color: theme.colorScheme.onSurface,
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
            Divider(height: 1, thickness: 0.5, color: Theme.of(context).colorScheme.outline),
            _AlertRow(alert: alert),
          ],
          if (hasMore) ...[
            Divider(height: 1, thickness: 0.5, color: Theme.of(context).colorScheme.outline),
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
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                    Text(
                      alert.subtitleLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
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
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 11,
                color: theme.colorScheme.onSurfaceVariant,
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
  const _PatientGreetingHeader({required this.profile, this.onHelpTap});

  final UserProfile profile;
  final VoidCallback? onHelpTap;

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
      trailingAction: onHelpTap == null
          ? null
          : IconButton(
              tooltip: 'Rever tutorial',
              onPressed: onHelpTap,
              icon: const Icon(Icons.help_outline_rounded),
              color: Colors.white,
            ),
    );
  }
}

/// Próximo passo concreto do paciente: questionário aguardando resposta,
/// check-in do dia ainda não feito, ou reconhecimento de que está em dia.
/// Pulso emocional: mostra o último check-in (carinha + como estava) e convida
/// ao check-in de hoje. Conexão emocional logo na abertura da home.
class _PatientMoodPulse extends ConsumerWidget {
  const _PatientMoodPulse();

  static const _faces = ['😭', '😞', '😐', '🙂', '😄'];
  static const _words = [
    'muito para baixo',
    'para baixo',
    'neutro(a)',
    'bem',
    'muito bem'
  ];

  String _relativeDay(DateTime dt) {
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(dt.year, dt.month, dt.day);
    final days = d0.difference(d1).inDays;
    if (days <= 0) return 'Hoje';
    if (days == 1) return 'Ontem';
    return 'Há $days dias';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final list = ref.watch(myPatientCheckInsProvider).valueOrNull;
    // Enquanto carrega, não ocupa espaço (evita pulo de layout).
    if (list == null) return const SizedBox.shrink();

    final latest = list.isEmpty ? null : list.first;
    final today = latest != null && latest.isToday;
    final mood = latest?.moodScore;
    final idx = mood == null ? 2 : ((mood / 10) * 4).round().clamp(0, 4);
    final face = mood == null ? '🙂' : _faces[idx];

    final String title;
    final String subtitle;
    final String ctaLabel;

    if (latest == null) {
      title = 'Como você está hoje?';
      subtitle = 'Um check-in rápido ajuda no seu acompanhamento. Leva 1 minuto.';
      ctaLabel = 'Check-in';
    } else if (today) {
      title = 'Check-in de hoje feito 💚';
      subtitle = mood == null
          ? 'Obrigado por se cuidar hoje.'
          : 'Você registrou que está ${_words[idx]}.';
      ctaLabel = 'Abrir';
    } else {
      final rel = _relativeDay(latest.checkedInAt.toLocal());
      title = mood == null
          ? 'E hoje, como você está?'
          : '$rel você estava ${_words[idx]}';
      subtitle = 'E hoje, como você se sente?';
      ctaLabel = 'Check-in';
    }

    final detailId = today ? latest.id : null;
    Future<void> onCta() async {
      if (detailId != null) {
        await context.push(PatientCheckInRoutes.patientDetail(detailId));
      } else {
        await context.push(PatientCheckInRoutes.patientCreate);
      }
      ref.read(myPatientCheckInsProvider.notifier).refresh();
      ref.invalidate(todayCheckInProvider);
    }

    return ClayCard(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.turquoise.withValues(alpha: 0.25)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.surfaceTintTurquoise,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(face, style: const TextStyle(fontSize: 26)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            FilledButton(
              onPressed: onCta,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.turquoise,
                foregroundColor: Colors.white,
                visualDensity: VisualDensity.compact,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              ),
              child: Text(ctaLabel,
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }
}

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
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  Text(
                    'Você já cuidou do que precisava por hoje. Volte quando '
                    'quiser — sem pressa.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
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
    final dark = Color.lerp(accentColor, const Color(0xFF0D1B3D), 0.42)!;

    return MotionSurface(
      onTap: onTap,
      borderRadius: AppRadius.xlAll,
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.xlAll,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [accentColor, dark],
            ),
            borderRadius: AppRadius.xlAll,
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.28),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.xlAll,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(icon, color: Colors.white, size: 25),
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
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxs),
                        Text(
                          subtitle,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.85),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded,
                      color: Colors.white.withValues(alpha: 0.8), size: 20),
                ],
              ),
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
    // IntrinsicHeight limita a altura: sem ele, o stretch dentro da ListView
    // (altura infinita) estoura com "BoxConstraints forces an infinite height".
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < metrics.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: MotionReveal(
                delay: Duration(milliseconds: 160 + 55 * i),
                child: _PatientMetricCell(metric: metrics[i]),
              ),
            ),
          ],
        ],
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
      child: Material(
        color: theme.colorScheme.surface,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.mdAll,
          side: BorderSide(
              color: theme.colorScheme.outline.withValues(alpha: 0.5)),
        ),
        child: InkWell(
          onTap: metric.onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.xs,
              vertical: AppSpacing.md,
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
                        color: metric.accent,
                        fontWeight: FontWeight.w800,
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
                    color: theme.colorScheme.onSurfaceVariant,
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
                      color: theme.colorScheme.onSurface,
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
                  color: theme.colorScheme.onSurfaceVariant,
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
  const _ProfileHeader({
    required this.profile,
    required this.summaryKey,
    required this.onHelpTap,
  });

  final UserProfile profile;
  final GlobalKey summaryKey;
  final VoidCallback onHelpTap;

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

    return _CupolaHeader(
      profile: profile,
      name: firstName,
      areaLabel: 'Profissional',
      contextLine: _contextLine(
        patients == null ? null : activePatients,
        invitations,
      ),
      onProfileTap: () => context.push(ProfileRoutes.me),
      trailingAction: IconButton(
        tooltip: 'Rever tutorial',
        onPressed: onHelpTap,
        icon: const Icon(Icons.help_outline_rounded),
        color: Colors.white,
      ),
      footer: KeyedSubtree(
        key: summaryKey,
        child: _PsychologistSummaryFooter(
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
              onTap: () =>
                  context.push(QuestionnaireRoutes.psychologistCatalog),
            ),
          ],
        ),
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

// ---------------------------------------------------------------------------
// Header Cúpula — design com gradiente teal centrado e onda na base
// ---------------------------------------------------------------------------

class _CupolaHeader extends StatelessWidget {
  const _CupolaHeader({
    required this.profile,
    required this.name,
    required this.areaLabel,
    required this.contextLine,
    required this.onProfileTap,
    required this.trailingAction,
    this.footer,
  });

  final UserProfile profile;
  final String name;
  final String areaLabel;
  final String contextLine;
  final VoidCallback? onProfileTap;
  final Widget? trailingAction;
  final Widget? footer;

  static String _greeting(int h) =>
      h < 12 ? 'Bom dia' : h < 18 ? 'Boa tarde' : 'Boa noite';
  static String _timeAsset(int h) => h < 12
      ? 'assets/greeting/sunrise.svg'
      : h < 18
          ? 'assets/greeting/sun.svg'
          : 'assets/greeting/moon.svg';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final hour = DateTime.now().hour;
    final scaffoldBg = theme.colorScheme.surfaceContainerLow;

    final gradientBody = Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0A4A6E), Color(0xFF007A73), Color(0xFF00B2A9)],
          stops: [0.0, 0.5, 1.0],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Marca-d'água
          Positioned(
            right: -8,
            top: topInset + 48,
            child: Icon(
              Icons.psychology_alt_outlined,
              size: 110,
              color: Colors.white.withValues(alpha: 0.07),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              topInset + AppSpacing.xs,
              AppSpacing.xl,
              footer != null ? 68 : AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // App bar row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Marca à esquerda: flexível para ceder espaço ao grupo da
                    // direita em telas estreitas, em vez de estourar a Row.
                    Expanded(
                      child: Row(
                        children: [
                          const BrandBrainMark(size: 20, color: Colors.white),
                          const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'EsquemaCore',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
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
                            areaLabel,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white.withValues(alpha: 0.95),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        if (trailingAction != null) ...[
                          const SizedBox(width: AppSpacing.xs),
                          trailingAction!,
                        ],
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: AppSpacing.md),

                // Avatar centralizado com anel
                GestureDetector(
                  onTap: onProfileTap,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.5),
                        width: 2.5,
                      ),
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                    child: UserAvatar(profile: profile, size: 68),
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Saudação
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SvgPicture.asset(_timeAsset(hour), width: 16, height: 16),
                    const SizedBox(width: 5),
                    Text(
                      _greeting(hour).toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.92),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                // Nome
                Text(
                  name,
                  style: theme.textTheme.headlineLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    height: 1.05,
                  ),
                ),

                const SizedBox(height: AppSpacing.xs),

                // Linha de contexto
                Text(
                  contextLine,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.white.withValues(alpha: 0.95),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),

          // Onda na base — pinta a cor de fundo sobre o gradiente
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 64,
              child: CustomPaint(
                painter: _CupolaPainter(color: scaffoldBg),
              ),
            ),
          ),
        ],
      ),
    );

    if (footer == null) return gradientBody;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        gradientBody,
        Transform.translate(
          offset: const Offset(0, -12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: footer,
          ),
        ),
      ],
    );
  }
}

class _CupolaPainter extends CustomPainter {
  const _CupolaPainter({required this.color});
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path()
      ..moveTo(0, size.height)
      ..lineTo(0, size.height * 0.46)
      ..quadraticBezierTo(
        size.width * 0.25, 0,
        size.width * 0.5, size.height * 0.35,
      )
      ..quadraticBezierTo(
        size.width * 0.75, size.height * 0.69,
        size.width, size.height * 0.23,
      )
      ..lineTo(size.width, size.height)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CupolaPainter old) => old.color != color;
}

// ---------------------------------------------------------------------------
// Footer unificado do psicólogo: stats + faixa semanal num único ClayCard
// ---------------------------------------------------------------------------

/// Stats (Pacientes / Convites / Questionários) e faixa semanal num único
/// ClayCard que flutua sobre o canopy via Transform.translate do
/// AppCanopyHeader. Unificados para não haver gap visual entre os dois blocos.
class _PsychologistSummaryFooter extends ConsumerWidget {
  const _PsychologistSummaryFooter({required this.metrics});

  final List<_WorkspaceMetric> metrics;

  // Iniciais em português: S=Segunda, T=Terça, Q=Quarta, Q=Quinta,
  // S=Sexta, S=Sábado, D=Domingo (segunda-feira é dia 1 no Dart)
  static const _labels = ['S', 'T', 'Q', 'Q', 'S', 'S', 'D'];

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static Color _alertColor(PsychologistAlertKind kind) {
    switch (kind) {
      case PsychologistAlertKind.expiringInvitation:
        return AppColors.error;
      case PsychologistAlertKind.staleQuestionnaire:
        return AppColors.warning;
      case PsychologistAlertKind.missingCheckin:
        return AppColors.info;
      case PsychologistAlertKind.pendingResultsRelease:
        return AppColors.success;
    }
  }

  /// Mapeia alertas para o índice do dia na semana atual (0=seg…6=dom).
  /// expiringInvitation usa daysCount para apontar o dia exato de expiração;
  /// os demais ficam no dia de hoje.
  static List<List<Color>> _buildDots(
    List<PsychologistAlert> alerts,
    DateTime now,
    List<DateTime> days,
  ) {
    // Por dia: set de cores (sem duplicatas de cor) — máx 3 dots.
    final dotsPerDay = List.generate(7, (_) => <Color>{});

    for (final alert in alerts) {
      final color = _alertColor(alert.kind);
      DateTime target;
      if (alert.kind == PsychologistAlertKind.expiringInvitation) {
        target = DateTime(now.year, now.month, now.day)
            .add(Duration(days: alert.daysCount));
      } else {
        target = now;
      }
      for (var i = 0; i < days.length; i++) {
        if (_sameDay(days[i], target)) {
          dotsPerDay[i].add(color);
          break;
        }
      }
    }

    return dotsPerDay.map((s) => s.take(3).toList()).toList();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final days = List.generate(7, (i) => startOfWeek.add(Duration(days: i)));

    final alerts = ref.watch(psychologistAlertsProvider).valueOrNull ?? [];
    final dots = _buildDots(alerts, now, days);

    return ClayCard(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Linha de stats
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                for (var i = 0; i < metrics.length; i++) ...[
                  if (i > 0)
                    Container(width: 1, height: 56, color: Theme.of(context).colorScheme.outline),
                  Expanded(child: _WorkspaceMetricCell(metric: metrics[i])),
                ],
              ],
            ),
          ),
          // Divisória
          Divider(height: 1, thickness: 0.5, color: Theme.of(context).colorScheme.outline),
          // Faixa semanal
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                for (var i = 0; i < 7; i++)
                  _DayCell(
                    label: _labels[i],
                    day: days[i],
                    isToday: _sameDay(days[i], now),
                    dots: dots[i],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.label,
    required this.day,
    required this.isToday,
    this.dots = const [],
  });

  final String label;
  final DateTime day;
  final bool isToday;
  final List<Color> dots;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: 36,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? theme.colorScheme.primaryContainer : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: isToday ? Colors.white60 : theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 10,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${day.day}',
            style: theme.textTheme.titleSmall?.copyWith(
              color: isToday ? Colors.white : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 5),
          SizedBox(
            height: 6,
            child: dots.isEmpty
                ? const SizedBox.shrink()
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (var i = 0; i < dots.length; i++) ...[
                        if (i > 0) const SizedBox(width: 2),
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            color: isToday
                                ? dots[i].withValues(alpha: 0.9)
                                : dots[i],
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}
