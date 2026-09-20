import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/case_conceptualization.dart';
import '../providers/case_conceptualization_providers.dart';

/// Edição dos campos do terapeuta da Conceitualização de caso (Síntese):
/// necessidades não atendidas (7.2), sequência de modos (10) e relação
/// terapêutica (11). As demais seções vêm da agregação e não são editadas aqui.
class CaseConceptualizationEditPage extends ConsumerWidget {
  const CaseConceptualizationEditPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

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
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({
    required this.role,
    required this.patientId,
    required this.initial,
  });

  final ProfileRole role;
  final String patientId;
  final CaseConceptualization initial;

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
  _FuncCtrls(this.areaKey, {this.rating, String? explanation})
      : explanation = TextEditingController(text: explanation ?? '');
  final String areaKey;
  int? rating;
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
  // 2 · motivo (complemento do terapeuta)
  late final TextEditingController _motivoNotes;

  // 3 · impressões gerais / 4 · diagnóstico / 13 · comentários
  late final TextEditingController _impInitial;
  late final TextEditingController _impCurrent;
  String? _dxSystem;
  late final List<(TextEditingController, TextEditingController)> _dxItems;
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

    _impInitial =
        TextEditingController(text: data.generalImpressions.initial ?? '');
    _impCurrent =
        TextEditingController(text: data.generalImpressions.current ?? '');
    _dxSystem = data.diagnosis.system;
    _dxItems = [
      for (var i = 0; i < 4; i++)
        () {
          final it =
              i < data.diagnosis.items.length ? data.diagnosis.items[i] : null;
          return (
            TextEditingController(text: it?.name ?? ''),
            TextEditingController(text: it?.code ?? ''),
          );
        }()
    ];
    _comments = TextEditingController(text: data.additionalComments ?? '');

    _motivoNotes = TextEditingController(text: data.motivoNotes ?? '');

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
              rating: e.rating, explanation: e.explanation);
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
    _impInitial.dispose();
    _impCurrent.dispose();
    for (final p in _dxItems) {
      p.$1.dispose();
      p.$2.dispose();
    }
    _comments.dispose();
    _motivoNotes.dispose();
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
      ),
      generalImpressions: GeneralImpressions(
        initial: _impInitial.text,
        current: _impCurrent.text,
      ),
      diagnosis: Diagnosis(
        system: _dxSystem,
        items: [
          for (final p in _dxItems)
            DiagnosisItem(name: p.$1.text, code: p.$2.text),
        ],
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
                rating: f.rating, explanation: f.explanation.text),
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
      motivoNotes: _motivoNotes.text,
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

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Editar conceitualização',
      accent: AppColors.navy,
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 96),
            children: [
              _card(
                icon: Icons.chat_bubble_outline,
                title: '2 · Motivo da terapia',
                subtitle:
                    'Complemento seu ao motivo/queixa (contexto e demandas já vêm do Mapa mental).',
                children: [_field(_motivoNotes, 'Complemento do terapeuta')],
              ),
              _card(
                icon: Icons.visibility_outlined,
                title: '3 · Impressões gerais',
                subtitle: 'Como o cliente se apresenta nas sessões.',
                children: [
                  _field(_impInitial, 'Inicialmente'),
                  _field(_impCurrent, 'Atualmente'),
                ],
              ),
              _card(
                icon: Icons.medical_information_outlined,
                title: '4 · Perspectiva diagnóstica',
                subtitle: 'Sistema e diagnósticos principais.',
                children: [
                  Wrap(
                    spacing: 6,
                    children: [
                      for (final s in const ['CID-11', 'DSM-5-TR'])
                        ChoiceChip(
                          label: Text(s),
                          selected: _dxSystem == s,
                          onSelected: (sel) =>
                              setState(() => _dxSystem = sel ? s : null),
                        ),
                    ],
                  ),
                  for (var i = 0; i < _dxItems.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 3,
                            child: TextField(
                              controller: _dxItems[i].$1,
                              textCapitalization: TextCapitalization.sentences,
                              decoration: InputDecoration(
                                labelText: 'Diagnóstico ${i + 1}',
                                isDense: true,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 1,
                            child: TextField(
                              controller: _dxItems[i].$2,
                              decoration: const InputDecoration(
                                labelText: 'Código',
                                isDense: true,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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
                    'Avaliação: 0 = quase nada, 1 = muito limitado, 3 = moderado, 5 = grande medida.',
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
                children: [_field(_temperament, 'Temperamento / biológico')],
              ),
              _card(
                icon: Icons.diversity_3_outlined,
                title: '7.4 · Fatores culturais, étnicos e religiosos',
                subtitle:
                    'Normas e atitudes da origem étnica, religiosa e comunitária que tiveram papel nos problemas.',
                children: [_field(_cultural, 'Fatores culturais')],
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
                subtitle: 'Colaboração e vínculo (1–5) + notas.',
                children: [
                  _ratingRow('Colaboração', _collabRating, 5,
                      (v) => setState(() => _collabRating = v)),
                  _field(_collabNotes, 'Notas sobre a colaboração'),
                  const SizedBox(height: 8),
                  _ratingRow('Vínculo (reparent.)', _bondRating, 5,
                      (v) => setState(() => _bondRating = v)),
                  _field(_bondNotes, 'Notas sobre o vínculo'),
                  const SizedBox(height: 8),
                  _field(_therapistReactions,
                      'Reações do terapeuta ao cliente'),
                ],
              ),
              // ── 5 · Nível de funcionamento ──────────────────────────────
              _card(
                icon: Icons.bar_chart_outlined,
                title: '5 · Nível de funcionamento',
                subtitle:
                    '1 = Não Funcional  ·  6 = Excelente. Avalie cada área e adicione uma justificativa.',
                children: [
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
                  _field(_lp1, '6.1 Problema de vida'),
                  _field(_lp2, '6.2 Problema de vida'),
                  _field(_lp3, '6.3 Problema de vida'),
                  _field(_lp4, '6.4 Outro problema de vida'),
                ],
              ),

              // ── 8 · Esquemas centrais ────────────────────────────────────
              _card(
                icon: Icons.hub_outlined,
                title: '8 · Esquemas desadaptativos centrais',
                subtitle:
                    'Selecione 4–6 esquemas mais centrais (8.2) e descreva a experiência do cliente quando ativados.',
                children: [
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
          const SizedBox(height: 2),
          Text(subtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.3)),
          const SizedBox(height: 12),
          ...children,
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
            for (final r in const ['0', '1', '3', '5'])
              ChoiceChip(
                label: Text(r),
                selected: n.rating == r,
                onSelected: (sel) =>
                    setState(() => n.rating = sel ? r : null),
              ),
          ],
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

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: c,
          minLines: 1,
          maxLines: 3,
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
              StatefulBuilder(
                builder: (_, set) => ChoiceChip(
                  label: Text('$v'),
                  selected: ctrls.rating == v,
                  onSelected: (_) =>
                      setState(() => ctrls.rating = ctrls.rating == v ? null : v),
                ),
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
