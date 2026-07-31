import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import 'initial_assessment_routes.dart';
import '../domain/functioning_level.dart';
import '../domain/initial_assessment.dart';
import '../domain/life_area.dart';
import '../providers/initial_assessment_providers.dart';

/// Tela 1 do fluxo Conhecer na lente do terapeuta — leitura das respostas do
/// paciente + campos clínicos (Bloco 1 privado, Bloco 2 clínico, comentários
/// do Bloco 3) + Bloco 4 (Primeiras Impressões Clínicas).
class InitialAssessmentTherapistPage extends ConsumerStatefulWidget {
  const InitialAssessmentTherapistPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  ConsumerState<InitialAssessmentTherapistPage> createState() =>
      _InitialAssessmentTherapistPageState();
}

class _InitialAssessmentTherapistPageState
    extends ConsumerState<InitialAssessmentTherapistPage> {
  // Bloco 1 privado + Bloco 2 clínico
  final _observations = TextEditingController();
  final _complaint = TextEditingController();
  final _problem = TextEditingController();
  final _factors = TextEditingController();
  final _goals = TextEditingController();
  final _motivation = TextEditingController();
  final _initialHypotheses = TextEditingController();

  // Bloco 3 — comentário clínico por área
  final Map<LifeArea, TextEditingController> _comments = {};

  // Bloco 4 — impressões
  final _temperament = TextEditingController();
  final _bond = TextEditingController();
  final _resources = TextEditingController();
  final _vulnerabilities = TextEditingController();
  final _dxHypotheses = TextEditingController();
  final _prevDx = TextEditingController();
  final _diffDx = TextEditingController();
  final _priorities = TextEditingController();
  FunctioningLevel? _level;

  final _schemaHypothesesText = TextEditingController();
  final _modeHypothesesText = TextEditingController();
  final _emotionalNeedsText = TextEditingController();

  bool _initialized = false;
  bool _saving = false;

  InitialAssessmentContext get _ctx => InitialAssessmentContext(
        role: widget.role,
        patientId: widget.patientId,
      );

  @override
  void dispose() {
    for (final c in [
      _observations,
      _complaint,
      _problem,
      _factors,
      _goals,
      _motivation,
      _initialHypotheses,
      _temperament,
      _bond,
      _resources,
      _vulnerabilities,
      _dxHypotheses,
      _prevDx,
      _diffDx,
      _priorities,
      _schemaHypothesesText,
      _modeHypothesesText,
      _emotionalNeedsText,
      ..._comments.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFromData(InitialAssessment data) {
    if (_initialized) return;
    final ci = data.clinicalIntake;
    _observations.text = ci?.initialObservations ?? '';
    _complaint.text = ci?.mainComplaint ?? '';
    _problem.text = ci?.currentProblem ?? '';
    _factors.text = ci?.precipitatingFactors ?? '';
    _goals.text = ci?.patientGoals ?? '';
    _motivation.text = ci?.motivation ?? '';
    _initialHypotheses.text = ci?.initialHypotheses ?? '';

    for (final area in kLifeAreasInOrder) {
      _comments[area] = TextEditingController(
          text: data.lifeAreaFor(area).clinicalComment ?? '');
    }

    final imp = data.clinicalImpressions;
    _temperament.text = imp?.observedTemperament ?? '';
    _bond.text = imp?.therapeuticBond ?? '';
    _resources.text = imp?.resources ?? '';
    _vulnerabilities.text = imp?.vulnerabilities ?? '';
    _dxHypotheses.text = imp?.hypotheses ?? '';
    _prevDx.text = imp?.previousDiagnoses ?? '';
    _diffDx.text = imp?.differentialDiagnosis ?? '';
    _priorities.text = imp?.therapeuticPriorities ?? '';
    _level = imp?.functioningLevel;
    _schemaHypothesesText.text = imp?.schemaHypothesesText ?? '';
    _modeHypothesesText.text = imp?.modeHypothesesText ?? '';
    _emotionalNeedsText.text = imp?.emotionalNeedsText ?? '';

    _initialized = true;
  }

  String? _nullIfEmpty(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final repo = ref.read(initialAssessmentRepositoryProvider);
    final pid = widget.patientId;
    try {
      await repo.saveClinicalIntake(
        patientId: pid,
        initialObservations: _nullIfEmpty(_observations.text),
        mainComplaint: _nullIfEmpty(_complaint.text),
        currentProblem: _nullIfEmpty(_problem.text),
        precipitatingFactors: _nullIfEmpty(_factors.text),
        patientGoals: _nullIfEmpty(_goals.text),
        motivation: _nullIfEmpty(_motivation.text),
        initialHypotheses: _nullIfEmpty(_initialHypotheses.text),
      );
      await repo.saveLifeAreaNotesBulk(
        patientId: pid,
        notes: {
          for (final area in kLifeAreasInOrder) area: _comments[area]?.text,
        },
      );
      await repo.saveClinicalImpressions(
        patientId: pid,
        observedTemperament: _nullIfEmpty(_temperament.text),
        therapeuticBond: _nullIfEmpty(_bond.text),
        resources: _nullIfEmpty(_resources.text),
        vulnerabilities: _nullIfEmpty(_vulnerabilities.text),
        hypotheses: _nullIfEmpty(_dxHypotheses.text),
        previousDiagnoses: _nullIfEmpty(_prevDx.text),
        differentialDiagnosis: _nullIfEmpty(_diffDx.text),
        functioningLevel: _level,
        therapeuticPriorities: _nullIfEmpty(_priorities.text),
        schemaHypothesesText: _nullIfEmpty(_schemaHypothesesText.text),
        modeHypothesesText: _nullIfEmpty(_modeHypothesesText.text),
        emotionalNeedsText: _nullIfEmpty(_emotionalNeedsText.text),
      );

      ref.invalidate(initialAssessmentProvider(_ctx));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conceitualização salva.')),
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

    return AppScaffold(
      title: 'Conceitualização inicial',
      body: AsyncStateBody<InitialAssessment>(
        asyncValue: async,
        onRetry: () => ref.invalidate(initialAssessmentProvider(_ctx)),
        dataBuilder: (data) {
          _initFromData(data);
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  // ── Bloco 2 — Motivo da Procura ──────────────────────────
                  _sectionTitle(context, 'Motivo da Procura / Queixa Atual'),
                  if (data.intake != null) _PatientIntakeCard(data: data),
                  _field(_complaint, 'Queixa principal'),
                  _field(_problem, 'Problema atual'),
                  _field(_factors, 'Fatores precipitantes'),
                  _field(_goals, 'Objetivos do paciente'),
                  _field(_motivation, 'Motivação'),
                  _field(_initialHypotheses, 'Hipóteses iniciais'),
                  _field(_observations, 'Observações Iniciais (privado)'),

                  const SizedBox(height: 20),
                  // ── Bloco 3 — Funcionamento Atual ────────────────────────
                  _sectionTitle(context, 'Funcionamento Atual'),
                  for (final group in FunctioningGroup.values)
                    _functioningGroup(context, data, group),

                  const SizedBox(height: 20),
                  // ── Bloco 4 — Primeiras Impressões Clínicas ──────────────
                  _sectionTitle(context, 'Primeiras Impressões Clínicas'),
                  _subheader(context, 'Impressão geral'),
                  _field(_temperament, 'Temperamento observado'),
                  _field(_bond, 'Vínculo terapêutico'),
                  _field(_resources, 'Recursos'),
                  _field(_vulnerabilities, 'Vulnerabilidades'),
                  _subheader(context, 'Perspectiva diagnóstica'),
                  _field(_dxHypotheses, 'Hipóteses'),
                  _field(_prevDx, 'Diagnósticos prévios'),
                  _field(_diffDx, 'Diagnóstico diferencial'),
                  _subheader(context, 'Nível atual de funcionamento'),
                  _functioningLevelSelector(context),
                  const SizedBox(height: 12),
                  _field(_schemaHypothesesText, 'Hipóteses de esquemas'),
                  _field(_modeHypothesesText, 'Hipóteses de modos'),
                  _field(_emotionalNeedsText,
                      'Necessidades emocionais percebidas'),
                  _subheader(context, 'Prioridades terapêuticas'),
                  _field(_priorities, 'Prioridades terapêuticas'),
                  const SizedBox(height: 12),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.timeline_outlined),
                      title: const Text('Linha do Tempo'),
                      subtitle: const Text(
                          'História de vida, eventos e crenças formadas.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        InitialAssessmentRoutes.staffHistory(
                          role: widget.role,
                          patientId: widget.patientId,
                        ),
                      ),
                    ),
                  ),
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.family_restroom_outlined),
                      title: const Text('Genograma emocional'),
                      subtitle: const Text(
                          'Vínculos, figuras de apego, clima e padrões familiares.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.push(
                        InitialAssessmentRoutes.staffFamily(
                          role: widget.role,
                          patientId: widget.patientId,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: FilledButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label:
                      Text(_saving ? 'Salvando...' : 'Salvar conceitualização'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _functioningGroup(
    BuildContext context,
    InitialAssessment data,
    FunctioningGroup group,
  ) {
    final areas = kLifeAreasInOrder.where((a) => a.group == group).toList();
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(group.label,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            for (final area in areas) _areaRow(context, data, area),
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
    final parts = <String>[
      if (a.score != null) 'Satisfação ${a.score}/10',
      if (a.suffering != null) 'Sofrimento ${a.suffering}/10',
    ];
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(area.label,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ),
              if (parts.isNotEmpty)
                Text(parts.join(' · '),
                    style: theme.textTheme.labelSmall
                        ?.copyWith(color: AppColors.textSecondary)),
            ],
          ),
          if ((a.guidedAnswer ?? '').isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text('"${a.guidedAnswer}"',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic)),
            ),
          const SizedBox(height: 4),
          TextField(
            controller: _comments[area],
            minLines: 1,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Comentário clínico',
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _functioningLevelSelector(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final level in FunctioningLevel.values)
          ChoiceChip(
            label: Text(level.label),
            selected: _level == level,
            onSelected: (sel) => setState(() => _level = sel ? level : null),
          ),
      ],
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.w700),
      ),
    );
  }

  Widget _subheader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.cyan),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 4,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}

/// Resumo (read-only) das respostas do paciente no Bloco 2.
class _PatientIntakeCard extends StatelessWidget {
  const _PatientIntakeCard({required this.data});

  final InitialAssessment data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final intake = data.intake!;
    final rows = <(String, String?)>[
      ('Procurou terapia porque', intake.reasonForSeeking),
      ('Há quanto tempo', intake.problemDuration),
      ('O que mais incomoda', intake.mainDiscomfort),
      ('Expectativas', intake.expectations),
      ('Acontecimento relacionado', intake.relatedEvent),
    ].where((r) => (r.$2 ?? '').trim().isNotEmpty).toList();

    if (rows.isEmpty) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surfaceTintBlue,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 16, color: AppColors.cyan),
                const SizedBox(width: 6),
                Text('Respostas do paciente',
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700, color: AppColors.cyan)),
              ],
            ),
            const SizedBox(height: 8),
            for (final r in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.$1,
                        style: theme.textTheme.labelSmall
                            ?.copyWith(color: AppColors.textSecondary)),
                    Text(r.$2!, style: theme.textTheme.bodyMedium),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
