import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../personality_reference/presentation/personality_reference_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/personality_assessment.dart';
import '../providers/personality_assessment_providers.dart';
import 'personality_assessment_routes.dart';

/// Lista de avaliações de personalidade do paciente (camada terapeuta).
class PersonalityAssessmentListPage extends ConsumerWidget {
  const PersonalityAssessmentListPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(personalityAssessmentsProvider(patientId));
    return AppScaffold(
      title: 'Personalidade',
      accent: AppColors.purple,
      actions: [
        IconButton(
          tooltip: 'O que significa cada fator?',
          onPressed: () => context.push(
            PersonalityReferenceRoutes.staffList(
              role: role,
              patientId: patientId,
            ),
          ),
          icon: const Icon(Icons.menu_book_outlined),
        ),
      ],
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.purple,
        foregroundColor: Colors.white,
        onPressed: () async {
          await context.push(
            PersonalityAssessmentRoutes.staffNew(
              role: role,
              patientId: patientId,
            ),
          );
          ref.invalidate(personalityAssessmentsProvider(patientId));
        },
        icon: const Icon(Icons.add),
        label: const Text('Registrar avaliação'),
      ),
      body: AsyncStateBody<List<PersonalityAssessment>>(
        asyncValue: async,
        onRetry: () => ref.invalidate(personalityAssessmentsProvider(patientId)),
        emptyIcon: Icons.psychology_alt_outlined,
        emptyMessage: 'Nenhuma avaliação de personalidade registrada.',
        dataBuilder: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
          children: [
            _intro(context),
            const SizedBox(height: 12),
            for (final a in list)
              _AssessmentTile(
                assessment: a,
                onTap: () async {
                  await context.push(
                    PersonalityAssessmentRoutes.staffDetail(
                      role: role,
                      patientId: patientId,
                      assessmentId: a.id,
                    ),
                  );
                  ref.invalidate(personalityAssessmentsProvider(patientId));
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _intro(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Registre aqui os resultados de instrumentos já aplicados e '
              'corrigidos (ex.: NEO PI-R). O app organiza os dados informados '
              'por você — não aplica nem corrige o teste.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AssessmentTile extends StatelessWidget {
  const _AssessmentTile({required this.assessment, required this.onTap});

  final PersonalityAssessment assessment;
  final VoidCallback onTap;

  String _dateLabel(DateTime? d) {
    if (d == null) return 'Data não informada';
    String two(int x) => x.toString().padLeft(2, '0');
    return 'Aplicado em ${two(d.day)}/${two(d.month)}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final validity = assessment.protocolValidity;
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 40,
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.purple.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.psychology_alt_outlined,
              color: AppColors.purple),
        ),
        title: Text(
          assessment.instrumentDef.name,
          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 2),
            Text(_dateLabel(assessment.appliedOn),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: AppColors.textMuted)),
            if (validity != null) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: (validity == ProtocolValidity.appropriate
                          ? AppColors.success
                          : validity == ProtocolValidity.caution
                              ? AppColors.warning
                              : AppColors.error)
                      .withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  validity.label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: validity == ProtocolValidity.appropriate
                        ? AppColors.success
                        : validity == ProtocolValidity.caution
                            ? AppColors.warning
                            : AppColors.error,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }
}
