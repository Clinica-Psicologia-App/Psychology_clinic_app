import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../clinical_dashboard/domain/clinical_dashboard_builder.dart'
    show
        ysqInstrumentMarker,
        yamiInstrumentMarker,
        attachmentInstrumentCode,
        yciInstrumentCode,
        yraiInstrumentCode;
import '../../clinical_dashboard/domain/clinical_dashboard_data.dart';
import '../../clinical_dashboard/domain/clinical_instrument_dashboard.dart';
import '../../clinical_dashboard/presentation/widgets/clinical_dashboard_widgets.dart';
import '../../clinical_dashboard/providers/clinical_dashboard_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../../results/presentation/result_routes.dart';
import '../domain/questionnaire.dart';
import 'questionnaire_route_helpers.dart';
import 'questionnaire_routes.dart';

/// Dashboard clínico individual de um instrumento, no contexto de um paciente
/// (visão do psicólogo). Mostra a leitura por esquema daquele instrumento e o
/// botão para aplicar/preencher. Quando o paciente ainda não respondeu, exibe
/// um estado animado de "aguardando dados".
class PatientInstrumentDashboardPage extends ConsumerWidget {
  const PatientInstrumentDashboardPage({
    super.key,
    required this.role,
    required this.patientId,
    required this.questionnaire,
  });

  final ProfileRole role;
  final String patientId;
  final Questionnaire questionnaire;

  ClinicalInstrumentDashboard? _panelFor(ClinicalDashboardData d) {
    final code = questionnaire.code.trim().toUpperCase();
    if (code.contains(ysqInstrumentMarker)) return d.ysq;
    if (code.contains(yamiInstrumentMarker)) return d.yami;
    if (code == attachmentInstrumentCode) return d.attachment;
    if (code == yciInstrumentCode) return d.yci;
    if (code == yraiInstrumentCode) return d.yrai;
    return null;
  }

  void _apply(BuildContext context) {
    context.push(
      QuestionnaireRoutes.intro(role: role, patientId: patientId),
      extra: QuestionnaireIntroArgs(
        questionnaire: questionnaire,
        patientId: patientId,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(
      staffClinicalDashboardProvider(
        StaffClinicalDashboardContext(role: role, patientId: patientId),
      ),
    );

    return AppScaffold(
      title: questionnaire.name,
      accent: AppColors.blue,
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(
            staffClinicalDashboardProvider(
              StaffClinicalDashboardContext(role: role, patientId: patientId),
            ),
          );
        },
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xxxl,
          ),
          children: [
            // Ação principal: aplicar/preencher o instrumento.
            FilledButton.icon(
              onPressed: () => _apply(context),
              icon: const Icon(Icons.edit_note_outlined),
              label: const Text('Aplicar / Preencher'),
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            dashAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => _ErrorRetry(
                onRetry: () => ref.invalidate(
                  staffClinicalDashboardProvider(
                    StaffClinicalDashboardContext(
                        role: role, patientId: patientId),
                  ),
                ),
              ),
              data: (data) {
                final panel = _panelFor(data);
                if (panel != null) {
                  return InstrumentDashboardCard(
                    title: questionnaire.name,
                    panel: panel,
                    isStaff: role != ProfileRole.patient,
                    patientId: patientId,
                    role: role,
                  );
                }

                // Sem dashboard estruturado (ainda não respondido, ou
                // instrumento genérico). Se há resposta no histórico, oferece
                // ver o resultado; senão, "aguardando dados".
                final responded = data.history.any((h) =>
                    h.questionnaireCode.trim().toUpperCase() ==
                        questionnaire.code.trim().toUpperCase() &&
                    h.hasResults);
                final responseId = data.history
                    .where((h) =>
                        h.questionnaireCode.trim().toUpperCase() ==
                        questionnaire.code.trim().toUpperCase())
                    .map((h) => h.responseId)
                    .cast<String?>()
                    .firstWhere((id) => id != null, orElse: () => null);

                if (responded && responseId != null) {
                  return _GenericResultCard(
                    onOpen: () => context.push(
                      ResultRoutes.detail(
                        role: role,
                        patientId: patientId,
                        responseId: responseId,
                      ),
                    ),
                  );
                }

                return const _WaitingForData();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Estado animado de "aguardando dados" — o paciente ainda não respondeu.
class _WaitingForData extends StatefulWidget {
  const _WaitingForData();

  @override
  State<_WaitingForData> createState() => _WaitingForDataState();
}

class _WaitingForDataState extends State<_WaitingForData>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animate = AppAnimations.shouldAnimate(context);
    final icon = Icon(
      Icons.hourglass_top_outlined,
      size: 44,
      color: AppColors.blue.withValues(alpha: 0.8),
    );

    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.xxxl),
        child: Column(
          children: [
            if (animate)
              AnimatedBuilder(
                animation: _pulse,
                builder: (context, child) {
                  final t = Curves.easeInOut.transform(_pulse.value);
                  return Opacity(
                    opacity: 0.55 + t * 0.45,
                    child: Transform.scale(scale: 0.94 + t * 0.12, child: child),
                  );
                },
                child: icon,
              )
            else
              icon,
            const SizedBox(height: AppSpacing.md),
            const Text(
              'Aguardando dados',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            const Text(
              'O paciente ainda não respondeu este instrumento. Assim que '
              'houver uma resposta, o dashboard aparece aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.5,
                color: AppColors.textSecondary,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GenericResultCard extends StatelessWidget {
  const _GenericResultCard({required this.onOpen});
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Este instrumento não tem um painel de esquemas dedicado, mas já '
              'há uma resposta registrada.',
              style: TextStyle(fontSize: 13.5, color: AppColors.textSecondary),
            ),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton.icon(
              onPressed: onOpen,
              icon: const Icon(Icons.assignment_turned_in_outlined, size: 18),
              label: const Text('Ver resultado completo'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 48),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Não foi possível carregar o dashboard.'),
            const SizedBox(height: AppSpacing.md),
            OutlinedButton(
              onPressed: onRetry,
              child: const Text('Tentar de novo'),
            ),
          ],
        ),
      ),
    );
  }
}
