import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/daily_monitors_providers.dart';
import 'daily_monitor_routes.dart';
import 'widgets/daily_monitor_widgets.dart';

class DailyMonitorDetailPage extends ConsumerWidget {
  const DailyMonitorDetailPage({
    super.key,
    required this.role,
    required this.monitorId,
    this.patientId,
    this.readOnly = false,
  });

  final ProfileRole role;
  final String monitorId;
  final String? patientId;
  final bool readOnly;

  bool get _isPatient => role == ProfileRole.patient;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monitorAsync = ref.watch(dailyMonitorDetailProvider(monitorId));

    return AppScaffold(
      title: _isPatient ? 'Meu registro' : 'Registro diário',
      accent: AppColors.cyan,
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () =>
              ref.invalidate(dailyMonitorDetailProvider(monitorId)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: monitorAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Erro ao carregar registro.'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(dailyMonitorDetailProvider(monitorId)),
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (monitor) {
          if (monitor == null) {
            return const Center(child: Text('Registro não encontrado.'));
          }

          return Column(
            children: [
              Expanded(
                child: MotionReveal(
                  child: DailyMonitorDetailBody(
                    monitor: monitor,
                    readOnly: readOnly || !_isPatient,
                  ),
                ),
              ),
              if (_isPatient && monitor.isEditableToday) ...[
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: FilledButton.icon(
                    onPressed: () => context.push(
                      DailyMonitorRoutes.patientEdit(monitorId),
                    ),
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Editar registro de hoje'),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
