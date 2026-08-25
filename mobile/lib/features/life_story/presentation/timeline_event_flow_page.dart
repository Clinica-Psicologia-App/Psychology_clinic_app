import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_banner.dart';
import '../domain/life_story_enums.dart';
import '../domain/life_timeline_event.dart';
import '../domain/timeline_person.dart';
import '../providers/life_story_providers.dart';
import '../../../shared/widgets/brand_loading.dart';

/// Fluxo em etapas para registrar um acontecimento — núcleo do Conhecer.
/// Textos e opções literais do documento da cliente (spec §3–9, §13).
class TimelineEventFlowPage extends ConsumerStatefulWidget {
  const TimelineEventFlowPage({super.key});

  @override
  ConsumerState<TimelineEventFlowPage> createState() =>
      _TimelineEventFlowPageState();
}

class _TimelineEventFlowPageState extends ConsumerState<TimelineEventFlowPage> {
  static const _stepCount = 5;
  int _step = 0;
  bool _busy = false;

  // Etapa 1 — quando
  LifeChapter? _chapter;
  final _ageController = TextEditingController();
  bool _dontRememberAge = false;

  // Etapa 2 — o quê
  final _descriptionController = TextEditingController();
  final _titleController = TextEditingController();

  // Etapa 3 — quem
  final Set<String> _selectedPeople = {};

  // Etapa 4 — como se sentiu
  final Set<TimelineEmotion> _emotions = {};
  final _emotionOtherController = TextEditingController();
  bool _emotionOtherOn = false;
  double _impact = 5;

  @override
  void dispose() {
    _ageController.dispose();
    _descriptionController.dispose();
    _titleController.dispose();
    _emotionOtherController.dispose();
    super.dispose();
  }

  bool get _canAdvance {
    switch (_step) {
      case 0:
        return _chapter != null ||
            _dontRememberAge ||
            _ageController.text.trim().isNotEmpty;
      case 1:
        return _titleController.text.trim().isNotEmpty;
      default:
        return true; // etapas 2, 3 e revisão são opcionais para avançar
    }
  }

  void _next() {
    if (_step < _stepCount - 1) setState(() => _step++);
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _save() async {
    if (_busy) return;
    setState(() => _busy = true);
    final age = int.tryParse(_ageController.text.trim());
    final event = LifeTimelineEvent(
      id: '',
      patientId: '',
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim().isEmpty
          ? null
          : _descriptionController.text.trim(),
      lifeChapter: _chapter,
      ageAtEvent: _dontRememberAge ? null : age,
      agePrecision:
          _dontRememberAge ? AgePrecision.approximate : (age != null ? AgePrecision.exact : null),
      emotions: _emotions.toList(),
      emotionOther: _emotionOtherOn && _emotionOtherController.text.trim().isNotEmpty
          ? _emotionOtherController.text.trim()
          : null,
      emotionalImpact: _impact.round(),
    );
    try {
      await ref.read(createTimelineEventProvider.notifier).submit(
            event: event,
            personIds: _selectedPeople.toList(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Este momento foi adicionado à sua história.')),
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
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Cabeçalho com progresso.
          Container(
            padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 16),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.turquoise, AppColors.cyan, AppColors.blue],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _circleIcon(Icons.arrow_back_rounded, () => context.pop()),
                    const SizedBox(width: 10),
                    Text(
                      'Minha História',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    for (var i = 0; i < _stepCount; i++) ...[
                      Expanded(
                        child: Container(
                          height: 3,
                          decoration: BoxDecoration(
                            color: i <= _step
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                      if (i < _stepCount - 1) const SizedBox(width: 4),
                    ],
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              child: _buildStep(theme),
            ),
          ),
          _buildNav(theme),
        ],
      ),
    );
  }

  Widget _buildStep(ThemeData theme) => switch (_step) {
        0 => _stepWhen(theme),
        1 => _stepWhat(theme),
        2 => _stepWho(theme),
        3 => _stepFelt(theme),
        _ => _stepReview(theme),
      };

  // ── Etapa 1 · Quando (§4) ────────────────────────────────────────────────
  Widget _stepWhen(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _question('Em qual período da sua vida você gostaria de começar?'),
        _hint('Comece pela lembrança que vier primeiro.'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final c in kLifeChaptersInOrder)
              _choiceChip(
                label: c.label,
                selected: _chapter == c,
                onTap: () => setState(() => _chapter = _chapter == c ? null : c),
              ),
          ],
        ),
        const SizedBox(height: 22),
        _label('Quantos anos você tinha?'),
        const SizedBox(height: 6),
        Opacity(
          opacity: _dontRememberAge ? 0.4 : 1,
          child: TextField(
            controller: _ageController,
            enabled: !_dontRememberAge,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(3),
            ],
            onChanged: (_) => setState(() {}),
            decoration: _fieldDecoration(hint: 'anos'),
          ),
        ),
        const SizedBox(height: 10),
        _choiceChip(
          label: 'Não lembro exatamente',
          selected: _dontRememberAge,
          onTap: () => setState(() => _dontRememberAge = !_dontRememberAge),
        ),
      ],
    );
  }

  // ── Etapa 2 · O quê (§5) ─────────────────────────────────────────────────
  Widget _stepWhat(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _question('Conte um acontecimento importante dessa época.'),
        const SizedBox(height: 8),
        TextField(
          controller: _descriptionController,
          maxLines: 4,
          decoration: _fieldDecoration(
            hint: 'Ex.: meus pais se separaram; mudei de cidade; '
                'nasceu minha irmã; sofri bullying; entrei na faculdade...',
          ),
        ),
        const SizedBox(height: 22),
        _label('Como você chamaria esse momento?'),
        const SizedBox(height: 6),
        TextField(
          controller: _titleController,
          onChanged: (_) => setState(() {}),
          decoration: _fieldDecoration(hint: 'Ex.: Separação dos meus pais'),
        ),
      ],
    );
  }

  // ── Etapa 3 · Quem (§8) ──────────────────────────────────────────────────
  Widget _stepWho(ThemeData theme) {
    final peopleAsync = ref.watch(myTimelinePeopleProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _question('Quem estava envolvido ou foi importante nesse acontecimento?'),
        _hint('Pessoas que você já citou aparecem primeiro.'),
        peopleAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(20),
            child: BrandLoader(),
          ),
          error: (e, _) => _hint('Não foi possível carregar as pessoas.'),
          data: (people) => Column(
            children: [
              for (final p in people) _personTile(p),
            ],
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: _openAddPerson,
          borderRadius: BorderRadius.circular(10),
          child: const Padding(
            padding: EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                Icon(Icons.add, size: 18, color: AppColors.blue),
                SizedBox(width: 6),
                Text('Adicionar pessoa',
                    style: TextStyle(
                        color: AppColors.blue, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _personTile(TimelinePerson p) {
    final selected = _selectedPeople.contains(p.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() {
          selected ? _selectedPeople.remove(p.id) : _selectedPeople.add(p.id);
        }),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFFF2FBFA) : Colors.white,
            border: Border.all(
                color: selected ? AppColors.turquoise : AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 15,
                backgroundColor: const Color(0xFFDDE7F7),
                child: Text(p.initials,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E5A9E))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.fullName,
                        style: const TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w500)),
                    if (p.role != null)
                      Text(p.role!.label,
                          style: const TextStyle(
                              fontSize: 11, color: AppColors.textMuted)),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle : Icons.circle_outlined,
                color: selected ? AppColors.turquoise : AppColors.borderStrong,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openAddPerson() async {
    final created = await showModalBottomSheet<TimelinePerson>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => const _AddPersonSheet(),
    );
    if (created != null && mounted) {
      setState(() => _selectedPeople.add(created.id));
    }
  }

  // ── Etapa 4 · Como se sentiu (§9) ────────────────────────────────────────
  Widget _stepFelt(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _question('Quando isso aconteceu, como você se sentiu?'),
        _hint('Selecione até três.'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final e in kTimelineEmotionsInOrder)
              _choiceChip(
                label: e.label,
                selected: _emotions.contains(e),
                onTap: () => setState(() {
                  if (_emotions.contains(e)) {
                    _emotions.remove(e);
                  } else if (_emotions.length < 3) {
                    _emotions.add(e);
                  }
                }),
              ),
            _choiceChip(
              label: 'Outro',
              selected: _emotionOtherOn,
              onTap: () => setState(() => _emotionOtherOn = !_emotionOtherOn),
            ),
          ],
        ),
        if (_emotionOtherOn) ...[
          const SizedBox(height: 10),
          TextField(
            controller: _emotionOtherController,
            decoration: _fieldDecoration(hint: 'Como você chamaria esse sentimento?'),
          ),
        ],
        const SizedBox(height: 24),
        _label('Quanto isso marcou você naquela época?'),
        Slider(
          value: _impact,
          min: 0,
          max: 10,
          divisions: 10,
          activeColor: AppColors.turquoise,
          label: '${_impact.round()}',
          onChanged: (v) => setState(() => _impact = v),
        ),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Quase nada',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
              Text('Marcou profundamente',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Revisão / salvar (§13) ───────────────────────────────────────────────
  Widget _stepReview(ThemeData theme) {
    final ageText = _dontRememberAge
        ? 'Idade aproximada'
        : (_ageController.text.trim().isEmpty
            ? (_chapter?.label ?? '')
            : '${_ageController.text.trim()} anos');
    final emo = [
      ..._emotions.map((e) => e.label),
      if (_emotionOtherOn && _emotionOtherController.text.trim().isNotEmpty)
        _emotionOtherController.text.trim(),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _question('Pronto para adicionar este momento?'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (ageText.isNotEmpty)
                Text(ageText,
                    style: const TextStyle(
                        color: AppColors.turquoise,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              const SizedBox(height: 2),
              Text(
                _titleController.text.trim().isEmpty
                    ? 'Sem título'
                    : _titleController.text.trim(),
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              if (emo.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(emo,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary)),
              ],
              if (_selectedPeople.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text('${_selectedPeople.length} pessoa(s)',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ── Navegação inferior ───────────────────────────────────────────────────
  Widget _buildNav(ThemeData theme) {
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
            TextButton(onPressed: _busy ? null : _back, child: const Text('Voltar')),
          const Spacer(),
          FilledButton(
            onPressed: (isLast ? _titleController.text.trim().isNotEmpty : _canAdvance) && !_busy
                ? (isLast ? _save : _next)
                : null,
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
                : Text(isLast ? 'Adicionar à minha história' : 'Avançar'),
          ),
        ],
      ),
    );
  }

  // ── Helpers de UI ────────────────────────────────────────────────────────
  Widget _question(String text) => Text(
        text,
        style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w600, color: AppColors.navy, height: 1.3),
      );

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary));

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.only(top: 4, bottom: 14),
        child: Text(text,
            style: const TextStyle(
                fontSize: 12.5, color: AppColors.textMuted, height: 1.4)),
      );

  Widget _choiceChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0F2F1) : Colors.white,
          border: Border.all(
              color: selected ? AppColors.turquoise : AppColors.border),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(label,
            style: TextStyle(
              fontSize: 13,
              color: selected ? const Color(0xFF0F766E) : AppColors.textPrimary,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }

  InputDecoration _fieldDecoration({required String hint}) => InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 13),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.turquoise, width: 1.5),
        ),
      );

  Widget _circleIcon(IconData icon, VoidCallback onTap) => InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      );
}

/// Folha "Adicionar pessoa" (§8): nome + parentesco. Sem perguntas de vínculo
/// — isso pertence ao Genograma.
class _AddPersonSheet extends ConsumerStatefulWidget {
  const _AddPersonSheet();

  @override
  ConsumerState<_AddPersonSheet> createState() => _AddPersonSheetState();
}

class _AddPersonSheetState extends ConsumerState<_AddPersonSheet> {
  final _nameController = TextEditingController();
  RelationshipRole? _role;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      final person = await ref.read(createPersonProvider.notifier).submit(
            fullName: name,
            role: _role,
          );
      if (mounted) Navigator.of(context).pop(person);
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showErrorBanner(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Quem é essa pessoa?',
              style: TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.navy)),
          const SizedBox(height: 16),
          const Text('Nome',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          TextField(
            controller: _nameController,
            autofocus: true,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF7F9FC),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Essa pessoa é seu/sua...',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final r in kRelationshipRolesInOrder)
                InkWell(
                  onTap: () => setState(() => _role = _role == r ? null : r),
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: _role == r
                          ? const Color(0xFFE0F2F1)
                          : const Color(0xFFF7F9FC),
                      border: Border.all(
                          color: _role == r
                              ? AppColors.turquoise
                              : AppColors.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(r.label,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: _role == r
                              ? const Color(0xFF0F766E)
                              : AppColors.textPrimary,
                          fontWeight:
                              _role == r ? FontWeight.w600 : FontWeight.w400,
                        )),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _nameController.text.trim().isNotEmpty && !_busy
                ? _save
                : null,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.turquoise,
              minimumSize: const Size.fromHeight(48),
            ),
            child: _busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Adicionar'),
          ),
        ],
      ),
    );
  }
}
