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
import '../../patients/presentation/patient_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/questionnaire.dart';
import '../providers/questionnaires_providers.dart';
import 'widgets/questionnaire_list_tile.dart';

class PsychologistQuestionnairesPage extends ConsumerWidget {
  const PsychologistQuestionnairesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(psychologistQuestionnairesProvider);

    return AppScaffold(
      title: 'Meus questionários',
      accent: AppColors.blue,
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(psychologistQuestionnairesProvider),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<Questionnaire>>(
        asyncValue: listAsync,
        onRetry: () => ref.invalidate(psychologistQuestionnairesProvider),
        emptyMessage:
            'Nenhum questionário liberado para você no momento.\nSolicite ao administrador a liberação dos instrumentos.',
        emptyIcon: Icons.assignment_late_outlined,
        dataBuilder: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(psychologistQuestionnairesProvider);
            await ref.read(psychologistQuestionnairesProvider.future);
          },
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
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
                  child: AppPageHeader(
                    icon: Icons.assignment_outlined,
                    title: 'Meus questionários',
                    subtitle:
                        'Instrumentos liberados pelo administrador para sua prática clínica. Para aplicar, escolha um paciente da sua carteira.',
                    metadata: [
                      Chip(label: Text('${items.length} liberado(s)')),
                    ],
                    primaryAction: FilledButton.icon(
                      onPressed: () => context.push(
                        PatientRoutes.list(ProfileRole.psychologist),
                      ),
                      icon: const Icon(Icons.people_outline),
                      label: const Text('Escolher paciente'),
                    ),
                  ),
                );
              }

              if (index == 1) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AppSectionHeader(
                    title: 'Catálogo disponível',
                    subtitle:
                        'A disponibilidade para o paciente segue esta lista e a relação clínica com você.',
                  ),
                );
              }

              final questionnaire = items[index - 2];
              final canApply = questionnaire.canStart(
                allowUnvalidated: EnvConfig.allowsUnvalidatedInstruments,
              );
              return MotionReveal(
                delay: staggerDelay(index - 2),
                child: QuestionnaireListTile(
                  questionnaire: questionnaire,
                  enabled: canApply,
                  showStaffDetails: true,
                  onTap: () => context.push(
                    PatientRoutes.list(ProfileRole.psychologist),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
