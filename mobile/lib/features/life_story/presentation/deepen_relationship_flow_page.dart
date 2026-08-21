import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_banner.dart';
import '../domain/family_person.dart';
import '../domain/genogram_relationship_enums.dart';
import '../providers/life_story_providers.dart';
import 'widgets/flow_ui.dart';

/// "Aprofundar a relação" com uma pessoa da família (Tela 3).
/// Etapas 3, 4, 7, 8, 9 e 10 da spec (§22, §23, §26, §27, §28, §29).
/// As Etapas 5 e 6 são retiradas conforme a própria spec sugere.
class DeepenRelationshipFlowPage extends ConsumerStatefulWidget {
  const DeepenRelationshipFlowPage({super.key, required this.person});

  final FamilyPerson person;

  @override
  ConsumerState<DeepenRelationshipFlowPage> createState() =>
      _DeepenRelationshipFlowPageState();
}

class _DeepenRelationshipFlowPageState
    extends ConsumerState<DeepenRelationshipFlowPage> {
  static const _stepCount = 6;
  int _step = 0;
  bool _busy = false;

  CaregiverRole? _caregiverRole;
  double _closeness = 0;
  double _conflict = 0;
  BondType? _bondType;
  final _bondChangeController = TextEditingController();
  final Set<FeltInRelationship> _felt = {};
  final Set<RelationalNeed> _received = {};
  final Set<RelationalNeed> _wished = {};
  bool _gotWhatNeeded = false;
  CurrentRelationship? _current;
  final _currentNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    _caregiverRole = p.caregiverRole;
    _closeness = (p.closeness ?? 0).toDouble();
    _conflict = (p.conflict ?? 0).toDouble();
    _bondType = p.bondType;
    _bondChangeController.text = p.bondChangeNote ?? '';
    _felt.addAll(p.feltInRelationship);
    _received.addAll(p.receivedNeeds);
    _wished.addAll(p.wishedMoreNeeds);
    _gotWhatNeeded = p.gotWhatNeeded;
    _current = p.currentRelationship;
    _currentNoteController.text = p.currentRelationshipNote ?? '';
  }

  @override
  void dispose() {
    _bondChangeController.dispose();
    _currentNoteController.dispose();
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
    final p = widget.person;
    final updated = FamilyPerson(
      id: p.id,
      fullName: p.fullName,
      role: p.role,
      gender: p.gender,
      ageApprox: p.ageApprox,
      deceasedStatus: p.deceasedStatus,
      deathAge: p.deathAge,
      caregiverRole: _caregiverRole,
      closeness: _closeness.round(),
      conflict: _conflict.round(),
      bondType: _bondType,
      bondChangeNote: _bondType == BondType.changed &&
              _bondChangeController.text.trim().isNotEmpty
          ? _bondChangeController.text.trim()
          : null,
      feltInRelationship: _felt.toList(),
      receivedNeeds: _received.toList(),
      wishedMoreNeeds: _wished.toList(),
      gotWhatNeeded: _gotWhatNeeded,
      currentRelationship: _current,
      currentRelationshipNote: _currentNoteController.text.trim().isEmpty
          ? null
          : _currentNoteController.text.trim(),
    );
    try {
      await ref
          .read(saveFamilyPersonProvider.notifier)
          .updatePerson(p.id, updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Relação aprofundada.')),
      );
      context.pop();
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
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
            title: widget.person.fullName,
            step: _step,
            stepCount: _stepCount,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: switch (_step) {
                0 => _stepCaregiver(),
                1 => _stepBond(),
                2 => _stepFelt(),
                3 => _stepReceived(),
                4 => _stepWished(),
                _ => _stepToday(),
              },
            ),
          ),
          _buildNav(),
        ],
      ),
    );
  }

  // ── Etapa 3 · Papel de cuidado (§22) ─────────────────────────────────────
  Widget _stepCaregiver() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        flowQuestion('Essa pessoa participou da sua criação ou cuidou de você '
            'durante sua infância ou adolescência?'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final r in kCaregiverRolesInOrder)
              FlowChip(
                label: r.label,
                selected: _caregiverRole == r,
                onTap: () => setState(
                    () => _caregiverRole = _caregiverRole == r ? null : r),
              ),
          ],
        ),
      ],
    );
  }

  // ── Etapa 4 · Como era a relação (§23) ───────────────────────────────────
  Widget _stepBond() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        flowHint('Pensando principalmente na época em que você estava '
            'crescendo...'),
        flowLabel('Quanto você se sentia próximo(a) dessa pessoa?'),
        _scale(_closeness, 'Nada próximo', 'Muito próximo',
            (v) => setState(() => _closeness = v)),
        const SizedBox(height: 18),
        flowLabel('Quanto conflito existia entre vocês?'),
        _scale(_conflict, 'Nenhum', 'Muito conflito',
            (v) => setState(() => _conflict = v)),
        const SizedBox(height: 22),
        flowLabel('De forma geral, como você descreveria essa relação?'),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final b in kBondTypesInOrder)
              FlowChip(
                label: b.label,
                selected: _bondType == b,
                onTap: () =>
                    setState(() => _bondType = _bondType == b ? null : b),
              ),
          ],
        ),
        if (_bondType == BondType.changed) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _bondChangeController,
            maxLines: 3,
            decoration:
                flowFieldDecoration('Conte brevemente como essa relação mudou.'),
          ),
        ],
      ],
    );
  }

  // ── Etapa 7 · Como me sentia (§26) ───────────────────────────────────────
  Widget _stepFelt() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        flowQuestion('Quando você estava com essa pessoa, geralmente se '
            'sentia...'),
        const SizedBox(height: 14),
        _multiChips(
          kFeltInRelationshipInOrder,
          (f) => f.label,
          (f) => _felt.contains(f),
          (f) => setState(
              () => _felt.contains(f) ? _felt.remove(f) : _felt.add(f)),
        ),
      ],
    );
  }

  // ── Etapa 8 · O que recebi (§27) ─────────────────────────────────────────
  Widget _stepReceived() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        flowQuestion('O que você sente que recebeu dessa pessoa e foi '
            'importante para você?'),
        const SizedBox(height: 14),
        _multiChips(
          kRelationalNeedsInOrder,
          (n) => n.label,
          (n) => _received.contains(n),
          (n) => setState(() =>
              _received.contains(n) ? _received.remove(n) : _received.add(n)),
        ),
      ],
    );
  }

  // ── Etapa 9 · O que gostaria de ter recebido mais (§28) ──────────────────
  Widget _stepWished() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        flowQuestion('O que você gostaria de ter recebido mais?'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final n in kRelationalNeedsInOrder)
              FlowChip(
                label: n.label,
                selected: _wished.contains(n),
                onTap: () => setState(() =>
                    _wished.contains(n) ? _wished.remove(n) : _wished.add(n)),
              ),
            FlowChip(
              label: 'Sinto que recebi o que precisava',
              selected: _gotWhatNeeded,
              onTap: () => setState(() => _gotWhatNeeded = !_gotWhatNeeded),
            ),
          ],
        ),
      ],
    );
  }

  // ── Etapa 10 · Relação hoje (§29) ────────────────────────────────────────
  Widget _stepToday() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        flowQuestion('Como está sua relação com essa pessoa hoje?'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in kCurrentRelationshipInOrder)
              FlowChip(
                label: c.label,
                selected: _current == c,
                onTap: () =>
                    setState(() => _current = _current == c ? null : c),
              ),
          ],
        ),
        const SizedBox(height: 22),
        flowLabel('Existe algo importante sobre essa relação hoje que você '
            'gostaria de registrar?'),
        const SizedBox(height: 8),
        TextField(
          controller: _currentNoteController,
          maxLines: 3,
          decoration: flowFieldDecoration('Opcional'),
        ),
      ],
    );
  }

  Widget _multiChips<T>(
    List<T> items,
    String Function(T) label,
    bool Function(T) selected,
    void Function(T) onTap,
  ) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final it in items)
            FlowChip(
                label: label(it), selected: selected(it), onTap: () => onTap(it)),
        ],
      );

  Widget _scale(
    double value,
    String low,
    String high,
    ValueChanged<double> onChanged,
  ) =>
      Column(
        children: [
          Slider(
            value: value,
            min: 0,
            max: 10,
            divisions: 10,
            activeColor: AppColors.turquoise,
            label: '${value.round()}',
            onChanged: onChanged,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(low,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
                Text(high,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      );

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
