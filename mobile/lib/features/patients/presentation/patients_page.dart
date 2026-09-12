import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../auth/providers/auth_providers.dart';
import '../../initial_assessment/presentation/initial_assessment_routes.dart';
import '../../patients/domain/psychologist_alert.dart';
import '../../results/presentation/result_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient.dart';
import '../domain/patient_data_completion.dart';
import '../domain/patient_attention.dart';
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
  _SortMode _sortMode = _SortMode.alphabetical;
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
    final pendingReleaseIds = widget.role == ProfileRole.psychologist
        ? ref.watch(patientsPendingResultsReleaseProvider).valueOrNull
        : null;

    final dataCompletionMap = widget.role == ProfileRole.psychologist
        ? ref.watch(patientsDataCompletionProvider).valueOrNull
        : null;

    final checkinMissingMap = <String, int>{};
    if (widget.role == ProfileRole.psychologist) {
      final alerts = ref.watch(psychologistAlertsProvider).valueOrNull ?? [];
      for (final a in alerts) {
        if (a.kind == PsychologistAlertKind.missingCheckin &&
            a.patientId != null) {
          checkinMissingMap[a.patientId!] = a.daysCount;
        }
      }
    }

    final isWide = AppBreakpoints.isWide(context);

    // Derived always-available values (empty lists during loading/error).
    final patients = listState.valueOrNull ?? [];
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
    final totalAll = patients.length;
    final alertCount =
        checkinMissingMap.length + (pendingReleaseIds?.length ?? 0);
    final isStaff = widget.role.isStaff;

    void doRefresh() => ref.read(patientsListProvider.notifier).refresh();

    return AppCanopyScaffold(
      body: RefreshIndicator(
        onRefresh: () async => doRefresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header full-bleed (inclui status bar + nav embutida) ──────
            SliverToBoxAdapter(
              child: _PatientsHeader(
                totalActive: totalActive,
                totalAll: totalAll,
                alertCount: alertCount,
                showActions: profile != null && isStaff,
                onBack: () => context.pop(),
                onRefresh: doRefresh,
                onInvite: () =>
                    context.push(PatientRoutes.invitationCreate(widget.role)),
                onNew: () => context.push(PatientRoutes.create(widget.role)),
              ),
            ),

            // ── Estados de carregamento / erro ───────────────────────────
            if (listState.isLoading)
              const SliverFillRemaining(
                child: Center(child: BrandLoader()),
              )
            else if (listState.hasError)
              SliverFillRemaining(
                child: ErrorStatePanel(
                  message:
                      'Não conseguimos carregar. Pode tentar de novo?',
                  onRetry: doRefresh,
                ),
              )
            else ...[
              // ── Busca + filtros ────────────────────────────────────────
              SliverToBoxAdapter(
                child: () {
                  final inner = Column(
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
                          children: [
                            ..._PatientFilter.values.map((f) {
                              return FilterChip(
                                selected: _filter == f,
                                label: Text(f.label),
                                onSelected: (_) =>
                                    setState(() => _filter = f),
                              );
                            }),
                            const SizedBox(width: 4),
                            ..._SortMode.values.map((s) {
                              return FilterChip(
                                selected: _sortMode == s,
                                showCheckmark: false,
                                label: Text(s.label),
                                avatar: Icon(s.icon, size: 13),
                                onSelected: (_) =>
                                    setState(() => _sortMode = s),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],
                  );
                  if (isWide) {
                    return ResponsiveContent(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.sm,
                        ),
                        child: inner,
                      ),
                    );
                  }
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: inner,
                  );
                }(),
              ),

              // ── Lista ou estado vazio ──────────────────────────────────
              if (patients.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: AppEmptyState(
                      icon: Icons.people_outline,
                      title: 'Nenhum paciente',
                      message: 'Nenhum paciente encontrado.\n'
                          'Toque em + para cadastrar o primeiro.',
                    ),
                  ),
                )
              else if (filtered.isEmpty)
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
                ...() {
                  final listSlivers = _flatSortedSlivers(
                    context: context,
                    patients: filtered,
                    pendingReleaseIds: pendingReleaseIds,
                    checkinMissingMap: checkinMissingMap,
                    dataCompletionMap: dataCompletionMap,
                    showEmail: normalized.isNotEmpty,
                  );
                  if (isWide && listSlivers.isNotEmpty) {
                    return [
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.xxxl,
                        ),
                        sliver: listSlivers.first,
                      ),
                    ];
                  }
                  return listSlivers;
                }(),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Lista plana ordenada pelo modo selecionado (sem agrupamentos).
  List<Widget> _flatSortedSlivers({
    required BuildContext context,
    required List<Patient> patients,
    required Set<String>? pendingReleaseIds,
    required Map<String, int> checkinMissingMap,
    required Map<String, PatientDataCompletion>? dataCompletionMap,
    required bool showEmail,
  }) {
    final attentions = <String, PatientAttention>{};
    for (final p in patients) {
      final a = attentionFor(
        patient: p,
        hasPendingResultsRelease: pendingReleaseIds?.contains(p.id) ?? false,
        checkinMissingDays: checkinMissingMap[p.id],
        completion: dataCompletionMap?[p.id],
      );
      if (a != null) attentions[p.id] = a;
    }

    final sorted = [...patients];
    switch (_sortMode) {
      case _SortMode.alphabetical:
        sorted.sort(
          (a, b) => a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase()),
        );
      case _SortMode.lastAccess:
        sorted.sort((a, b) {
          final ma = checkinMissingMap[a.id] ?? 999;
          final mb = checkinMissingMap[b.id] ?? 999;
          if (ma != mb) return ma.compareTo(mb);
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
        });
      case _SortMode.alerts:
        sorted.sort((a, b) {
          final aa = attentions[a.id];
          final ab = attentions[b.id];
          if (aa != null && ab == null) return -1;
          if (aa == null && ab != null) return 1;
          if (aa != null && ab != null) return aa.rank.compareTo(ab.rank);
          return a.fullName.toLowerCase().compareTo(b.fullName.toLowerCase());
        });
    }

    return [
      SliverList.builder(
        itemCount: sorted.length,
        itemBuilder: (context, i) {
          final patient = sorted[i];
          final attention = attentions[patient.id];
          return MotionReveal(
            delay: staggerDelay(i),
            child: PatientListTile(
              patient: patient,
              attention: attention,
              checkinMissingDays: checkinMissingMap[patient.id],
              dataCompletion: dataCompletionMap?[patient.id],
              showEmail: showEmail,
              onQuickAction: attention != null &&
                      attention.kind.hasDirectAction &&
                      widget.role == ProfileRole.psychologist
                  ? () => _runQuickAction(context, patient, attention)
                  : null,
              onTap: () => context.push(
                PatientRoutes.detail(widget.role, patient.id),
              ),
            ),
          );
        },
      ),
    ];
  }

  /// Botão do motivo: leva direto para onde a coisa se resolve, em vez de
  /// jogar o psicólogo na ficha para ele procurar. Só é chamado para motivos
  /// com `hasDirectAction`.
  void _runQuickAction(
    BuildContext context,
    Patient patient,
    PatientAttention attention,
  ) {
    switch (attention.kind) {
      case PatientAttentionKind.pendingRelease:
        context.push(
          ResultRoutes.list(role: widget.role, patientId: patient.id),
        );
      case PatientAttentionKind.emptyData:
        context.push(
          InitialAssessmentRoutes.staff(
            role: widget.role,
            patientId: patient.id,
          ),
        );
      // Sem ação direta hoje: a linha mostra a seta e leva à ficha.
      case PatientAttentionKind.noCheckin:
      case PatientAttentionKind.fewCheckins:
        context.push(PatientRoutes.detail(widget.role, patient.id));
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header — onda navy com gradiente e wave clipper na base
// ─────────────────────────────────────────────────────────────────────────────

class _PatientsHeader extends StatelessWidget {
  const _PatientsHeader({
    required this.totalActive,
    required this.totalAll,
    required this.alertCount,
    required this.showActions,
    required this.onBack,
    required this.onRefresh,
    required this.onInvite,
    required this.onNew,
  });

  final int totalActive;
  final int totalAll;
  final int alertCount;
  final bool showActions;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onInvite;
  final VoidCallback onNew;

  @override
  Widget build(BuildContext context) {
    if (AppBreakpoints.isWide(context)) return _buildCompact(context);

    final theme = Theme.of(context);
    final statusBarTop = MediaQuery.paddingOf(context).top;

    return MotionReveal(
      child: ClipPath(
        clipper: _WaveClipper(),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1B2D5B),
                Color(0xFF1E4D8C),
                Color(0xFF0D7A75),
              ],
              stops: [0.0, 0.55, 1.0],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Status bar inset + nav ────────────────────────────────────
              SizedBox(height: statusBarTop),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: onBack,
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      tooltip: 'Voltar',
                    ),
                    Expanded(
                      child: Text(
                        'Pacientes',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onRefresh,
                      icon: const Icon(
                        Icons.refresh_rounded,
                        color: Colors.white,
                      ),
                      tooltip: 'Atualizar',
                    ),
                  ],
                ),
              ),

              // ── Conteúdo ──────────────────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.xs,
                  AppSpacing.lg,
                  showActions ? 56 : 44,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Eyebrow
                    Text(
                      'MINHA CARTEIRA',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.7,
                      ),
                    ),
                    const SizedBox(height: 6),

                    // Título com número em destaque
                    RichText(
                      text: TextSpan(
                        style: theme.textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          height: 1.1,
                        ),
                        children: [
                          TextSpan(
                            text: '$totalActive',
                            style: const TextStyle(color: Color(0xFF00D4C9)),
                          ),
                          const TextSpan(text: ' pacientes\nativos hoje'),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),

                    // Stats glass bar
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: AppRadius.smAll,
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.14),
                        ),
                      ),
                      child: IntrinsicHeight(
                        child: Row(
                          children: [
                            _WaveStat(
                              value: '$totalActive',
                              label: 'Ativos',
                              accent: const Color(0xFF00D4C9),
                            ),
                            _WaveStatDivider(),
                            _WaveStat(
                              value: alertCount > 0 ? '$alertCount' : '—',
                              label: 'Alertas',
                              accent: alertCount > 0
                                  ? const Color(0xFFFBBF24)
                                  : Colors.white38,
                            ),
                            _WaveStatDivider(),
                            _WaveStat(
                              value: '$totalAll',
                              label: 'Total',
                              accent: Colors.white.withValues(alpha: 0.9),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (showActions) ...[
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(
                            child: _GlassButton(
                              onPressed: onInvite,
                              icon: Icons.mark_email_unread_outlined,
                              label: 'Convidar',
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Expanded(
                            child: _GlassButton(
                              onPressed: onNew,
                              icon: Icons.person_add_outlined,
                              label: 'Novo paciente',
                              filled: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompact(BuildContext context) {
    final theme = Theme.of(context);

    const gradient = LinearGradient(
      begin: Alignment.centerLeft,
      end: Alignment.centerRight,
      colors: [Color(0xFF1B2D5B), Color(0xFF1E4D8C), Color(0xFF0D7A75)],
      stops: [0.0, 0.55, 1.0],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        gradient: gradient,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E4D8C).withValues(alpha: 0.22),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'PACIENTES',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.55),
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.7,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      '$totalActive',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFF00D4C9),
                        height: 1,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'ativos · $totalAll total',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    if (alertCount > 0) ...[
                      const SizedBox(width: AppSpacing.sm),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFBBF24).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: const Color(0xFFFBBF24).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          '$alertCount alertas',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: const Color(0xFFFBBF24),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          if (showActions) ...[
            const SizedBox(width: AppSpacing.md),
            _GlassButton(
              onPressed: onInvite,
              icon: Icons.mark_email_unread_outlined,
              label: 'Convidar',
            ),
            const SizedBox(width: AppSpacing.xs),
            _GlassButton(
              onPressed: onNew,
              icon: Icons.person_add_outlined,
              label: 'Novo paciente',
              filled: true,
            ),
          ],
          const SizedBox(width: AppSpacing.xs),
          IconButton(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white),
            tooltip: 'Atualizar',
          ),
        ],
      ),
    );
  }
}

class _WaveStat extends StatelessWidget {
  const _WaveStat({
    required this.value,
    required this.label,
    required this.accent,
  });

  final String value;
  final String label;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w900,
                color: accent,
                height: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.55),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WaveStatDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      margin: const EdgeInsets.symmetric(vertical: 12),
      color: Colors.white.withValues(alpha: 0.15),
    );
  }
}

class _WaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..lineTo(0, size.height - 36)
      ..cubicTo(
        size.width * 0.22,
        size.height + 2,
        size.width * 0.72,
        size.height - 30,
        size.width,
        size.height - 8,
      )
      ..lineTo(size.width, 0)
      ..close();
  }

  @override
  bool shouldReclip(_WaveClipper oldClipper) => false;
}

class _GlassButton extends StatelessWidget {
  const _GlassButton({
    required this.onPressed,
    required this.icon,
    required this.label,
    this.filled = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled
          ? AppColors.turquoise
          : Colors.white.withValues(alpha: 0.12),
      borderRadius: AppRadius.smAll,
      child: InkWell(
        onTap: onPressed,
        borderRadius: AppRadius.smAll,
        child: Container(
          padding: const EdgeInsets.symmetric(
            vertical: AppSpacing.sm,
            horizontal: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            borderRadius: AppRadius.smAll,
            border: filled
                ? null
                : Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 15, color: Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
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

enum _SortMode { alphabetical, lastAccess, alerts }

extension on _SortMode {
  String get label => switch (this) {
        _SortMode.alphabetical => 'A–Z',
        _SortMode.lastAccess => 'Último acesso',
        _SortMode.alerts => 'Alertas',
      };

  IconData get icon => switch (this) {
        _SortMode.alphabetical => Icons.sort_by_alpha_rounded,
        _SortMode.lastAccess => Icons.access_time_rounded,
        _SortMode.alerts => Icons.notifications_rounded,
      };
}
