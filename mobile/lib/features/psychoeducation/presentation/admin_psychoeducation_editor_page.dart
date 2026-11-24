import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/desktop_admin/desktop_admin_kit.dart';
import '../../../shared/widgets/desktop_admin/desktop_admin_shell.dart';
import 'psychoeducation_routes.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../domain/psychoeducation_module.dart';
import '../providers/psychoeducation_providers.dart';
import '../../../shared/widgets/brand_loading.dart';

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
    for (final c in _removed) {
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
    // A partir de 768 px: mestre-detalhe na casca de desktop. Abaixo disso, a
    // tela do celular, sem alteração.
    if (isDesktopAdminWidth(context)) return _buildDesktop();
    return AppSectionScaffold(
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
          ? const BrandLoader()
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

  // ── Desktop (>= 768 px) ───────────────────────────────────────────────────
  // Mestre-detalhe: lista de cards + identificação à esquerda, card em edição
  // à direita. Mesmos controllers e métodos (_save, _delete, _pickCover).
  int _sel = 0;
  final List<_CardField> _removed = [];

  /// Remove o card (só no rascunho da tela; grava ao salvar) após confirmar.
  Future<void> _removeCardAt(int i) async {
    final ok = await showDaConfirm(
      context,
      title: 'Remover card?',
      body: 'O card sai do módulo quando você salvar.',
      confirmLabel: 'Remover',
      danger: true,
    );
    if (!ok || !mounted) return;
    setState(() {
      // Os controllers só são descartados ao sair da tela (a troca animada
      // ainda pode estar desenhando o card removido).
      _removed.add(_cards.removeAt(i));
      if (_sel >= _cards.length) _sel = _cards.length - 1;
      if (_sel < 0) _sel = 0;
    });
  }

  Widget _buildDesktop() {
    final t = DesktopAdminTokens.of(context);
    final m = DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width);
    return DesktopAdminShell(
      nav: DesktopAdminNav.home,
      crumbs: const [
        DaCrumb('Início', '/platform'),
        DaCrumb('Psicoeducação', PsychoeducationRoutes.adminCatalog),
      ],
      title: _isEditing ? 'Editar módulo' : 'Novo módulo',
      subtitle: 'Biblioteca de Psicoeducação',
      actions: [
        if (_isEditing)
          DaButton(
            kind: DaButtonKind.ghost,
            icon: Icons.delete_outline,
            danger: true,
            tooltip: 'Remover',
            onPressed: _saving ? null : _delete,
          ),
        DaButton(
          kind: DaButtonKind.primary,
          icon: Icons.save_outlined,
          label: _isEditing ? 'Salvar' : 'Criar módulo',
          onPressed: _saving ? null : _save,
        ),
      ],
      body: _loading
          ? const BrandLoader()
          : _loadError != null
              ? Center(
                  child: Text(_loadError!,
                      style: daText(context, t, color: t.err)))
              : Form(
                  key: _formKey,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        width: m.size == DesktopAdminSize.desktop ? 420 : 360,
                        decoration: BoxDecoration(
                            border: Border(right: BorderSide(color: t.bd))),
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(20),
                          child: _dLeft(t),
                        ),
                      ),
                      Expanded(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          layoutBuilder: (cur, prev) => Stack(
                            alignment: Alignment.topLeft,
                            children: [...prev, if (cur != null) cur],
                          ),
                          child: _cards.isEmpty
                              ? SizedBox.expand(
                                  key: const ValueKey('vazio'),
                                  child: Center(
                                    child: Text(
                                        'Adicione um card para editá-lo aqui.',
                                        style: daText(context, t,
                                            color: t.tx3)),
                                  ),
                                )
                              : _dCardEditor(t, _sel.clamp(0, _cards.length - 1)),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _dLeft(DesktopAdminTokens t) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(children: [
          Expanded(
            child: Text('Cards (${_cards.length})',
                style: daText(context, t, size: 15, weight: FontWeight.w600)),
          ),
          DaButton(
            kind: DaButtonKind.ghost,
            icon: Icons.add,
            tooltip: 'Adicionar card',
            onPressed: () => setState(() {
              _cards.add(_CardField.empty());
              _sel = _cards.length - 1;
            }),
          ),
        ]),
        const SizedBox(height: 10),
        if (_cards.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('Nenhum card ainda.',
                style: daText(context, t, color: t.tx3)),
          )
        else
          Container(
            decoration: BoxDecoration(
              color: t.rz,
              border: Border.all(color: t.bd2),
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(children: [
              for (var i = 0; i < _cards.length; i++)
                _CardListRow(
                  index: i,
                  field: _cards[i],
                  selected: i == _sel.clamp(0, _cards.length - 1),
                  onTap: () => setState(() => _sel = i),
                  onRemove: () => _removeCardAt(i),
                ),
            ]),
          ),
        const SizedBox(height: 28),
        Text('Identificação',
            style: daText(context, t, size: 15, weight: FontWeight.w600)),
        const SizedBox(height: 14),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(
              width: 100,
              child: DaTextField('Número', _number,
                  required: true, number: true)),
          const SizedBox(width: 14),
          Expanded(
            child: DaDropdown<String>(
              label: 'Etapa',
              value: _stage,
              items: [
                for (final s in _stages)
                  DropdownMenuItem(value: s, child: Text(s)),
              ],
              onChanged: (v) => setState(() => _stage = v ?? 'Compreender'),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        DaTextField('Título', _title, required: true),
        const SizedBox(height: 14),
        DaTextField('Apresentação', _presentation, lines: 3),
        const SizedBox(height: 14),
        DaTextField('Fechamento (mensagem final)', _closing, lines: 2),
        const SizedBox(height: 14),
        DaTextField('Cor (hex, ex.: #6366F1)', _accentColor),
        const SizedBox(height: 14),
        Text('Capa',
            style: daText(context, t,
                size: 12.5, weight: FontWeight.w500, color: t.tx2)),
        const SizedBox(height: 6),
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DaButton(
                  icon: Icons.upload_outlined,
                  label: _uploadingCover ? 'Enviando…' : 'Enviar imagem',
                  expand: true,
                  onPressed: _uploadingCover ? null : _pickCover,
                ),
                const SizedBox(height: 10),
                DaTextField('URL da capa (ou cole um link)', _coverUrl),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 18),
        Row(children: [
          Expanded(
            child: Text('Publicado (liberado aos psicólogos e pacientes)',
                style: daText(context, t, size: 12.5, color: t.tx2)),
          ),
          DaSwitch(
            value: _isPublished,
            semantics: 'Publicado',
            tablet: DesktopAdminMetrics.of(MediaQuery.sizeOf(context).width)
                .tablet,
            onChanged: () => setState(() => _isPublished = !_isPublished),
          ),
        ]),
      ],
    );
  }

  Widget _dCardEditor(DesktopAdminTokens t, int i) {
    final f = _cards[i];
    return SingleChildScrollView(
      key: ValueKey(f),
      padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
      child: Align(
        alignment: Alignment.topLeft,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 760),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Card ${i + 1}',
                  style: daText(context, t, size: 15, weight: FontWeight.w600)),
              const SizedBox(height: 14),
              DaTextField('Título', f.title),
              const SizedBox(height: 14),
              DaTextField('Texto do paciente', f.patientText, lines: 4),
              const SizedBox(height: 14),
              DaGrid([
                (DaTextField('Reflexão', f.reflection, lines: 2), false),
                (DaTextField('Exercício', f.exercise, lines: 2), false),
              ]),
              const SizedBox(height: 14),
              DaTextField(
                  'Texto do terapeuta (opcional, não vai ao paciente)',
                  f.therapistText,
                  lines: 3),
              const SizedBox(height: 14),
              DaTextField('URL da imagem', f.imageUrl),
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
            style: Theme.of(context)
                .textTheme
                .titleSmall
                ?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurface)),
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
                ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant)),
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
                    label:
                        Text(_uploadingCover ? 'Enviando…' : 'Enviar imagem'),
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
    Widget f(TextEditingController c, String label, {int lines = 1}) => Padding(
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
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurface)),
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
            f(field.therapistText,
                'Texto do terapeuta (opcional, não vai ao paciente)',
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


class _CardListRow extends StatefulWidget {
  const _CardListRow({
    required this.index,
    required this.field,
    required this.selected,
    required this.onTap,
    required this.onRemove,
  });

  final int index;
  final _CardField field;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onRemove;

  @override
  State<_CardListRow> createState() => _CardListRowState();
}

class _CardListRowState extends State<_CardListRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final t = DesktopAdminTokens.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
          constraints: const BoxConstraints(minHeight: 52),
          decoration: BoxDecoration(
            color: widget.selected
                ? t.sel
                : (_hover ? t.hov : Colors.transparent),
            border: Border(
              bottom: BorderSide(color: t.bd),
              left: BorderSide(
                  color: widget.selected ? t.tq : Colors.transparent,
                  width: 3),
            ),
          ),
          child: Row(children: [
            Container(
              width: 28,
              height: 28,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: t.sel, shape: BoxShape.circle),
              child: Text('${widget.index + 1}',
                  style: daText(context, t,
                      size: 12, weight: FontWeight.w600, color: t.tq)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: AnimatedBuilder(
                animation: widget.field.title,
                builder: (_, __) => Text(
                    widget.field.title.text.trim().isEmpty
                        ? 'Sem título'
                        : widget.field.title.text.trim(),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: daText(context, t, weight: FontWeight.w600)),
              ),
            ),
            DaButton(
              kind: DaButtonKind.ghost,
              icon: Icons.delete_outline,
              danger: true,
              tooltip: 'Remover',
              onPressed: widget.onRemove,
            ),
          ]),
        ),
      ),
    );
  }
}
