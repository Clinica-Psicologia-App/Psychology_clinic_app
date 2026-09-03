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
                subtitle: 'Nota 0–5 (ou X = insuficiente), origem e esquemas.',
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
            for (final r in const ['X', '0', '1', '2', '3', '4', '5'])
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
}
