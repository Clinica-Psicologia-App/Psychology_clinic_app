import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../genogram/data/genogram_repository.dart';
import '../../genogram/domain/genogram_data.dart';
import '../../genogram/domain/genogram_layout_adapter.dart';
import '../../genogram/domain/genogram_person.dart';
import '../../genogram/domain/genogram_relationship_input.dart';
import '../../genogram/domain/genogram_relationship_type.dart';
import '../../genogram/presentation/genogram_routes.dart';
import '../../genogram/presentation/widgets/motor_genogram_diagram.dart';
import '../../genogram/providers/genogram_providers.dart';
import '../providers/life_story_providers.dart';
import 'widgets/genogram_diagram.dart';
import '../../../shared/widgets/brand_loading.dart';

/// Resultado visual — Genograma gráfico (spec §36–38). Mostra a estrutura
/// familiar em gerações, com camadas ligáveis: relações emocionais (camada 2)
/// e destaque das figuras de cuidado (camada 3, visão do terapeuta).
class GenogramDiagramPage extends ConsumerStatefulWidget {
  const GenogramDiagramPage({super.key, required this.patientId});

  final String patientId;

  @override
  ConsumerState<GenogramDiagramPage> createState() =>
      _GenogramDiagramPageState();
}

class _GenogramDiagramPageState extends ConsumerState<GenogramDiagramPage> {
  bool _showBonds = false;
  bool _highlightCaregivers = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Genograma',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: _body(),
    );
  }

  Widget _body() {
    // Com vínculos estruturais explícitos, desenha pelo MOTOR (árvore
    // bilateral, linhagens). Sem eles, cai no desenho por inferência de papel.
    final gdataAsync =
        ref.watch(genogramDataForPatientProvider(widget.patientId));

    // Durante reload (após edição), mostra loader em vez do dado antigo.
    if (gdataAsync.isLoading) return const BrandLoader();

    final gdata = gdataAsync.valueOrNull;
    if (gdata != null && MotorGenogramDiagram.hasStructure(gdata)) {
      final hasEmotional =
          emotionalRelations(gdata.relationships).isNotEmpty;
      return Column(
        children: [
          _motorControls(hasEmotional: hasEmotional, gdata: gdata),
          Expanded(
            child: Container(
              width: double.infinity,
              color: const Color(0xFFF3F5F9),
              child: MotorGenogramDiagram(
                data: gdata,
                showEmotional: _showBonds,
                onTapPerson: _openPerson,
              ),
            ),
          ),
          if (_showBonds) _bondLegend(),
          _note(),
        ],
      );
    }
    return _fallbackBody();
  }

  Widget _fallbackBody() {
    final familyAsync = ref.watch(familyForPatientProvider(widget.patientId));
    // Camada de relações tipadas (mãe×pai, etc.), secundária no desenho antigo.
    final relationships = ref
            .watch(genogramRelationshipsForPatientProvider(widget.patientId))
            .valueOrNull ??
        const [];
    return familyAsync.when(
      loading: () => const BrandLoader(),
      error: (e, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: OutlinedButton(
            onPressed: () =>
                ref.invalidate(familyForPatientProvider(widget.patientId)),
            child: const Text('Tentar de novo'),
          ),
        ),
      ),
      data: (people) {
        if (people.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(28),
              child: Text(
                'Ainda não há pessoas registradas para desenhar o genograma.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }
        return Column(
          children: [
            _bootstrapHint(),
            _controls(),
            Expanded(
              child: Container(
                width: double.infinity,
                color: const Color(0xFFF3F5F9),
                child: GenogramDiagram(
                  people: people,
                  relationships: relationships,
                  showBonds: _showBonds,
                  highlightCaregivers: _highlightCaregivers,
                ),
              ),
            ),
            if (_showBonds) _bondLegend(),
            _note(),
          ],
        );
      },
    );
  }

  /// Toque num símbolo do motor → abre o detalhe STANDALONE daquela pessoa
  /// (rota de topo, não reconstrói StaffPatientGenogramPage — evita o crash de
  /// GlobalKey ao cruzar de branch), com os vínculos e a linha do tempo dela.
  /// Da tela de detalhe dá para editar ou ir direto a um evento registrado.
  /// Ao voltar, revalida os dados do diagrama.
  Future<void> _openPerson(String personId) async {
    await context.push(
      GenogramRoutes.personDetailFor(widget.patientId, personId),
    );
    if (!mounted) return;
    ref.invalidate(genogramDataForPatientProvider(widget.patientId));
  }

  Future<void> _openAddBondSheet(BuildContext ctx, GenogramData gdata) async {
    await showModalBottomSheet<void>(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddEmotionalBondSheet(
        patientId: widget.patientId,
        people: gdata.people,
        repo: ref.read(genogramRepositoryProvider),
      ),
    );
    if (!mounted) return;
    ref.invalidate(genogramDataForPatientProvider(widget.patientId));
    if (_showBonds == false) setState(() => _showBonds = true);
  }

  Widget _motorControls({required bool hasEmotional, required GenogramData gdata}) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 6, 4, 6),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Mostrar relações'),
            selected: _showBonds,
            onSelected: (v) => setState(() => _showBonds = v),
            selectedColor: AppColors.turquoise.withValues(alpha: 0.18),
            checkmarkColor: AppColors.turquoise,
          ),
          const SizedBox(width: 6),
          if (_showBonds && !hasEmotional)
            const Expanded(
              child: Text(
                'Sem vínculos. Adicione um →',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted),
              ),
            )
          else
            const Spacer(),
          Builder(
            builder: (ctx) => TextButton.icon(
              onPressed: () => _openAddBondSheet(ctx, gdata),
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('Vínculo'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.turquoise,
                textStyle: const TextStyle(fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bootstrapHint() {
    return Material(
      color: const Color(0xFFEAF3F2),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
        child: Row(
          children: [
            const Icon(Icons.account_tree_outlined,
                size: 18, color: AppColors.turquoise),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Estrutura inferida do parentesco. Para a árvore por '
                'linhagens, sugira os vínculos a partir dos papéis.',
                style: TextStyle(fontSize: 12.5, color: AppColors.navy),
              ),
            ),
            TextButton(
              onPressed: () => context.push(
                GenogramRoutes.bootstrapFor(widget.patientId),
              ),
              child: const Text('Sugerir vínculos'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _controls() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 4,
        children: [
          FilterChip(
            label: const Text('Mostrar relações'),
            selected: _showBonds,
            onSelected: (v) => setState(() => _showBonds = v),
            selectedColor: AppColors.turquoise.withValues(alpha: 0.18),
            checkmarkColor: AppColors.turquoise,
          ),
          FilterChip(
            label: const Text('Destacar figuras de cuidado'),
            selected: _highlightCaregivers,
            onSelected: (v) => setState(() => _highlightCaregivers = v),
            selectedColor: AppColors.turquoise.withValues(alpha: 0.18),
            checkmarkColor: AppColors.turquoise,
          ),
        ],
      ),
    );
  }

  Widget _bondLegend() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 8),
      child: const Wrap(
        spacing: 14,
        runSpacing: 4,
        children: [
          _LegendItem(color: Color(0xFF2E7D6B), text: 'Próxima/afeto (linha dupla)'),
          _LegendItem(color: Color(0xFF6B7A90), text: 'Distante (tracejada)'),
          _LegendItem(color: Color(0xFFB5651D), text: 'Conflito (ziguezague)'),
          _LegendItem(color: Color(0xFFB03A3A), text: 'Rompimento (com traços)'),
        ],
      ),
    );
  }

  Widget _note() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      child: const Text(
        'Estrutura inferida do parentesco informado. Símbolos: ▢ masculino · '
        '○ feminino · ◇ outro · ✕ falecido. Arraste para mover, use dois dedos '
        'para aproximar.',
        style: TextStyle(fontSize: 11, color: AppColors.textMuted, height: 1.4),
      ),
    );
  }
}

// ── Sheet: adicionar vínculo emocional ────────────────────────────────────────

class _AddEmotionalBondSheet extends StatefulWidget {
  const _AddEmotionalBondSheet({
    required this.patientId,
    required this.people,
    required this.repo,
  });

  final String patientId;
  final List<GenogramPerson> people;
  final GenogramRepository repo;

  @override
  State<_AddEmotionalBondSheet> createState() => _AddEmotionalBondSheetState();
}

class _AddEmotionalBondSheetState extends State<_AddEmotionalBondSheet> {
  String? _personAId;
  String? _personBId;
  GenogramRelationshipType _kind = GenogramRelationshipType.close;
  bool _saving = false;
  String? _error;

  static const _emotional = [
    (type: GenogramRelationshipType.close,    label: 'Próxima',     color: Color(0xFF2E7D6B), icon: Icons.favorite_border_rounded),
    (type: GenogramRelationshipType.distant,  label: 'Distante',    color: Color(0xFF6B7A90), icon: Icons.remove_circle_outline_rounded),
    (type: GenogramRelationshipType.conflict, label: 'Conflituosa', color: Color(0xFFB5651D), icon: Icons.bolt_rounded),
    (type: GenogramRelationshipType.ruptured, label: 'Rompida',     color: Color(0xFFB03A3A), icon: Icons.link_off_rounded),
  ];

  List<DropdownMenuItem<String>> _personItems({String? excludeId}) {
    return [
      for (final p in widget.people)
        if (p.id != excludeId)
          DropdownMenuItem(
            value: p.id,
            child: Text(
              p.nickname?.trim().isNotEmpty == true
                  ? p.nickname!.trim()
                  : p.fullName,
              overflow: TextOverflow.ellipsis,
            ),
          ),
    ];
  }

  Future<void> _save() async {
    if (_personAId == null || _personBId == null) {
      setState(() => _error = 'Selecione as duas pessoas.');
      return;
    }
    setState(() { _saving = true; _error = null; });
    try {
      final ctx = await widget.repo.resolvePatientContext(
        patientId: widget.patientId,
      );
      await widget.repo.createRelationship(
        clinicId: ctx.clinicId,
        patientId: ctx.patientId,
        input: GenogramRelationshipInput(
          personAId: _personAId!,
          personBId: _personBId!,
          relationshipType: _kind,
        ),
      );
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) setState(() { _saving = false; _error = 'Não foi possível salvar. Tente novamente.'; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, 24 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Novo vínculo emocional',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 4),
          const Text(
            'Registre a qualidade da relação entre duas pessoas do genograma.',
            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          // ── Tipo ──
          const Text('Tipo de vínculo',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final e in _emotional)
                _KindChip(
                  label: e.label,
                  icon: e.icon,
                  color: e.color,
                  selected: _kind == e.type,
                  onTap: () => setState(() => _kind = e.type),
                ),
            ],
          ),
          const SizedBox(height: 20),
          // ── Pessoas ──
          const Text('Pessoas envolvidas',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _personAId,
                  decoration: const InputDecoration(labelText: 'Pessoa A'),
                  items: _personItems(excludeId: _personBId),
                  onChanged: (v) => setState(() => _personAId = v),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _personBId,
                  decoration: const InputDecoration(labelText: 'Pessoa B'),
                  items: _personItems(excludeId: _personAId),
                  onChanged: (v) => setState(() => _personBId = v),
                ),
              ),
            ],
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: Colors.red, fontSize: 13)),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(backgroundColor: AppColors.turquoise),
              child: _saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Salvar vínculo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _KindChip extends StatelessWidget {
  const _KindChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.12) : const Color(0xFFF5F7FA),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? color : AppColors.textMuted),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({required this.color, required this.text});
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 16, height: 3, color: color),
        const SizedBox(width: 6),
        Text(text,
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}
