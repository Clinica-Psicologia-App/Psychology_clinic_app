import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/patient_check_ins_providers.dart';
import 'patient_check_in_routes.dart';
import 'widgets/patient_check_in_widgets.dart';

class PatientCheckInDetailPage extends ConsumerWidget {
  const PatientCheckInDetailPage({
    super.key,
    required this.role,
    required this.checkInId,
    this.patientId,
  });

  final ProfileRole role;
  final String checkInId;
  final String? patientId;

  bool get _isPatient => role == ProfileRole.patient;
  bool get _readOnly => !_isPatient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final checkInAsync = ref.watch(patientCheckInDetailProvider(checkInId));

    return AppScaffold(
      title: 'Check-in',
      accent: AppColors.turquoise,
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.invalidate(patientCheckInDetailProvider(checkInId)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: checkInAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erro ao carregar check-in.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(patientCheckInDetailProvider(checkInId)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (checkIn) {
          if (checkIn == null) {
            return const Center(child: Text('Check-in não encontrado.'));
          }

          final loc = MaterialLocalizations.of(context);
          final theme = Theme.of(context);

          return Column(
            children: [
              Expanded(
                child: MotionReveal(
                  child: ListView(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    children: [
                      AppPageHeader(
                        title: loc.formatFullDate(
                          checkIn.checkedInAt.toLocal(),
                        ),
                        subtitle: loc.formatTimeOfDay(
                          TimeOfDay.fromDateTime(
                            checkIn.checkedInAt.toLocal(),
                          ),
                        ),
                        icon: Icons.fact_check_outlined,
                        metadata: [
                          if (checkIn.isToday)
                            const Chip(label: Text('Check-in de hoje')),
                          if (_readOnly)
                            const Chip(label: Text('Somente leitura')),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      const AppSectionHeader(
                        title: 'Resumo do dia',
                        subtitle: 'Escalas preenchidas neste check-in.',
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      CheckInScoresSummary(checkIn: checkIn),
                      if (checkIn.notes != null &&
                          checkIn.notes!.trim().isNotEmpty) ...[
                        const SizedBox(height: AppSpacing.xl),
                        AppInfoCard(
                          title: 'Observações',
                          body: checkIn.notes!,
                          icon: Icons.notes_outlined,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              if (_isPatient && checkIn.isEditableToday) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: FilledButton.icon(
                    onPressed: () => context.push(
                      PatientCheckInRoutes.patientEdit(checkInId),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar check-in de hoje'),
                  ),
                ),
              ],
              if (_readOnly)
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    'Visualização somente leitura para a equipe.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
