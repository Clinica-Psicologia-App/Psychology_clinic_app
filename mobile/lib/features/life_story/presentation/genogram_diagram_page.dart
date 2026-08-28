import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
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
    final familyAsync = ref.watch(familyForPatientProvider(widget.patientId));
    // Camada de relações tipadas (mãe×pai, etc.). Secundária: se falhar ou
    // estiver vazia, o diagrama ainda desenha a estrutura normalmente.
    final relationships = ref
            .watch(genogramRelationshipsForPatientProvider(widget.patientId))
            .valueOrNull ??
        const [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Genograma',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: familyAsync.when(
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
