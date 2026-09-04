import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../genogram/providers/genogram_providers.dart';
import '../../patient_check_ins/presentation/widgets/patient_check_in_widgets.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient_timeline_event.dart';
import '../domain/patient_timeline_event_input.dart';
import '../providers/patient_timeline_providers.dart';
import '../../../shared/widgets/brand_loading.dart';

class PatientTimelineEventFormPage extends ConsumerStatefulWidget {
  const PatientTimelineEventFormPage({
    super.key,
    required this.role,
    this.patientId,
    this.eventId,
  });

  final ProfileRole role;
  final String? patientId;
  final String? eventId;

  bool get isEdit => eventId != null;

  @override
  ConsumerState<PatientTimelineEventFormPage> createState() =>
      _PatientTimelineEventFormPageState();
}

class _PatientTimelineEventFormPageState
    extends ConsumerState<PatientTimelineEventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _periodLabelController = TextEditingController();
  final _categoryController = TextEditingController();
  final _emotionalNeedOtherController = TextEditingController();
  final _emotionsFeltController = TextEditingController();
  final _selfMeaningController = TextEditingController();
  final _othersMeaningController = TextEditingController();
  final _worldMeaningController = TextEditingController();
  final _copingOtherController = TextEditingController();
  final _presentReactionController = TextEditingController();

  DateTime? _eventDate;
  Set<String> _emotionalNeedKeys = {};
  Set<String> _copingKeys = {};
  bool _includePresentInfluence = false;
  int _presentInfluence = 5;
  Set<String> _presentAreaKeys = {};
  bool _isSensitive = false;
  bool _saving = false;
  bool _loaded = false;
  String? _relatedPersonId;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _periodLabelController.dispose();
    _categoryController.dispose();
    _emotionalNeedOtherController.dispose();
    _emotionsFeltController.dispose();
    _selfMeaningController.dispose();
    _othersMeaningController.dispose();
    _worldMeaningController.dispose();
    _copingOtherController.dispose();
    _presentReactionController.dispose();
    super.dispose();
  }

  void _populateFromEvent(PatientTimelineEvent event) {
    if (_loaded) return;
    _loaded = true;
    final input = PatientTimelineEventInput.fromEvent(event);
    _titleController.text = input.title;
    _descriptionController.text = input.description ?? '';
    _periodLabelController.text = input.periodLabel ?? '';
    _categoryController.text = input.category ?? '';
    _emotionalNeedKeys = input.emotionalNeedKeys.toSet();
    _emotionalNeedOtherController.text = input.emotionalNeedOther ?? '';
    _emotionsFeltController.text = input.emotionsFelt ?? '';
    _selfMeaningController.text = input.selfMeaning ?? '';
    _othersMeaningController.text = input.othersMeaning ?? '';
    _worldMeaningController.text = input.worldMeaning ?? '';
    _copingKeys = input.copingKeys.toSet();
    _copingOtherController.text = input.copingOther ?? '';
    _presentAreaKeys = input.presentAreaKeys.toSet();
    _presentReactionController.text = input.presentReaction ?? '';
    _eventDate = input.eventDate;
    _isSensitive = input.isSensitive;
    _relatedPersonId =
        input.relatedPersonIds.isNotEmpty ? input.relatedPersonIds.first : null;
    if (input.presentInfluence != null) {
      _includePresentInfluence = true;
      _presentInfluence = input.presentInfluence!;
    }
  }

  PatientTimelineEventInput _buildInput() {
    return PatientTimelineEventInput(
      title: _titleController.text,
      description: _descriptionController.text,
      eventDate: _eventDate,
      periodLabel: _periodLabelController.text,
      category: _categoryController.text,
      emotionalNeedKeys: _emotionalNeedKeys.toList(),
      emotionalNeedOther: _emotionalNeedOtherController.text,
      emotionsFelt: _emotionsFeltController.text,
      selfMeaning: _selfMeaningController.text,
      othersMeaning: _othersMeaningController.text,
      worldMeaning: _worldMeaningController.text,
      copingKeys: _copingKeys.toList(),
      copingOther: _copingOtherController.text,
      presentInfluence: _includePresentInfluence ? _presentInfluence : null,
      presentAreaKeys: _presentAreaKeys.toList(),
      presentReaction: _presentReactionController.text,
      isSensitive: _isSensitive,
      relatedPersonIds:
          _relatedPersonId != null ? [_relatedPersonId!] : const [],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

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
      final repo = ref.read(patientTimelineRepositoryProvider);

      if (widget.isEdit) {
        await repo.update(id: widget.eventId!, input: input);
      } else {
        final ctx = await repo.resolvePatientContext(
          patientId: widget.patientId,
        );
        await repo.create(
          clinicId: ctx.clinicId,
          patientId: ctx.patientId,
          input: input,
        );
      }

      if (!mounted) return;
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

  Future<void> _pickEventDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 80)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isEdit) {
      final eventAsync =
          ref.watch(patientTimelineEventDetailProvider(widget.eventId!));
      return eventAsync.when(
        loading: () => const AppScaffold(
          title: 'Carregando...',
          accent: AppColors.cyan,
          body: BrandLoader(),
        ),
        error: (_, __) => AppScaffold(
          title: 'Erro',
          accent: AppColors.cyan,
          body: Center(
            child: FilledButton(
              onPressed: () => ref.invalidate(
                patientTimelineEventDetailProvider(widget.eventId!),
              ),
              child: const Text('Tentar novamente'),
            ),
          ),
        ),
        data: (event) {
          if (event == null) {
            return const AppScaffold(
              title: 'Evento',
              accent: AppColors.cyan,
              body: Center(child: Text('Evento não encontrado.')),
            );
          }
          _populateFromEvent(event);
          return _buildForm(context);
        },
      );
    }

    return _buildForm(context);
  }

  Widget _buildForm(BuildContext context) {
    return AppScaffold(
      title: widget.isEdit ? 'Editar evento' : 'Novo evento',
      accent: AppColors.cyan,
      body: Form(
        key: _formKey,
        child: MotionReveal(
          child: ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              AppPageHeader(
                icon: Icons.timeline_outlined,
                title: widget.isEdit ? 'Editar evento' : 'Novo evento',
                subtitle:
                    'Registre o acontecimento, o impacto emocional e a ponte com o presente em etapas clínicas claras.',
              ),
              const SizedBox(height: AppSpacing.lg),
              DropdownButtonFormField<String>(
                initialValue: _lifeStageValue,
                decoration: const InputDecoration(
                  labelText: 'Etapa da vida *',
                ),
                items: _lifeStageOptions
                    .map(
                      (option) => DropdownMenuItem(
                        value: option.key,
                        child: Text(option.label),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _periodLabelController.text = value);
                  }
                },
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Selecione a etapa da vida.'
                    : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título *',
                  hintText:
                      'Ex.: falecimento, nascimento, viagem, conquista, mudança importante',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Informe o título.' : null,
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição do evento',
                  alignLabelWithHint: true,
                ),
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Data do evento (opcional)'),
                subtitle: Text(
                  _eventDate == null
                      ? 'Não definida'
                      : MaterialLocalizations.of(context).formatFullDate(
                          _eventDate!,
                        ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.calendar_today_outlined),
                  onPressed: _pickEventDate,
                ),
              ),
              if (_eventDate != null)
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => setState(() => _eventDate = null),
                    child: const Text('Remover data'),
                  ),
                ),
              const SizedBox(height: AppSpacing.xs),
              TextFormField(
                controller: _categoryController,
                decoration: const InputDecoration(
                  labelText: 'Observações',
                  hintText: 'Ex.: onde isso aconteceu, quem estava envolvido',
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              _RelatedPersonField(
                role: widget.role,
                patientId: widget.patientId,
                value: _relatedPersonId,
                onChanged: (v) => setState(() => _relatedPersonId = v),
              ),
              const SizedBox(height: AppSpacing.md),
              const _SectionTitle(
                  '1. Esse evento impactou em qual necessidade emocional?'),
              ..._emotionalNeedOptions.map(
                (option) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _emotionalNeedKeys.contains(option.key),
                  title: Text(option.label),
                  onChanged: (value) => _toggleKey(
                    _emotionalNeedKeys,
                    option.key,
                    value,
                  ),
                ),
              ),
              if (_emotionalNeedKeys.contains('other')) ...[
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _emotionalNeedOtherController,
                  decoration: const InputDecoration(
                    labelText: 'Outra necessidade emocional *',
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _emotionsFeltController,
                decoration: const InputDecoration(
                  labelText: '2. Que emoções você sentiu na época?',
                  hintText:
                      'Ex.: medo, insegurança, tristeza, desamparo, felicidade, entusiasmo, orgulho, realização',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              const _SectionTitle('3. Significado'),
              TextFormField(
                controller: _selfMeaningController,
                decoration: const InputDecoration(
                  labelText: 'O que você concluiu sobre você mesmo?',
                  hintText: 'Ex.: "não sou importante"',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _othersMeaningController,
                decoration: const InputDecoration(
                  labelText: 'O que você concluiu sobre os outros?',
                  hintText: 'Ex.: "não posso confiar em ninguém"',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.sm),
              TextFormField(
                controller: _worldMeaningController,
                decoration: const InputDecoration(
                  labelText: 'O que você concluiu sobre o mundo?',
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              const _SectionTitle('4. O que você fez para lidar com isso?'),
              ..._copingOptions.map(
                (option) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _copingKeys.contains(option.key),
                  title: Text(option.label),
                  onChanged: (value) => _toggleKey(
                    _copingKeys,
                    option.key,
                    value,
                  ),
                ),
              ),
              if (_copingKeys.contains('other')) ...[
                const SizedBox(height: AppSpacing.xs),
                TextFormField(
                  controller: _copingOtherController,
                  decoration: const InputDecoration(
                    labelText: 'Outra forma de lidar *',
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              const _SectionTitle('5. Ponte com o presente'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title:
                    const Text('Esse evento ainda influencia sua vida hoje?'),
                subtitle: const Text('Escala de 0 a 10'),
                value: _includePresentInfluence,
                onChanged: (v) => setState(() => _includePresentInfluence = v),
              ),
              if (_includePresentInfluence)
                ScoreSliderField(
                  label: 'Influência atual',
                  value: _presentInfluence,
                  onChanged: (v) => setState(() => _presentInfluence = v),
                  lowLabel: '0',
                  highLabel: '10',
                ),
              const SizedBox(height: AppSpacing.xs),
              Text('Em quais áreas?',
                  style: Theme.of(context).textTheme.titleSmall),
              ..._presentAreaOptions.map(
                (option) => CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: _presentAreaKeys.contains(option.key),
                  title: Text(option.label),
                  onChanged: (value) => _toggleKey(
                    _presentAreaKeys,
                    option.key,
                    value,
                  ),
                ),
              ),
              TextFormField(
                controller: _presentReactionController,
                decoration: const InputDecoration(
                  labelText:
                      'Quando algo parecido acontece hoje, você reage como?',
                ),
                maxLines: 3,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: AppSpacing.md),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Conteúdo sensível'),
                subtitle: const Text(
                  'Destaca o evento na linha do tempo para atenção na leitura.',
                ),
                value: _isSensitive,
                onChanged: (v) => setState(() => _isSensitive = v),
              ),
              const SizedBox(height: AppSpacing.xxl),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(widget.isEdit
                        ? 'Salvar alterações'
                        : 'Registrar evento'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? get _lifeStageValue {
    final text = _periodLabelController.text.trim();
    if (text.isEmpty) return null;
    return _lifeStageOptions.any((option) => option.key == text) ? text : null;
  }

  void _toggleKey(Set<String> target, String key, bool? value) {
    setState(() {
      if (value == true) {
        target.add(key);
      } else {
        target.remove(key);
      }
    });
  }
}

/// Vínculo opcional com uma pessoa do genograma — permite depois navegar do
/// genograma direto para o(s) evento(s) daquela pessoa.
class _RelatedPersonField extends ConsumerWidget {
  const _RelatedPersonField({
    required this.role,
    required this.patientId,
    required this.value,
    required this.onChanged,
  });

  final ProfileRole role;
  final String? patientId;
  final String? value;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genogramAsync = role == ProfileRole.patient
        ? ref.watch(myGenogramProvider)
        : ref.watch(
            staffGenogramProvider(
              StaffGenogramContext(role: role, patientId: patientId!),
            ),
          );

    return genogramAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (data) {
        if (data.people.isEmpty) return const SizedBox.shrink();
        final validValue =
            data.people.any((p) => p.id == value) ? value : null;
        return DropdownButtonFormField<String>(
          initialValue: validValue,
          decoration: const InputDecoration(
            labelText: 'Pessoa do genograma relacionada (opcional)',
            helperText:
                'Assim é possível achar este evento a partir do genograma.',
          ),
          items: [
            const DropdownMenuItem<String>(
              value: null,
              child: Text('Nenhuma'),
            ),
            ...data.people.map(
              (p) => DropdownMenuItem(
                value: p.id,
                child: Text(p.displayName),
              ),
            ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceWarm,
          borderRadius: AppRadius.mdAll,
          border: Border.all(color: AppColors.border),
        ),
        child: Text(
          text,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
        ),
      ),
    );
  }
}

class _Option {
  const _Option(this.key, this.label);

  final String key;
  final String label;
}

const _lifeStageOptions = [
  _Option('Infância', 'Infância'),
  _Option('Adolescência', 'Adolescência'),
  _Option('Vida adulta', 'Vida adulta'),
  _Option('Maturidade', 'Maturidade'),
];

const _emotionalNeedOptions = [
  _Option('connection_acceptance', 'Conexão e Aceitação'),
  _Option(
      'autonomy_competence_identity', 'Autonomia, competência e identidade'),
  _Option('limits_self_control', 'Limites e autocontrole'),
  _Option('expression_freedom', 'Liberdade de Expressão'),
  _Option('recognition_value', 'Valorização e reconhecimento'),
  _Option('spontaneity_leisure', 'Espontaneidade e Lazer'),
  _Option('other', 'Outra'),
];

const _copingOptions = [
  _Option('avoidance', 'Me afastei / evitei sentir'),
  _Option('surrender_adaptation', 'Aceitei e busquei me adaptar'),
  _Option('overcompensation_reaction', 'Explodi / reagi'),
  _Option('emotional_shutdown', 'Desliguei emocionalmente'),
  _Option('help_protection', 'Procurei ajuda / proteção'),
  _Option('perfectionism', 'Tentei "ser perfeito"'),
  _Option('other', 'Outro'),
];

const _presentAreaOptions = [
  _Option('relationships', 'Relações'),
  _Option('self_esteem', 'Autoestima'),
  _Option('work', 'Trabalho'),
  _Option('emotions', 'Emoções'),
  _Option('decisions', 'Decisões'),
  _Option('body', 'Corpo'),
];
