import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show FilteringTextInputFormatter;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/case_conceptualization.dart';
import '../providers/case_conceptualization_providers.dart';
import '../../initial_assessment/presentation/initial_assessment_routes.dart';
import '../../patient_problems/presentation/patient_problem_routes.dart';
import '../../personality_assessment/domain/personality_assessment.dart';
import '../../personality_assessment/providers/personality_assessment_providers.dart';
import '../../personality_assessment/presentation/personality_assessment_routes.dart';
import '../../questionnaires/presentation/questionnaire_routes.dart';
import '../../therapy_demands/presentation/therapy_demands_routes.dart';
import '../../patients/presentation/patient_routes.dart';

/// Edição dos campos do terapeuta da Conceitualização de caso (Síntese):
/// necessidades não atendidas (7.2), sequência de modos (10) e relação
/// terapêutica (11). As demais seções vêm da agregação e não são editadas aqui.
class CaseConceptualizationEditPage extends ConsumerWidget {
  const CaseConceptualizationEditPage({
    super.key,
    required this.role,
    required this.patientId,
    this.focus,
  });

  final ProfileRole role;
  final String patientId;

  /// Item a mostrar ao abrir (ex.: `7.1`): o editor rola até o cartão dele.
  final String? focus;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Garante o documento carregado antes de montar o formulário (o prefill
    // depende disso — senão os controllers nasceriam vazios e um salvar
    // apagaria o conteúdo existente).
    final async = ref.watch(caseConceptualizationProvider(patientId));
    return async.when(
      loading: () => const AppScaffold(
        title: 'Editar conceitualização',
        accent: AppColors.navy,
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => AppScaffold(
        title: 'Editar conceitualização',
        accent: AppColors.navy,
        body: Center(
          child: FilledButton(
            onPressed: () =>
                ref.invalidate(caseConceptualizationProvider(patientId)),
            child: const Text('Tentar novamente'),
          ),
        ),
      ),
      data: (data) => _EditForm(
        role: role,
        patientId: patientId,
        initial: data,
        focus: focus,
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({
    required this.role,
    required this.patientId,
    required this.initial,
    this.focus,
  });

  final ProfileRole role;
  final String patientId;
  final CaseConceptualization initial;
  final String? focus;

  @override
  ConsumerState<_EditForm> createState() => _EditState();
}

class _NeedCtrls {
  _NeedCtrls(this.key, this.label, {this.rating, String? origin, String? schemas})
      : origin = TextEditingController(text: origin ?? ''),
        schemas = TextEditingController(text: schemas ?? '');
  final String key;
  final String label;
  String? rating;
  final TextEditingController origin;
  final TextEditingController schemas;
  void dispose() {
    origin.dispose();
    schemas.dispose();
  }
}

class _SeqCtrls {
  _SeqCtrls([ModeSequence? s])
      : trigger = TextEditingController(text: s?.trigger ?? ''),
        modes = TextEditingController(text: s?.activatedModes ?? ''),
        coping = TextEditingController(text: s?.copingMode ?? ''),
        sequence = TextEditingController(text: s?.sequence ?? ''),
        effect = TextEditingController(text: s?.effect ?? ''),
        perpetuation = TextEditingController(text: s?.perpetuation ?? '');
  final TextEditingController trigger;
  final TextEditingController modes;
  final TextEditingController coping;
  final TextEditingController sequence;
  final TextEditingController effect;
  final TextEditingController perpetuation;

  ModeSequence toModel() => ModeSequence(
        trigger: trigger.text,
        activatedModes: modes.text,
        copingMode: coping.text,
        sequence: sequence.text,
        effect: effect.text,
        perpetuation: perpetuation.text,
      );

  void dispose() {
    trigger.dispose();
    modes.dispose();
    coping.dispose();
    sequence.dispose();
    effect.dispose();
    perpetuation.dispose();
  }
}

class _FuncCtrls {
  _FuncCtrls(this.areaKey,
      {this.rating, String? explanation, this.notApplicable = false})
      : explanation = TextEditingController(text: explanation ?? '');
  final String areaKey;
  int? rating;
  bool notApplicable;
  final TextEditingController explanation;
  void dispose() => explanation.dispose();
}

class _ExampleCtrls {
  _ExampleCtrls([ModeExample? e])
      : trigger = TextEditingController(text: e?.trigger ?? ''),
        experience = TextEditingController(text: e?.experience ?? ''),
        coping = TextEditingController(text: e?.coping ?? '');
  final TextEditingController trigger;
  final TextEditingController experience;
  final TextEditingController coping;
  ModeExample toModel() =>
      ModeExample(trigger: trigger.text, experience: experience.text, coping: coping.text);
  void dispose() {
    trigger.dispose();
    experience.dispose();
    coping.dispose();
  }
}

class _CentralSchemaCtrls {
  _CentralSchemaCtrls([CentralSchemaEntry? e])
      : name = TextEditingController(text: e?.name ?? ''),
        description = TextEditingController(text: e?.description ?? '');
  final TextEditingController name;
  final TextEditingController description;
  CentralSchemaEntry toModel() =>
      CentralSchemaEntry(name: name.text, description: description.text);
  void dispose() {
    name.dispose();
    description.dispose();
  }
}

class _ParentalModeCtrls {
  _ParentalModeCtrls([ParentalModeEntry? e])
      : name = TextEditingController(text: e?.name ?? ''),
        messages = TextEditingController(text: e?.messages ?? '');
  final TextEditingController name;
  final TextEditingController messages;
  ParentalModeEntry toModel() =>
      ParentalModeEntry(name: name.text, messages: messages.text);
  void dispose() {
    name.dispose();
    messages.dispose();
  }
}

class _CopingModeCtrls {
  _CopingModeCtrls([CopingModeDetail? e])
      : category = TextEditingController(text: e?.category ?? ''),
        name = TextEditingController(text: e?.name ?? ''),
        schemas = TextEditingController(text: e?.schemas ?? ''),
        example = TextEditingController(text: e?.example ?? ''),
        experience = TextEditingController(text: e?.experience ?? ''),
        addresses = TextEditingController(text: e?.addresses ?? ''),
        perceivedValue = TextEditingController(text: e?.perceivedValue ?? ''),
        consequences = TextEditingController(text: e?.consequences ?? '');
  final TextEditingController category;
  final TextEditingController name;
  final TextEditingController schemas;
  final TextEditingController example;
  final TextEditingController experience;
  final TextEditingController addresses;
  final TextEditingController perceivedValue;
  final TextEditingController consequences;
  CopingModeDetail toModel() => CopingModeDetail(
        category: category.text,
        name: name.text,
        schemas: schemas.text,
        example: example.text,
        experience: experience.text,
        addresses: addresses.text,
        perceivedValue: perceivedValue.text,
        consequences: consequences.text,
      );
  void dispose() {
    category.dispose();
    name.dispose();
    schemas.dispose();
    example.dispose();
    experience.dispose();
    addresses.dispose();
    perceivedValue.dispose();
    consequences.dispose();
  }
}

class _TherapyObjCtrls {
  _TherapyObjCtrls([TherapyObjectiveEntry? e])
      : goal = TextEditingController(text: e?.goal ?? ''),
        schemasModes = TextEditingController(text: e?.schemasModes ?? ''),
        healthyBehaviors =
            TextEditingController(text: e?.healthyBehaviors ?? ''),
        interventions = TextEditingController(text: e?.interventions ?? ''),
        progress = TextEditingController(text: e?.progress ?? '');
  final TextEditingController goal;
  final TextEditingController schemasModes;
  final TextEditingController healthyBehaviors;
  final TextEditingController interventions;
  final TextEditingController progress;
  TherapyObjectiveEntry toModel() => TherapyObjectiveEntry(
        goal: goal.text,
        schemasModes: schemasModes.text,
        healthyBehaviors: healthyBehaviors.text,
        interventions: interventions.text,
        progress: progress.text,
      );
  void dispose() {
    goal.dispose();
    schemasModes.dispose();
    healthyBehaviors.dispose();
    interventions.dispose();
    progress.dispose();
  }
}

class _EditState extends ConsumerState<_EditForm> {
  late final List<_NeedCtrls> _needs;
  late final List<_SeqCtrls> _seqs;
  int? _collabRating;
  int? _bondRating;
  late final TextEditingController _collabNotes;
  late final TextEditingController _bondNotes;
  late final TextEditingController _therapistReactions;
  // 11.2.3 · como melhorar a colaboração; 11.3.3 · fortalecer o vínculo; 11.4
  late final TextEditingController _collabImprove;
  late final TextEditingController _bondStrengthen;
  late final TextEditingController _otherFactors;

  // Cabeçalho do formulário (digitado pela psicóloga)
  late final TextEditingController _fhName;
  late final TextEditingController _fhSessions;
  late final TextEditingController _fhMonths;
  DateTime? _fhDate;
  // 8.1 · lista completa de esquemas antes de selecionar os centrais
  late final TextEditingController _allSchemas;

  // 13 · comentários (2, 3 e 4 são preenchidos em Demandas terapêuticas)
  late final TextEditingController _comments;

  // 7 · origens (7.1 história inicial, 7.3 temperamento, 7.4 cultural)
  late final TextEditingController _earlyHistory;
  late final TextEditingController _temperament;
  late final TextEditingController _cultural;

  // 5 · funcionamento
  late final List<_FuncCtrls> _funcAreas;

  // 6 · problemas de vida (terapeuta)
  late final TextEditingController _lp1;
  late final TextEditingController _lp2;
  late final TextEditingController _lp3;
  late final TextEditingController _lp4;

  // 8 · esquemas centrais (até 6)
  late final List<_CentralSchemaCtrls> _centralSchemas;

  // 9.1 · modos saudáveis — Criança Feliz
  late final TextEditingController _hcSpontaneity;
  late final TextEditingController _hcPlay;
  late final TextEditingController _hcCreativity;

  // 9.1 · modos saudáveis — Adulto Saudável
  late final TextEditingController _haMetaAwareness;
  late final TextEditingController _haEmotionalConnection;
  late final TextEditingController _haRealityOrientation;
  late final TextEditingController _haIdentity;
  late final TextEditingController _haSelfAssertion;
  late final TextEditingController _haAgency;
  late final TextEditingController _haCareForOthers;
  late final TextEditingController _haHope;

  // 9.2 · Criança Vulnerável
  late final TextEditingController _vcDescription;
  late final TextEditingController _vcSchemas;
  late final List<_ExampleCtrls> _vcExamples;

  // 9.2 · Outros modos infantis
  late final TextEditingController _ocDescription;
  late final TextEditingController _ocSchemas;
  late final List<_ExampleCtrls> _ocExamples;

  // 9.3 · Modos parentais
  late final List<_ParentalModeCtrls> _parentalModes;

  // 9.4 · Modos de enfrentamento detalhados (até 3)
  late final List<_CopingModeCtrls> _copingModes;

  // 12 · objetivos de terapia (até 5)
  late final List<_TherapyObjCtrls> _therapyObjs;

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final focus = widget.focus;
    if (focus != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _sectionKeys[focus]?.currentContext;
        if (ctx != null && ctx.mounted) {
          Scrollable.ensureVisible(ctx,
              duration: const Duration(milliseconds: 300), alignment: 0.02);
        }
      });
    }
    // Prefill garantido: o formulário só é montado depois que o documento
    // carrega (ver CaseConceptualizationEditPage.build).
    final data = widget.initial;

    _needs = [
      for (final n in kCoreNeeds)
        () {
          final u = data.needFor(n.key);
          return _NeedCtrls(n.key, n.label,
              rating: u.rating, origin: u.origin, schemas: u.schemas);
        }()
    ];

    // Até 3 sequências (preenche com as existentes, completa com vazias).
    _seqs = [
      for (var i = 0; i < 3; i++)
        _SeqCtrls(i < data.modeSequences.length ? data.modeSequences[i] : null),
    ];

    final rel = data.relationship;
    _collabRating = rel.collaborationRating;
    _bondRating = rel.bondRating;
    _collabNotes = TextEditingController(text: rel.collaborationNotes ?? '');
    _bondNotes = TextEditingController(text: rel.bondNotes ?? '');
    _therapistReactions =
        TextEditingController(text: rel.therapistReactions ?? '');
    _collabImprove = TextEditingController(text: rel.collaborationImprove ?? '');
    _bondStrengthen = TextEditingController(text: rel.bondStrengthen ?? '');
    _otherFactors = TextEditingController(text: rel.otherFactors ?? '');

    final fh = data.formHeader;
    _fhName = TextEditingController(text: fh.therapistName ?? '');
    _fhSessions = TextEditingController(text: fh.sessionsCount?.toString() ?? '');
    _fhMonths = TextEditingController(text: fh.monthsSinceFirst?.toString() ?? '');
    _fhDate = fh.formDate;

    _comments = TextEditingController(text: data.additionalComments ?? '');

    _allSchemas = TextEditingController(text: data.allSchemas ?? '');

    final o = data.origins;
    _earlyHistory = TextEditingController(text: o.earlyHistory ?? '');
    _temperament = TextEditingController(text: o.temperament ?? '');
    _cultural = TextEditingController(text: o.cultural ?? '');

    // 5 · funcionamento
    _funcAreas = [
      for (final a in kFunctioningAreas)
        () {
          final e = data.functioning.entryFor(a.key);
          return _FuncCtrls(a.key,
              rating: e.rating,
              explanation: e.explanation,
              notApplicable: e.notApplicable);
        }()
    ];

    // 6 · problemas de vida
    final lp = data.lifeProblems;
    _lp1 = TextEditingController(text: lp.problem1 ?? '');
    _lp2 = TextEditingController(text: lp.problem2 ?? '');
    _lp3 = TextEditingController(text: lp.problem3 ?? '');
    _lp4 = TextEditingController(text: lp.problem4 ?? '');

    // 8 · esquemas centrais
    _centralSchemas = [
      for (var i = 0; i < 6; i++)
        _CentralSchemaCtrls(
            i < data.centralSchemas.length ? data.centralSchemas[i] : null),
    ];

    // 9.1 · modos saudáveis
    final hm = data.modeAssessment.healthyModes;
    _hcSpontaneity =
        TextEditingController(text: hm.happyChildSpontaneity ?? '');
    _hcPlay = TextEditingController(text: hm.happyChildPlay ?? '');
    _hcCreativity =
        TextEditingController(text: hm.happyChildCreativity ?? '');
    _haMetaAwareness =
        TextEditingController(text: hm.adultMetaAwareness ?? '');
    _haEmotionalConnection =
        TextEditingController(text: hm.adultEmotionalConnection ?? '');
    _haRealityOrientation =
        TextEditingController(text: hm.adultRealityOrientation ?? '');
    _haIdentity = TextEditingController(text: hm.adultIdentity ?? '');
    _haSelfAssertion =
        TextEditingController(text: hm.adultSelfAssertion ?? '');
    _haAgency = TextEditingController(text: hm.adultAgency ?? '');
    _haCareForOthers =
        TextEditingController(text: hm.adultCareForOthers ?? '');
    _haHope = TextEditingController(text: hm.adultHope ?? '');

    // 9.2 · Criança Vulnerável
    final vc = data.modeAssessment.vulnerableChild;
    _vcDescription = TextEditingController(text: vc.description ?? '');
    _vcSchemas = TextEditingController(text: vc.schemas ?? '');
    _vcExamples = [
      for (var i = 0; i < 3; i++)
        _ExampleCtrls(i < vc.examples.length ? vc.examples[i] : null),
    ];

    // 9.2 · Outros modos infantis
    final oc = data.modeAssessment.otherChild;
    _ocDescription = TextEditingController(text: oc.description ?? '');
    _ocSchemas = TextEditingController(text: oc.schemas ?? '');
    _ocExamples = [
      for (var i = 0; i < 2; i++)
        _ExampleCtrls(i < oc.examples.length ? oc.examples[i] : null),
    ];

    // 9.3 · Modos parentais
    final pm = data.modeAssessment.parentalModes;
    _parentalModes = [
      for (var i = 0; i < 4; i++)
        _ParentalModeCtrls(i < pm.length ? pm[i] : null),
    ];

    // 9.4 · Modos de enfrentamento
    final cm = data.modeAssessment.copingModes;
    _copingModes = [
      for (var i = 0; i < 3; i++)
        _CopingModeCtrls(i < cm.length ? cm[i] : null),
    ];

    // 12 · objetivos de terapia
    final to = data.therapyObjectives;
    _therapyObjs = [
      for (var i = 0; i < 5; i++)
        _TherapyObjCtrls(i < to.length ? to[i] : null),
    ];
  }

  @override
  void dispose() {
    for (final n in _needs) {
      n.dispose();
    }
    for (final s in _seqs) {
      s.dispose();
    }
    _collabNotes.dispose();
    _bondNotes.dispose();
    _therapistReactions.dispose();
    _collabImprove.dispose();
    _bondStrengthen.dispose();
    _otherFactors.dispose();
    _fhName.dispose();
    _fhSessions.dispose();
    _fhMonths.dispose();
    _comments.dispose();
    _allSchemas.dispose();
    _earlyHistory.dispose();
    _temperament.dispose();
    _cultural.dispose();
    for (final f in _funcAreas) {
      f.dispose();
    }
    _lp1.dispose();
    _lp2.dispose();
    _lp3.dispose();
    _lp4.dispose();
    for (final s in _centralSchemas) {
      s.dispose();
    }
    _hcSpontaneity.dispose();
    _hcPlay.dispose();
    _hcCreativity.dispose();
    _haMetaAwareness.dispose();
    _haEmotionalConnection.dispose();
    _haRealityOrientation.dispose();
    _haIdentity.dispose();
    _haSelfAssertion.dispose();
    _haAgency.dispose();
    _haCareForOthers.dispose();
    _haHope.dispose();
    _vcDescription.dispose();
    _vcSchemas.dispose();
    for (final e in _vcExamples) {
      e.dispose();
    }
    _ocDescription.dispose();
    _ocSchemas.dispose();
    for (final e in _ocExamples) {
      e.dispose();
    }
    for (final p in _parentalModes) {
      p.dispose();
    }
    for (final c in _copingModes) {
      c.dispose();
    }
    for (final t in _therapyObjs) {
      t.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final model = CaseConceptualization(
      unmetNeeds: [
        for (final n in _needs)
          UnmetNeed(
            needKey: n.key,
            rating: n.rating,
            origin: n.origin.text,
            schemas: n.schemas.text,
          ),
      ],
      modeSequences: [for (final s in _seqs) s.toModel()],
      relationship: TherapeuticRelationship(
        collaborationRating: _collabRating,
        collaborationNotes: _collabNotes.text,
        bondRating: _bondRating,
        bondNotes: _bondNotes.text,
        therapistReactions: _therapistReactions.text,
        collaborationImprove: _collabImprove.text,
        bondStrengthen: _bondStrengthen.text,
        otherFactors: _otherFactors.text,
      ),
      formHeader: CaseFormHeader(
        therapistName: _fhName.text,
        formDate: _fhDate,
        sessionsCount: int.tryParse(_fhSessions.text.trim()),
        monthsSinceFirst: int.tryParse(_fhMonths.text.trim()),
      ),
      origins: CaseOrigins(
        earlyHistory: _earlyHistory.text,
        temperament: _temperament.text,
        cultural: _cultural.text,
      ),
      functioning: FunctioningAssessment(
        entries: {
          for (final f in _funcAreas)
            f.areaKey: FunctioningEntry(
                rating: f.rating,
                explanation: f.explanation.text,
                notApplicable: f.notApplicable),
        },
      ),
      lifeProblems: TherapistLifeProblems(
        problem1: _lp1.text,
        problem2: _lp2.text,
        problem3: _lp3.text,
        problem4: _lp4.text,
      ),
      centralSchemas: [for (final s in _centralSchemas) s.toModel()],
      modeAssessment: SchemaModeAssessment(
        healthyModes: HealthyModes(
          happyChildSpontaneity: _hcSpontaneity.text,
          happyChildPlay: _hcPlay.text,
          happyChildCreativity: _hcCreativity.text,
          adultMetaAwareness: _haMetaAwareness.text,
          adultEmotionalConnection: _haEmotionalConnection.text,
          adultRealityOrientation: _haRealityOrientation.text,
          adultIdentity: _haIdentity.text,
          adultSelfAssertion: _haSelfAssertion.text,
          adultAgency: _haAgency.text,
          adultCareForOthers: _haCareForOthers.text,
          adultHope: _haHope.text,
        ),
        vulnerableChild: VulnerableChildAssessment(
          description: _vcDescription.text,
          schemas: _vcSchemas.text,
          examples: [for (final e in _vcExamples) e.toModel()],
        ),
        otherChild: OtherChildAssessment(
          description: _ocDescription.text,
          schemas: _ocSchemas.text,
          examples: [for (final e in _ocExamples) e.toModel()],
        ),
        parentalModes: [for (final p in _parentalModes) p.toModel()],
        copingModes: [for (final c in _copingModes) c.toModel()],
      ),
      therapyObjectives: [for (final t in _therapyObjs) t.toModel()],
      allSchemas: _allSchemas.text,
      additionalComments: _comments.text,
    );
    try {
      await ref
          .read(caseConceptualizationRepositoryProvider)
          .save(widget.patientId, model);
      ref.invalidate(caseConceptualizationProvider(widget.patientId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Conceitualização salva.')),
      );
      context.pop(true);
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  /// Chave de cada cartão (pelo número do item no título), para rolar até ele.
  final _sectionKeys = <String, GlobalKey>{};

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Editar conceitualização',
      accent: AppColors.navy,
      body: Stack(
        children: [
          ListView(
            // Com item em foco, monta tudo para o cartão existir ao rolar.
            // ignore: deprecated_member_use
            cacheExtent: widget.focus == null ? null : 100000,
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
            children: [
              _card(
                icon: Icons.article_outlined,
                title: 'Cabeçalho do formulário',
                subtitle:
                    'Aparece no topo do PDF e do Word. Preencha como no formulário 3.8.',
                children: [
                  _field(_fhName, 'Nome da psicóloga'),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: OutlinedButton.icon(
                        key: const Key('edit_fh_date'),
                        onPressed: _pickFormDate,
                        icon: const Icon(Icons.event_outlined, size: 16),
                        label: Text(_fhDate == null
                            ? 'Data do formulário'
                            : 'Data: ${_fmtDate(_fhDate!)}'),
                      ),
                    ),
                  ),
                  _numField(_fhSessions, 'Número de sessões',
                      key: const Key('edit_fh_sessions')),
                  _numField(_fhMonths, 'Meses desde a primeira sessão',
                      key: const Key('edit_fh_months')),
                ],
              ),
              _card(
                icon: Icons.badge_outlined,
                title: '1 · Identificação',
                subtitle: '',
                children: [
                  _openAction(
                    key: const Key('edit_open_registration'),
                    text:
                        'Os dados de identificação são preenchidos em Dados cadastrais e alimentam esta síntese.',
                    label: 'Abrir Dados cadastrais',
                    route: PatientRoutes.registration(
                        widget.role, widget.patientId),
                  ),
                ],
              ),
              _card(
                icon: Icons.assignment_ind_outlined,
                title: '2, 3 e 4 · Demandas terapêuticas',
                subtitle:
                    'Motivos da terapia, impressões gerais e perspectiva diagnóstica são preenchidos em Conhecer › Demandas Terapêuticas e alimentam esta síntese.',
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('edit_open_demands'),
                      onPressed: () => context.push(TherapyDemandsRoutes.staff(
                          role: widget.role, patientId: widget.patientId)),
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('Abrir Demandas Terapêuticas'),
                    ),
                  ),
                ],
              ),
              // ── 5 · Nível de funcionamento ──────────────────────────────
              _card(
                icon: Icons.bar_chart_outlined,
                title: '5 · Nível de funcionamento',
                subtitle:
                    '1 = Não Funcional  ·  6 = Excelente  ·  N/A = não se aplica. Avalie cada área e adicione uma justificativa.',
                children: [
                  _openAction(
                    key: const Key('edit_open_context'),
                    text:
                        'O contexto de vida é preenchido em Conhecer › Contexto de Vida e alimenta esta síntese.',
                    label: 'Abrir Contexto de Vida',
                    route: InitialAssessmentRoutes.staffContext(role: widget.role, patientId: widget.patientId),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _funcAreas.length; i++) ...[
                    if (i > 0) const Divider(height: 20),
                    _funcBlock(kFunctioningAreas[i], _funcAreas[i]),
                  ],
                ],
              ),

              // ── 6 · Principais problemas de vida ────────────────────────
              _card(
                icon: Icons.report_problem_outlined,
                title: '6 · Principais problemas de vida',
                subtitle:
                    'Identifique 3 ou mais problemas que precisam ser compreendidos e abordados na terapia.',
                children: [
                  _openAction(
                    key: const Key('edit_open_problems'),
                    text:
                        'Os problemas do paciente são preenchidos em Conhecer › Problemas e alimentam esta síntese.',
                    label: 'Abrir Problemas',
                    route: PatientProblemRoutes.staffList(role: widget.role, patientId: widget.patientId),
                  ),
                  const SizedBox(height: 12),
                  _field(_lp1, '6.1 Problema de vida'),
                  _field(_lp2, '6.2 Problema de vida'),
                  _field(_lp3, '6.3 Problema de vida'),
                  _field(_lp4, '6.4 Outro problema de vida'),
                ],
              ),

              _card(
                icon: Icons.history_edu_outlined,
                title: '7.1 · Descrição geral da história inicial',
                subtitle:
                    'Aspectos da infância/adolescência e experiências adversas que contribuíram para os problemas atuais.',
                children: [_field(_earlyHistory, 'História inicial')],
              ),
              _card(
                icon: Icons.spa_outlined,
                title: '7.2 · Necessidades não atendidas',
                subtitle:
                    'Avaliação: X = informação insuficiente, 0 = quase nada, 1 = muito limitado, 3 = moderado, 5 = grande medida.',
                children: [
                  for (var i = 0; i < _needs.length; i++) ...[
                    if (i > 0) const Divider(height: 22),
                    _needBlock(_needs[i]),
                  ],
                ],
              ),
              _card(
                icon: Icons.psychology_alt_outlined,
                title: '7.3 · Fatores temperamentais/biológicos',
                subtitle:
                    'Facetas do temperamento e fatores biológicos relevantes (ver Guia de Conceitualização).',
                children: [
                  _openAction(
                    key: const Key('edit_open_personality'),
                    text:
                        'Os fatores de temperamento podem ser consultados em Avaliar › Personalidade; o campo abaixo continua disponível.',
                    label: 'Abrir Personalidade',
                    route: PersonalityAssessmentRoutes.staffList(role: widget.role, patientId: widget.patientId),
                  ),
                  const SizedBox(height: 12),
                  _personalityPull(),
                  _field(_temperament, 'Temperamento / biológico', maxLines: 8)],
              ),
              _card(
                icon: Icons.diversity_3_outlined,
                title: '7.4 · Fatores culturais, étnicos e religiosos',
                subtitle:
                    'Normas e atitudes da origem étnica, religiosa e comunitária que tiveram papel nos problemas.',
                children: [_field(_cultural, 'Fatores culturais')],
              ),

              // ── 8.1 · Lista completa de esquemas ─────────────────────────
              _card(
                icon: Icons.list_alt_outlined,
                title: '8.1 · Todos os esquemas identificados',
                subtitle:
                    'Liste todos os esquemas identificados nas 9 necessidades (7.2) antes de selecionar os centrais.',
                children: [
                  _openAction(
                    key: const Key('edit_open_questionnaires_81'),
                    text:
                        'Os esquemas identificados vêm dos questionários em Avaliar › Questionários; o campo abaixo continua disponível.',
                    label: 'Abrir Questionários',
                    route: QuestionnaireRoutes.list(role: widget.role, patientId: widget.patientId),
                  ),
                  const SizedBox(height: 12),
                  _field(_allSchemas, 'Esquemas identificados (um por linha ou por vírgula)'),
                ],
              ),

              // ── 8.2 · Esquemas centrais ───────────────────────────────────
              _card(
                icon: Icons.hub_outlined,
                title: '8.2 · Esquemas desadaptativos centrais',
                subtitle:
                    'Selecione 4–6 esquemas mais centrais e descreva a experiência do cliente quando ativados.',
                children: [
                  _openAction(
                    key: const Key('edit_open_questionnaires_82'),
                    text:
                        'Os esquemas centrais vêm dos questionários em Avaliar › Questionários; os campos abaixo continuam disponíveis.',
                    label: 'Abrir Questionários',
                    route: QuestionnaireRoutes.list(role: widget.role, patientId: widget.patientId),
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < _centralSchemas.length; i++) ...[
                    if (i > 0) const Divider(height: 20),
                    _centralSchemaBlock(i + 1, _centralSchemas[i]),
                  ],
                ],
              ),

              // ── 9.1 · Modos saudáveis ────────────────────────────────────
              _card(
                icon: Icons.favorite_outline,
                title: '9.1 · Modos saudáveis',
                subtitle: 'Criança Feliz e Adulto Saudável.',
                children: [
                  _sectionLabel('Criança Feliz'),
                  _field(_hcSpontaneity, 'Capacidade de naturalidade e espontaneidade'),
                  _field(_hcPlay, 'Capacidade de brincar e divertir-se de forma inocente'),
                  _field(_hcCreativity, 'Capacidade de ser criativo'),
                  const SizedBox(height: 12),
                  _sectionLabel('Adulto Saudável'),
                  _field(_haMetaAwareness,
                      '1. Meta-Consciência: recuar e refletir sobre si e os outros'),
                  _field(_haEmotionalConnection,
                      '2. Conexão emocional: abertura e vivência das emoções'),
                  _field(_haRealityOrientation,
                      '3. Orientação para a realidade: decisões baseadas na realidade'),
                  _field(_haIdentity,
                      '4. Senso coerente de identidade: crenças, valores e motivações'),
                  _field(_haSelfAssertion,
                      '5. Autoafirmação e reciprocidade: defender-se e comunicar-se'),
                  _field(_haAgency,
                      '6. Agência e responsabilidade: assumir responsabilidade pelas ações'),
                  _field(_haCareForOthers,
                      '7. Cuidar além de si mesmo: engajamento com os outros e a sociedade'),
                  _field(_haHope,
                      '8. Esperança e Significado: encontrar e manter a fé nas dificuldades'),
                ],
              ),

              // ── 9.2 · Modos infantis ─────────────────────────────────────
              _card(
                icon: Icons.child_care_outlined,
                title: '9.2 · Modos infantis',
                subtitle:
                    'Criança Vulnerável (até 3 exemplos) e outros modos infantis (até 2 exemplos).',
                children: [
                  _sectionLabel('Criança Vulnerável'),
                  _field(_vcDescription, 'Nome / subtipos (ex: Criança Solitária, Abandonada…)'),
                  _field(_vcSchemas, 'Esquemas relacionados'),
                  for (var i = 0; i < _vcExamples.length; i++) ...[
                    const SizedBox(height: 10),
                    _exampleBlock('Ex ${i + 1}', _vcExamples[i]),
                  ],
                  const SizedBox(height: 12),
                  _sectionLabel('Outros modos infantis'),
                  _field(_ocDescription,
                      'Descrição (ex: Criança Irritada, Impulsiva…)'),
                  _field(_ocSchemas, 'Esquemas relacionados'),
                  for (var i = 0; i < _ocExamples.length; i++) ...[
                    const SizedBox(height: 10),
                    _exampleBlock('Ex ${i + 1}', _ocExamples[i]),
                  ],
                ],
              ),

              // ── 9.3 · Modos parentais ────────────────────────────────────
              _card(
                icon: Icons.supervisor_account_outlined,
                title: '9.3 · Modos parentais disfuncionais',
                subtitle:
                    'Liste os modos parentais e exemplos de mensagens (explícitas ou implícitas) para a criança.',
                children: [
                  for (var i = 0; i < _parentalModes.length; i++) ...[
                    if (i > 0) const Divider(height: 20),
                    _parentalModeBlock(i + 1, _parentalModes[i]),
                  ],
                ],
              ),

              // ── 9.4 · Modos de enfrentamento ─────────────────────────────
              _card(
                icon: Icons.shield_outlined,
                title: '9.4 · Modos de enfrentamento desadaptativos',
                subtitle:
                    'Detalhe até 3 modos de enfrentamento (campos a–e do formulário).',
                children: [
                  for (var i = 0; i < _copingModes.length; i++) ...[
                    if (i > 0) const Divider(height: 22),
                    _copingModeBlock(i + 1, _copingModes[i]),
                  ],
                ],
              ),

              _card(
                icon: Icons.account_tree_outlined,
                title: '10 · Sequência de modos',
                subtitle: 'Até 3 sequências (gatilho → cadeia de modos).',
                children: [
                  for (var i = 0; i < _seqs.length; i++) ...[
                    if (i > 0) const Divider(height: 22),
                    _seqBlock(i + 1, _seqs[i]),
                  ],
                ],
              ),
              _card(
                icon: Icons.handshake_outlined,
                title: '11 · Relação terapêutica',
                subtitle: 'Colaboração e vínculo (1–5) + descrição e como melhorar.',
                children: [
                  _sectionLabel('11.1 Reações pessoais do terapeuta ao cliente'),
                  _field(_therapistReactions,
                      '11.1 Reações pessoais do terapeuta ao cliente'),
                  const SizedBox(height: 8),
                  _sectionLabel('11.2 Colaboração'),
                  _ratingRow('11.2.1 Nota', _collabRating, 5,
                      (v) => setState(() => _collabRating = v)),
                  _field(_collabNotes, '11.2.2 Descrição da colaboração'),
                  _field(_collabImprove, '11.2.3 Como melhorar a colaboração'),
                  const SizedBox(height: 8),
                  _sectionLabel('11.3 Vínculo de reparentalidade'),
                  _ratingRow('11.3.1 Nota', _bondRating, 5,
                      (v) => setState(() => _bondRating = v)),
                  _field(_bondNotes, '11.3.2 Descrição do vínculo'),
                  _field(_bondStrengthen, '11.3.3 Como fortalecer o vínculo'),
                  const SizedBox(height: 8),
                  _sectionLabel('11.4 Outros fatores (opcional)'),
                  _field(_otherFactors, '11.4 Outros fatores'),
                ],
              ),

              // ── 12 · Objetivos da terapia ────────────────────────────────
              _card(
                icon: Icons.flag_outlined,
                title: '12 · Objetivos da terapia',
                subtitle:
                    'Selecione pelo menos 4 objetivos centrais e preencha os subcampos.',
                children: [
                  for (var i = 0; i < _therapyObjs.length; i++) ...[
                    if (i > 0) const Divider(height: 22),
                    _therapyObjBlock(i + 1, _therapyObjs[i]),
                  ],
                ],
              ),

              _card(
                icon: Icons.notes_outlined,
                title: '13 · Comentários adicionais',
                subtitle: 'Qualquer nota ou explicação extra.',
                children: [
                  _field(_comments, 'Comentários'),
                ],
              ),
            ],
          ),
          Positioned(
            left: 14,
            right: 14,
            bottom: 14,
            child: FilledButton.icon(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.navy,
                minimumSize: const Size.fromHeight(50),
              ),
              icon: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check),
              label: Text(_saving ? 'Salvando...' : 'Salvar conceitualização'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      key: _sectionKeys.putIfAbsent(
          title.split(' · ').first, () => GlobalKey()),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 17, color: AppColors.navy),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(subtitle,
                style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant, height: 1.3)),
          ],
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _openAction({
    required Key key,
    required String text,
    required String label,
    required String route,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(text,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          key: key,
          onPressed: () => context.push(route),
          icon: const Icon(Icons.open_in_new, size: 16),
          label: Text(label),
        ),
      ],
    );
  }

  /// 7.3: acrescenta ao campo o resumo do resultado de Personalidade já
  /// registrado (domínios com nível), sem apagar o que a psicóloga escreveu.
  Widget _personalityPull() {
    final async = ref.watch(personalityAssessmentsProvider(widget.patientId));
    final summary = async.hasValue
        ? personalitySummaryForConceptualization(async.value!)
        : null;
    final theme = Theme.of(context);
    final hintStyle =
        theme.textTheme.bodySmall?.copyWith(color: AppColors.textSecondary);

    // Texto da dica / estado: carregando, erro (com nova tentativa) ou vazio.
    Widget? note;
    var label = 'Trazer da Personalidade (NEO PI-R)';
    if (async.isLoading && !async.hasValue) {
      label = 'Carregando Personalidade…';
    } else if (async.hasError && !async.hasValue) {
      note = Row(
        key: const Key('edit_pull_personality_error'),
        children: [
          Flexible(
            child: Text('Não foi possível carregar a Personalidade.',
                style: hintStyle),
          ),
          TextButton(
            key: const Key('edit_pull_personality_retry'),
            onPressed: () =>
                ref.invalidate(personalityAssessmentsProvider(widget.patientId)),
            child: const Text('Tentar novamente'),
          ),
        ],
      );
    } else if (summary == null) {
      note = Text('Sem resultado de Personalidade ainda',
          key: const Key('edit_pull_personality_hint'), style: hintStyle);
    }

    final button = OutlinedButton.icon(
      key: const Key('edit_pull_personality'),
      onPressed: summary == null
          ? null
          : () {
              final cur = _temperament.text.trimRight();
              final next = cur.isEmpty ? summary : '$cur\n\n$summary';
              setState(() {
                _temperament.text = next;
                _temperament.selection =
                    TextSelection.collapsed(offset: next.length);
              });
            },
      icon: const Icon(Icons.download_outlined, size: 16),
      label: Text(label),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: note == null
          ? button
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (async.hasValue)
                  Tooltip(
                      message: 'Sem resultado de Personalidade ainda',
                      child: button)
                else
                  button,
                const SizedBox(height: 4),
                note,
              ],
            ),
    );
  }

  Widget _needBlock(_NeedCtrls n) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(n.label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final r in kUnmetNeedRatings)
              ChoiceChip(
                key: Key('need_${n.key}_$r'),
                label: Text(r),
                selected: n.rating == r,
                onSelected: (sel) =>
                    setState(() => n.rating = sel ? r : null),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'X = informação insuficiente, 0 = quase nada, 1 = muito limitado, 3 = moderado, 5 = grande medida',
          style: theme.textTheme.bodySmall
              ?.copyWith(color: AppColors.textSecondary),
        ),
        _field(n.origin, 'Origem'),
        _field(n.schemas, 'Esquemas'),
      ],
    );
  }

  Widget _seqBlock(int index, _SeqCtrls s) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Sequência $index',
            style: theme.textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w800, color: AppColors.textSecondary)),
        _field(s.trigger, 'Gatilho'),
        _field(s.modes, 'Modos ativados (criança/pai)'),
        _field(s.coping, 'Modo de enfrentamento'),
        _field(s.sequence, 'Sequência de modos'),
        _field(s.effect, 'Efeito do enfrentamento'),
        _field(s.perpetuation, 'Como perpetua o esquema'),
      ],
    );
  }

  Widget _ratingRow(
      String label, int? value, int max, ValueChanged<int?> onChanged) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(label,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
          ),
          Wrap(
            spacing: 5,
            children: [
              for (var v = 1; v <= max; v++)
                ChoiceChip(
                  label: Text('$v'),
                  selected: value == v,
                  onSelected: (sel) => onChanged(sel ? v : null),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickFormDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _fhDate ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
    );
    if (picked != null) setState(() => _fhDate = picked);
  }

  Widget _numField(TextEditingController c, String label, {Key? key}) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          key: key,
          controller: c,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(labelText: label, isDense: true),
        ),
      );

  Widget _field(TextEditingController c, String label, {int maxLines = 3}) =>
      Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: c,
          minLines: 1,
          maxLines: maxLines,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(labelText: label, isDense: true),
        ),
      );

  Widget _sectionLabel(String text) => Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 2),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
        ),
      );

  Widget _funcBlock(FunctioningArea area, _FuncCtrls ctrls) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(area.label,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final v in [1, 2, 3, 4, 5, 6])
              ChoiceChip(
                key: Key('func_${ctrls.areaKey}_$v'),
                label: Text('$v'),
                selected: ctrls.rating == v,
                onSelected: (_) => setState(() {
                  ctrls.notApplicable = false;
                  ctrls.rating = ctrls.rating == v ? null : v;
                }),
              ),
            // N/A e nota são excludentes: marcar N/A descarta a nota.
            ChoiceChip(
              key: Key('func_${ctrls.areaKey}_na'),
              label: const Text('N/A'),
              selected: ctrls.notApplicable,
              onSelected: (sel) => setState(() {
                ctrls.notApplicable = sel;
                if (sel) ctrls.rating = null;
              }),
            ),
          ],
        ),
        _field(ctrls.explanation, 'Justificativa'),
      ],
    );
  }

  Widget _exampleBlock(String title, _ExampleCtrls ctrls) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          _field(ctrls.trigger, 'Gatilho'),
          _field(ctrls.experience, 'Experiência interna'),
          _field(ctrls.coping, 'Comportamento de enfrentamento'),
        ],
      );

  Widget _centralSchemaBlock(int n, _CentralSchemaCtrls ctrls) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Esquema $n',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          _field(ctrls.name, 'Nome do esquema'),
          _field(ctrls.description, 'Experiência do cliente quando ativado'),
        ],
      );

  Widget _parentalModeBlock(int n, _ParentalModeCtrls ctrls) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Modo parental $n',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          _field(ctrls.name, 'Nome do modo (ex: Pai Punitivo)'),
          _field(ctrls.messages, 'Mensagens típicas para a criança'),
        ],
      );

  Widget _copingModeBlock(int n, _CopingModeCtrls ctrls) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Modo de enfrentamento $n',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          _field(ctrls.category, 'Categoria (Rendição / Evitação / Compensação)'),
          _field(ctrls.name, 'Nome do modo'),
          _field(ctrls.schemas, 'Esquemas relacionados'),
          _field(ctrls.example, 'Exemplo de situação'),
          _field(ctrls.experience, 'Experiência interna'),
          _field(ctrls.addresses, 'Necessidades que tenta atender'),
          _field(ctrls.perceivedValue, 'Valor percebido pelo cliente'),
          _field(ctrls.consequences, 'Consequências negativas'),
        ],
      );

  Widget _therapyObjBlock(int n, _TherapyObjCtrls ctrls) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Objetivo $n',
              style: Theme.of(context)
                  .textTheme
                  .labelSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          _field(ctrls.goal, 'Objetivo terapêutico'),
          _field(ctrls.schemasModes, 'Esquemas/modos-alvo'),
          _field(ctrls.healthyBehaviors, 'Comportamentos saudáveis a desenvolver'),
          _field(ctrls.interventions, 'Intervenções planejadas'),
          _field(ctrls.progress, 'Progresso / notas'),
        ],
      );
}

/// Resumo do resultado de Personalidade mais recente que tenha algum domínio
/// com nível: "NEO PI-R (dd/mm/aaaa): Neuroticismo: Alto; …". `null` quando não
/// há resultado. Só usa rótulos que o app já tem (instrumento, domínios, níveis).
@visibleForTesting
String? personalitySummaryForConceptualization(
    List<PersonalityAssessment> list) {
  final sorted = [...list]..sort((a, b) =>
      (b.appliedOn ?? b.createdAt).compareTo(a.appliedOn ?? a.createdAt));
  for (final a in sorted) {
    final inst = a.instrumentDef;
    final parts = <String>[];
    for (final d in inst.domains) {
      final level = a.results.domains[d.code]?.overall.level;
      if (level != null) parts.add('${d.label}: ${level.label}');
    }
    if (parts.isEmpty) continue;
    final dt = a.appliedOn ?? a.createdAt;
    String two(int n) => n.toString().padLeft(2, '0');
    return '${inst.name} (${two(dt.day)}/${two(dt.month)}/${dt.year}): '
        '${parts.join('; ')}.';
  }
  return null;
}
