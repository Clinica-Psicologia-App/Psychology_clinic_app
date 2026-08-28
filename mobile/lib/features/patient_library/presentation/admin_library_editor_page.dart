import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../domain/library_work_full.dart';
import '../providers/admin_library_providers.dart';
import 'widgets/library_cover.dart';
import '../../../shared/widgets/brand_loading.dart';

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
      final work = await ref
          .read(adminLibraryRepositoryProvider)
          .getWork(widget.workId!);
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
      accent: AppColors.cyan,
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
                        // ── 1. Hero: preview reactivo ──────────────────────
                        _WorkHero(
                          titleController: _title,
                          coverController: _coverUrl,
                          workType: _workType,
                          isPublished: _isPublished,
                          onTogglePublished: (v) =>
                              setState(() => _isPublished = v),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // ── 2. Identificação + Capa ─────────────────────────
                        _section('Identificação', AppColors.cyan),
                        _card([
                          _text(_title, 'Título exibido', required: true),
                          _text(_originalTitle, 'Título original'),
                          Row(children: [
                            Expanded(child: _typeDropdown()),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                                child: _text(_year, 'Ano', number: true)),
                          ]),
                          _text(_genres, 'Gêneros'),
                          Row(children: [
                            Expanded(child: _text(_duration, 'Duração')),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _text(_seasons, 'Temporadas')),
                          ]),
                          Row(children: [
                            Expanded(
                                child: _text(
                                    _rating, 'Classificação (etária)')),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(child: _intensityDropdown()),
                          ]),
                          _text(_synopsis, 'Sinopse', lines: 3),
                          _AnimationToggle(
                            value: _isAnimation,
                            onChanged: (v) => setState(() => _isAnimation = v),
                          ),
                        ]),
                        const SizedBox(height: AppSpacing.sm),
                        // Capa: logo abaixo do card de identificação,
                        // sem seção separada — é metadata da obra.
                        _coverSection(),
                        const SizedBox(height: AppSpacing.lg),

                        // ── 3. Classificação clínica ────────────────────────
                        _section('Classificação clínica', AppColors.purple),
                        _card([
                          _text(_primarySchema, 'Esquema principal'),
                          _text(_domain, 'Domínio'),
                          _listEditor(
                              'Esquemas associados', _associatedSchemas),
                          _listEditor('Temas', _themes),
                        ]),
                        const SizedBox(height: AppSpacing.lg),

                        // ── 4. Camada do psicólogo (3 sub-cards) ───────────
                        _section('Camada do psicólogo', AppColors.blue,
                            subtitle: 'Não visível ao paciente'),
                        _subcard(
                          icon: Icons.medical_services_outlined,
                          title: 'Indicação clínica',
                          color: AppColors.blue,
                          children: [
                            _listEditor('Quando indicar', _whenToIndicate),
                            _listEditor('Objetivos', _objectives),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _subcard(
                          icon: Icons.psychology_outlined,
                          title: 'Análise da obra',
                          color: AppColors.blue,
                          children: [
                            _listEditor(
                                'Focos de observação', _observationFocus),
                            _listEditor('Mobilizações emocionais',
                                _emotionalMobilizations),
                            _listEditor(
                                'Modos de esquema', _schemaModes),
                            _listEditor(
                                'Cuidados clínicos', _clinicalCautions),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        _subcard(
                          icon: Icons.forum_outlined,
                          title: 'Para a sessão',
                          color: AppColors.blue,
                          children: [
                            _listEditor('Intervenções em sessão',
                                _sessionInterventions),
                            _listEditor(
                                'Perguntas de sessão', _sessionQuestions),
                            _text(_clinicalNote, 'Nota clínica', lines: 3),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // ── 5. Camada do paciente ───────────────────────────
                        _section('Camada do paciente', AppColors.turquoise),
                        _card([
                          _text(_patientBefore, 'Antes de assistir', lines: 3),
                          _listEditor(
                              'Enquanto assiste, observe', _patientDuring),
                          const SizedBox(height: AppSpacing.sm),
                          _AfterQuestionsEditor(
                            questions: _patientAfter,
                            onChanged: () => setState(() {}),
                          ),
                          _text(_whereToWatch, 'Onde assistir'),
                        ]),
                        const SizedBox(height: AppSpacing.xl),

                        // ── Salvar ──────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: FilledButton.icon(
                            onPressed: _saving ? null : _save,
                            icon: _saving
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  )
                                : const Icon(Icons.save_outlined),
                            label: Text(
                              _isEditing ? 'Salvar alterações' : 'Criar obra',
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
    );
  }

  // ── Builders ──────────────────────────────────────────────────────────────

  Widget _section(String title, Color accent, {String? subtitle}) => Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
        child: AppSectionHeader(
          title: title,
          subtitle: subtitle,
          accentColor: accent,
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

  // Sub-card com cabeçalho ícone em pill colorido + separador sutil.
  Widget _subcard({
    required IconData icon,
    required String title,
    required Color color,
    required List<Widget> children,
  }) =>
      ClayCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Cabeçalho: ícone em container arredondado + rótulo
              Container(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: color.withValues(alpha: 0.18),
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(9),
                      ),
                      child: Icon(icon, size: 15, color: color),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
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
    return AnimatedBuilder(
      animation: _coverUrl,
      builder: (context, _) {
        final url = _coverUrl.text.trim();
        final isSer = _workType == 'Série' || _workType == 'Minissérie';
        final theme = Theme.of(context);
        final hasCover = url.isNotEmpty;

        return ClayCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Rótulo da seção dentro do card
                Row(
                  children: [
                    Icon(Icons.image_outlined,
                        size: 15, color: AppColors.purple),
                    const SizedBox(width: 6),
                    Text(
                      'Capa',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppColors.purple,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Preview
                    ClipRRect(
                      borderRadius: AppRadius.lgAll,
                      child: SizedBox(
                        width: 84,
                        height: 120,
                        child: LibraryCover(
                          gradient: isSer
                              ? const [Color(0xFF2E7D6B), Color(0xFF11808F)]
                              : const [Color(0xFF3B2F8F), Color(0xFF7C6A9C)],
                          url: hasCover ? url : null,
                        ),
                      ),
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
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.upload_outlined, size: 18),
                            label: Text(_uploadingCover
                                ? 'Enviando…'
                                : 'Enviar imagem'),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          TextFormField(
                            controller: _coverUrl,
                            decoration: const InputDecoration(
                              labelText: 'URL da capa',
                              hintText: 'https://…',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            hasCover
                                ? 'Pré-visualização atualizada ao lado.'
                                : 'Suba uma imagem ou cole a URL diretamente.',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Hero reactivo ─────────────────────────────────────────────────────────────

/// Card de resumo no topo do editor: capa em altura total + título + badge de
/// tipo + chip de publicação. Escuta dois controllers sem rebuildar a página.
class _WorkHero extends StatelessWidget {
  const _WorkHero({
    required this.titleController,
    required this.coverController,
    required this.workType,
    required this.isPublished,
    required this.onTogglePublished,
  });

  final TextEditingController titleController;
  final TextEditingController coverController;
  final String workType;
  final bool isPublished;
  final ValueChanged<bool> onTogglePublished;

  bool get _isSeries => workType == 'Série' || workType == 'Minissérie';

  IconData get _typeIcon => switch (workType) {
        'Série' || 'Minissérie' => Icons.live_tv_outlined,
        'Episódio' => Icons.smart_display_outlined,
        _ => Icons.movie_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final pubColor =
        isPublished ? AppColors.success : theme.colorScheme.onSurfaceVariant;

    return AnimatedBuilder(
      animation: Listenable.merge([titleController, coverController]),
      builder: (context, _) {
        final url = coverController.text.trim();
        final title = titleController.text.trim();

        return ClayCard(
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
          child: SizedBox(
            height: 168,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ── Capa: ocupa toda a altura do card ────────────────
                SizedBox(
                  width: 116,
                  child: LibraryCover(
                    gradient: _isSeries
                        ? const [Color(0xFF2E7D6B), Color(0xFF11808F)]
                        : const [Color(0xFF3B2F8F), Color(0xFF7C6A9C)],
                    url: url.isEmpty ? null : url,
                  ),
                ),
                // ── Painel direito ───────────────────────────────────
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Topo: badge de tipo + título
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Badge de tipo (pill com ícone)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(99),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(_typeIcon,
                                      size: 11, color: AppColors.cyan),
                                  const SizedBox(width: 4),
                                  Text(
                                    workType,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.cyan,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.4,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            // Título reactivo
                            Text(
                              title.isEmpty ? 'Sem título' : title,
                              maxLines: 4,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                                height: 1.25,
                              ),
                            ),
                          ],
                        ),
                        // Rodapé: chip de publicação (toque para alternar)
                        GestureDetector(
                          onTap: () => onTogglePublished(!isPublished),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: pubColor.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(99),
                              border: Border.all(
                                  color: pubColor.withValues(alpha: 0.28)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  isPublished
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  size: 12,
                                  color: pubColor,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  isPublished ? 'Publicada' : 'Oculta',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: pubColor,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Toggle de animação com visual de chip — substitui o SwitchListTile genérico.
class _AnimationToggle extends StatelessWidget {
  const _AnimationToggle({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: value
            ? AppColors.cyan.withValues(alpha: 0.08)
            : theme.colorScheme.surface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(
          color: value
              ? AppColors.cyan.withValues(alpha: 0.25)
              : theme.colorScheme.outline,
        ),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xxs,
        ),
        dense: true,
        title: Text(
          'Animação',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: value ? AppColors.cyan : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        secondary: Icon(
          Icons.animation_outlined,
          size: 20,
          color: value ? AppColors.cyan : theme.colorScheme.onSurfaceVariant,
        ),
        value: value,
        onChanged: onChanged,
      ),
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

  List<String> get values =>
      controllers.map((c) => c.text.trim()).where((s) => s.isNotEmpty).toList();

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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        if (field.controllers.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(
              'Nenhum item ainda.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: [
                for (var i = 0; i < field.controllers.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        // Número do item
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerLow,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                          icon: const Icon(Icons.remove_circle_outline,
                              size: 20),
                          color: AppColors.error,
                          padding: const EdgeInsets.all(4),
                          constraints: const BoxConstraints(),
                          onPressed: () {
                            field.controllers.removeAt(i).dispose();
                            onChanged();
                          },
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        TextButton.icon(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {
            field.controllers.add(TextEditingController());
            onChanged();
          },
          icon: const Icon(Icons.add_circle_outline, size: 16),
          label: const Text('Adicionar item'),
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
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Depois de assistir (perguntas)',
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        if (questions.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 2),
            child: Text(
              'Nenhuma pergunta ainda.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          )
        else
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              children: [
                for (var i = 0; i < questions.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: AppColors.turquoise
                                      .withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Center(
                                  child: Text(
                                    '${i + 1}',
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: AppColors.turquoise,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
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
                                icon: const Icon(Icons.remove_circle_outline,
                                    size: 20),
                                color: AppColors.error,
                                padding: const EdgeInsets.all(4),
                                constraints: const BoxConstraints(),
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
                              labelText: 'Tipo de campo (ex.: texto longo)',
                              isDense: true,
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        TextButton.icon(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          onPressed: () {
            questions.add(_QuestionField('', null));
            onChanged();
          },
          icon: const Icon(Icons.add_circle_outline, size: 16),
          label: const Text('Adicionar pergunta'),
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
