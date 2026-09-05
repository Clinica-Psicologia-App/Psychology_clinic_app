import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/check_in_diary_stats.dart';
import '../domain/patient_check_in.dart';
import '../providers/patient_check_ins_providers.dart';
import 'patient_check_in_routes.dart';
import 'widgets/check_in_diary_widgets.dart';

class PatientCheckInsPage extends ConsumerWidget {
  const PatientCheckInsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final listAsync = ref.watch(myPatientCheckInsProvider);
    final todayAsync = ref.watch(todayCheckInProvider);

    return AppScaffold(
      title: 'Check-in',
      accent: AppColors.turquoise,
      // Sem check-in hoje, quem convida é a "página em branco" no topo do
      // caderno — um FAB ao lado dela seria o mesmo pedido duas vezes.
      floatingActionButton: todayAsync.valueOrNull == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () async {
                await context.push(
                  PatientCheckInRoutes.patientEdit(
                    todayAsync.requireValue!.id,
                  ),
                );
                ref.read(myPatientCheckInsProvider.notifier).refresh();
                ref.invalidate(todayCheckInProvider);
              },
              icon: const Icon(Icons.edit),
              label: const Text('Editar a página de hoje'),
            ),
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () {
            ref.read(myPatientCheckInsProvider.notifier).refresh();
            ref.invalidate(todayCheckInProvider);
          },
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<PatientCheckIn>>(
        asyncValue: listAsync,
        onRetry: () {
          ref.read(myPatientCheckInsProvider.notifier).refresh();
          ref.invalidate(todayCheckInProvider);
        },
        emptyMessage: 'Seu diário ainda está em branco. '
            'A primeira página é a de hoje.',
        emptyIcon: Icons.menu_book_outlined,
        dataBuilder: (items) => RefreshIndicator(
          onRefresh: () async {
            await ref.read(myPatientCheckInsProvider.notifier).refresh();
            ref.invalidate(todayCheckInProvider);
          },
          child: _CheckInsList(
            items: items,
            onWriteToday: () => _openCreate(context, ref),
            onTap: (c) async {
              await context.push(PatientCheckInRoutes.patientDetail(c.id));
              ref.read(myPatientCheckInsProvider.notifier).refresh();
              ref.invalidate(todayCheckInProvider);
            },
          ),
        ),
      ),
    );
  }

  Future<void> _openCreate(BuildContext context, WidgetRef ref) async {
    final created =
        await context.push<bool>(PatientCheckInRoutes.patientCreate);
    if (created == true) {
      ref.read(myPatientCheckInsProvider.notifier).refresh();
      ref.invalidate(todayCheckInProvider);
    }
  }
}

class StaffPatientCheckInsPage extends ConsumerWidget {
  const StaffPatientCheckInsPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ctx = StaffCheckInsContext(role: role, patientId: patientId);
    final listAsync = ref.watch(staffPatientCheckInsProvider(ctx));

    return AppScaffold(
      title: 'Check-ins',
      accent: AppColors.turquoise,
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.invalidate(staffPatientCheckInsProvider(ctx)),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<PatientCheckIn>>(
        asyncValue: listAsync,
        onRetry: () => ref.invalidate(staffPatientCheckInsProvider(ctx)),
        emptyMessage: 'Nenhum check-in registrado pelo paciente.',
        emptyIcon: Icons.menu_book_outlined,
        dataBuilder: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(staffPatientCheckInsProvider(ctx));
            await ref.read(staffPatientCheckInsProvider(ctx).future);
          },
          child: _CheckInsList(
            items: items,
            readOnly: true,
            onTap: (c) => context.push(
              PatientCheckInRoutes.staffDetail(
                role: role,
                patientId: patientId,
                checkInId: c.id,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// O caderno: capa (só do paciente), página de hoje e as páginas anteriores
/// agrupadas por mês, costuradas por um fio vertical.
class _CheckInsList extends StatelessWidget {
  const _CheckInsList({
    required this.items,
    required this.onTap,
    this.readOnly = false,
    this.onWriteToday,
  });

  final List<PatientCheckIn> items;
  final void Function(PatientCheckIn checkIn) onTap;

  /// Visão do psicólogo: sem capa motivacional, sem convite de hoje.
  final bool readOnly;

  final VoidCallback? onWriteToday;

  @override
  Widget build(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final hasToday = items.any((c) => c.isToday);
    final onWrite = onWriteToday;

    final blocks = <Widget>[];

    if (!readOnly) {
      blocks.add(CheckInDiaryCover(stats: buildDiaryStats(items)));
      blocks.add(const SizedBox(height: AppSpacing.md));
      if (!hasToday && onWrite != null) {
        blocks.add(CheckInBlankPage(onWrite: onWrite));
        blocks.add(const SizedBox(height: AppSpacing.md));
      }
    } else {
      blocks.add(
        AppPageHeader(
          title: 'Diário do paciente',
          subtitle: 'O que ele registrou entre as sessões, na ordem em que '
              'escreveu.',
          icon: Icons.menu_book_outlined,
          metadata: [
            if (hasToday) const Chip(label: Text('Escreveu hoje')),
            Chip(label: Text('${items.length} páginas')),
          ],
        ),
      );
      blocks.add(const SizedBox(height: AppSpacing.lg));
    }

    // Capítulos por mês. `items` já vem do mais recente para o mais antigo.
    String? currentMonth;
    for (var i = 0; i < items.length; i++) {
      final c = items[i];
      final at = c.checkedInAt.toLocal();
      final month = loc.formatMonthYear(at);
      if (month != currentMonth) {
        currentMonth = month;
        blocks.add(CheckInMonthDivider(label: month));
      }
      final nextIsNewMonth = i == items.length - 1 ||
          loc.formatMonthYear(items[i + 1].checkedInAt.toLocal()) != month;
      blocks.add(
        CheckInDiaryEntry(
          checkIn: c,
          isToday: c.isToday,
          // O fio para no fim de cada capítulo, senão atravessa o divisor.
          isLast: nextIsNewMonth,
          onTap: () => onTap(c),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        88,
      ),
      children: [MotionStaggered(children: blocks)],
    );
  }
}
