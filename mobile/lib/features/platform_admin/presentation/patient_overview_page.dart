import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../profile/domain/profile_role.dart';
import '../../profile/presentation/widgets/user_avatar.dart';
import '../../user_management/domain/clinic_user.dart';
import '../../user_management/providers/user_management_providers.dart';
import '../../../shared/widgets/brand_loading.dart';

class PatientOverviewPage extends ConsumerWidget {
  const PatientOverviewPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(clinicUsersProvider);

    return AppScaffold(
      title: 'Distribuição de Pacientes',
      accent: AppColors.blue,
      body: usersAsync.when(
        loading: () => const BrandLoader(),
        error: (e, _) => Center(
          child: Text(
            'Erro ao carregar dados.',
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.error),
          ),
        ),
        data: (users) {
          final psychologists = users
              .where((u) => u.role == ProfileRole.psychologist)
              .toList()
            ..sort((a, b) => a.fullName.compareTo(b.fullName));

          final totalActive = psychologists.fold<int>(
            0,
            (sum, u) => sum + u.assignedPatientsCount,
          );
          final totalPending = psychologists.fold<int>(
            0,
            (sum, u) => sum + u.pendingPatientInvitationsCount,
          );

          return RefreshIndicator(
            onRefresh: () => ref.read(clinicUsersProvider.notifier).refresh(),
            child: ResponsiveContent(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.xxl,
                ),
                children: [
                  MotionReveal(
                    child: _SummaryHeader(
                      totalActive: totalActive,
                      totalPending: totalPending,
                      psychologistCount: psychologists.length,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (psychologists.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 48),
                        child: Text('Nenhum psicólogo cadastrado.'),
                      ),
                    )
                  else
                    ...psychologists.asMap().entries.map(
                          (entry) => MotionReveal(
                            delay: staggerDelay(entry.key),
                            child: Padding(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.sm,
                              ),
                              child: _PsychologistPatientCard(
                                user: entry.value,
                              ),
                            ),
                          ),
                        ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.totalActive,
    required this.totalPending,
    required this.psychologistCount,
  });

  final int totalActive;
  final int totalPending;
  final int psychologistCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.xlAll,
        boxShadow: AppShadows.card,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.turquoise,
                    borderRadius: AppRadius.lgAll,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.45),
                        blurRadius: 4,
                        offset: const Offset(-2, -2),
                      ),
                      BoxShadow(
                        color: AppColors.turquoise.withValues(alpha: 0.38),
                        blurRadius: 10,
                        offset: const Offset(3, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.people_alt_outlined,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Visão geral da clínica',
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        '$psychologistCount psicólogo${psychologistCount != 1 ? 's' : ''} cadastrado${psychologistCount != 1 ? 's' : ''}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _StatCell(
                    label: 'Pacientes ativos',
                    value: '$totalActive',
                    color: AppColors.turquoise,
                    icon: Icons.person_outline,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _StatCell(
                    label: 'Convites pendentes',
                    value: '$totalPending',
                    color: AppColors.warning,
                    icon: Icons.mail_outline,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: AppRadius.lgAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PsychologistPatientCard extends StatelessWidget {
  const _PsychologistPatientCard({required this.user});

  final ClinicUser user;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reserved = user.reservedPatientSlots;
    final limit = user.patientAssignmentLimit;
    final hasLimit = limit != null;
    final atLimit = user.reachedPatientAssignmentLimit;
    final canReceive = user.canReceivePatients;
    final isActive = user.isActive;

    Color statusColor;
    String statusLabel;
    if (!isActive) {
      statusColor = AppColors.disabled;
      statusLabel = 'Inativo';
    } else if (!canReceive) {
      statusColor = AppColors.error;
      statusLabel = 'Bloqueado';
    } else if (atLimit) {
      statusColor = AppColors.warning;
      statusLabel = 'Capacidade máxima';
    } else {
      statusColor = AppColors.success;
      statusLabel = 'Disponível';
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar.parts(
                  fullName: user.fullName,
                  initials: user.initials,
                  role: user.role,
                  avatarType: user.avatarType,
                  photoUrl: user.photoUrl,
                  avatarConfig: user.avatarConfig,
                  size: 42,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if (user.crp != null && user.crp!.isNotEmpty)
                        Text(
                          'CRP ${user.crp}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                    ],
                  ),
                ),
                _StatusPill(label: statusLabel, color: statusColor),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            const Divider(height: 1),
            const SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Expanded(
                  child: _CountChip(
                    icon: Icons.person_outline,
                    label: 'Pacientes ativos',
                    value: '${user.assignedPatientsCount}',
                    color: AppColors.turquoise,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: _CountChip(
                    icon: Icons.mail_outline,
                    label: 'Convites pendentes',
                    value: '${user.pendingPatientInvitationsCount}',
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
            if (hasLimit) ...[
              const SizedBox(height: AppSpacing.sm),
              _SlotBar(used: reserved, limit: limit, color: statusColor),
            ],
          ],
        ),
      ),
    );
  }
}


class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: AppRadius.mdAll,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  Text(
                    label,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: AppColors.textMuted,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SlotBar extends StatelessWidget {
  const _SlotBar({
    required this.used,
    required this.limit,
    required this.color,
  });

  final int used;
  final int limit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (used / limit).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Capacidade',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textMuted,
                  ),
            ),
            Text(
              '$used / $limit slots',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
