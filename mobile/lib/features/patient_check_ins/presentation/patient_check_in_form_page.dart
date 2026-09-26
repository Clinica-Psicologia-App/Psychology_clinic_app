import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../domain/check_in_mode.dart';
import '../domain/patient_check_in.dart';
import '../domain/patient_check_in_input.dart';
import '../providers/patient_check_ins_providers.dart';
import '../../../shared/widgets/brand_loading.dart';

class PatientCheckInFormPage extends ConsumerStatefulWidget {
  const PatientCheckInFormPage({super.key, this.checkInId});

  final String? checkInId;

  bool get isEdit => checkInId != null;

  @override
  ConsumerState<PatientCheckInFormPage> createState() =>
      _PatientCheckInFormPageState();
}

class _PatientCheckInFormPageState
    extends ConsumerState<PatientCheckInFormPage> {
  final _notesController = TextEditingController();
  final _nicknameController = TextEditingController();

  int _mood = 5;
  List<String> _moodEmotions = [];
  int _anxiety = 5;
  int _energy = 5;
  int _problemIntensity = 5;
  CheckInMode? _selectedMode;
  String? _expandedFamilyId;
  bool _saving = false;
  bool _loaded = false;

  /// Passos: 0=humor, 1=ansiedade, 2=energia, 3=intensidade, 4=modos, 5=notas
  int _step = 0;
  static const int _kTotalSteps = 6;

  @override
  void dispose() {
    _notesController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  void _populateFromCheckIn(PatientCheckIn checkIn) {
    if (_loaded) return;
    _loaded = true;
    _mood = checkIn.moodScore ?? 5;
    _moodEmotions = List.of(checkIn.moodEmotions);
    _anxiety = checkIn.anxietyScore ?? 5;
    _energy = checkIn.energyScore ?? 5;
    _problemIntensity = checkIn.problemIntensityScore ?? 5;
    _selectedMode = checkIn.selectedMode;
    _nicknameController.text = checkIn.selectedMode?.nickname ?? '';
    _notesController.text = checkIn.notes ?? '';
  }

  void _onMoodChanged(int value) {
    setState(() {
      _mood = value;
      _moodEmotions = [];
    });
  }

  PatientCheckInInput _buildInput() {
    final nickname = _nicknameController.text.trim();
    final mode = _selectedMode;
    return PatientCheckInInput(
      moodScore: _mood,
      moodEmotions: _moodEmotions,
      anxietyScore: _anxiety,
      energyScore: _energy,
      problemIntensityScore: _problemIntensity,
      selectedMode: mode == null
          ? null
          : CheckInMode(
              family: mode.family,
              clinicalName: mode.clinicalName,
              patientLabel: mode.patientLabel,
              nickname: nickname.isEmpty ? null : nickname,
            ),
      notes: _notesController.text,
    );
  }

  Future<void> _save() async {
    final input = _buildInput();
    final localError = input.validate();
    if (localError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(localError)),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final repo = ref.read(patientCheckInsRepositoryProvider);

      if (widget.isEdit) {
        final existing = await repo.getById(widget.checkInId!);
        if (existing == null) {
          throw AppException(
            code: AppExceptionCodes.notFound,
            message: 'Check-in não encontrado.',
          );
        }
        await repo.update(
          id: widget.checkInId!,
          input: input,
          existing: existing,
        );
      } else {
        final today = await repo.findTodayForCurrentPatient();
        if (today != null) {
          await repo.update(id: today.id, input: input, existing: today);
        } else {
          final ctx = await repo.resolvePatientContext();
          await repo.create(
            clinicId: ctx.clinicId,
            patientId: ctx.patientId,
            input: input,
          );
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Check-in registrado. Obrigado por se cuidar hoje.'),
        ),
      );
      context.pop(true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppException
                  ? userMessageFor(e)
                  : 'Não foi possível salvar.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final checkInAsync =
          ref.watch(patientCheckInDetailProvider(widget.checkInId!));
      return checkInAsync.when(
        loading: () => const AppScaffold(
          title: 'Carregando...',
          accent: AppColors.turquoise,
          body: BrandLoader(),
        ),
        error: (_, __) => AppScaffold(
          title: 'Erro',
          accent: AppColors.turquoise,
          body: Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(
                patientCheckInDetailProvider(widget.checkInId!),
              ),
              child: const Text('Tentar novamente'),
            ),
          ),
        ),
        data: (checkIn) {
          if (checkIn == null) {
            return const AppScaffold(
              title: 'Check-in',
              accent: AppColors.turquoise,
              body: Center(child: Text('Check-in não encontrado.')),
            );
          }
          if (!checkIn.isEditableToday) {
            return const AppScaffold(
              title: 'Check-in',
              accent: AppColors.turquoise,
              body: Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'Este check-in não pode mais ser editado (apenas o de hoje).',
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            );
          }
          _populateFromCheckIn(checkIn);
          return _buildForm(context, isEditToday: true);
        },
      );
    }

    return _buildForm(context, isEditToday: false);
  }

  Widget _buildForm(BuildContext context, {required bool isEditToday}) {
    final isLast = _step == _kTotalSteps - 1;

    return AppScaffold(
      title: widget.isEdit || isEditToday ? 'Editar check-in' : 'Check-in',
      accent: AppColors.turquoise,
      body: SafeArea(
        top: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, 0),
              child: _ProgressDots(count: _kTotalSteps, index: _step),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                child: SingleChildScrollView(
                  key: ValueKey(_step),
                  padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md, AppSpacing.lg, AppSpacing.md, AppSpacing.lg),
                  child: _stepContent(),
                ),
              ),
            ),
            _navBar(isLast: isLast),
          ],
        ),
      ),
    );
  }

  Widget _stepContent() {
    switch (_step) {
      case 0:
        return _moodStep();
      case 1:
        return _scoreStep(
          question: 'Como está sua ansiedade?',
          helper: 'Do mais tranquilo ao mais agitado.',
          lowLabel: 'Calmo(a)',
          highLabel: 'Muito ansioso(a)',
          faces: const ['😌', '🙂', '😐', '😰', '😱'],
          positiveHigh: false,
          value: _anxiety,
          onChanged: (v) => setState(() => _anxiety = v),
        );
      case 2:
        return _scoreStep(
          question: 'Como está sua energia?',
          helper: 'Quanto pique você sentiu hoje.',
          lowLabel: 'Exausto(a)',
          highLabel: 'Muita energia',
          faces: const ['😴', '😪', '🙂', '😀', '🤩'],
          positiveHigh: true,
          value: _energy,
          onChanged: (v) => setState(() => _energy = v),
        );
      case 3:
        return _scoreStep(
          question: 'E os problemas, como pesaram?',
          helper: 'O quanto os problemas te afetaram hoje.',
          lowLabel: 'Leve',
          highLabel: 'Muito intenso',
          faces: const ['🙂', '😐', '😕', '😣', '😖'],
          positiveHigh: false,
          value: _problemIntensity,
          onChanged: (v) => setState(() => _problemIntensity = v),
        );
      case 4:
        return _modesStep();
      default:
        return _notesStep();
    }
  }

  // ── Passo 0: Humor — Opção A ───────────────────────────────────────────

  Widget _moodStep() {
    final theme = Theme.of(context);
    final emotions = emotionsForScore(_mood);
    final label = kMoodLabels[_mood] ?? '';
    final surfaceVariant = theme.colorScheme.onSurfaceVariant;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Como está seu humor agora?',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 28),

        // ── Emoji grande + score ──
        Column(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: anim,
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Text(
                kMoodEmojis[_mood],
                key: ValueKey(_mood),
                style: const TextStyle(fontSize: 80),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.baseline,
              textBaseline: TextBaseline.alphabetic,
              children: [
                Text(
                  '$_mood',
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    color: AppColors.turquoise,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '— $label',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: surfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),

        // ── Strip com fundo cinza ──
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest
                .withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(11, (i) {
              final selected = _mood == i;
              return GestureDetector(
                onTap: () => _onMoodChanged(i),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: selected
                        ? AppColors.turquoise
                        : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    kMoodEmojis[i],
                    style: const TextStyle(fontSize: 19),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Péssimo',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: surfaceVariant)),
              Text('Excelente',
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: surfaceVariant)),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // ── Emoções ──
        Text(
          'Quer contar um pouco mais? Escolha uma ou mais.',
          style: theme.textTheme.bodyMedium?.copyWith(color: surfaceVariant),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 160),
          child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: emotions.map((emotion) {
            final selected = _moodEmotions.contains(emotion);
            return FilterChip(
              label: Text(emotion),
              selected: selected,
              onSelected: (on) {
                setState(() {
                  if (on) {
                    _moodEmotions = [..._moodEmotions, emotion];
                  } else {
                    _moodEmotions =
                        _moodEmotions.where((e) => e != emotion).toList();
                  }
                });
              },
              selectedColor: AppColors.turquoise.withValues(alpha: 0.18),
              checkmarkColor: AppColors.turquoise,
              side: BorderSide(
                color: selected
                    ? AppColors.turquoise
                    : theme.colorScheme.outlineVariant,
              ),
            );
          }).toList(),
          ),
        ),
      ],
    );
  }

  // ── Passo 4: Modos ───────────────────────────────────────────────────────

  Widget _modesStep() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Que modo está aparecendo agora?',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Toque na opção que mais se parece com você neste momento.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        ...kModeFamilies.map((family) => _familyCard(family, theme)),
        if (_selectedMode != null) ...[
          const SizedBox(height: 20),
          Text(
            'Esse modo tem um nome para você? (opcional)',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nicknameController,
            decoration: const InputDecoration(
              hintText: 'Ex: General, A Sombra, O Crítico...',
              prefixIcon: Icon(Icons.edit_outlined),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
        ],
      ],
    );
  }

  Widget _familyCard(ModeFamily family, ThemeData theme) {
    final isExpanded = _expandedFamilyId == family.id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () {
              setState(() {
                _expandedFamilyId = isExpanded ? null : family.id;
              });
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isExpanded
                    ? AppColors.turquoise.withValues(alpha: 0.1)
                    : theme.colorScheme.surfaceContainerLow,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isExpanded
                      ? AppColors.turquoise
                      : theme.colorScheme.outlineVariant,
                  width: isExpanded ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Text(family.icon,
                      style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      family.patientLabel,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.expand_less_rounded
                        : Icons.expand_more_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: AppColors.turquoise.withValues(alpha: 0.3)),
              ),
              child: Column(
                children: family.submodes.asMap().entries.map((entry) {
                  final i = entry.key;
                  final option = entry.value;
                  final isSelected = _selectedMode?.clinicalName ==
                          option.clinicalName &&
                      _selectedMode?.patientLabel == option.patientLabel &&
                      _selectedMode?.family == family.id;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        _selectedMode = CheckInMode(
                          family: family.id,
                          clinicalName: option.clinicalName,
                          patientLabel: option.patientLabel,
                        );
                        _nicknameController.clear();
                      });
                    },
                    borderRadius: BorderRadius.vertical(
                      top: i == 0
                          ? const Radius.circular(12)
                          : Radius.zero,
                      bottom: i == family.submodes.length - 1
                          ? const Radius.circular(12)
                          : Radius.zero,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.turquoise.withValues(alpha: 0.12)
                            : null,
                        border: i < family.submodes.length - 1
                            ? Border(
                                bottom: BorderSide(
                                  color: theme.colorScheme.outlineVariant
                                      .withValues(alpha: 0.4),
                                ),
                              )
                            : null,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(option.icon,
                              style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.patientLabel,
                                  style:
                                      theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? AppColors.turquoise
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '"${option.patientDescription}"',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isSelected)
                            Icon(Icons.check_circle_rounded,
                                color: AppColors.turquoise, size: 20),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  // ── Passos de escala genérica ─────────────────────────────────────────────

  Widget _scoreStep({
    required String question,
    required String helper,
    required String lowLabel,
    required String highLabel,
    required List<String> faces,
    required bool positiveHigh,
    required int value,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    final goodness = positiveHigh ? value / 10 : 1 - value / 10;
    final tone = goodness >= 0.66
        ? AppColors.success
        : goodness >= 0.33
            ? AppColors.warning
            : AppColors.error;
    final faceIndex =
        ((value / 10) * (faces.length - 1)).round().clamp(0, faces.length - 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          question,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helper,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 22),
        Center(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: tone.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: tone.withValues(alpha: 0.5), width: 2),
            ),
            alignment: Alignment.center,
            child: Text(faces[faceIndex], style: const TextStyle(fontSize: 60)),
          ),
        ),
        const SizedBox(height: 14),
        Center(
          child: Text(
            '$value/10',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
              color: tone,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Slider(
          value: value.toDouble(),
          max: 10,
          divisions: 10,
          activeColor: tone,
          label: '$value',
          onChanged: (v) => onChanged(v.round()),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(lowLabel,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
              Text(highLabel,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ],
    );
  }

  // ── Passo de notas ────────────────────────────────────────────────────────

  Widget _notesStep() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Quer contar algo do seu dia?',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.navy,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Opcional — só se quiser dar um contexto pro seu psicólogo.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _notesController,
          decoration: const InputDecoration(
            hintText: 'Escreva aqui (opcional)',
            alignLabelWithHint: true,
          ),
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }

  // ── Barra de navegação ────────────────────────────────────────────────────

  Widget _navBar({required bool isLast}) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
            AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
        child: Row(
          children: [
            if (_step > 0)
              TextButton.icon(
                onPressed: _saving
                    ? null
                    : () => setState(() => _step -= 1),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                label: const Text('Voltar'),
              )
            else
              TextButton(
                onPressed: _saving ? null : () => context.pop(),
                child: const Text('Agora não'),
              ),
            const Spacer(),
            FilledButton(
              onPressed: _saving
                  ? null
                  : isLast
                      ? _save
                      : () => setState(() => _step += 1),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.turquoise,
                minimumSize: const Size(150, 48),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isLast
                      ? (widget.isEdit ? 'Salvar' : 'Registrar check-in')
                      : 'Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Pontinhos de progresso do fluxo em passos.
class _ProgressDots extends StatelessWidget {
  const _ProgressDots({required this.count, required this.index});
  final int count;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < count; i++) ...[
          if (i > 0) const SizedBox(width: 5),
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 5,
            width: i == index ? 24 : 12,
            decoration: BoxDecoration(
              color: i <= index
                  ? AppColors.turquoise
                  : AppColors.turquoise.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ],
      ],
    );
  }
}
