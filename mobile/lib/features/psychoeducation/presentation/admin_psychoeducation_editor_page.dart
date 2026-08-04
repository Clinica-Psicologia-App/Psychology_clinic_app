import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../domain/psychoeducation_module.dart';
import '../providers/psychoeducation_providers.dart';

/// Editor de módulo de psicoeducação (criar ou editar): metadados + cards.
class AdminPsychoeducationEditorPage extends ConsumerStatefulWidget {
  const AdminPsychoeducationEditorPage({super.key, this.moduleId});

  /// Nulo = criar novo módulo.
  final String? moduleId;

  @override
  ConsumerState<AdminPsychoeducationEditorPage> createState() =>
      _AdminPsychoeducationEditorPageState();
}

class _AdminPsychoeducationEditorPageState
    extends ConsumerState<AdminPsychoeducationEditorPage> {
  static const _stages = ['Conhecer', 'Compreender', 'Transformar'];

  final _formKey = GlobalKey<FormState>();

  final _number = TextEditingController();
  final _title = TextEditingController();
  final _presentation = TextEditingController();
  final _closing = TextEditingController();
  final _accentColor = TextEditingController();
  final _coverUrl = TextEditingController();

  String _stage = 'Compreender';
  bool _isPublished = true;
  final List<_CardField> _cards = [];

  bool get _isEditing => widget.moduleId != null;
  bool _loading = false;
  bool _saving = false;
  bool _uploadingCover = false;
  String? _loadError;

  @override
  void initState() {
    super.initState();
    if (_isEditing) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final m = await ref
          .read(adminPsychoeducationRepositoryProvider)
          .getModule(widget.moduleId!);
      if (m != null) _populate(m);
      if (mounted) setState(() => _loading = false);
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _loadError = _message(e);
        });
      }
    }
  }

  void _populate(PsychoeducationModule m) {
    _number.text = m.number.toString();
    _stage = _stages.contains(m.stage) ? m.stage : 'Compreender';
    _title.text = m.title;
    _presentation.text = m.presentation ?? '';
    _closing.text = m.closing ?? '';
    _accentColor.text = m.accentColor ?? '';
    _coverUrl.text = m.coverUrl ?? '';
    _cards
      ..clear()
      ..addAll(m.cards.map(_CardField.fromCard));
  }

  @override
  void dispose() {
    for (final c in [
      _number,
      _title,
      _presentation,
      _closing,
      _accentColor,
      _coverUrl,
    ]) {
      c.dispose();
    }
    for (final c in _cards) {
      c.dispose();
    }
    super.dispose();
  }

  String? _nn(String s) => s.trim().isEmpty ? null : s.trim();

  Map<String, dynamic> _buildValues() {
    return {
      'number': int.tryParse(_number.text.trim()) ?? 0,
      'stage': _stage,
      'title': _title.text.trim(),
      'presentation': _nn(_presentation.text),
      'closing': _nn(_closing.text),
      'accent_color': _nn(_accentColor.text),
      'cover_url': _nn(_coverUrl.text),
      'is_published': _isPublished,
      'cards': _cards
          .where((c) => c.title.text.trim().isNotEmpty)
          .map((c) => {
                'title': c.title.text.trim(),
                'image_url': _nn(c.imageUrl.text),
                'patient_text': _nn(c.patientText.text),
                'therapist_text': _nn(c.therapistText.text),
                'reflection': _nn(c.reflection.text),
                'exercise': _nn(c.exercise.text),
              })
          .toList(),
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(psychoMutationProvider.notifier).save(
            id: widget.moduleId,
            values: _buildValues(),
          );
      ref.invalidate(adminPsychoListProvider);
      if (widget.moduleId != null) {
        ref.invalidate(adminPsychoModuleProvider(widget.moduleId!));
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Módulo salvo.')),
        );
        Navigator.of(context).maybePop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message(e))),
        );
      }
    }
  }

  Future<void> _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover módulo?'),
        content: const Text('O módulo sai da Biblioteca de Psicoeducação.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    setState(() => _saving = true);
    try {
      await ref.read(psychoMutationProvider.notifier).delete(widget.moduleId!);
      ref.invalidate(adminPsychoListProvider);
      if (mounted) Navigator.of(context).maybePop();
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message(e))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: _isEditing ? 'Editar módulo' : 'Novo módulo',
      subtitle: 'Biblioteca de Psicoeducação',
      actions: [
        if (_isEditing)
          IconButton(
            tooltip: 'Remover',
            onPressed: _saving ? null : _delete,
            icon: const Icon(Icons.delete_outline),
          ),
      ],
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: Text(_loadError!))
              : ResponsiveContent(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                          AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, 120),
                      children: [
                        _section('Identificação'),
                        _card([
                          Row(children: [
                            SizedBox(
                              width: 100,
                              child: _text(_number, 'Número',
                                  required: true, number: true),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _stageDropdown()),
                          ]),
                          _text(_title, 'Título', required: true),
                          _text(_presentation, 'Apresentação', lines: 3),
                          _text(_closing, 'Fechamento (mensagem final)',
                              lines: 2),
                          _text(_accentColor, 'Cor (hex, ex.: #6366F1)'),
                          _coverSection(),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                                'Publicado (liberado aos psicólogos e pacientes)'),
                            value: _isPublished,
                            onChanged: (v) => setState(() => _isPublished = v),
                          ),
                        ]),
                        _section('Cards'),
                        for (var i = 0; i < _cards.length; i++)
                          _CardEditor(
                            index: i,
                            field: _cards[i],
                            onRemove: () {
                              setState(() => _cards.removeAt(i).dispose());
                            },
                          ),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () =>
                                setState(() => _cards.add(_CardField.empty())),
                            icon: const Icon(Icons.add),
                            label: const Text('Adicionar card'),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        FilledButton.icon(
                          onPressed: _saving ? null : _save,
                          icon: _saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2, color: Colors.white),
                                )
                              : const Icon(Icons.save_outlined),
                          label: Text(_isEditing ? 'Salvar' : 'Criar módulo'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _section(String title) => Padding(
        padding:
            const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700, color: AppColors.navy)),
      );

  Widget _card(List<Widget> children) => ClayCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                children[i],
                if (i != children.length - 1)
                  const SizedBox(height: AppSpacing.sm),
              ],
            ],
          ),
        ),
      );

  Widget _text(
    TextEditingController c,
    String label, {
    bool required = false,
    bool number = false,
    int lines = 1,
  }) =>
      TextFormField(
        controller: c,
        maxLines: lines,
        keyboardType: number ? TextInputType.number : null,
        inputFormatters:
            number ? [FilteringTextInputFormatter.digitsOnly] : null,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          border: const OutlineInputBorder(),
        ),
        validator: required
            ? (v) => (v == null || v.trim().isEmpty) ? 'Obrigatório' : null
            : null,
      );

  Widget _stageDropdown() => DropdownButtonFormField<String>(
        initialValue: _stage,
        decoration: const InputDecoration(
          labelText: 'Etapa',
          isDense: true,
          border: OutlineInputBorder(),
        ),
        items: [
          for (final s in _stages) DropdownMenuItem(value: s, child: Text(s)),
        ],
        onChanged: (v) => setState(() => _stage = v ?? 'Compreender'),
      );

  Future<void> _pickCover() async {
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 88,
      );
      if (picked == null) return;
      setState(() => _uploadingCover = true);
      final bytes = await picked.readAsBytes();
      final base =
          widget.moduleId ?? 'module_${DateTime.now().millisecondsSinceEpoch}';
      final url =
          await ref.read(adminPsychoeducationRepositoryProvider).uploadCover(
                baseName: base,
                bytes: bytes,
                fileName: picked.name,
              );
      if (mounted) setState(() => _coverUrl.text = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _uploadingCover = false);
    }
  }

  Widget _coverSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Capa',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedBuilder(
              animation: _coverUrl,
              builder: (_, __) {
                final url = _coverUrl.text.trim();
                return ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 72,
                    height: 104,
                    child: url.isEmpty
                        ? Container(
                            color: AppColors.surfaceTintPurple,
                            child: const Icon(Icons.image_outlined,
                                color: AppColors.purple),
                          )
                        : Image.network(
                            url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: AppColors.surfaceTintPurple,
                              child: const Icon(Icons.broken_image_outlined,
                                  color: AppColors.purple),
                            ),
                          ),
                  ),
                );
              },
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  OutlinedButton.icon(
                    onPressed: _uploadingCover ? null : _pickCover,
                    icon: _uploadingCover
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_outlined, size: 18),
                    label: Text(_uploadingCover ? 'Enviando…' : 'Enviar imagem'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  _text(_coverUrl, 'URL da capa (ou cole um link)'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Estado dos cards ──────────────────────────────────────────────────────────

class _CardField {
  _CardField({
    String title = '',
    String? imageUrl,
    String? patientText,
    String? therapistText,
    String? reflection,
    String? exercise,
  })  : title = TextEditingController(text: title),
        imageUrl = TextEditingController(text: imageUrl ?? ''),
        patientText = TextEditingController(text: patientText ?? ''),
        therapistText = TextEditingController(text: therapistText ?? ''),
        reflection = TextEditingController(text: reflection ?? ''),
        exercise = TextEditingController(text: exercise ?? '');

  factory _CardField.empty() => _CardField();

  factory _CardField.fromCard(PsychoeducationCard c) => _CardField(
        title: c.title,
        imageUrl: c.imageUrl,
        patientText: c.patientText,
        therapistText: c.therapistText,
        reflection: c.reflection,
        exercise: c.exercise,
      );

  final TextEditingController title;
  final TextEditingController imageUrl;
  final TextEditingController patientText;
  final TextEditingController therapistText;
  final TextEditingController reflection;
  final TextEditingController exercise;

  void dispose() {
    title.dispose();
    imageUrl.dispose();
    patientText.dispose();
    therapistText.dispose();
    reflection.dispose();
    exercise.dispose();
  }
}

class _CardEditor extends StatelessWidget {
  const _CardEditor({
    required this.index,
    required this.field,
    required this.onRemove,
  });
  final int index;
  final _CardField field;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    Widget f(TextEditingController c, String label, {int lines = 1}) =>
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.sm),
          child: TextField(
            controller: c,
            maxLines: lines,
            decoration: InputDecoration(
              labelText: label,
              isDense: true,
              border: const OutlineInputBorder(),
            ),
          ),
        );

    return ClayCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Card ${index + 1}',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w800, color: AppColors.navy)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.error,
                  onPressed: onRemove,
                ),
              ],
            ),
            f(field.title, 'Título'),
            f(field.patientText, 'Texto do paciente', lines: 3),
            f(field.reflection, 'Reflexão'),
            f(field.exercise, 'Exercício'),
            f(field.therapistText, 'Texto do terapeuta (opcional, não vai ao paciente)',
                lines: 2),
            f(field.imageUrl, 'URL da imagem'),
          ],
        ),
      ),
    );
  }
}

String _message(Object error) =>
    error.toString().replaceFirst(RegExp(r'^AppException\([^)]*\):\s*'), '');
