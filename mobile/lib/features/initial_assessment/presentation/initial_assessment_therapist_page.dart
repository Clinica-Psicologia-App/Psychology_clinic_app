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
import '../domain/patient_basics.dart';
import '../providers/initial_assessment_providers.dart';
import '../../profile/domain/profile_role.dart' show ProfileRole;
import '../../profile/presentation/widgets/user_avatar.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';
import 'widgets/life_area_wheel_chart.dart';

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
      accent: AppColors.turquoise,
      body: AsyncStateBody<InitialAssessment>(
        asyncValue: async,
        onRetry: () => ref.invalidate(initialAssessmentProvider(_ctx)),
        dataBuilder: (data) {
          _initFromData(data);
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
                children: [
                  // ── Bloco 1 — Dados do Paciente (campo privado) ──────────
                  _sectionHeader(
                    context,
                    step: 'Bloco 1',
                    title: 'Dados do Paciente',
                    icon: Icons.person_outline,
                    accent: AppColors.navy,
                    subtitle:
                        'Informações gerais preenchidas pelo paciente + sua nota clínica.',
                  ),
                  if (data.basics != null)
                    _PatientBasicsCard(basics: data.basics!),
                  _group(
                    context,
                    title: 'Nota clínica inicial',
                    icon: Icons.lock_outline,
                    children: [
                      _field(_observations, 'Observações iniciais',
                          hint: 'Visível apenas para você', privateNote: true),
                    ],
                  ),

                  // ── Bloco 2 — Motivo da Procura ──────────────────────────
                  _sectionHeader(
                    context,
                    step: 'Bloco 2',
                    title: 'Motivo da Procura / Queixa Atual',
                    icon: Icons.record_voice_over_outlined,
                    accent: AppColors.blue,
                    subtitle:
                        'O que o paciente trouxe e a sua leitura clínica.',
                  ),
                  if (data.intake != null) _PatientIntakeCard(data: data),
                  _group(
                    context,
                    title: 'Sua leitura clínica',
                    icon: Icons.edit_note_outlined,
                    children: [
                      _field(_complaint, 'Queixa principal'),
                      _field(_problem, 'Problema atual'),
                      _field(_factors, 'Fatores precipitantes'),
                      _field(_goals, 'Objetivos do paciente'),
                      _field(_motivation, 'Motivação'),
                      _field(_initialHypotheses, 'Hipóteses iniciais'),
                    ],
                  ),

                  // ── Bloco 3 — Funcionamento Atual ────────────────────────
                  _sectionHeader(
                    context,
                    step: 'Bloco 3',
                    title: 'Funcionamento Atual',
                    icon: Icons.tune_outlined,
                    accent: AppColors.turquoise,
                    subtitle: 'Satisfação e sofrimento por área da vida.',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.07),
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

                  // ── Bloco 4 — Primeiras Impressões Clínicas ──────────────
                  _sectionHeader(
                    context,
                    step: 'Bloco 4',
                    title: 'Primeiras Impressões Clínicas',
                    icon: Icons.psychology_alt_outlined,
                    accent: AppColors.purple,
                    subtitle: 'Sua síntese após o primeiro contato.',
                  ),
                  _group(
                    context,
                    title: 'Impressão geral',
                    icon: Icons.visibility_outlined,
                    children: [
                      _field(_temperament, 'Temperamento observado'),
                      _field(_bond, 'Vínculo terapêutico'),
                      _field(_resources, 'Recursos'),
                      _field(_vulnerabilities, 'Vulnerabilidades'),
                    ],
                  ),
                  _group(
                    context,
                    title: 'Perspectiva diagnóstica',
                    icon: Icons.biotech_outlined,
                    children: [
                      _field(_dxHypotheses, 'Hipóteses'),
                      _field(_prevDx, 'Diagnósticos prévios'),
                      _field(_diffDx, 'Diagnóstico diferencial'),
                    ],
                  ),
                  _group(
                    context,
                    title: 'Nível atual de funcionamento',
                    icon: Icons.speed_outlined,
                    children: [_functioningLevelSelector(context)],
                  ),
                  _group(
                    context,
                    title: 'Hipóteses de esquemas',
                    icon: Icons.schema_outlined,
                    children: [
                      _field(_schemaHypothesesText, 'Hipóteses de esquemas'),
                      _field(_modeHypothesesText, 'Hipóteses de modos'),
                      _field(_emotionalNeedsText,
                          'Necessidades emocionais percebidas'),
                    ],
                  ),
                  _group(
                    context,
                    title: 'Prioridades terapêuticas',
                    icon: Icons.flag_outlined,
                    children: [
                      _field(_priorities, 'Prioridades terapêuticas'),
                    ],
                  ),

                  // ── Aprofundar ───────────────────────────────────────────
                  _sectionHeader(
                    context,
                    step: 'Aprofundar',
                    title: 'História e vínculos',
                    icon: Icons.explore_outlined,
                    accent: AppColors.cyan,
                    subtitle: 'Linha do tempo e genograma emocional.',
                  ),
                  _navCard(
                    icon: Icons.timeline_outlined,
                    title: 'Linha do Tempo',
                    subtitle: 'História de vida, eventos e crenças formadas.',
                    onTap: () => context.push(
                      InitialAssessmentRoutes.staffHistory(
                        role: widget.role,
                        patientId: widget.patientId,
                      ),
                    ),
                  ),
                  _navCard(
                    icon: Icons.family_restroom_outlined,
                    title: 'Genograma emocional',
                    subtitle:
                        'Vínculos, figuras de apego, clima e padrões familiares.',
                    onTap: () => context.push(
                      InitialAssessmentRoutes.staffFamily(
                        role: widget.role,
                        patientId: widget.patientId,
                      ),
                    ),
                  ),
                ],
              ),
              // Barra de salvar fixa, com leve degradê para o conteúdo não
              // "grudar" no botão ao rolar.
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
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(
                        _saving ? 'Salvando...' : 'Salvar conceitualização'),
                  ),
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
                  child: Text(group.label,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < areas.length; i++) ...[
              if (i > 0) const Divider(height: 20, color: AppColors.border),
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
              child: Text(area.label,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.w600)),
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
                color: AppColors.surfaceTint,
                borderRadius: BorderRadius.circular(10),
                border: const Border(
                  left: BorderSide(color: AppColors.cyan, width: 2.5),
                ),
              ),
              child: Text('"${a.guidedAnswer}"',
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic,
                      height: 1.4)),
            ),
          ),
        const SizedBox(height: 8),
        TextField(
          controller: _comments[area],
          minLines: 1,
          maxLines: 3,
          decoration: _fieldDecoration('Comentário clínico'),
        ),
      ],
    );
  }

  /// Selo compacto de nota (0–10) com cor de acento.
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
          Text(label,
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: color,
              )),
          const SizedBox(width: 4),
          Text('$value',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              )),
          Text('/10',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                color: color.withValues(alpha: 0.7),
              )),
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

  /// Cabeçalho de bloco: selo tonal com número + ícone + título + subtítulo.
  Widget _sectionHeader(
    BuildContext context, {
    required String step,
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
                Text(step.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    )),
                Text(title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                      height: 1.15,
                    )),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.textMuted,
                        height: 1.3,
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Card temático que agrupa campos do terapeuta sob um subtítulo.
  Widget _group(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: AppColors.cyan),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy,
                      )),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _navCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color accent = AppColors.cyan,
  }) {
    return ClayCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: accent, size: 20),
        ),
        title: Text(title,
            style: const TextStyle(
                fontWeight: FontWeight.w700, color: AppColors.navy)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
        onTap: onTap,
      ),
    );
  }

  InputDecoration _fieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      filled: true,
      fillColor: AppColors.surfaceTint,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.cyan, width: 1.5),
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? hint,
    bool privateNote = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 4,
            textInputAction: TextInputAction.newline,
            decoration: _fieldDecoration(label, hint: hint),
          ),
          if (privateNote)
            const Padding(
              padding: EdgeInsets.only(top: 4, left: 4),
              child: Row(
                children: [
                  Icon(Icons.lock_outline,
                      size: 12, color: AppColors.textMuted),
                  SizedBox(width: 4),
                  Text('Só você vê este campo',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      )),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Resumo (read-only) dos dados básicos do paciente no Bloco 1.
class _PatientBasicsCard extends StatelessWidget {
  const _PatientBasicsCard({required this.basics});

  final PatientBasics basics;

  static String? _humanize(String? raw, Map<String, String> map) {
    if (raw == null || raw.isEmpty) return null;
    return map[raw.toLowerCase()] ?? raw;
  }

  static String? _relStatus(String? v) => _humanize(v, const {
        'single': 'Solteiro(a)',
        'solteiro': 'Solteiro(a)',
        'married': 'Casado(a)',
        'casado': 'Casado(a)',
        'divorced': 'Divorciado(a)',
        'divorciado': 'Divorciado(a)',
        'widowed': 'Viúvo(a)',
        'viuvo': 'Viúvo(a)',
        'stable_union': 'União estável',
        'uniao_estavel': 'União estável',
        'nao_informado': 'Não informado',
      });

  static String? _sexOrientation(String? v) => _humanize(v, const {
        'heterosexual': 'Heterossexual',
        'homosexual': 'Homossexual',
        'bisexual': 'Bissexual',
        'asexual': 'Assexual',
        'pansexual': 'Pansexual',
        'nao_informado': 'Não informado',
      });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Monta a lista de pares (rótulo, valor) filtrando nulos e vazios.
    String? _age() {
      final a = basics.age;
      final b = basics.birthDate;
      if (a == null && b == null) return null;
      if (a != null && b != null) {
        return '$a anos (${b.day.toString().padLeft(2, '0')}/${b.month.toString().padLeft(2, '0')}/${b.year})';
      }
      return a != null ? '$a anos' : null;
    }

    final rows = <(String, String?)>[
      ('Nome preferido', basics.preferredName ?? basics.fullName),
      ('Idade', _age()),
      ('Profissão/Ocupação', basics.occupation),
      ('Com quem mora', basics.livesWith),
      if (basics.hasChildren != null)
        ('Tem filhos', basics.hasChildren! ? 'Sim' : 'Não'),
      if (basics.usesMedication != null)
        ('Usa medicação', basics.usesMedication! ? 'Sim' : 'Não'),
      if ((basics.medicationNotes ?? '').isNotEmpty)
        ('Medicação', basics.medicationNotes),
      if (basics.psychiatricFollowup != null)
        ('Acomp. psiquiátrico', basics.psychiatricFollowup! ? 'Sim' : 'Não'),
      if ((basics.psychiatristNotes ?? '').isNotEmpty)
        ('Psiquiatra', basics.psychiatristNotes),
      if ((basics.importantToKnow ?? '').isNotEmpty)
        ('Algo importante', basics.importantToKnow),
    ].where((r) => (r.$2 ?? '').trim().isNotEmpty).toList();

    final extraRows = <(String, String?)>[
      ('Estado civil', _relStatus(basics.relationshipStatus)),
      ('Orientação sexual', _sexOrientation(basics.sexualOrientation)),
      ('País de nascimento', basics.countryBirth),
      ('Grupo étnico', basics.ethnicGroup),
      ('Religião/Espiritualidade', basics.religiousOrientation),
    ].where((r) => (r.$2 ?? '').trim().isNotEmpty).toList();

    if (rows.isEmpty && extraRows.isEmpty) return const SizedBox.shrink();

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                UserAvatar.parts(
                  fullName: basics.fullName ?? basics.preferredName ?? '',
                  initials: basics.initials,
                  role: ProfileRole.patient,
                  avatarType: basics.avatarType,
                  photoUrl: basics.photoUrl,
                  avatarConfig: basics.avatarConfig,
                  size: 44,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dados do paciente',
                          style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.navy)),
                      Text('Preenchidos na ficha',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                    height: 14, color: AppColors.navy.withValues(alpha: 0.08)),
              _InfoRow(label: rows[i].$1, value: rows[i].$2!),
            ],
            if (extraRows.isNotEmpty) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceTint,
                  borderRadius: BorderRadius.circular(10),
                  border: const Border(
                    left: BorderSide(color: AppColors.navy, width: 2.5),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Dados complementares',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                        )),
                    const SizedBox(height: 6),
                    for (var i = 0; i < extraRows.length; i++) ...[
                      if (i > 0)
                        Divider(
                            height: 12,
                            color: AppColors.navy.withValues(alpha: 0.08)),
                      _InfoRow(label: extraRows[i].$1, value: extraRows[i].$2!),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
              fontSize: 10,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppColors.navy,
              height: 1.35,
            ),
          ),
        ),
      ],
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

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 16),
      color: AppColors.surfaceTintBlue,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.format_quote_rounded,
                      size: 18, color: AppColors.cyan),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Respostas do paciente',
                          style: theme.textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.cyan)),
                      Text('Na avaliação inicial',
                          style: theme.textTheme.labelSmall
                              ?.copyWith(color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < rows.length; i++) ...[
              if (i > 0)
                Divider(
                    height: 18, color: AppColors.cyan.withValues(alpha: 0.15)),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(rows[i].$1.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.4,
                        fontSize: 10,
                      )),
                  const SizedBox(height: 3),
                  Text(rows[i].$2!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.navy,
                        height: 1.35,
                      )),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
