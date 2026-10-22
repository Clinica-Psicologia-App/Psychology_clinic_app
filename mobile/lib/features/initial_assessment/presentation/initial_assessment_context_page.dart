import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';
import '../../patients/presentation/widgets/patient_context_header.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/initial_assessment.dart';
import '../domain/life_area.dart';
import '../providers/initial_assessment_providers.dart';
import 'widgets/life_area_wheel_chart.dart';

/// Tela "Contexto de Vida" — Bloco 3 do fluxo Conhecer (visão terapeuta).
/// Exibe o Mapa da Vida (gráfico + áreas) e permite comentário clínico por área.
class InitialAssessmentContextPage extends ConsumerStatefulWidget {
  const InitialAssessmentContextPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  ConsumerState<InitialAssessmentContextPage> createState() =>
      _InitialAssessmentContextPageState();
}

class _InitialAssessmentContextPageState
    extends ConsumerState<InitialAssessmentContextPage> {
  final Map<LifeArea, TextEditingController> _comments = {};

  bool _initialized = false;
  bool _saving = false;

  InitialAssessmentContext get _ctx => InitialAssessmentContext(
        role: widget.role,
        patientId: widget.patientId,
      );

  @override
  void dispose() {
    for (final c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFromData(InitialAssessment data) {
    if (_initialized) return;
    for (final area in kLifeAreasInOrder) {
      _comments[area] = TextEditingController(
          text: data.lifeAreaFor(area).clinicalComment ?? '');
    }
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(initialAssessmentRepositoryProvider);
    try {
      await repo.saveLifeAreaNotesBulk(
        patientId: widget.patientId,
        notes: {
          for (final area in kLifeAreasInOrder) area: _comments[area]?.text,
        },
      );
      ref.invalidate(initialAssessmentProvider(_ctx));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contexto de Vida salvo.')),
      );
    } catch (e) {
      if (!mounted) return;
      showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(initialAssessmentProvider(_ctx));

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: PatientContextHeader(
              patientId: widget.patientId,
              pageTitle: 'CONTEXTO DE VIDA',
              role: widget.role,
              accentColor: AppColors.cyan,
            ),
          ),
          SliverFillRemaining(
            hasScrollBody: true,
            child: AsyncStateBody<InitialAssessment>(
              asyncValue: async,
              onRetry: () => ref.invalidate(initialAssessmentProvider(_ctx)),
              dataBuilder: (data) {
                _initFromData(data);
                return Stack(
                  children: [
                    ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
                      children: [
                        _sectionHeader(
                          context,
                          title: 'Contexto de Vida',
                          icon: Icons.tune_outlined,
                          accent: AppColors.turquoise,
                          subtitle:
                              'Funcionamento e contexto de vida do paciente.',
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.navy.withValues(alpha: 0.07),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: LifeAreaWheelChart(
                                scores: {
                                  for (final area in kLifeAreasInOrder)
                                    area: data.lifeAreaFor(area).score,
                                },
                              ),
                            ),
                          ),
                        ),
                        for (final group in FunctioningGroup.values)
                          _functioningGroup(context, data, group),
                      ],
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              AppColors.background.withValues(alpha: 0),
                              AppColors.background,
                              AppColors.background,
                            ],
                            stops: const [0, 0.4, 1],
                          ),
                        ),
                        child: FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(52),
                          ),
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2),
                                )
                              : const Icon(Icons.check),
                          label:
                              Text(_saving ? 'Salvando...' : 'Salvar contexto'),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    BuildContext context, {
    required String title,
    required IconData icon,
    required Color accent,
    String? subtitle,
  }) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: accent, size: 23),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null)
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _functioningGroup(
    BuildContext context,
    InitialAssessment data,
    FunctioningGroup group,
  ) {
    final areas = kLifeAreasInOrder.where((a) => a.group == group).toList();
    final theme = Theme.of(context);
    return ClayCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.category_outlined,
                    size: 16, color: AppColors.turquoise),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    group.label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < areas.length; i++) ...[
              if (i > 0)
                Divider(height: 20, color: theme.colorScheme.outline),
              _areaRow(context, data, areas[i]),
            ],
          ],
        ),
      ),
    );
  }

  Widget _areaRow(
    BuildContext context,
    InitialAssessment data,
    LifeArea area,
  ) {
    final a = data.lifeAreaFor(area);
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                area.label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            if (a.score != null)
              _scorePill('Satisfação', a.score!, AppColors.turquoise),
            if (a.suffering != null) ...[
              const SizedBox(width: 6),
              _scorePill('Sofrimento', a.suffering!, AppColors.warning),
            ],
          ],
        ),
        if ((a.guidedAnswer ?? '').isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: AppColors.cyan, width: 2.5),
                ),
              ),
              child: Text(
                '"${a.guidedAnswer}"',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                  height: 1.4,
                ),
              ),
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _comments[area],
          minLines: 1,
          maxLines: 3,
          decoration: _fieldDecoration(context, 'Comentário clínico'),
        ),
      ],
    );
  }

  Widget _scorePill(String label, int value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            '/10',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w600,
              color: color.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDecoration(BuildContext context, String label) {
    final theme = Theme.of(context);
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: theme.colorScheme.surfaceContainerLow,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: theme.colorScheme.outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
      ),
    );
  }
}
