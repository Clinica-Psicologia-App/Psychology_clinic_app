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
                      child: _QuestionnairesHeader(
                        role: widget.role,
                        staffPatientHeader: staffPatientHeader,
                        availableCount: items.length,
                      ),
                    );
                  }

                  if (index == 1) {
                    return const Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AppSectionHeader(
                        title: 'Instrumentos disponíveis',
                        subtitle:
                            'Abra um questionário para revisar orientações e iniciar a resposta.',
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
                      enabled: canApply,
                      showStaffDetails: widget.role != ProfileRole.patient,
                      patientStatus: statusMap[q.id],
                      onTap: canApply
                          ? () => _onQuestionnaireTap(q, patientId)
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
