import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_banner.dart';
import '../domain/life_story_deepen_enums.dart';
import '../domain/life_timeline_event.dart';
import '../providers/life_story_providers.dart';
import 'widgets/flow_ui.dart';

/// "Aprofundar este momento" — as 5 etapas opcionais (spec §6, §7, §10–12).
/// Recebe um acontecimento já salvo e complementa seus campos.
class DeepenEventFlowPage extends ConsumerStatefulWidget {
  const DeepenEventFlowPage({super.key, required this.event});

  final LifeTimelineEvent event;

  @override
  ConsumerState<DeepenEventFlowPage> createState() =>
      _DeepenEventFlowPageState();
}

class _DeepenEventFlowPageState extends ConsumerState<DeepenEventFlowPage> {
  static const _stepCount = 5;
  int _step = 0;
  bool _busy = false;

  // Etapa 3 — evento ou período
  EventRecurrence? _recurrence;
  final _ageFromController = TextEditingController();
  final _ageToController = TextEditingController();

  // Etapa 4 — área da vida (até 2)
  final Set<LifeCategory> _categories = {};

  // Etapa 7 — do que precisava
  final Set<EmotionalNeed> _needs = {};
  final _needOtherController = TextEditingController();
  bool _needOtherOn = false;
  NeedWasMet? _needWasMet;

  // Etapa 8 — significado
  final _meaningController = TextEditingController();

  // Etapa 9 — e hoje
  double _influence = 0;
  StillInfluences? _stillInfluences;
  final Set<PresentArea> _presentAreas = {};

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _recurrence = e.eventRecurrence;
    _ageFromController.text = e.ageFrom?.toString() ?? '';
    _ageToController.text = e.ageTo?.toString() ?? '';
    _categories.addAll(e.categories);
    _needs.addAll(e.needs);
    _needOtherOn = (e.needOther ?? '').trim().isNotEmpty;
    _needOtherController.text = e.needOther ?? '';
    _needWasMet = e.needWasMet;
    _meaningController.text = e.meaning ?? '';
    _influence = (e.presentInfluence ?? 0).toDouble();
    _stillInfluences = e.stillInfluences;
    _presentAreas.addAll(e.presentAreas);
  }

  @override
  void dispose() {
    _ageFromController.dispose();
    _ageToController.dispose();
    _needOtherController.dispose();
    _meaningController.dispose();
    super.dispose();
  }

  void _next() => setState(() {
        if (_step < _stepCount - 1) _step++;
      });
  void _back() => setState(() {
        if (_step > 0) _step--;
      });

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final e = widget.event;
    final showAreas = _stillInfluences == StillInfluences.yes ||
        _stillInfluences == StillInfluences.maybe;
    final updated = LifeTimelineEvent(
      id: e.id,
      patientId: e.patientId,
      // núcleo preservado
      title: e.title,
      description: e.description,
      lifeChapter: e.lifeChapter,
      ageAtEvent: e.ageAtEvent,
      agePrecision: e.agePrecision,
      emotions: e.emotions,
      emotionOther: e.emotionOther,
      emotionalImpact: e.emotionalImpact,
      peopleIds: e.peopleIds,
      // aprofundar
      eventRecurrence: _recurrence,
      ageFrom: _recurrence == EventRecurrence.prolonged
          ? int.tryParse(_ageFromController.text.trim())
          : null,
      ageTo: _recurrence == EventRecurrence.prolonged
          ? int.tryParse(_ageToController.text.trim())
          : null,
      categories: _categories.toList(),
      needs: _needs.toList(),
      needOther: _needOtherOn && _needOtherController.text.trim().isNotEmpty
          ? _needOtherController.text.trim()
          : null,
      needWasMet: _needWasMet,
      meaning: _meaningController.text.trim().isEmpty
          ? null
          : _meaningController.text.trim(),
      presentInfluence: _influence.round(),
      stillInfluences: _stillInfluences,
      presentAreas: showAreas ? _presentAreas.toList() : const [],
    );
    try {
      await ref
          .read(updateTimelineEventProvider.notifier)
          .submit(eventId: e.id, event: updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Momento aprofundado.')),
      );
      context.pop();
    } catch (err) {
      if (mounted) showErrorBanner(context, err);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          FlowHeader(
            title: 'Aprofundar',
            step: _step,
            stepCount: _stepCount,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: switch (_step) {
                0 => _stepRecurrence(),
                1 => _stepCategory(),
                2 => _stepNeeds(),
                3 => _stepMeaning(),
                _ => _stepToday(),
              },
            ),
          ),
          _buildNav(),
        ],
      ),
    );
  }

  // ── Etapa 3 · Evento ou período (§6) ─────────────────────────────────────
  Widget _stepRecurrence() {
    final prolonged = _recurrence == EventRecurrence.prolonged;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        flowQuestion('Isso aconteceu...'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in kEventRecurrenceInOrder)
              FlowChip(
                label: r.label,
                selected: _recurrence == r,
                onTap: () =>
                    setState(() => _recurrence = _recurrence == r ? null : r),
              ),
          ],
        ),
        if (prolonged) ...[
          const SizedBox(height: 22),
          flowLabel('Aproximadamente de que idade até que idade?'),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _ageFromController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: flowFieldDecoration('De ___ anos'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _ageToController,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: flowFieldDecoration('Até ___ anos'),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ── Etapa 4 · Área da vida (§7) ──────────────────────────────────────────
  Widget _stepCategory() {
    final full = _categories.length >= 2;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        flowQuestion('Esse acontecimento estava relacionado principalmente a...'),
        flowHint('Selecione até duas opções.'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in kLifeCategoriesInOrder)
              FlowChip(
                label: c.label,
                selected: _categories.contains(c),
                dimmed: full && !_categories.contains(c),
                onTap: () => setState(() {
                  if (_categories.contains(c)) {
                    _categories.remove(c);
                  } else if (_categories.length < 2) {
                    _categories.add(c);
                  }
                }),
              ),
          ],
        ),
      ],
    );
  }

  // ── Etapa 7 · Do que precisava (§10) ─────────────────────────────────────
  Widget _stepNeeds() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        flowQuestion('Naquele momento, do que você mais precisava?'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in kEmotionalNeedsInOrder)
              if (n != EmotionalNeed.other)
                FlowChip(
                  label: n.label,
                  selected: _needs.contains(n),
                  onTap: () => setState(() {
                    _needs.contains(n) ? _needs.remove(n) : _needs.add(n);
                  }),
                ),
            FlowChip(
              label: 'Outro',
              selected: _needOtherOn,
              onTap: () => setState(() => _needOtherOn = !_needOtherOn),
            ),
          ],
        ),
        if (_needOtherOn) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _needOtherController,
            decoration: flowFieldDecoration('Do que mais você precisava?'),
          ),
        ],
        const SizedBox(height: 24),
        flowLabel('Você recebeu isso naquela época?'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final m in kNeedWasMetInOrder)
              FlowChip(
                label: m.label,
                selected: _needWasMet == m,
                onTap: () =>
                    setState(() => _needWasMet = _needWasMet == m ? null : m),
              ),
          ],
        ),
      ],
    );
  }

  // ── Etapa 8 · Significado (§11) ──────────────────────────────────────────
  Widget _stepMeaning() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        flowQuestion('Naquela época, você lembra do que pensava sobre você, '
            'sobre as outras pessoas ou sobre o que estava acontecendo?'),
        flowHint('Escreva do seu jeito. Não existe resposta certa.'),
        TextField(
          controller: _meaningController,
          maxLines: 5,
          decoration:
              flowFieldDecoration('Escreva do seu jeito. Não existe resposta certa.'),
        ),
      ],
    );
  }

  // ── Etapa 9 · E hoje (§12) ───────────────────────────────────────────────
  Widget _stepToday() {
    final showAreas = _stillInfluences == StillInfluences.yes ||
        _stillInfluences == StillInfluences.maybe;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        flowQuestion(
            'Quando você lembra desse acontecimento hoje, quanto ele ainda '
            'mexe com você?'),
        Slider(
          value: _influence,
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: AppColors.turquoise,
          label: '${_influence.round()}',
          onChanged: (v) => setState(() => _influence = v),
        ),
        const SizedBox(height: 20),
        flowLabel('Você sente que essa experiência ainda influencia alguma '
            'parte da sua vida?'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final s in kStillInfluencesInOrder)
              FlowChip(
                label: s.label,
                selected: _stillInfluences == s,
                onTap: () => setState(
                    () => _stillInfluences = _stillInfluences == s ? null : s),
              ),
          ],
        ),
        if (showAreas) ...[
          const SizedBox(height: 22),
          flowLabel('Em quais partes?'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final a in kPresentAreasInOrder)
                FlowChip(
                  label: a.label,
                  selected: _presentAreas.contains(a),
                  onTap: () => setState(() {
                    _presentAreas.contains(a)
                        ? _presentAreas.remove(a)
                        : _presentAreas.add(a);
                  }),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildNav() {
    final isLast = _step == _stepCount - 1;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          if (_step > 0)
            TextButton(
                onPressed: _busy ? null : _back, child: const Text('Voltar')),
          const Spacer(),
          FilledButton(
            onPressed: _busy ? null : (isLast ? _save : _next),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.navy,
              minimumSize: const Size(120, 46),
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : Text(isLast ? 'Salvar' : 'Avançar'),
          ),
        ],
      ),
    );
  }
}
