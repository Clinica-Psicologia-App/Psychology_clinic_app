import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../patients/presentation/widgets/patient_context_header.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import 'initial_assessment_routes.dart';
import '../domain/initial_assessment.dart';
import '../domain/life_area.dart';
import '../domain/life_area_assessment.dart';
import '../domain/patient_basics.dart';
import '../providers/initial_assessment_providers.dart';
import 'widgets/life_area_card.dart';
import 'widgets/life_area_wheel_chart.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Tela 1 do fluxo Conhecer na lente do paciente — Blocos 2 e 3.
/// (O Bloco 1 vive na tabela `patients` e será integrado separadamente; o
/// Bloco 4 é exclusivo do terapeuta.)
class InitialAssessmentPatientPage extends ConsumerStatefulWidget {
  const InitialAssessmentPatientPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  ConsumerState<InitialAssessmentPatientPage> createState() =>
      _InitialAssessmentPatientPageState();
}

class _InitialAssessmentPatientPageState
    extends ConsumerState<InitialAssessmentPatientPage> {
  // Bloco 1
  final _preferredName = TextEditingController();
  final _occupation = TextEditingController();
  final _livesWith = TextEditingController();
  final _childrenNotes = TextEditingController();
  final _medicationNotes = TextEditingController();
  final _psychiatristNotes = TextEditingController();
  final _importantToKnow = TextEditingController();
  DateTime? _birthDate;
  bool _hasChildren = false;
  bool _usesMedication = false;
  bool _psychiatricFollowup = false;
  String? _fullName;

  // Bloco 2
  final _reason = TextEditingController();
  final _duration = TextEditingController();
  final _discomfort = TextEditingController();
  final _expectations = TextEditingController();
  final _relatedEvent = TextEditingController();

  // Bloco 3 — estado das 12 áreas
  final Map<LifeArea, int?> _scores = {};
  final Map<LifeArea, int?> _sufferings = {};
  final Map<LifeArea, TextEditingController> _guided = {};

  bool _initialized = false;

  // Salvamento (#21): foto dos campos já gravados e save em andamento.
  String? _savedSnapshot;
  Future<bool>? _saving;
  Object? _lastError;
  bool _dirtyFlag = false;

  // Etapa atual do indicador (#14), conforme a rolagem.
  final _scroll = ScrollController();
  final _listKey = GlobalKey();
  final _stepKeys = [GlobalKey(), GlobalKey(), GlobalKey()];
  final _step = ValueNotifier<int>(0);

  InitialAssessmentContext get _ctx => InitialAssessmentContext(
        role: widget.role,
        patientId: widget.patientId,
      );

  List<TextEditingController> get _allControllers => [
        _preferredName,
        _occupation,
        _livesWith,
        _childrenNotes,
        _medicationNotes,
        _psychiatristNotes,
        _importantToKnow,
        _reason,
        _duration,
        _discomfort,
        _expectations,
        _relatedEvent,
        ..._guided.values,
      ];

  /// Há alteração ainda não gravada?
  bool get _isDirty => _initialized && _snapshot() != _savedSnapshot;

  /// Mantém o `PopScope` em dia quando só o texto muda.
  void _recheckDirty() {
    if (!mounted) return;
    final d = _isDirty;
    if (d != _dirtyFlag) setState(() => _dirtyFlag = d);
  }

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateStep);
  }

  /// Etapa visível: a última seção cujo topo já passou da linha de leitura.
  void _updateStep() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    var step = 0;
    if (pos.maxScrollExtent > 0 && pos.pixels >= pos.maxScrollExtent - 4) {
      step = 2;
    } else {
      final list = _listKey.currentContext?.findRenderObject();
      if (list is! RenderBox || !list.attached) return;
      final listTop = list.localToGlobal(Offset.zero).dy;
      for (var i = 0; i < _stepKeys.length; i++) {
        final r = _stepKeys[i].currentContext?.findRenderObject();
        if (r is! RenderBox || !r.attached) continue;
        final top = r.localToGlobal(Offset.zero).dy - listTop;
        if (top <= 140) step = i;
      }
    }
    if (_step.value != step) _step.value = step;
  }

  @override
  void dispose() {
    _scroll.dispose();
    _step.dispose();
    for (final c in _allControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFromData(InitialAssessment data) {
    if (_initialized) return;

    final basics = data.basics;
    _fullName = basics?.fullName;
    _preferredName.text = basics?.preferredName ?? '';
    _occupation.text = basics?.occupation ?? '';
    _livesWith.text = basics?.livesWith ?? '';
    _childrenNotes.text = basics?.childrenNotes ?? '';
    _medicationNotes.text = basics?.medicationNotes ?? '';
    _psychiatristNotes.text = basics?.psychiatristNotes ?? '';
    _importantToKnow.text = basics?.importantToKnow ?? '';
    _birthDate = basics?.birthDate;
    _hasChildren = basics?.hasChildren ?? false;
    _usesMedication = basics?.usesMedication ?? false;
    _psychiatricFollowup = basics?.psychiatricFollowup ?? false;

    final intake = data.intake;
    _reason.text = intake?.reasonForSeeking ?? '';
    _duration.text = intake?.problemDuration ?? '';
    _discomfort.text = intake?.mainDiscomfort ?? '';
    _expectations.text = intake?.expectations ?? '';
    _relatedEvent.text = intake?.relatedEvent ?? '';

    for (final area in kLifeAreasInOrder) {
      final a = data.lifeAreaFor(area);
      _scores[area] = a.score;
      _sufferings[area] = a.suffering;
      _guided[area] = TextEditingController(text: a.guidedAnswer ?? '');
    }
    _initialized = true;
    _savedSnapshot = _snapshot();
    for (final c in _allControllers) {
      c.addListener(_recheckDirty);
    }
  }

  List<LifeAreaAssessment> _collectAreas() {
    final result = <LifeAreaAssessment>[];
    for (final area in kLifeAreasInOrder) {
      final score = _scores[area];
      final suffering = _sufferings[area];
      final guided = _guided[area]?.text.trim();
      final hasAny =
          score != null || suffering != null || (guided ?? '').isNotEmpty;
      if (!hasAny) continue;
      result.add(LifeAreaAssessment(
        area: area,
        score: score,
        suffering: suffering,
        guidedAnswer: (guided ?? '').isEmpty ? null : guided,
      ));
    }
    return result;
  }

  String? _nullIfEmpty(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Data de nascimento',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  /// Foto de todos os campos editáveis, para saber se algo mudou.
  String _snapshot() => [
        _preferredName.text,
        _occupation.text,
        _livesWith.text,
        _hasChildren ? _childrenNotes.text : '',
        _medicationNotes.text,
        _psychiatristNotes.text,
        _importantToKnow.text,
        _birthDate?.toIso8601String(),
        _hasChildren,
        _usesMedication,
        _psychiatricFollowup,
        _reason.text,
        _duration.text,
        _discomfort.text,
        _expectations.text,
        _relatedEvent.text,
        for (final area in kLifeAreasInOrder) ...[
          _scores[area],
          _sufferings[area],
          _guided[area]?.text,
        ],
      ].join('\u0001');

  /// Captura os valores AGORA e devolve a gravação (mesmo fluxo do botão
  /// Salvar). Não depende do `context` depois de chamada.
  Future<void> Function() _prepareSave() {
    final notifier = ref.read(initialAssessmentMutationProvider(_ctx).notifier);
    final preferredName = _nullIfEmpty(_preferredName.text);
    final birthDate = _birthDate;
    final occupation = _nullIfEmpty(_occupation.text);
    final livesWith = _nullIfEmpty(_livesWith.text);
    final hasChildren = _hasChildren;
    final childrenNotes =
        hasChildren ? _nullIfEmpty(_childrenNotes.text) : null;
    final usesMedication = _usesMedication;
    final medicationNotes =
        usesMedication ? _nullIfEmpty(_medicationNotes.text) : null;
    final psychiatricFollowup = _psychiatricFollowup;
    final psychiatristNotes =
        psychiatricFollowup ? _nullIfEmpty(_psychiatristNotes.text) : null;
    final importantToKnow = _nullIfEmpty(_importantToKnow.text);
    final reason = _reason.text.trim();
    final duration = _duration.text.trim();
    final discomfort = _discomfort.text.trim();
    final expectations = _expectations.text.trim();
    final relatedEvent = _relatedEvent.text.trim();
    final areas = _collectAreas();
    return () async {
      await notifier.savePatientBasics(
        preferredName: preferredName,
        birthDate: birthDate,
        occupation: occupation,
        livesWith: livesWith,
        hasChildren: hasChildren,
        childrenNotes: childrenNotes,
        usesMedication: usesMedication,
        medicationNotes: medicationNotes,
        psychiatricFollowup: psychiatricFollowup,
        psychiatristNotes: psychiatristNotes,
        importantToKnow: importantToKnow,
      );
      await notifier.saveIntake(
        reasonForSeeking: reason,
        problemDuration: duration,
        mainDiscomfort: discomfort,
        expectations: expectations,
        relatedEvent: relatedEvent,
      );
      await notifier.saveLifeAreas(areas);
    };
  }

  /// Grava tudo (mesma gravação do botão, da saída e da navegação). Se já
  /// houver gravação em andamento, devolve o MESMO Future. Nunca lança:
  /// `true` = gravou; `false` = falhou (erro em [_lastError]) e a tela
  /// continua com alteração pendente.
  Future<bool> _saveOnce() {
    final running = _saving;
    if (running != null) return running;
    final f = _doSave().whenComplete(() {
      _saving = null;
      if (mounted) setState(() {});
    });
    _saving = f;
    if (mounted) setState(() {});
    return f;
  }

  Future<bool> _doSave() async {
    try {
      final snap = _snapshot();
      final run = _prepareSave();
      await run();
      _savedSnapshot = snap; // só depois do sucesso
      _lastError = null;
      return true;
    } catch (e) {
      _lastError = e;
      return false;
    }
  }

  void _snack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  /// Abre outra tela só depois de gravar o que mudou; se falhar, fica aqui.
  Future<void> _pushSaving(String route) async {
    if (_isDirty) {
      final ok = await _saveOnce();
      if (!mounted) return;
      if (!ok) {
        _snack('Não foi possível salvar. Tente de novo antes de continuar.');
        return;
      }
    }
    context.push(route);
  }

  Future<void> _save() async {
    final ok = await _saveOnce();
    if (!mounted) return;
    if (ok) {
      _snack('Avaliação salva.');
    } else {
      showErrorBanner(context, _lastError ?? 'Não foi possível salvar.');
    }
  }

  /// Saída com alteração pendente: pergunta o que fazer.
  Future<void> _onPopBlocked() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Você tem informações não salvas'),
        content: const Text('Deseja salvar antes de sair?'),
        actions: [
          TextButton(
            key: const Key('exit_continue'),
            onPressed: () => Navigator.of(ctx).pop('continue'),
            child: const Text('Continuar editando'),
          ),
          TextButton(
            key: const Key('exit_discard'),
            onPressed: () => Navigator.of(ctx).pop('discard'),
            child: const Text('Sair sem salvar'),
          ),
          FilledButton(
            key: const Key('exit_save'),
            onPressed: () => Navigator.of(ctx).pop('save'),
            child: const Text('Salvar e sair'),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (choice == 'discard') {
      Navigator.of(context).pop();
    } else if (choice == 'save') {
      final ok = await _saveOnce();
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
      } else {
        _snack('Não foi possível salvar. Você continua nesta tela.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    _dirtyFlag = _isDirty;
    final async = ref.watch(initialAssessmentProvider(_ctx));
    final saving = _saving != null ||
        ref.watch(initialAssessmentMutationProvider(_ctx)).isLoading;

    return PopScope(
        canPop: !_isDirty && _saving == null,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_saving != null) {
            _snack('Aguarde, salvando…');
            return;
          }
          _onPopBlocked();
        },
        child: AppCanopyScaffold(
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: PatientContextHeader(
                  patientId: widget.patientId,
                  pageTitle: 'CONHECENDO VOCÊ',
                  role: widget.role,
                  accentColor: AppColors.cyan,
                  onBack: () => Navigator.of(context).maybePop(),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: true,
                child: AsyncStateBody<InitialAssessment>(
                  asyncValue: async,
                  onRetry: () =>
                      ref.invalidate(initialAssessmentProvider(_ctx)),
                  dataBuilder: (data) {
                    _initFromData(data);
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          child: _stepsIndicator(context),
                        ),
                        Expanded(
                          child: Stack(
                            children: [
                              // Enquanto grava, o formulário inteiro fica travado (toque e foco).
                              ExcludeFocus(
                                  excluding: saving,
                                  child: IgnorePointer(
                                      ignoring: saving,
                                      child: ListView(
                                        key: _listKey,
                                        controller: _scroll,
                                        padding: const EdgeInsets.fromLTRB(
                                            16, 14, 16, 96),
                                        children: [
                                          _section(
                                            context,
                                            key: _stepKeys[0],
                                            icon: Icons.waving_hand_outlined,
                                            accent: AppColors.turquoise,
                                            title: 'Conhecendo você',
                                            subtitle:
                                                'Antes de começarmos, queremos conhecer um pouco sobre você.',
                                            children: [
                                              if ((_fullName ?? '').isNotEmpty)
                                                Padding(
                                                  padding:
                                                      const EdgeInsets.only(
                                                          bottom: 12),
                                                  child: InputDecorator(
                                                    decoration:
                                                        const InputDecoration(
                                                      labelText: 'Nome',
                                                      helperText:
                                                          'Para alterar, fale com seu psicólogo.',
                                                      prefixIcon: Icon(
                                                          Icons.lock_outline,
                                                          size: 18),
                                                    ),
                                                    child: Text(_fullName!),
                                                  ),
                                                ),
                                              _field(_preferredName,
                                                  'Como prefere ser chamado(a)?'),
                                              _birthDateField(context),
                                              _field(_occupation, 'Profissão'),
                                              _field(
                                                _livesWith,
                                                'Com quem você mora?',
                                                helper:
                                                    'Você pode mencionar familiares, companheiro(a), '
                                                    'amigos ou se mora sozinho(a).',
                                              ),
                                              _switchTile(
                                                'Tem filhos?',
                                                _hasChildren,
                                                (v) => setState(() {
                                                  _hasChildren = v;
                                                  if (!v) _childrenNotes.clear();
                                                }),
                                              ),
                                              if (_hasChildren)
                                                _field(
                                                  _childrenNotes,
                                                  'Conte sobre seus filhos (nomes e idades)',
                                                  maxLength: 1000,
                                                  fieldKey: const ValueKey(
                                                      'children_notes_field'),
                                                ),
                                              _switchTile(
                                                'Faz uso de algum medicamento?',
                                                _usesMedication,
                                                (v) => setState(
                                                    () => _usesMedication = v),
                                              ),
                                              if (_usesMedication)
                                                _field(
                                                  _medicationNotes,
                                                  'Qual medicação? (opcional)',
                                                  helper:
                                                      'Informar nome e, se desejar, dosagem.',
                                                ),
                                              _switchTile(
                                                'Tem acompanhamento psiquiátrico?',
                                                _psychiatricFollowup,
                                                (v) => setState(() =>
                                                    _psychiatricFollowup = v),
                                              ),
                                              if (_psychiatricFollowup)
                                                _field(_psychiatristNotes,
                                                    'Detalhes do acompanhamento (opcional)'),
                                              _field(
                                                _importantToKnow,
                                                'Existe algo importante sobre você que gostaria que seu '
                                                'terapeuta soubesse?',
                                              ),
                                            ],
                                          ),
                                          _section(
                                            context,
                                            key: _stepKeys[1],
                                            icon: Icons.chat_bubble_outline,
                                            accent: AppColors.blue,
                                            title: 'O que está acontecendo?',
                                            subtitle:
                                                'Conte um pouco sobre o que está acontecendo na sua vida '
                                                'e o que fez você procurar terapia neste momento.',
                                            children: [
                                              _field(_reason,
                                                  'O que fez você procurar terapia agora?'),
                                              _field(_duration,
                                                  'Há quanto tempo isso acontece?'),
                                              _field(_discomfort,
                                                  'O que mais incomoda hoje?'),
                                              _field(_expectations,
                                                  'O que espera que seja diferente após a terapia?'),
                                              _field(_relatedEvent,
                                                  'Existe algum acontecimento importante relacionado a isso?'),
                                            ],
                                          ),
                                          KeyedSubtree(
                                              key: _stepKeys[2],
                                              child: _sectionHeader(
                                                context,
                                                icon: Icons.spa_outlined,
                                                accent: AppColors.purple,
                                                title:
                                                    'Como está sua vida hoje?',
                                                subtitle:
                                                    'Cada área da nossa vida pode estar em um momento '
                                                    'diferente. Pense em como você se sente em relação a '
                                                    'cada uma delas e indique sua percepção neste momento.',
                                              )),
                                          const SizedBox(height: 14),
                                          Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 16),
                                            child: DecoratedBox(
                                              decoration: BoxDecoration(
                                                color:
                                                    Theme.of(context).cardColor,
                                                borderRadius:
                                                    BorderRadius.circular(16),
                                                boxShadow: [
                                                  BoxShadow(
                                                    color: AppColors.navy
                                                        .withValues(
                                                            alpha: 0.07),
                                                    blurRadius: 10,
                                                    offset: const Offset(0, 2),
                                                  ),
                                                ],
                                              ),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.all(16),
                                                child: LifeAreaWheelChart(
                                                    scores: _scores),
                                              ),
                                            ),
                                          ),
                                          for (final area in kLifeAreasInOrder)
                                            LifeAreaCard(
                                              area: area,
                                              score: _scores[area],
                                              suffering: _sufferings[area],
                                              guidedController: _guided[area]!,
                                              onScoreChanged: (v) => setState(
                                                  () => _scores[area] = v),
                                              onSufferingChanged: (v) =>
                                                  setState(() =>
                                                      _sufferings[area] = v),
                                            ),
                                          const SizedBox(height: 12),
                                          ClayCard(
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            child: ListTile(
                                              leading: const Icon(
                                                  Icons.history_edu_outlined),
                                              title:
                                                  const Text('Minha História'),
                                              subtitle: const Text(
                                                  'Conte os momentos marcantes da sua vida.'),
                                              trailing: const Icon(
                                                  Icons.chevron_right),
                                              onTap: () => _pushSaving(
                                                  InitialAssessmentRoutes
                                                      .patientHistory),
                                            ),
                                          ),
                                          ClayCard(
                                            margin: const EdgeInsets.only(
                                                bottom: 10),
                                            child: ListTile(
                                              leading: const Icon(Icons
                                                  .family_restroom_outlined),
                                              title:
                                                  const Text('Minha Família'),
                                              subtitle: const Text(
                                                  'As pessoas da sua história e como eram essas relações.'),
                                              trailing: const Icon(
                                                  Icons.chevron_right),
                                              onTap: () => _pushSaving(
                                                  InitialAssessmentRoutes
                                                      .patientFamily),
                                            ),
                                          ),
                                        ],
                                      ))),
                              if (saving)
                                const Positioned(
                                  left: 0,
                                  right: 0,
                                  top: 0,
                                  child: LinearProgressIndicator(minHeight: 3),
                                ),
                              Positioned(
                                left: 16,
                                right: 16,
                                bottom: 16,
                                child: FilledButton.icon(
                                  onPressed: saving ? null : _save,
                                  icon: saving
                                      ? const SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.check),
                                  label: Text(saving
                                      ? 'Salvando...'
                                      : 'Salvar informações'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ));
  }

  /// Indicador das 3 partes da tela: atual em destaque, concluídas em
  /// turquesa suave e as que faltam em cinza.
  Widget _stepsIndicator(BuildContext context) {
    final theme = Theme.of(context);
    const labels = ['Sobre você', 'O que houve', 'Sua vida'];
    return ValueListenableBuilder<int>(
      valueListenable: _step,
      builder: (context, current, _) => Row(
        children: [
          for (var i = 0; i < labels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  AnimatedContainer(
                    key: Key('step_bar_$i'),
                    duration: const Duration(milliseconds: 200),
                    height: i == current ? 6 : 4,
                    decoration: BoxDecoration(
                      color: i == current
                          ? AppColors.turquoise
                          : i < current
                              ? AppColors.turquoise.withValues(alpha: 0.45)
                              : theme.colorScheme.outline
                                  .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    labels[i],
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight:
                          i == current ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 9.5,
                      color: i == current
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// Cabeçalho de seção: ícone tintado + título + subtítulo.
  Widget _sectionHeader(
    BuildContext context, {
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: accent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  /// Seção em card: cabeçalho + campos.
  Widget _section(
    BuildContext context, {
    Key? key,
    required IconData icon,
    required Color accent,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      key: key,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(context,
              icon: icon, accent: accent, title: title, subtitle: subtitle),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _field(
    TextEditingController controller,
    String label, {
    String? helper,
    int? maxLength,
    Key? fieldKey,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: fieldKey,
        controller: controller,
        minLines: 1,
        maxLines: 4,
        maxLength: maxLength,

        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(
          labelText: label,
          helperText: helper,
          helperMaxLines: 3,
        ),
      ),
    );
  }

  Widget _birthDateField(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final date = _birthDate;
    final age = date == null ? null : PatientBasics(birthDate: date).age;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _pickBirthDate,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Data de nascimento',
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            helperText: age == null ? null : '$age anos',
          ),
          child: Text(
            date == null ? 'Toque para selecionar' : loc.formatFullDate(date),
            style: date == null
                ? TextStyle(color: Theme.of(context).hintColor)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label),
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }
}
