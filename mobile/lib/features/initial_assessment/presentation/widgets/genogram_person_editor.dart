import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/error_banner.dart';
import '../../domain/genogram_enums.dart';
import '../../domain/genogram_person_entry.dart';
import '../../providers/patient_family_providers.dart';

/// Abre o editor de uma pessoa do genograma (criar ou editar).
Future<void> showGenogramPersonEditor({
  required BuildContext context,
  required InitialAssessmentContext ctx,
  GenogramPersonEntry? person,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => _GenogramPersonEditor(ctx: ctx, person: person),
  );
}

class _GenogramPersonEditor extends ConsumerStatefulWidget {
  const _GenogramPersonEditor({required this.ctx, this.person});

  final InitialAssessmentContext ctx;
  final GenogramPersonEntry? person;

  @override
  ConsumerState<_GenogramPersonEditor> createState() =>
      _GenogramPersonEditorState();
}

class _GenogramPersonEditorState extends ConsumerState<_GenogramPersonEditor> {
  late final TextEditingController _fullName;
  late final TextEditingController _relationship;
  late final TextEditingController _age;
  late final TextEditingController _traitsOther;
  late final TextEditingController _eventsOther;
  String? _gender;
  bool _isDeceased = false;
  bool _isSensitive = false;
  bool _isCaregiver = false;
  BondQuality? _bond;
  int? _presence;
  final Set<CaregiverTrait> _traits = {};
  final Set<CaregiverNeed> _feltNeeds = {};
  final Set<CaregiverNeed> _wishedNeeds = {};
  final Set<LinkedEvent> _events = {};
  bool _saving = false;

  bool get _isEditing => widget.person != null;

  @override
  void initState() {
    super.initState();
    final p = widget.person;
    _fullName = TextEditingController(text: p?.fullName ?? '');
    _relationship = TextEditingController(text: p?.relationshipToPatient ?? '');
    final age = p?.birthYear == null
        ? ''
        : (DateTime.now().year - p!.birthYear!).toString();
    _age = TextEditingController(text: age);
    _traitsOther = TextEditingController(text: p?.caregiverTraitsOther ?? '');
    _eventsOther = TextEditingController(text: p?.linkedEventsOther ?? '');
    _gender = p?.gender;
    _isDeceased = p?.isDeceased ?? false;
    _isSensitive = p?.isSensitive ?? false;
    _isCaregiver = p?.isCaregiver ?? false;
    _bond = p?.bondQuality;
    _presence = p?.emotionalPresence;
    _traits.addAll(p?.caregiverTraits ?? const []);
    _feltNeeds.addAll(p?.feltNeeds ?? const []);
    _wishedNeeds.addAll(p?.wishedNeeds ?? const []);
    _events.addAll(p?.linkedEvents ?? const []);
  }

  @override
  void dispose() {
    _fullName.dispose();
    _relationship.dispose();
    _age.dispose();
    _traitsOther.dispose();
    _eventsOther.dispose();
    super.dispose();
  }

  String? _nullIfEmpty(String v) => v.trim().isEmpty ? null : v.trim();

  Future<void> _save() async {
    if (_fullName.text.trim().isEmpty) {
      showErrorBanner(context, 'Informe o nome da pessoa.');
      return;
    }
    setState(() => _saving = true);
    final notifier =
        ref.read(patientFamilyMutationProvider(widget.ctx).notifier);
    final age = int.tryParse(_age.text.trim());
    final birthYear = age == null ? null : DateTime.now().year - age;
    try {
      if (_isEditing) {
        await notifier.updatePerson(
          personId: widget.person!.id,
          fullName: _fullName.text,
          relationshipToPatient: _nullIfEmpty(_relationship.text),
          gender: _gender,
          birthYear: birthYear,
          isDeceased: _isDeceased,
          isSensitive: _isSensitive,
          isCaregiver: _isCaregiver,
          bondQuality: _bond,
          emotionalPresence: _presence,
          caregiverTraits: _traits.toList(),
          caregiverTraitsOther: _nullIfEmpty(_traitsOther.text),
          feltNeeds: _feltNeeds.toList(),
          wishedNeeds: _wishedNeeds.toList(),
          linkedEvents: _events.toList(),
          linkedEventsOther: _nullIfEmpty(_eventsOther.text),
        );
      } else {
        await notifier.createPerson(
          fullName: _fullName.text,
          relationshipToPatient: _nullIfEmpty(_relationship.text),
          gender: _gender,
          birthYear: birthYear,
          isDeceased: _isDeceased,
          isSensitive: _isSensitive,
          isCaregiver: _isCaregiver,
          bondQuality: _bond,
          emotionalPresence: _presence,
          caregiverTraits: _traits.toList(),
          caregiverTraitsOther: _nullIfEmpty(_traitsOther.text),
          feltNeeds: _feltNeeds.toList(),
          wishedNeeds: _wishedNeeds.toList(),
          linkedEvents: _events.toList(),
          linkedEventsOther: _nullIfEmpty(_eventsOther.text),
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
        title: const Text('Excluir pessoa?'),
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
          .read(patientFamilyMutationProvider(widget.ctx).notifier)
          .deletePerson(widget.person!.id);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

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
                _isEditing ? 'Editar pessoa' : 'Adicionar pessoa',
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 16),
              // ── Dados básicos ──────────────────────────────────────────
              TextField(
                controller: _fullName,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _relationship,
                decoration: const InputDecoration(
                  labelText: 'Grau de parentesco (ex.: Mãe, Irmão)',
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _gender,
                      decoration: const InputDecoration(labelText: 'Gênero'),
                      items: const [
                        DropdownMenuItem(
                            value: 'female', child: Text('Feminino')),
                        DropdownMenuItem(
                            value: 'male', child: Text('Masculino')),
                        DropdownMenuItem(value: 'other', child: Text('Outro')),
                        DropdownMenuItem(
                            value: 'unknown', child: Text('Não informado')),
                      ],
                      onChanged: (v) => setState(() => _gender = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 90,
                    child: TextField(
                      controller: _age,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(labelText: 'Idade'),
                    ),
                  ),
                ],
              ),
              SwitchListTile(
                value: _isDeceased,
                onChanged: (v) => setState(() => _isDeceased = v),
                title: const Text('É falecido(a)?'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              SwitchListTile(
                value: _isSensitive,
                onChanged: (v) => setState(() => _isSensitive = v),
                title: const Text('Conteúdo sensível'),
                subtitle: const Text(
                  'Indica que informações sobre esta pessoa são delicadas.',
                ),
                secondary: const Icon(Icons.lock_outline),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const Divider(height: 24),
              // ── Camada emocional ───────────────────────────────────────
              SwitchListTile(
                value: _isCaregiver,
                onChanged: (v) => setState(() => _isCaregiver = v),
                title: const Text(
                    'Participou da sua criação ou foi sua cuidadora?'),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              const SizedBox(height: 8),
              _label('Como você descreveria sua relação com essa pessoa?'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final q in BondQuality.values)
                    ChoiceChip(
                      label: Text(q.label),
                      selected: _bond == q,
                      onSelected: (sel) =>
                          setState(() => _bond = sel ? q : null),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              _presenceRow(theme),
              const SizedBox(height: 8),
              _multiSelect<CaregiverTrait>(
                'Como essa pessoa costumava agir com você?',
                CaregiverTrait.values,
                _traits,
                (e) => e.label,
              ),
              _otherField(_traitsOther),
              const SizedBox(height: 8),
              _multiSelect<CaregiverNeed>(
                'Quando estava com essa pessoa, geralmente se sentia...',
                CaregiverNeed.values,
                _feltNeeds,
                (e) => e.label,
              ),
              const SizedBox(height: 8),
              _multiSelect<CaregiverNeed>(
                'O que você mais gostaria de ter recebido dessa pessoa?',
                CaregiverNeed.values,
                _wishedNeeds,
                (e) => e.label,
              ),
              const SizedBox(height: 8),
              _multiSelect<LinkedEvent>(
                'Existe algum acontecimento importante relacionado a essa pessoa?',
                LinkedEvent.values,
                _events,
                (e) => e.label,
              ),
              _otherField(_eventsOther),
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

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(text,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: AppColors.textSecondary)),
      );

  Widget _presenceRow(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child:
                  _label('Quanto essa pessoa esteve emocionalmente presente?'),
            ),
            Text(_presence?.toString() ?? '—',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const Text('/10'),
          ],
        ),
        Slider(
          value: (_presence ?? 0).toDouble(),
          max: 10,
          divisions: 10,
          label: (_presence ?? 0).toString(),
          onChanged: (v) => setState(() => _presence = v.round()),
        ),
      ],
    );
  }

  Widget _multiSelect<E>(
    String title,
    List<E> options,
    Set<E> selected,
    String Function(E) label,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _label(title),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final option in options)
              FilterChip(
                label: Text(label(option)),
                selected: selected.contains(option),
                onSelected: (_) => setState(() {
                  if (!selected.remove(option)) selected.add(option);
                }),
              ),
          ],
        ),
      ],
    );
  }

  Widget _otherField(TextEditingController controller) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: 'Outro (opcional)',
            isDense: true,
          ),
        ),
      );
}
