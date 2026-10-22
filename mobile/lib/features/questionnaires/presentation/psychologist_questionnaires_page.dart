import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env_config.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../patients/presentation/patient_routes.dart';
import '../../patients/presentation/widgets/staff_section_header.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/questionnaires_providers.dart';
import 'widgets/questionnaire_list_tile.dart';

class PsychologistQuestionnairesPage extends ConsumerWidget {
  const PsychologistQuestionnairesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(psychologistQuestionnairesProvider);
    final items = listAsync.valueOrNull;

    final stats = items != null
        ? [
            StaffSectionStat(
              value: '${items.length}',
              label: 'Instrumentos',
              accent: const Color(0xFF00D4C9),
            ),
          ]
        : null;

    return AppCanopyScaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(psychologistQuestionnairesProvider);
          await ref.read(psychologistQuestionnairesProvider.future);
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header ───────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: StaffSectionHeader(
                navTitle: 'Meus questionários',
                eyebrow: 'INSTRUMENTOS CLÍNICOS',
                headline: Builder(
                  builder: (ctx) {
                    final theme = Theme.of(ctx);
                    return RichText(
                      text: TextSpan(
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        children: const [
                          TextSpan(
                            text: 'Meus',
                            style: TextStyle(color: Color(0xFF00D4C9)),
                          ),
                          TextSpan(text: '\nquestionários'),
                        ],
                      ),
                    );
                  },
                ),
                onBack: () => context.pop(),
                onRefresh: () =>
                    ref.invalidate(psychologistQuestionnairesProvider),
                stats: stats,
              ),
            ),

            // ── Loading ───────────────────────────────────────────────────
            if (listAsync.isLoading)
              const SliverFillRemaining(
                child: Center(child: BrandLoader()),
              )
            // ── Error ─────────────────────────────────────────────────────
            else if (listAsync.hasError)
              SliverFillRemaining(
                child: ErrorStatePanel(
                  message:
                      'Não conseguimos carregar os questionários. Tente novamente.',
                  onRetry: () =>
                      ref.invalidate(psychologistQuestionnairesProvider),
                ),
              )
            // ── Data ──────────────────────────────────────────────────────
            else ...[
              // Section header
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.lg,
                    AppSpacing.md,
                    AppSpacing.sm,
                  ),
                  child: AppSectionHeader(
                    title: 'Catálogo disponível',
                    subtitle:
                        'A disponibilidade para o paciente segue esta lista e a relação clínica com você.',
                  ),
                ),
              ),

              // Empty state
              if (items == null || items.isEmpty)
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: AppEmptyState(
                      icon: Icons.assignment_late_outlined,
                      title: 'Sem questionários liberados',
                      message:
                          'Nenhum questionário liberado para você no momento.\n'
                          'Solicite ao administrador a liberação dos instrumentos.',
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    AppSpacing.xxxl,
                  ),
                  sliver: SliverList.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final questionnaire = items[index];
                      final canApply = questionnaire.canStart(
                        allowUnvalidated:
                            EnvConfig.allowsUnvalidatedInstruments,
                      );
                      return MotionReveal(
                        delay: staggerDelay(index),
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
            ],
          ],
        ),
      ),
    );
  }
}
