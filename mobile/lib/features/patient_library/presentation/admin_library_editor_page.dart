import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../domain/library_work_full.dart';
import '../providers/admin_library_providers.dart';

/// Editor de obra do catálogo (criar ou editar). Cobre metadados, a camada
/// clínica (só do staff) e a camada do paciente.
class AdminLibraryEditorPage extends ConsumerStatefulWidget {
  const AdminLibraryEditorPage({super.key, this.workId});

  /// Nulo = criar nova obra.
  final String? workId;

  @override
  ConsumerState<AdminLibraryEditorPage> createState() =>
      _AdminLibraryEditorPageState();
}

class _AdminLibraryEditorPageState
    extends ConsumerState<AdminLibraryEditorPage> {
  static const _workTypes = ['Filme', 'Série', 'Minissérie', 'Episódio'];
  static const _intensities = ['Leve', 'Moderada', 'Alta'];

  final _formKey = GlobalKey<FormState>();

  // Escalares.
  final _title = TextEditingController();
  final _originalTitle = TextEditingController();
  final _year = TextEditingController();
  final _genres = TextEditingController();
  final _duration = TextEditingController();
  final _seasons = TextEditingController();
  final _rating = TextEditingController();
  final _coverUrl = TextEditingController();
  final _synopsis = TextEditingController();
  final _primarySchema = TextEditingController();
  final _domain = TextEditingController();
  final _clinicalNote = TextEditingController();
  final _patientBefore = TextEditingController();
  final _whereToWatch = TextEditingController();

  String _workType = 'Filme';
  String? _intensity;
  bool _isAnimation = false;
  bool _isPublished = true;

  // Listas.
  late final _ListField _associatedSchemas = _ListField();
  late final _ListField _themes = _ListField();
  late final _ListField _whenToIndicate = _ListField();
  late final _ListField _objectives = _ListField();
  late final _ListField _observationFocus = _ListField();
  late final _ListField _emotionalMobilizations = _ListField();
  late final _ListField _clinicalCautions = _ListField();
  late final _ListField _schemaModes = _ListField();
  late final _ListField _sessionInterventions = _ListField();
  late final _ListField _sessionQuestions = _ListField();
  late final _ListField _patientDuring = _ListField();
  final List<_QuestionField> _patientAfter = [];

  bool get _isEditing => widget.workId != null;
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
      final work =
          await ref.read(adminLibraryRepositoryProvider).getWork(widget.workId!);
      if (work != null) _populate(work);
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

  void _populate(LibraryWorkFull w) {
    _title.text = w.displayTitle;
    _originalTitle.text = w.originalTitle ?? '';
    _workType = _workTypes.contains(w.workType) ? w.workType : 'Filme';
    _isAnimation = w.isAnimation;
    _year.text = w.year?.toString() ?? '';
    _genres.text = w.genres ?? '';
    _duration.text = w.duration ?? '';
    _seasons.text = w.seasons ?? '';
    _rating.text = w.rating ?? '';
    _intensity = _intensities.contains(w.intensity) ? w.intensity : null;
    _coverUrl.text = w.coverUrl ?? '';
    _synopsis.text = w.synopsis ?? '';
    _primarySchema.text = w.primarySchema ?? '';
    _domain.text = w.domain ?? '';
    _associatedSchemas.setAll(w.associatedSchemas);
    _themes.setAll(w.themes);

    final p = w.psychologist;
    _whenToIndicate.setAll(p.whenToIndicate);
    _objectives.setAll(p.objectives);
    _observationFocus.setAll(p.observationFocus);
    _emotionalMobilizations.setAll(p.emotionalMobilizations);
    _clinicalCautions.setAll(p.clinicalCautions);
    _schemaModes.setAll(p.schemaModes);
    _sessionInterventions.setAll(p.sessionInterventions);
    _sessionQuestions.setAll(p.sessionQuestions);
    _clinicalNote.text = p.clinicalNote ?? '';

    final pt = w.patientLayer;
    _patientBefore.text = pt.before ?? '';
    _patientDuring.setAll(pt.during);
    _whereToWatch.text = pt.whereToWatch ?? '';
    _patientAfter
      ..clear()
      ..addAll(pt.after.map((q) => _QuestionField(q.question, q.fieldType)));
  }

  @override
  void dispose() {
    for (final c in [
      _title,
      _originalTitle,
      _year,
      _genres,
      _duration,
      _seasons,
      _rating,
      _coverUrl,
      _synopsis,
      _primarySchema,
      _domain,
      _clinicalNote,
      _patientBefore,
      _whereToWatch,
    ]) {
      c.dispose();
    }
    for (final f in [
      _associatedSchemas,
      _themes,
      _whenToIndicate,
      _objectives,
      _observationFocus,
      _emotionalMobilizations,
      _clinicalCautions,
      _schemaModes,
      _sessionInterventions,
      _sessionQuestions,
      _patientDuring,
    ]) {
      f.dispose();
    }
    for (final q in _patientAfter) {
      q.dispose();
    }
    super.dispose();
  }

  String? _nn(String s) => s.trim().isEmpty ? null : s.trim();

  Map<String, dynamic> _buildValues() {
    return {
      'display_title': _title.text.trim(),
      'original_title': _nn(_originalTitle.text),
      'work_type': _workType,
      'is_animation': _isAnimation,
      'year': int.tryParse(_year.text.trim()),
      'genres': _nn(_genres.text),
      'duration': _nn(_duration.text),
      'seasons': _nn(_seasons.text),
      'rating': _nn(_rating.text),
      'intensity': _intensity,
      'cover_url': _nn(_coverUrl.text),
      'synopsis': _nn(_synopsis.text),
      'primary_schema': _nn(_primarySchema.text),
      'domain': _nn(_domain.text),
      'associated_schemas': _associatedSchemas.values,
      'themes': _themes.values,
      'is_published': _isPublished,
      'psychologist_layer': {
        'when_to_indicate': _whenToIndicate.values,
        'objectives': _objectives.values,
        'observation_focus': _observationFocus.values,
        'emotional_mobilizations': _emotionalMobilizations.values,
        'clinical_cautions': _clinicalCautions.values,
        'schema_modes': _schemaModes.values,
        'session_interventions': _sessionInterventions.values,
        'session_questions': _sessionQuestions.values,
        'clinical_note': _nn(_clinicalNote.text),
      },
      'patient_layer': {
        'patient_before': _nn(_patientBefore.text),
        'patient_during': _patientDuring.values,
        'patient_after': _patientAfter
            .where((q) => q.question.text.trim().isNotEmpty)
            .map((q) => {
                  'question': q.question.text.trim(),
                  'field_type': _nn(q.fieldType.text),
                })
            .toList(),
        'where_to_watch': _nn(_whereToWatch.text),
      },
    };
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      await ref.read(libraryCatalogMutationProvider.notifier).save(
            id: widget.workId,
            values: _buildValues(),
          );
      ref.invalidate(adminLibraryListProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Obra salva.')),
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
        title: const Text('Remover obra?'),
        content: const Text(
            'A obra sai do catálogo. Indicações já feitas aos pacientes não '
            'são afetadas.'),
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
      await ref
          .read(libraryCatalogMutationProvider.notifier)
          .delete(widget.workId!);
      ref.invalidate(adminLibraryListProvider);
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
      title: _isEditing ? 'Editar obra' : 'Nova obra',
      subtitle: 'Catálogo da Biblioteca',
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
                          _text(_title, 'Título exibido', required: true),
                          _text(_originalTitle, 'Título original'),
                          Row(children: [
                            Expanded(child: _typeDropdown()),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _text(_year, 'Ano', number: true),
                            ),
                          ]),
                          _text(_genres, 'Gêneros'),
                          Row(children: [
                            Expanded(child: _text(_duration, 'Duração')),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _text(_seasons, 'Temporadas')),
                          ]),
                          Row(children: [
                            Expanded(
                                child: _text(_rating, 'Classificação (etária)')),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _intensityDropdown()),
                          ]),
                          _coverSection(),
                          _text(_synopsis, 'Sinopse', lines: 3),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Animação'),
                            value: _isAnimation,
                            onChanged: (v) => setState(() => _isAnimation = v),
                          ),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Publicada (liberada aos psicólogos)'),
                            value: _isPublished,
                            onChanged: (v) => setState(() => _isPublished = v),
                          ),
                        ]),
                        _section('Classificação clínica'),
                        _card([
                          _text(_primarySchema, 'Esquema principal'),
                          _text(_domain, 'Domínio'),
                          _listEditor('Esquemas associados', _associatedSchemas),
                          _listEditor('Temas', _themes),
                        ]),
                        _section('Camada do psicólogo (não visível ao paciente)'),
                        _card([
                          _listEditor('Quando indicar', _whenToIndicate),
                          _listEditor('Objetivos', _objectives),
                          _listEditor('Focos de observação', _observationFocus),
                          _listEditor(
                              'Mobilizações emocionais', _emotionalMobilizations),
                          _listEditor('Cuidados clínicos', _clinicalCautions),
                          _listEditor('Modos de esquema', _schemaModes),
                          _listEditor(
                              'Intervenções em sessão', _sessionInterventions),
                          _listEditor('Perguntas de sessão', _sessionQuestions),
                          _text(_clinicalNote, 'Nota clínica', lines: 3),
                        ]),
                        _section('Camada do paciente'),
                        _card([
                          _text(_patientBefore, 'Antes de assistir', lines: 3),
                          _listEditor('Enquanto assiste, observe', _patientDuring),
                          const SizedBox(height: AppSpacing.sm),
                          _AfterQuestionsEditor(
                            questions: _patientAfter,
                            onChanged: () => setState(() {}),
                          ),
                          _text(_whereToWatch, 'Onde assistir'),
                        ]),
                        const SizedBox(height: AppSpacing.xl),
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
                          label: Text(_isEditing ? 'Salvar' : 'Criar obra'),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ── Builders ──────────────────────────────────────────────────────────────

  Widget _section(String title) => Padding(
        padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: AppSpacing.sm),
        child: Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleSmall
              ?.copyWith(fontWeight: FontWeight.w700, color: AppColors.navy),
        ),
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

  Widget _typeDropdown() => DropdownButtonFormField<String>(
        initialValue: _workType,
        decoration: const InputDecoration(
          labelText: 'Tipo',
          isDense: true,
          border: OutlineInputBorder(),
        ),
        items: [
          for (final t in _workTypes)
            DropdownMenuItem(value: t, child: Text(t)),
        ],
        onChanged: (v) => setState(() => _workType = v ?? 'Filme'),
      );

  Widget _intensityDropdown() => DropdownButtonFormField<String?>(
        initialValue: _intensity,
        decoration: const InputDecoration(
          labelText: 'Intensidade',
          isDense: true,
          border: OutlineInputBorder(),
        ),
        items: [
          const DropdownMenuItem(value: null, child: Text('—')),
          for (final i in _intensities)
            DropdownMenuItem(value: i, child: Text(i)),
        ],
        onChanged: (v) => setState(() => _intensity = v),
      );

  Widget _listEditor(String label, _ListField field) => _StringListEditor(
        label: label,
        field: field,
        onChanged: () => setState(() {}),
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
          widget.workId ?? 'work_${DateTime.now().millisecondsSinceEpoch}';
      final url = await ref.read(adminLibraryRepositoryProvider).uploadCover(
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
            // Preview reativo ao conteúdo do campo de URL.
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

// ── Modelos de estado das listas ──────────────────────────────────────────────

class _ListField {
  final List<TextEditingController> controllers = [];

  void setAll(List<String> values) {
    for (final c in controllers) {
      c.dispose();
    }
    controllers
      ..clear()
      ..addAll(values.map((v) => TextEditingController(text: v)));
  }

  List<String> get values => controllers
      .map((c) => c.text.trim())
      .where((s) => s.isNotEmpty)
      .toList();

  void dispose() {
    for (final c in controllers) {
      c.dispose();
    }
  }
}

class _QuestionField {
  _QuestionField(String q, String? t)
      : question = TextEditingController(text: q),
        fieldType = TextEditingController(text: t ?? '');

  final TextEditingController question;
  final TextEditingController fieldType;

  void dispose() {
    question.dispose();
    fieldType.dispose();
  }
}

// ── Widgets de lista ──────────────────────────────────────────────────────────

class _StringListEditor extends StatelessWidget {
  const _StringListEditor({
    required this.label,
    required this.field,
    required this.onChanged,
  });

  final String label;
  final _ListField field;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        for (var i = 0; i < field.controllers.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: field.controllers[i],
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.error,
                  onPressed: () {
                    field.controllers.removeAt(i).dispose();
                    onChanged();
                  },
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              field.controllers.add(TextEditingController());
              onChanged();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar'),
          ),
        ),
      ],
    );
  }
}

class _AfterQuestionsEditor extends StatelessWidget {
  const _AfterQuestionsEditor({
    required this.questions,
    required this.onChanged,
  });

  final List<_QuestionField> questions;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Depois de assistir (perguntas)',
            style: Theme.of(context)
                .textTheme
                .labelLarge
                ?.copyWith(color: AppColors.textSecondary)),
        const SizedBox(height: 6),
        for (var i = 0; i < questions.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: questions[i].question,
                        decoration: const InputDecoration(
                          labelText: 'Pergunta',
                          isDense: true,
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      color: AppColors.error,
                      onPressed: () {
                        questions.removeAt(i).dispose();
                        onChanged();
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: questions[i].fieldType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de campo (ex.: Campo de texto longo.)',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () {
              questions.add(_QuestionField('', null));
              onChanged();
            },
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Adicionar pergunta'),
          ),
        ),
      ],
    );
  }
}

String _message(Object error) {
  return error
      .toString()
      .replaceFirst(RegExp(r'^AppException\([^)]*\):\s*'), '');
}
