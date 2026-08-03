import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/schema_activation.dart';
import '../../domain/scoring_schema_result.dart';
import '../../domain/scoring_snapshot.dart';
import '../../providers/results_providers.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Two-column card showing activated (● auto / ◎ psi) and inactive schemas.
/// For staff: inactive schemas are tappable to activate.
/// For patients: only shows activated schemas with legend.
class SchemaAtivadosCard extends ConsumerWidget {
  const SchemaAtivadosCard({
    super.key,
    required this.scoring,
    required this.activations,
    required this.isStaff,
    required this.responseId,
  });

  final ScoringSnapshot scoring;
  final List<SchemaActivation> activations;
  final bool isStaff;
  final String responseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final schemas = scoring.schemas;
    if (schemas.isEmpty) return const SizedBox.shrink();

    final psiMap = {for (final a in activations) a.schemaCode: a};

    final ativados = <({ScoringSchemaResult schema, bool isPsi})>[];
    final inativos = <ScoringSchemaResult>[];

    for (final s in schemas) {
      final isAuto = (s.averageScore ?? 0) >= kSchemaActivationThreshold;
      final isPsi = psiMap.containsKey(s.code);
      if (isAuto || isPsi) {
        ativados.add((schema: s, isPsi: isPsi && !isAuto));
      } else {
        inativos.add(s);
      }
    }

    ativados.sort(
      (a, b) =>
          (b.schema.averageScore ?? 0).compareTo(a.schema.averageScore ?? 0),
    );
    inativos.sort(
      (a, b) => (b.averageScore ?? 0).compareTo(a.averageScore ?? 0),
    );

    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.schema_outlined, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Perfil esquemático',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                _CountBadge(
                  count: ativados.length,
                  color: const Color(0xFFE24B4A),
                  label: 'ativos',
                ),
                const SizedBox(width: 6),
                if (isStaff)
                  _CountBadge(
                    count: inativos.length,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    label: 'não ativados',
                  ),
              ],
            ),
            const SizedBox(height: 14),
            if (isStaff)
              _StaffView(
                ativados: ativados,
                inativos: inativos,
                psiMap: psiMap,
                responseId: responseId,
              )
            else
              _PatientView(ativados: ativados),
            if (!isStaff) ...[
              const SizedBox(height: 12),
              const _SymbolLegend(),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Staff view: two columns ─────────────────────────────────────────────────

class _StaffView extends ConsumerWidget {
  const _StaffView({
    required this.ativados,
    required this.inativos,
    required this.psiMap,
    required this.responseId,
  });

  final List<({ScoringSchemaResult schema, bool isPsi})> ativados;
  final List<ScoringSchemaResult> inativos;
  final Map<String, SchemaActivation> psiMap;
  final String responseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left: Ativados
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ColumnHeader(
                icon: Icons.check_circle_outline,
                label: 'Ativados',
                color: const Color(0xFFE24B4A),
              ),
              const SizedBox(height: 6),
              if (ativados.isEmpty)
                Text(
                  'Nenhum',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                )
              else
                ...ativados.map(
                  (item) => _AtivadoRow(
                    schema: item.schema,
                    isPsi: item.isPsi,
                    activation: item.isPsi ? psiMap[item.schema.code] : null,
                    onEdit: () => _openActivateSheet(
                      context,
                      ref,
                      item.schema,
                      existing: psiMap[item.schema.code],
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 1),
        Container(
          width: 1,
          height: (ativados.length > inativos.length
                      ? ativados.length
                      : inativos.length) *
                  32.0 +
              40,
          color: Theme.of(context).dividerColor,
        ),
        const SizedBox(width: 12),
        // Right: Inativos
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ColumnHeader(
                icon: Icons.radio_button_unchecked,
                label: 'Não ativados',
                color: cs.onSurfaceVariant,
              ),
              const SizedBox(height: 6),
              if (inativos.isEmpty)
                Text(
                  'Nenhum',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                )
              else
                ...inativos.map(
                  (s) => _InativoRow(
                    schema: s,
                    onTap: () => _openActivateSheet(context, ref, s),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  void _openActivateSheet(
    BuildContext context,
    WidgetRef ref,
    ScoringSchemaResult schema, {
    SchemaActivation? existing,
  }) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _ActivateSchemaSheet(
        schema: schema,
        responseId: responseId,
        existing: existing,
      ),
    );
  }
}

// ── Patient view: single column ─────────────────────────────────────────────

class _PatientView extends StatelessWidget {
  const _PatientView({required this.ativados});

  final List<({ScoringSchemaResult schema, bool isPsi})> ativados;

  @override
  Widget build(BuildContext context) {
    if (ativados.isEmpty) {
      return Text(
        'Nenhum esquema ativado neste instrumento.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontStyle: FontStyle.italic,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: ativados
          .map(
            (item) => _AtivadoRowPatient(
              schema: item.schema,
              isPsi: item.isPsi,
            ),
          )
          .toList(),
    );
  }
}

// ── Row widgets ─────────────────────────────────────────────────────────────

class _AtivadoRow extends StatelessWidget {
  const _AtivadoRow({
    required this.schema,
    required this.isPsi,
    this.activation,
    this.onEdit,
  });

  final ScoringSchemaResult schema;
  final bool isPsi;
  final SchemaActivation? activation;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final color = isPsi ? AppColors.purple : const Color(0xFFE24B4A);
    final symbol = isPsi ? '◎' : '●';
    final obs = activation?.psiObservation;

    return GestureDetector(
      onTap: isPsi ? onEdit : null,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(symbol,
                style: TextStyle(
                    color: color, fontSize: 11, fontWeight: FontWeight.w900)),
            const SizedBox(width: 5),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schema.name,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight:
                              isPsi ? FontWeight.w600 : FontWeight.normal,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (obs != null && obs.isNotEmpty)
                    Text(
                      'Obs: $obs',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: AppColors.purple.withValues(alpha: 0.75),
                            fontStyle: FontStyle.italic,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              schema.averageScore?.toStringAsFixed(1) ?? '-',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AtivadoRowPatient extends StatelessWidget {
  const _AtivadoRowPatient({required this.schema, required this.isPsi});

  final ScoringSchemaResult schema;
  final bool isPsi;

  @override
  Widget build(BuildContext context) {
    final color = isPsi ? AppColors.purple : const Color(0xFFE24B4A);
    final symbol = isPsi ? '◎' : '●';

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(symbol,
              style: TextStyle(
                  color: color, fontSize: 12, fontWeight: FontWeight.w900)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              schema.name,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            schema.averageScore?.toStringAsFixed(1) ?? '-',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _InativoRow extends StatelessWidget {
  const _InativoRow({required this.schema, this.onTap});

  final ScoringSchemaResult schema;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          children: [
            Icon(Icons.add_circle_outline,
                size: 13, color: cs.onSurfaceVariant),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                schema.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              schema.averageScore?.toStringAsFixed(1) ?? '-',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Activate sheet ──────────────────────────────────────────────────────────

class _ActivateSchemaSheet extends ConsumerStatefulWidget {
  const _ActivateSchemaSheet({
    required this.schema,
    required this.responseId,
    this.existing,
  });

  final ScoringSchemaResult schema;
  final String responseId;
  final SchemaActivation? existing;

  @override
  ConsumerState<_ActivateSchemaSheet> createState() =>
      _ActivateSchemaSheetState();
}

class _ActivateSchemaSheetState extends ConsumerState<_ActivateSchemaSheet> {
  late final TextEditingController _obsController;
  bool _saving = false;

  bool get _isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _obsController = TextEditingController(
      text: widget.existing?.psiObservation ?? '',
    );
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(manageSchemaActivationProvider(widget.responseId).notifier)
          .activate(
            widget.schema.code,
            widget.schema.name,
            observation: _obsController.text.trim().isEmpty
                ? null
                : _obsController.text.trim(),
          );
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _deactivate() async {
    setState(() => _saving = true);
    try {
      await ref
          .read(manageSchemaActivationProvider(widget.responseId).notifier)
          .deactivate(widget.schema.code);
      if (mounted) Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final score = widget.schema.averageScore;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 24,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('◎',
                  style: TextStyle(color: AppColors.purple, fontSize: 18)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _isEditing ? 'Editar ativação' : 'Ativar esquema',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.schema.name,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          if (score != null) ...[
            const SizedBox(height: 2),
            Text(
              'Score do instrumento: ${score.toStringAsFixed(2)} '
              '(abaixo do limiar de 4.0)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _obsController,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Observação clínica (opcional, privada)',
              hintText: 'Justificativa da ativação — não visível ao paciente',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              if (_isEditing)
                TextButton.icon(
                  onPressed: _saving ? null : _deactivate,
                  icon: const Icon(Icons.remove_circle_outline, size: 18),
                  label: const Text('Remover ativação'),
                  style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: _saving ? null : () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _saving ? null : _save,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_outlined, size: 18),
                label: Text(_isEditing ? 'Salvar' : 'Ativar'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Shared small widgets ────────────────────────────────────────────────────

class _ColumnHeader extends StatelessWidget {
  const _ColumnHeader({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
        ),
      ],
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({
    required this.count,
    required this.color,
    required this.label,
  });

  final int count;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count $label',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

class _SymbolLegend extends StatelessWidget {
  const _SymbolLegend();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Wrap(
        spacing: 16,
        runSpacing: 4,
        children: [
          _LegendItem(
            symbol: '●',
            color: const Color(0xFFE24B4A),
            label: 'Ativado pelo sistema',
          ),
          _LegendItem(
            symbol: '◎',
            color: AppColors.purple,
            label: 'Ativado pelo psicólogo',
          ),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.symbol,
    required this.color,
    required this.label,
  });

  final String symbol;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          symbol,
          style: TextStyle(
              color: color, fontWeight: FontWeight.w900, fontSize: 11),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}
