import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../clinical_dashboard/presentation/widgets/clinical_dashboard_widgets.dart';
import '../../clinical_dashboard/providers/clinical_dashboard_providers.dart';
import '../../coach/domain/coach_step.dart';
import '../../coach/domain/coach_tour.dart';
import '../../coach/providers/coach_providers.dart';
import '../../patients/domain/patient.dart';
import '../../patients/presentation/widgets/results_release_card.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../../profile/presentation/widgets/user_avatar.dart';
import '../../results/presentation/result_routes.dart';
import '../domain/questionnaire.dart';
import '../providers/questionnaires_providers.dart';
import 'questionnaire_route_helpers.dart';
import 'questionnaire_routes.dart';
import 'widgets/questionnaire_list_tile.dart';
import '../../../shared/widgets/brand_loading.dart';

class QuestionnairesPage extends ConsumerStatefulWidget {
  const QuestionnairesPage({
    super.key,
    required this.role,
    this.patientId,
    this.attachmentOnly = false,
  });

  final ProfileRole role;
  final String? patientId;

  /// `true` → mostra só instrumentos de apego; `false` → exclui apego (esquemas YP/YSQ etc.).
  final bool attachmentOnly;

  @override
  ConsumerState<QuestionnairesPage> createState() => _QuestionnairesPageState();
}

class _QuestionnairesPageState extends ConsumerState<QuestionnairesPage> {
  String? _resolvedPatientId;
  final _tabBarKey = GlobalKey();
  bool _tourRequested = false;

  QuestionnaireListContext get _listContext => QuestionnaireListContext(
        role: widget.role,
        patientId: widget.patientId,
      );

  CoachTour _esquemasTour() => CoachTour(
        id: 'tour_esquemas_paciente',
        steps: [
          CoachStep(
            id: 'abas',
            text:
                'Esta é a central clínica do paciente, organizada em três abas.',
            pose: MascotPose.wave,
            targetKey: _tabBarKey,
          ),
          const CoachStep(
            id: 'o-que-tem',
            text:
                'Panorama traz a visão geral; Esquemas, os instrumentos; Histórico, as aplicações concluídas.',
            pose: MascotPose.point,
          ),
          const CoachStep(
            id: 'liberar-dashboard',
            text:
                'Na aba Esquemas você libera um instrumento para o paciente e toca nele para ver o dashboard individual. Bom trabalho!',
            pose: MascotPose.celebrate,
          ),
        ],
      );

  Future<void> _startTour({bool force = false}) async {
    if (!mounted) return;
    await ref
        .read(coachControllerProvider.notifier)
        .startTour(context, _esquemasTour(), force: force);
  }

  @override
  Widget build(BuildContext context) {
    final patientIdAsync =
        ref.watch(questionnairePatientIdProvider(_listContext));

    final title = widget.role == ProfileRole.patient
        ? 'Questionários'
        : widget.attachmentOnly
            ? 'Apego'
            : 'Esquemas';

    // Paciente usa AppScaffold simples; psicólogo usa AppCanopyScaffold com
    // header teal imersivo.
    if (widget.role == ProfileRole.patient) {
      return AppScaffold(
        title: title,
        accent: AppColors.blue,
        body: patientIdAsync.when(
          loading: () => const BrandLoader(),
          error: (e, _) => const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text('Não foi possível identificar o paciente.'),
            ),
          ),
          data: (patientId) {
            _resolvedPatientId = patientId;
            return _buildInstrumentsList(patientId, includeHeader: true);
          },
        ),
      );
    }

    return AppCanopyScaffold(
      body: patientIdAsync.when(
        loading: () => const BrandLoader(),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Não foi possível identificar o paciente.'),
          ),
        ),
        data: (patientId) {
          _resolvedPatientId = patientId;
          if (!_tourRequested) {
            _tourRequested = true;
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _startTour());
          }
          return widget.attachmentOnly
              ? _buildAttachmentView(patientId)
              : _buildStaffTabs(patientId);
        },
      ),
    );
  }

  // ── Visão do psicólogo: modo Apego (sem abas, só lista filtrada) ─────────
  Widget _buildAttachmentView(String patientId) {
    final patientAsync = ref.watch(patientDetailProvider(patientId));
    return Column(
      children: [
        _QuestionnairesHeroHeader(
          patientAsync: patientAsync,
          onBack: () => context.pop(),
          onTourTap: () {},
        ),
        Expanded(
          child: _buildInstrumentsList(patientId, includeHeader: false),
        ),
      ],
    );
  }

  // ── Visão do psicólogo: abas Panorama · Esquemas · Histórico ──────────────
  Widget _buildStaffTabs(String patientId) {
    final patientAsync = ref.watch(patientDetailProvider(patientId));

    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          _QuestionnairesHeroHeader(
            patientAsync: patientAsync,
            onBack: () => context.pop(),
            onTourTap: () => _startTour(force: true),
          ),
          Material(
            key: _tabBarKey,
            color: Theme.of(context).colorScheme.surface,
            child: const TabBar(
              tabs: [
                Tab(text: 'Panorama'),
                Tab(text: 'Esquemas'),
                Tab(text: 'Histórico'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildPanorama(patientId),
                _buildInstrumentsList(patientId, includeHeader: false),
                _buildHistorico(patientId),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Panorama = a antiga dashboard clínica consolidada + liberação de resultados.
  Widget _buildPanorama(String patientId) {
    final ctx =
        StaffClinicalDashboardContext(role: widget.role, patientId: patientId);
    final async = ref.watch(staffClinicalDashboardProvider(ctx));
    return async.when(
      loading: () => const BrandLoader(),
      error: (e, _) =>
          _dashError(() => ref.invalidate(staffClinicalDashboardProvider(ctx))),
      data: (data) {
        final sections = <Widget>[
          PendingResultsReleaseBanner(
            patientId: patientId,
            structuredResultCount: data.caseSummary.structuredResultCount,
          ),
          ClinicalExecutiveHeader(summary: data.caseSummary),
          ClinicalDashboardCalloutsSection(callouts: data.callouts),
          ClinicalPriorityGrid(summary: data.caseSummary),
          ClinicalRecentSignalsCard(summary: data.caseSummary),
          if (data.hasConsolidatedSchemas)
            ConsolidatedSchemaProfileCard(
              data: data,
              isStaff: true,
              onActivationChanged: () =>
                  ref.invalidate(staffClinicalDashboardProvider(ctx)),
            ),
          ResultsReleaseCard(patientId: patientId),
        ];
        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(staffClinicalDashboardProvider(ctx)),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
            itemCount: sections.length,
            itemBuilder: (context, i) => MotionReveal(
              delay: staggerDelay(i),
              child: sections[i],
            ),
          ),
        );
      },
    );
  }

  // Histórico = as últimas aplicações estruturadas concluídas.
  Widget _buildHistorico(String patientId) {
    final ctx =
        StaffClinicalDashboardContext(role: widget.role, patientId: patientId);
    final async = ref.watch(staffClinicalDashboardProvider(ctx));
    final loc = MaterialLocalizations.of(context);
    return async.when(
      loading: () => const BrandLoader(),
      error: (e, _) =>
          _dashError(() => ref.invalidate(staffClinicalDashboardProvider(ctx))),
      data: (data) => ListView(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
        children: [
          ClinicalDashboardHistoryCard(
            historyTiles: data.history.map((entry) {
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  entry.hasResults
                      ? Icons.check_circle_outline
                      : Icons.hourglass_empty,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(entry.questionnaireName),
                subtitle: Text([
                  entry.questionnaireCode,
                  if (entry.completedAt != null)
                    loc.formatFullDate(entry.completedAt!.toLocal()),
                  entry.hasResults ? 'Com resultados' : 'Sem resultados',
                ].join(' · ')),
                trailing: IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Ver resposta',
                  onPressed: () => context.push(
                    ResultRoutes.detail(
                      role: widget.role,
                      patientId: patientId,
                      responseId: entry.responseId,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _dashError(VoidCallback onRetry) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Não foi possível carregar o painel.'),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                  onPressed: onRetry, child: const Text('Tentar de novo')),
            ],
          ),
        ),
      );

  // ── Lista de instrumentos (esquemas) — paciente ou aba "Esquemas" ─────────
  Widget _buildInstrumentsList(String patientId,
      {required bool includeHeader}) {
    final listAsync = ref.watch(questionnairesListProvider(_listContext));
    final statusMap = ref
            .watch(questionnairePatientStatusProvider(patientId))
            .valueOrNull ??
        {};
    final isStaff = widget.role != ProfileRole.patient;
    final releasedIds = isStaff
        ? (ref.watch(patientAssignmentIdsProvider(patientId)).valueOrNull ??
            const <String>{})
        : const <String>{};
    final staffPatientHeader = widget.patientId != null
        ? ref.watch(patientDetailProvider(patientId))
        : null;

    return AsyncStateBody<List<Questionnaire>>(
      asyncValue: listAsync,
      onRetry: () => ref.invalidate(questionnairesListProvider(_listContext)),
      emptyMessage: isStaff
          ? 'Nenhum instrumento habilitado para você.'
          : 'Nenhum questionário disponível no momento.',
      emptyIcon: Icons.assignment_outlined,
      dataBuilder: (allItems) {
        final items = widget.attachmentOnly
            ? allItems.where((q) => q.isAttachmentStyles).toList()
            : allItems.where((q) => !q.isAttachmentStyles).toList();
        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(questionnairesListProvider(_listContext));
            ref.invalidate(questionnairePatientStatusProvider(patientId));
            if (isStaff) ref.invalidate(patientAssignmentIdsProvider(patientId));
            await ref.read(questionnairesListProvider(_listContext).future);
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xxxl),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                if (!isStaff && includeHeader) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                    child: _QuestionnairesHeader(
                      role: widget.role,
                      staffPatientHeader: staffPatientHeader,
                      availableCount: items.length,
                    ),
                  );
                }
                return const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppSectionHeader(
                    title: 'Esquemas do paciente',
                    subtitle:
                        'Toque em um esquema para ver o dashboard individual. Use "Liberar" para o paciente poder responder.',
                  ),
                );
              }

              final q = items[index - 1];
              final canApply = q.canStart(
                allowUnvalidated: EnvConfig.allowsUnvalidatedInstruments,
              );
              return MotionReveal(
                delay: staggerDelay(index - 1),
                child: QuestionnaireListTile(
                  questionnaire: q,
                  enabled: isStaff || canApply,
                  showStaffDetails: isStaff,
                  patientStatus: statusMap[q.id],
                  onTap: (isStaff || canApply)
                      ? () => _onQuestionnaireTap(q, patientId)
                      : null,
                  footer: isStaff
                      ? _ReleaseToggle(
                          patientId: patientId,
                          questionnaireId: q.id,
                          released: releasedIds.contains(q.id),
                        )
                      : null,
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _onQuestionnaireTap(
      Questionnaire questionnaire, String patientId) async {
    // Psicólogo: clicar abre o dashboard individual do instrumento (de onde
    // ele também aplica). Paciente: abre a introdução para responder.
    if (widget.role != ProfileRole.patient) {
      await context.push(
        QuestionnaireRoutes.instrumentDashboard(
          role: widget.role,
          patientId: widget.patientId ?? _resolvedPatientId,
        ),
        extra: questionnaire,
      );
      if (mounted) {
        ref.invalidate(questionnairePatientStatusProvider(patientId));
        ref.invalidate(patientAssignmentIdsProvider(patientId));
      }
      return;
    }

    await context.push(
      QuestionnaireRoutes.intro(
        role: widget.role,
        patientId: widget.patientId ?? _resolvedPatientId,
      ),
      extra: QuestionnaireIntroArgs(
        questionnaire: questionnaire,
        patientId: patientId,
      ),
    );

    if (mounted) {
      ref.invalidate(questionnairePatientStatusProvider(patientId));
    }
  }
}

/// Controle de liberação por paciente (visão do psicólogo): libera/revoga a
/// atribuição do questionário. Só o que estiver "Liberado" aparece para o
/// paciente responder.
class _ReleaseToggle extends ConsumerStatefulWidget {
  const _ReleaseToggle({
    required this.patientId,
    required this.questionnaireId,
    required this.released,
  });

  final String patientId;
  final String questionnaireId;
  final bool released;

  @override
  ConsumerState<_ReleaseToggle> createState() => _ReleaseToggleState();
}

class _ReleaseToggleState extends ConsumerState<_ReleaseToggle> {
  bool _busy = false;

  Future<void> _toggle() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(assignQuestionnaireProvider.notifier).setReleased(
            patientId: widget.patientId,
            questionnaireId: widget.questionnaireId,
            released: !widget.released,
          );
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final spinner = const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: widget.released
          ? FilledButton.tonalIcon(
              onPressed: _busy ? null : _toggle,
              icon: _busy
                  ? spinner
                  : const Icon(Icons.check_circle, size: 18),
              label: const Text('Liberado'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.successContainer,
                foregroundColor: AppColors.onSuccessContainer,
                visualDensity: VisualDensity.compact,
              ),
            )
          : OutlinedButton.icon(
              onPressed: _busy ? null : _toggle,
              icon: _busy ? spinner : const Icon(Icons.add, size: 18),
              label: const Text('Liberar'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.blue,
                visualDensity: VisualDensity.compact,
              ),
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header teal imersivo — visão do psicólogo
// ---------------------------------------------------------------------------

class _QuestionnairesHeroHeader extends StatelessWidget {
  const _QuestionnairesHeroHeader({
    required this.patientAsync,
    required this.onBack,
    required this.onTourTap,
  });

  final AsyncValue<Patient?> patientAsync;
  final VoidCallback onBack;
  final VoidCallback onTourTap;

  static String _initialsOf(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts.last.substring(0, 1)).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;
    final surfaceBg = theme.colorScheme.surfaceContainerLow;

    final patient = patientAsync.valueOrNull;

    return Container(
      width: double.infinity,
      color: const Color(0xFF0A4A6E),
      child: Stack(
        children: [
          // Luz radial teal — canto superior direito
          Positioned(
            right: -20,
            top: -10,
            child: Container(
              width: 180,
              height: 180,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x4400B2A9), Colors.transparent],
                ),
              ),
            ),
          ),
          // Luz radial indigo — canto inferior esquerdo
          Positioned(
            left: -30,
            bottom: 20,
            child: Container(
              width: 140,
              height: 140,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [Color(0x333D3F8F), Colors.transparent],
                ),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(0, topInset, 0, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Nav row
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.sm, AppSpacing.xs, AppSpacing.sm, 0),
                  child: Row(
                    children: [
                      _HdrBtn(icon: Icons.arrow_back_ios_new_rounded, onTap: onBack),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          'QUESTIONÁRIOS',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      _HdrBtn(icon: Icons.help_outline_rounded, onTap: onTourTap),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.sm),

                // Patient row
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
                  child: patientAsync.isLoading
                      ? const SizedBox(height: 52)
                      : Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            if (patient != null) ...[
                              Container(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.25),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: UserAvatar.parts(
                                  fullName: patient.fullName,
                                  initials: _initialsOf(patient.fullName),
                                  role: ProfileRole.patient,
                                  avatarType: patient.avatarType,
                                  photoUrl: patient.photoUrl,
                                  avatarConfig: patient.avatarConfig,
                                  size: 52,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              const SizedBox(width: AppSpacing.md),
                            ],
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    patient != null ? 'PACIENTE' : 'QUESTIONÁRIOS DO PACIENTE',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: const Color(0xFF00D4C9),
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.0,
                                      fontSize: 9,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    patient?.fullName ?? 'Carregando...',
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      height: 1.1,
                                      letterSpacing: -0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (patient != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: patient.isActive
                                      ? const Color(0x401A9B6C)
                                      : Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: patient.isActive
                                        ? const Color(0x601A9B6C)
                                        : Colors.white.withValues(alpha: 0.15),
                                  ),
                                ),
                                child: Text(
                                  patient.isActive ? '✓ Ativo' : 'Inativo',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: patient.isActive
                                        ? const Color(0xFF4DEBB5)
                                        : Colors.white.withValues(alpha: 0.7),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),

                // Onda na base
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: surfaceBg,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(16),
                    ),
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

class _HdrBtn extends StatelessWidget {
  const _HdrBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 34, height: 34,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: Colors.white, size: 16),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header da visão do paciente (inalterado)
// ---------------------------------------------------------------------------

class _QuestionnairesHeader extends StatelessWidget {
  const _QuestionnairesHeader({
    required this.role,
    required this.staffPatientHeader,
    required this.availableCount,
  });

  final ProfileRole role;
  final AsyncValue<dynamic>? staffPatientHeader;
  final int availableCount;

  @override
  Widget build(BuildContext context) {
    if (role == ProfileRole.patient) {
      return AppPageHeader(
        title: 'Questionários',
        subtitle:
            'Instrumentos liberados pelo profissional para apoiar a avaliação e o acompanhamento clínico.',
        icon: Icons.assignment_outlined,
        metadata: [
          Chip(label: Text('$availableCount disponíveis')),
        ],
      );
    }

    if (staffPatientHeader == null) {
      return AppPageHeader(
        title: 'Questionários do paciente',
        subtitle:
            'Acompanhe instrumentos disponíveis, status de resposta e detalhes de aplicação.',
        icon: Icons.assignment_outlined,
        metadata: [
          Chip(label: Text('$availableCount instrumentos')),
        ],
      );
    }

    return staffPatientHeader!.when(
      data: (patient) => AppPageHeader(
        title: 'Questionários do paciente',
        subtitle: patient != null
            ? 'Instrumentos disponíveis para ${patient.fullName}.'
            : 'Instrumentos disponíveis para este paciente.',
        icon: Icons.assignment_outlined,
        metadata: [
          Chip(label: Text('$availableCount instrumentos')),
        ],
      ),
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => AppPageHeader(
        title: 'Questionários do paciente',
        subtitle:
            'Acompanhe instrumentos disponíveis, status de resposta e detalhes de aplicação.',
        icon: Icons.assignment_outlined,
        metadata: [
          Chip(label: Text('$availableCount instrumentos')),
        ],
      ),
    );
  }
}
