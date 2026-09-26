import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../domain/exercise_definition.dart';
import '../domain/exercise_definitions_data.dart';
import '../domain/psychoeducation_module.dart';
import '../providers/psychoeducation_providers.dart';

/// Full-screen interactive exercise for a Fase 2 psychoeducation module.
class PsychoeducationExercisePage extends ConsumerStatefulWidget {
  const PsychoeducationExercisePage({
    super.key,
    required this.module,
  });

  final PsychoeducationModule module;

  @override
  ConsumerState<PsychoeducationExercisePage> createState() =>
      _PsychoeducationExercisePageState();
}

class _PsychoeducationExercisePageState
    extends ConsumerState<PsychoeducationExercisePage> {
  late final ExerciseDefinition _def;
  final Map<String, dynamic> _responses = {};
  String? _difficultyScale;
  bool? _wantsToTalk;
  bool _submitted = false;

  @override
  void initState() {
    super.initState();
    _def = kExerciseDefinitions[widget.module.number]!;

    // Prefill from saved response
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final saved = ref
          .read(exerciseSaveProvider(widget.module.id))
          .valueOrNull;
      if (saved != null && mounted) {
        setState(() {
          _responses.addAll(saved.responses);
          _difficultyScale = saved.difficultyScale;
          _wantsToTalk = saved.wantsToTalk;
        });
      }
    });
  }

  Color get _accentColor => widget.module.color;

  void _setResponse(String key, dynamic value) {
    setState(() => _responses[key] = value);
  }

  void _toggleCheck(String key, String option) {
    final current = List<String>.from(
        (_responses[key] as List?)?.cast<String>() ?? []);
    if (current.contains(option)) {
      current.remove(option);
    } else {
      current.add(option);
    }
    _setResponse(key, current);
  }

  Future<void> _save() async {
    try {
      await ref.read(exerciseSaveProvider(widget.module.id).notifier).save(
            responses: Map<String, dynamic>.from(_responses),
            difficultyScale: _difficultyScale,
            wantsToTalk: _wantsToTalk,
          );
      if (mounted) setState(() => _submitted = true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSaving = ref.watch(exerciseSaveProvider(widget.module.id)).isLoading;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: theme.colorScheme.onSurface,
        elevation: 0,
        title: Text(
          'Exercício',
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: _submitted
          ? _SuccessView(accentColor: _accentColor, onBack: () => Navigator.of(context).pop())
          : _FormView(
              def: _def,
              responses: _responses,
              difficultyScale: _difficultyScale,
              wantsToTalk: _wantsToTalk,
              accentColor: _accentColor,
              isSaving: isSaving,
              onSetResponse: _setResponse,
              onToggleCheck: _toggleCheck,
              onDifficultyChanged: (v) => setState(() => _difficultyScale = v),
              onWantsToTalkChanged: (v) => setState(() => _wantsToTalk = v),
              onSave: _save,
            ),
    );
  }
}

// ---------------------------------------------------------------------------
// Form view
// ---------------------------------------------------------------------------

class _FormView extends StatelessWidget {
  const _FormView({
    required this.def,
    required this.responses,
    required this.difficultyScale,
    required this.wantsToTalk,
    required this.accentColor,
    required this.isSaving,
    required this.onSetResponse,
    required this.onToggleCheck,
    required this.onDifficultyChanged,
    required this.onWantsToTalkChanged,
    required this.onSave,
  });

  final ExerciseDefinition def;
  final Map<String, dynamic> responses;
  final String? difficultyScale;
  final bool? wantsToTalk;
  final Color accentColor;
  final bool isSaving;
  final void Function(String key, dynamic value) onSetResponse;
  final void Function(String key, String option) onToggleCheck;
  final void Function(String?) onDifficultyChanged;
  final void Function(bool?) onWantsToTalkChanged;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.xl, AppSpacing.md, AppSpacing.xl, AppSpacing.xxl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: accentColor.withValues(alpha: 0.20)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.self_improvement, color: accentColor, size: 20),
                  const SizedBox(width: 8),
                  Text('Praticar',
                      style: theme.textTheme.labelMedium?.copyWith(
                          color: accentColor, fontWeight: FontWeight.w800)),
                ]),
                const SizedBox(height: 6),
                Text(def.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface)),
                if (def.intro != null) ...[
                  const SizedBox(height: 8),
                  Text(def.intro!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant, height: 1.5)),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),

          // Steps
          for (final step in def.steps) ...[
            _StepSection(
              step: step,
              responses: responses,
              accentColor: accentColor,
              onSetResponse: onSetResponse,
              onToggleCheck: onToggleCheck,
            ),
            const SizedBox(height: AppSpacing.xl),
          ],

          // Closing scale
          _ClosingSection(
            difficultyScale: difficultyScale,
            wantsToTalk: wantsToTalk,
            accentColor: accentColor,
            onDifficultyChanged: onDifficultyChanged,
            onWantsToTalkChanged: onWantsToTalkChanged,
          ),
          const SizedBox(height: AppSpacing.xl),

          // Save button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_outlined),
              label: Text(isSaving ? 'Salvando...' : 'Salvar exercício'),
              style: FilledButton.styleFrom(
                backgroundColor: accentColor,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Step section
// ---------------------------------------------------------------------------

class _StepSection extends StatelessWidget {
  const _StepSection({
    required this.step,
    required this.responses,
    required this.accentColor,
    required this.onSetResponse,
    required this.onToggleCheck,
  });

  final ExerciseStep step;
  final Map<String, dynamic> responses;
  final Color accentColor;
  final void Function(String key, dynamic value) onSetResponse;
  final void Function(String key, String option) onToggleCheck;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(step.title,
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: 0.3)),
        if (step.subtitle != null) ...[
          const SizedBox(height: 4),
          Text(step.subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant)),
        ],
        const SizedBox(height: AppSpacing.md),
        for (final field in step.fields)
          _FieldWidget(
            field: field,
            value: responses[field.key],
            accentColor: accentColor,
            onSetResponse: (v) => onSetResponse(field.key, v),
            onToggleCheck: (opt) => onToggleCheck(field.key, opt),
            otherKey: '${field.key}_other',
            otherValue: responses['${field.key}_other'] as String?,
            onSetOther: (v) => onSetResponse('${field.key}_other', v),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Field widget
// ---------------------------------------------------------------------------

class _FieldWidget extends StatefulWidget {
  const _FieldWidget({
    required this.field,
    required this.value,
    required this.accentColor,
    required this.onSetResponse,
    required this.onToggleCheck,
    required this.otherKey,
    required this.otherValue,
    required this.onSetOther,
  });

  final ExerciseField field;
  final dynamic value;
  final Color accentColor;
  final void Function(dynamic) onSetResponse;
  final void Function(String) onToggleCheck;
  final String otherKey;
  final String? otherValue;
  final void Function(String) onSetOther;

  @override
  State<_FieldWidget> createState() => _FieldWidgetState();
}

class _FieldWidgetState extends State<_FieldWidget> {
  late final TextEditingController _ctrl;
  late final TextEditingController _otherCtrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.field.type == ExerciseFieldType.text
            ? (widget.value as String? ?? '')
            : '');
    _otherCtrl =
        TextEditingController(text: widget.otherValue ?? '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _otherCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final field = widget.field;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (field.prompt.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(field.prompt,
                  style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface)),
            ),
          if (field.type == ExerciseFieldType.text) ...[
            if (field.prefix != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(field.prefix!,
                    style: theme.textTheme.bodySmall?.copyWith(
                        color: widget.accentColor,
                        fontWeight: FontWeight.w600,
                        fontStyle: FontStyle.italic)),
              ),
            TextField(
              controller: _ctrl,
              onChanged: widget.onSetResponse,
              maxLines: null,
              minLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: field.hint,
                hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.6)),
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                      color: widget.accentColor.withValues(alpha: 0.6)),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ] else if (field.type == ExerciseFieldType.multicheck) ...[
            for (final opt in field.options)
              _CheckTile(
                label: opt,
                checked: (widget.value as List?)?.contains(opt) ?? false,
                color: widget.accentColor,
                onTap: () => widget.onToggleCheck(opt),
              ),
            if (field.allowOther) ...[
              const SizedBox(height: 6),
              TextField(
                controller: _otherCtrl,
                onChanged: widget.onSetOther,
                decoration: InputDecoration(
                  hintText: 'Outro: especifique',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: widget.accentColor.withValues(alpha: 0.6)),
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ],
          ] else if (field.type == ExerciseFieldType.singlecheck) ...[
            for (final opt in field.options)
              RadioListTile<String>(
                value: opt,
                groupValue: widget.value as String?,
                onChanged: (v) => widget.onSetResponse(v),
                title: Text(opt, style: theme.textTheme.bodyMedium),
                activeColor: widget.accentColor,
                dense: true,
                contentPadding: EdgeInsets.zero,
              ),
          ],
        ],
      ),
    );
  }
}

class _CheckTile extends StatelessWidget {
  const _CheckTile({
    required this.label,
    required this.checked,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool checked;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: checked
              ? color.withValues(alpha: 0.10)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: checked
                  ? color.withValues(alpha: 0.45)
                  : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(
              checked ? Icons.check_box : Icons.check_box_outline_blank,
              color: checked ? color : theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(label, style: theme.textTheme.bodyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Closing section (scale + wants_to_talk)
// ---------------------------------------------------------------------------

class _ClosingSection extends StatelessWidget {
  const _ClosingSection({
    required this.difficultyScale,
    required this.wantsToTalk,
    required this.accentColor,
    required this.onDifficultyChanged,
    required this.onWantsToTalkChanged,
  });

  final String? difficultyScale;
  final bool? wantsToTalk;
  final Color accentColor;
  final void Function(String?) onDifficultyChanged;
  final void Function(bool?) onWantsToTalkChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(color: theme.colorScheme.outlineVariant),
        const SizedBox(height: AppSpacing.md),
        Text('Como foi realizar este exercício?',
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface)),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (var i = 0; i < ExerciseDefinition.closingScaleOptions.length; i++)
              _EmojiOption(
                emoji: ExerciseDefinition.closingScaleEmojis[i],
                label: ExerciseDefinition.closingScaleOptions[i],
                selected: difficultyScale ==
                    ExerciseDefinition.closingScaleOptions[i],
                color: accentColor,
                onTap: () => onDifficultyChanged(
                    ExerciseDefinition.closingScaleOptions[i]),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xl),
        Text('Quero conversar sobre este exercício com meu psicólogo',
            style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.colorScheme.onSurface)),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _YesNoButton(
              label: 'Sim',
              selected: wantsToTalk == true,
              color: accentColor,
              onTap: () => onWantsToTalkChanged(true),
            ),
            const SizedBox(width: AppSpacing.sm),
            _YesNoButton(
              label: 'Não',
              selected: wantsToTalk == false,
              color: accentColor,
              onTap: () => onWantsToTalkChanged(false),
            ),
          ],
        ),
      ],
    );
  }
}

class _EmojiOption extends StatelessWidget {
  const _EmojiOption({
    required this.emoji,
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String emoji;
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? color.withValues(alpha: 0.15)
                  : Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.5),
              shape: BoxShape.circle,
              border: Border.all(
                  color: selected
                      ? color.withValues(alpha: 0.5)
                      : Colors.transparent,
                  width: 2),
            ),
            child: Text(emoji, style: const TextStyle(fontSize: 22)),
          ),
        ],
      ),
    );
  }
}

class _YesNoButton extends StatelessWidget {
  const _YesNoButton({
    required this.label,
    required this.selected,
    required this.color,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? color.withValues(alpha: 0.12)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: selected
                  ? color.withValues(alpha: 0.45)
                  : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.w700,
                color: selected
                    ? color
                    : Theme.of(context).colorScheme.onSurfaceVariant)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Success view
// ---------------------------------------------------------------------------

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.accentColor, required this.onBack});
  final Color accentColor;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Text('🌱', style: const TextStyle(fontSize: 36)),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Exercício salvo!',
                style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface)),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Reconhecer uma necessidade é o primeiro passo para cuidar dela. '
              'Cada vez que você responde de uma forma mais saudável, '
              'fortalece seu Adulto Saudável.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant, height: 1.5),
            ),
            const SizedBox(height: AppSpacing.xxl),
            FilledButton(
              onPressed: onBack,
              style: FilledButton.styleFrom(backgroundColor: accentColor),
              child: const Text('Voltar à biblioteca'),
            ),
          ],
        ),
      ),
    );
  }
}
