import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/error_banner.dart';
import '../../domain/library_work_full.dart';
import '../../providers/staff_library_providers.dart';

/// Sheet de indicação de obra ao paciente — objetivo terapêutico opcional
/// e escopo (filme completo / temporada / episódios).
///
/// Extraído da ficha da obra para ser reaberto também a partir do card da
/// lista, sem exigir que o psicólogo entre no detalhe primeiro.
class IndicateWorkSheet extends ConsumerStatefulWidget {
  const IndicateWorkSheet({
    super.key,
    required this.patientId,
    required this.work,
  });

  final String patientId;
  final LibraryWorkFull work;

  @override
  ConsumerState<IndicateWorkSheet> createState() => _IndicateWorkSheetState();
}

class _IndicateWorkSheetState extends ConsumerState<IndicateWorkSheet> {
  final _objective = TextEditingController();
  String _scope = 'Filme completo';
  bool _saving = false;

  bool get _isSeries =>
      widget.work.workType == 'Série' || widget.work.workType == 'Minissérie';

  @override
  void dispose() {
    _objective.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await ref.read(indicateWorkProvider.notifier).submit(
            patientId: widget.patientId,
            workId: widget.work.id,
            objective:
                _objective.text.trim().isEmpty ? null : _objective.text.trim(),
            scope: _scope,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Obra indicada ao paciente.')),
      );
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scopes = _isSeries
        ? const ['Série completa', 'Temporada', 'Episódio(s)']
        : const ['Filme completo'];
    if (!scopes.contains(_scope)) _scope = scopes.first;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Indicar “${widget.work.displayTitle}”',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          TextField(
            controller: _objective,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Objetivo terapêutico (opcional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          Text('Escopo', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (final s in scopes)
                ChoiceChip(
                  label: Text(s),
                  selected: _scope == s,
                  onSelected: (_) => setState(() => _scope = s),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.check),
            label: Text(_saving ? 'Indicando…' : 'Confirmar indicação'),
          ),
        ],
      ),
    );
  }
}

/// Abre o sheet de indicação como bottom sheet modal — atalho comum aos dois
/// pontos de entrada (card da lista e ficha da obra).
void showIndicateWorkSheet({
  required BuildContext context,
  required String patientId,
  required LibraryWorkFull work,
}) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => IndicateWorkSheet(patientId: patientId, work: work),
  );
}
