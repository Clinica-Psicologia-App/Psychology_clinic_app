import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../auth/providers/auth_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient.dart';
import '../providers/patients_providers.dart';
import 'patient_routes.dart';
import 'widgets/patient_list_tile.dart';

class PatientsPage extends ConsumerStatefulWidget {
  const PatientsPage({super.key, required this.role});

  final ProfileRole role;

  @override
  ConsumerState<PatientsPage> createState() => _PatientsPageState();
}

class _PatientsPageState extends ConsumerState<PatientsPage> {
  String _query = '';
  _PatientFilter _filter = _PatientFilter.active;
  final _searchController = SearchController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final listState = ref.watch(patientsListProvider);
    final profile = ref.watch(authControllerProvider).valueOrNull;
    // Só o psicólogo libera resultados — a RPC é vazia para admin, mas evita
    // a chamada à toa.
    final pendingReleaseIds = widget.role == ProfileRole.psychologist
        ? ref.watch(patientsPendingResultsReleaseProvider).valueOrNull
        : null;

    return AppScaffold(
      title: 'Pacientes',
      accent: AppColors.blue,
      useResponsivePadding: true,
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.read(patientsListProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: AsyncStateBody<List<Patient>>(
        asyncValue: listState,
        onRetry: () => ref.read(patientsListProvider.notifier).refresh(),
        emptyMessage: 'Nenhum paciente encontrado.\n'
            'Toque em + para cadastrar o primeiro.',
        dataBuilder: (patients) {
          final normalized = _query.trim().toLowerCase();
          final searched = normalized.isEmpty
              ? patients
              : patients.where((p) {
                  return p.fullName.toLowerCase().contains(normalized) ||
                      (p.email?.toLowerCase().contains(normalized) ?? false) ||
                      (p.responsiblePsychologistName
                              ?.toLowerCase()
                              .contains(normalized) ??
                          false);
                }).toList();
          final filtered = searched.where((p) {
            return switch (_filter) {
              _PatientFilter.all => true,
              _PatientFilter.active => p.isActive,
              _PatientFilter.inactive => !p.isActive,
            };
          }).toList();
          final totalActive = patients.where((p) => p.isActive).length;
          final isStaff = widget.role.isStaff;

          return RefreshIndicator(
            onRefresh: () => ref.read(patientsListProvider.notifier).refresh(),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                // ── Header ──────────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: _PatientsHeader(
                      totalActive: totalActive,
                      totalList: filtered.length,
                      showActions: profile != null && isStaff,
                      onInvite: () => context.push(
                        PatientRoutes.invitationCreate(widget.role),
                      ),
                      onNew: () => context.push(
                        PatientRoutes.create(widget.role),
                      ),
                    ),
                  ),
                ),

                // ── Busca + filtros ──────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      0,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      children: [
                        SearchBar(
                          controller: _searchController,
                          hintText: 'Buscar por nome, e-mail ou psicólogo',
                          leading: const Icon(Icons.search),
                          trailing: [
                            if (_query.isNotEmpty)
                              IconButton(
                                tooltip: 'Limpar busca',
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _query = '');
                                },
                                icon: const Icon(Icons.close),
                              ),
                          ],
                          onChanged: (v) => setState(() => _query = v),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: AppSpacing.xs,
                            runSpacing: AppSpacing.xs,
                            children: _PatientFilter.values.map((f) {
                              return FilterChip(
                                selected: _filter == f,
                                label: Text(f.label),
                                onSelected: (_) => setState(() => _filter = f),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── Lista ou estado vazio ────────────────────────────────
                if (filtered.isEmpty)
                  SliverFillRemaining(
                    child: Center(
                      child: AppEmptyState(
                        icon: Icons.search_off_outlined,
                        title: 'Nenhum resultado',
                        message:
                            'Nenhum paciente corresponde à busca ou aos filtros.',
                        action: TextButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _query = '';
                              _filter = _PatientFilter.all;
                            });
                          },
                          icon: const Icon(Icons.filter_alt_off_outlined),
                          label: const Text('Limpar busca e filtros'),
                        ),
                      ),
                    ),
                  )
                else
                  SliverList.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final patient = filtered[index];
                      return MotionReveal(
                        delay: staggerDelay(index),
                        child: PatientListTile(
                          patient: patient,
                          hasPendingResultsRelease:
                              pendingReleaseIds?.contains(patient.id) ??
                                  false,
                          onTap: () => context.push(
                            PatientRoutes.detail(widget.role, patient.id),
                          ),
                        ),
                      );
                    },
                  ),

                // Respiro no final da lista
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xl),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header redesenhado
// ─────────────────────────────────────────────────────────────────────────────

class _PatientsHeader extends StatelessWidget {
  const _PatientsHeader({
    required this.totalActive,
    required this.totalList,
    required this.showActions,
    required this.onInvite,
    required this.onNew,
  });

  final int totalActive;
  final int totalList;
  final bool showActions;
  final VoidCallback onInvite;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MotionReveal(
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.xlAll,
          boxShadow: AppShadows.clay(),
        ),
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ícone + título + stats
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ícone gradiente
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.turquoise, Color(0xFF0096D6)],
                    ),
                    borderRadius: AppRadius.mdAll,
                    boxShadow: AppShadows.clay(AppColors.turquoise),
                  ),
                  child: const Icon(
                    Icons.people_outline,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),

                // Título + subtítulo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Minha carteira',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.navy,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        'Pacientes e convites',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),

                // Chips de contagem
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _StatPill(
                      label: '$totalActive ativos',
                      color: AppColors.success,
                      bg: AppColors.successContainer,
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    _StatPill(
                      label: '$totalList na lista',
                      color: AppColors.info,
                      bg: AppColors.infoContainer,
                    ),
                  ],
                ),
              ],
            ),

            if (showActions) ...[
              const SizedBox(height: AppSpacing.md),
              const Divider(height: 1, color: AppColors.border),
              const SizedBox(height: AppSpacing.md),

              // Botões lado a lado
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onInvite,
                      icon: const Icon(Icons.mark_email_unread_outlined,
                          size: 18),
                      label: const Text('Convidar'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onNew,
                      icon: const Icon(Icons.person_add_outlined, size: 18),
                      label: const Text('Novo paciente'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({
    required this.label,
    required this.color,
    required this.bg,
  });

  final String label;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: bg.withValues(alpha: 0.7),
        borderRadius: AppRadius.smAll,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.1,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

extension on ProfileRole {
  bool get isStaff => this == ProfileRole.psychologist;
}

enum _PatientFilter { active, inactive, all }

extension on _PatientFilter {
  String get label => switch (this) {
        _PatientFilter.active => 'Ativos',
        _PatientFilter.inactive => 'Inativos',
        _PatientFilter.all => 'Todos',
      };
}
