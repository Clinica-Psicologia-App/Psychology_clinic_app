import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_banner.dart';
import '../domain/family_context.dart';
import '../providers/life_story_providers.dart';
import 'widgets/flow_ui.dart';

/// Clima e padrões da família (Tela 3, §32–33) — perguntas sobre a família
/// como um todo. Recebe o contexto atual e complementa.
class FamilyContextFlowPage extends ConsumerStatefulWidget {
  const FamilyContextFlowPage({super.key, required this.context});

  final FamilyContext context;

  @override
  ConsumerState<FamilyContextFlowPage> createState() =>
      _FamilyContextFlowPageState();
}

class _FamilyContextFlowPageState extends ConsumerState<FamilyContextFlowPage> {
  static const _stepCount = 2;
  int _step = 0;
  bool _busy = false;

  final Set<ClimateTrait> _climate = {};
  final _climateNoteController = TextEditingController();
  HasPatterns? _hasPatterns;
  final Set<PatternTrait> _patterns = {};
  final Set<PatternGeneration> _generations = {};
  final _patternsNoteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final c = widget.context;
    _climate.addAll(c.climateTraits);
    _climateNoteController.text = c.climateNote ?? '';
    _hasPatterns = c.hasPatterns;
    _patterns.addAll(c.patternTraits);
    _generations.addAll(c.patternGenerations);
    _patternsNoteController.text = c.patternsNote ?? '';
  }

  @override
  void dispose() {
    _climateNoteController.dispose();
    _patternsNoteController.dispose();
    super.dispose();
  }

  bool get _showPatternDetail =>
      _hasPatterns == HasPatterns.yes || _hasPatterns == HasPatterns.maybe;

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final ctx = FamilyContext(
      climateTraits: _climate.toList(),
      climateNote: _climateNoteController.text.trim().isEmpty
          ? null
          : _climateNoteController.text.trim(),
      hasPatterns: _hasPatterns,
      patternTraits: _showPatternDetail ? _patterns.toList() : const [],
      patternGenerations:
          _showPatternDetail ? _generations.toList() : const [],
      patternsNote: _showPatternDetail &&
              _patternsNoteController.text.trim().isNotEmpty
          ? _patternsNoteController.text.trim()
          : null,
    );
    try {
      await ref.read(saveFamilyContextProvider.notifier).submit(ctx);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrado.')),
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
            title: 'O clima da minha família',
            step: _step,
            stepCount: _stepCount,
            onBack: () => context.pop(),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: _step == 0 ? _stepClimate() : _stepPatterns(),
            ),
          ),
          _buildNav(),
        ],
      ),
    );
  }

  // ── Etapa 12 · Clima da família (§32) ────────────────────────────────────
  Widget _stepClimate() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        flowHint('Pensando na família em que você cresceu...'),
        flowQuestion('O que costumava acontecer em casa?'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in kClimateTraitsInOrder)
              FlowChip(
                label: t.label,
                selected: _climate.contains(t),
                onTap: () => setState(() =>
                    _climate.contains(t) ? _climate.remove(t) : _climate.add(t)),
              ),
          ],
        ),
        const SizedBox(height: 24),
        flowLabel('Se tivesse que descrever o clima da sua família em poucas '
            'palavras, como descreveria?'),
        const SizedBox(height: 8),
        TextField(
          controller: _climateNoteController,
          maxLines: 3,
          decoration: flowFieldDecoration(
              'Ex.: Todos se gostavam, mas ninguém falava sobre sentimentos.'),
        ),
      ],
    );
  }

  // ── Etapa 13 · Padrões transgeracionais (§33) ────────────────────────────
  Widget _stepPatterns() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        flowQuestion('Olhando para diferentes gerações da sua família, '
            'existem situações ou formas de se relacionar que parecem se '
            'repetir?'),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final h in kHasPatternsInOrder)
              FlowChip(
                label: h.label,
                selected: _hasPatterns == h,
                onTap: () =>
                    setState(() => _hasPatterns = _hasPatterns == h ? null : h),
              ),
          ],
        ),
        if (_showPatternDetail) ...[
          const SizedBox(height: 24),
          flowLabel('Quais você percebe?'),
          for (final group in PatternGroup.values) ...[
            const SizedBox(height: 14),
            Text(group.label,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final p
                    in kPatternTraitsInOrder.where((p) => p.group == group))
                  FlowChip(
                    label: p.label,
                    selected: _patterns.contains(p),
                    onTap: () => setState(() => _patterns.contains(p)
                        ? _patterns.remove(p)
                        : _patterns.add(p)),
                  ),
              ],
            ),
          ],
          const SizedBox(height: 24),
          flowLabel('Em quais gerações você percebe esse padrão?'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final g in kPatternGenerationsInOrder)
                FlowChip(
                  label: g.label,
                  selected: _generations.contains(g),
                  onTap: () => setState(() => _generations.contains(g)
                      ? _generations.remove(g)
                      : _generations.add(g)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          flowLabel('Existe algum padrão da sua família que você considera '
              'importante entender melhor?'),
          const SizedBox(height: 8),
          TextField(
            controller: _patternsNoteController,
            maxLines: 3,
            decoration: flowFieldDecoration('Opcional'),
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
                onPressed: _busy ? null : () => setState(() => _step--),
                child: const Text('Voltar')),
          const Spacer(),
          FilledButton(
            onPressed: _busy
                ? null
                : (isLast ? _save : () => setState(() => _step++)),
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
