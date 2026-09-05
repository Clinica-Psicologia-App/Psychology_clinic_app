import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../auth/providers/auth_providers.dart';
import '../../patients/domain/psychologist_alert.dart';
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
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    AppSpacing.sm,
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
                              onSelected: (_) =>
                                  setState(() => _filter = f),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
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
                ..._groupedSlivers(
                  context: context,
                  patients: filtered,
                  pendingReleaseIds: pendingReleaseIds,
                  checkinMissingMap: checkinMissingMap,
                  dataCompletionMap: dataCompletionMap,
                  showEmail: normalized.isNotEmpty,
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: AppSpacing.xl),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Divide a lista em "precisam de atenção" / "em dia" / "inativos" e monta um
  /// sliver por grupo. Quando só existe um grupo (visão sem dados de alerta,
  /// filtro de inativos, clínica pequena), os cabeçalhos somem e a lista volta
  /// a ser uma lista simples.
  List<Widget> _groupedSlivers({
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

    final needAttention = patients.where((p) => attentions[p.id] != null).toList()
      ..sort((a, b) =>
          attentions[a.id]!.rank.compareTo(attentions[b.id]!.rank));
    final upToDate = patients
        .where((p) => p.isActive && attentions[p.id] == null)
        .toList();
    final inactive = patients.where((p) => !p.isActive).toList();

    final groups = <({String label, Color color, List<Patient> items})>[
      (
        label: 'Precisam de atenção',
        color: AppColors.error,
        items: needAttention
      ),
      (label: 'Em dia', color: AppColors.success, items: upToDate),
      (
        label: 'Inativos',
        color: Theme.of(context).colorScheme.onSurfaceVariant,
        items: inactive
      ),
    ].where((g) => g.items.isNotEmpty).toList();

    final showHeaders = groups.length > 1;
    final slivers = <Widget>[];
    var index = 0;

    for (var g = 0; g < groups.length; g++) {
      final group = groups[g];
      if (showHeaders) {
        slivers.add(SliverToBoxAdapter(
          child: PatientGroupHeader(
            label: group.label,
            count: group.items.length,
            color: group.color,
            topSpacing: g == 0 ? AppSpacing.xs : AppSpacing.md,
          ),
        ));
      }
      final base = index;
      slivers.add(SliverList.builder(
        itemCount: group.items.length,
        itemBuilder: (context, i) {
          final patient = group.items[i];
          return MotionReveal(
            delay: staggerDelay(base + i),
            child: PatientListTile(
              patient: patient,
              attention: attentions[patient.id],
              checkinMissingDays: checkinMissingMap[patient.id],
              dataCompletion: dataCompletionMap?[patient.id],
              showEmail: showEmail,
              onTap: () => context.push(
                PatientRoutes.detail(widget.role, patient.id),
              ),
            ),
          );
        },
      ));
      index += group.items.length;
    }

    return slivers;
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
