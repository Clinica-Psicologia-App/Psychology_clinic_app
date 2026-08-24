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
import '../../clinical_dashboard/domain/clinical_dashboard_data.dart';
import '../../clinical_dashboard/presentation/widgets/clinical_dashboard_widgets.dart';
import '../../clinical_dashboard/providers/clinical_dashboard_providers.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/questionnaire.dart';
import '../providers/questionnaires_providers.dart';
import 'questionnaire_route_helpers.dart';
import 'questionnaire_routes.dart';
import 'widgets/questionnaire_list_tile.dart';

class QuestionnairesPage extends ConsumerStatefulWidget {
  const QuestionnairesPage({
    super.key,
    required this.role,
    this.patientId,
  });

  final ProfileRole role;
  final String? patientId;

  @override
  ConsumerState<QuestionnairesPage> createState() => _QuestionnairesPageState();
}

class _QuestionnairesPageState extends ConsumerState<QuestionnairesPage> {
  String? _resolvedPatientId;

  QuestionnaireListContext get _listContext => QuestionnaireListContext(
        role: widget.role,
        patientId: widget.patientId,
      );

  @override
  Widget build(BuildContext context) {
    final patientIdAsync =
        ref.watch(questionnairePatientIdProvider(_listContext));
    final listAsync = ref.watch(questionnairesListProvider(_listContext));

    final title = widget.role == ProfileRole.patient
        ? 'Questionários'
        : 'Questionários do paciente';

    return AppScaffold(
      title: title,
      accent: AppColors.blue,
      body: patientIdAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Não foi possível identificar o paciente.'),
          ),
        ),
        data: (patientId) {
          _resolvedPatientId = patientId;

          final statusMap = ref
                  .watch(questionnairePatientStatusProvider(patientId))
                  .valueOrNull ??
              {};

          final isStaff = widget.role != ProfileRole.patient;
          final releasedIds = isStaff
              ? (ref
                      .watch(patientAssignmentIdsProvider(patientId))
                      .valueOrNull ??
                  const <String>{})
              : const <String>{};

          final staffPatientHeader = widget.patientId != null
              ? ref.watch(patientDetailProvider(patientId))
              : null;

          return AsyncStateBody<List<Questionnaire>>(
            asyncValue: listAsync,
            onRetry: () =>
                ref.invalidate(questionnairesListProvider(_listContext)),
            emptyMessage: 'Nenhum questionário disponível no momento.',
            emptyIcon: Icons.assignment_outlined,
            dataBuilder: (items) => RefreshIndicator(
              onRefresh: () async {
                ref.invalidate(questionnairesListProvider(_listContext));
                ref.invalidate(questionnairePatientStatusProvider(patientId));
                await ref.read(
                  questionnairesListProvider(_listContext).future,
                );
              },
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xxxl,
                ),
                itemCount: items.length + 2,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _QuestionnairesHeader(
                            role: widget.role,
                            staffPatientHeader: staffPatientHeader,
                            availableCount: items.length,
                          ),
                          if (isStaff) ...[
                            const SizedBox(height: AppSpacing.lg),
                            _ConsolidatedDashboardBlock(
                              role: widget.role,
                              patientId: patientId,
                            ),
                          ],
                        ],
                      ),
                    );
                  }

                  if (index == 1) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppSectionHeader(
                        title: isStaff
                            ? 'Esquemas do paciente'
                            : 'Instrumentos disponíveis',
                        subtitle: isStaff
                            ? 'Toque em um esquema para ver o dashboard individual. Use "Liberar" para o paciente poder responder.'
                            : 'Abra um questionário para revisar orientações e iniciar a resposta.',
                      ),
                    );
                  }

                  final q = items[index - 2];
                  final canApply = q.canStart(
                    allowUnvalidated: EnvConfig.allowsUnvalidatedInstruments,
                  );
                  return MotionReveal(
                    delay: staggerDelay(index - 2),
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
            ),
          );
        },
      ),
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

/// Panorama consolidado (visão do psicólogo) no topo da tela de esquemas —
/// o conteúdo que antes vivia na dashboard clínica isolada.
class _ConsolidatedDashboardBlock extends ConsumerWidget {
  const _ConsolidatedDashboardBlock({
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx =
        StaffClinicalDashboardContext(role: role, patientId: patientId);
    final async = ref.watch(staffClinicalDashboardProvider(ctx));

    return async.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: LinearProgressIndicator(),
      ),
      error: (_, __) => const SizedBox.shrink(),
      data: (ClinicalDashboardData data) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const AppSectionHeader(
              title: 'Panorama clínico',
              subtitle:
                  'Visão consolidada dos esquemas e sinais recentes deste paciente.',
            ),
            const SizedBox(height: AppSpacing.sm),
            ClinicalExecutiveHeader(summary: data.caseSummary),
            ClinicalRecentSignalsCard(summary: data.caseSummary),
            if (data.hasConsolidatedSchemas)
              ConsolidatedSchemaProfileCard(
                data: data,
                isStaff: true,
                onActivationChanged: () =>
                    ref.invalidate(staffClinicalDashboardProvider(ctx)),
              ),
          ],
        );
      },
    );
  }
}

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
