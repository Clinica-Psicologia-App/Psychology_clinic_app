import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env_config.dart';
import '../../../shared/widgets/app_motion.dart';
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

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (widget.role != ProfileRole.patient &&
                  staffPatientHeader != null)
                staffPatientHeader.when(
                  data: (p) => p != null
                      ? Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: Text(
                            p.fullName,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        )
                      : const SizedBox.shrink(),
                  loading: () => const Padding(
                    padding: EdgeInsets.all(16),
                    child: LinearProgressIndicator(),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              if (widget.role == ProfileRole.patient)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    'Selecione um instrumento para responder.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              Expanded(
                child: AsyncStateBody<List<Questionnaire>>(
                  asyncValue: listAsync,
                  onRetry: () =>
                      ref.invalidate(questionnairesListProvider(_listContext)),
                  emptyMessage: 'Nenhum questionário disponível no momento.',
                  emptyIcon: Icons.assignment_outlined,
                  dataBuilder: (items) => RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(questionnairesListProvider(_listContext));
                      ref.invalidate(
                          questionnairePatientStatusProvider(patientId));
                      await ref.read(
                        questionnairesListProvider(_listContext).future,
                      );
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final q = items[index];
                        final canApply = q.canStart(
                          allowUnvalidated:
                              EnvConfig.allowsUnvalidatedInstruments,
                        );
                        return MotionReveal(
                          delay: staggerDelay(index),
                          child: QuestionnaireListTile(
                            questionnaire: q,
                            enabled: canApply,
                            showStaffDetails:
                                widget.role != ProfileRole.patient,
                            patientStatus: statusMap[q.id],
                            onTap: canApply
                                ? () => _onQuestionnaireTap(q, patientId)
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
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
