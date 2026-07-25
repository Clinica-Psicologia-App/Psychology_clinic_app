import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../domain/life_chapter.dart';
import '../../domain/timeline_belief.dart';
import '../../domain/timeline_entry.dart';
import '../../providers/patient_history_providers.dart';

/// Abre o editor de um evento da Linha do Tempo (criar ou editar).
Future<void> showTimelineEventEditor({
  required BuildContext context,
  required InitialAssessmentContext ctx,
  LifeChapter? initialChapter,
  TimelineEntry? entry,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _TimelineEventEditor(
      ctx: ctx,
      initialChapter: initialChapter,
      entry: entry,
    ),
  );
}

class _TimelineEventEditor extends ConsumerStatefulWidget {
  const _TimelineEventEditor({
    required this.ctx,
    this.initialChapter,
    this.entry,
  });

  final InitialAssessmentContext ctx;
  final LifeChapter? initialChapter;
  final TimelineEntry? entry;

  @override
  ConsumerState<_TimelineEventEditor> createState() =>
      _TimelineEventEditorState();
}

class _TimelineEventEditorState extends ConsumerState<_TimelineEventEditor> {
  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _age;
  late final TextEditingController _beliefOther;
  late LifeChapter? _chapter;
  int? _impact;
  final Set<TimelineBelief> _beliefs = {};
  bool _saving = false;

  bool get _isEditing => widget.entry != null;

  @override
  void initState() {
    super.initState();
    final e = widget.entry;
    _title = TextEditingController(text: e?.title ?? '');
    _description = TextEditingController(text: e?.description ?? '');
    _age = TextEditingController(text: e?.ageAtEvent?.toString() ?? '');
    _beliefOther = TextEditingController(text: e?.beliefOther ?? '');
    _chapter = e?.lifeChapter ?? widget.initialChapter;
    _impact = e?.emotionalImpact;
    _beliefs.addAll(e?.beliefs ?? const []);
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _age.dispose();
    _beliefOther.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_title.text.trim().isEmpty) {
      showErrorBanner(context, 'Descreva o acontecimento.');
      return;
    }
    setState(() => _saving = true);
    final notifier =
        ref.read(patientHistoryMutationProvider(widget.ctx).notifier);
    final age = int.tryParse(_age.text.trim());
    final beliefOther = _beliefOther.text.trim();
    try {
      if (_isEditing) {
        await notifier.updateEntry(
          eventId: widget.entry!.id,
          title: _title.text,
          lifeChapter: _chapter,
          description: _nullIfEmpty(_description.text),
          ageAtEvent: age,
          emotionalImpact: _impact,
          beliefs: _beliefs.toList(),
          beliefOther: beliefOther.isEmpty ? null : beliefOther,
        );
      } else {
        await notifier.createEntry(
          title: _title.text,
          lifeChapter: _chapter,
          description: _nullIfEmpty(_description.text),
          ageAtEvent: age,
          emotionalImpact: _impact,
          beliefs: _beliefs.toList(),
          beliefOther: beliefOther.isEmpty ? null : beliefOther,
        );
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Excluir acontecimento?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogCtx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await ref
          .read(patientHistoryMutationProvider(widget.ctx).notifier)
          .deleteEntry(widget.entry!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 4, 20, 16 + bottomInset),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isEditing ? 'Editar acontecimento' : 'Novo acontecimento',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<LifeChapter>(
                initialValue: _chapter,
                decoration: const InputDecoration(labelText: 'Fase da vida'),
                items: [
                  for (final c in kLifeChaptersInOrder)
                    DropdownMenuItem(value: c, child: Text(c.label)),
                ],
                onChanged: (v) => setState(() => _chapter = v),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _title,
                minLines: 1,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Qual foi um acontecimento importante dessa fase?',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _age,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  labelText: 'Quantos anos você tinha?',
                ),
              ),
              const SizedBox(height: 16),
              _impactRow(theme),
              const SizedBox(height: 8),
              TextField(
                controller: _description,
                minLines: 2,
                maxLines: 5,
                decoration: const InputDecoration(
                  labelText: 'Gostaria de contar um pouco mais?',
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Depois de viver essas experiências, o que você passou a pensar '
                'sobre você mesmo(a)?',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 4),
              for (final belief in kTimelineBeliefsInOrder)
                CheckboxListTile(
                  value: _beliefs.contains(belief),
                  onChanged: (_) => setState(() {
                    if (!_beliefs.remove(belief)) _beliefs.add(belief);
                  }),
                  controlAffinity: ListTileControlAffinity.leading,
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(belief.label),
                ),
              TextField(
                controller: _beliefOther,
                decoration: const InputDecoration(
                  labelText: 'Outro (opcional)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  if (_isEditing)
                    TextButton.icon(
                      onPressed: _saving ? null : _delete,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Excluir'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.error),
                    ),
                  const Spacer(),
                  FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.check),
                    label: Text(_saving ? 'Salvando...' : 'Salvar'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _impactRow(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Qual foi o impacto emocional?',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: AppColors.textSecondary),
              ),
            ),
            Text(
              _impact?.toString() ?? '—',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const Text('/10'),
          ],
        ),
        Slider(
          value: (_impact ?? 0).toDouble(),
          max: 10,
          divisions: 10,
          label: (_impact ?? 0).toString(),
          onChanged: (v) => setState(() => _impact = v.round()),
        ),
      ],
    );
  }
}
