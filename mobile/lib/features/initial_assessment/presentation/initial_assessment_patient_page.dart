import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import 'initial_assessment_routes.dart';
import '../domain/initial_assessment.dart';
import '../domain/life_area.dart';
import '../domain/life_area_assessment.dart';
import '../domain/patient_basics.dart';
import '../providers/initial_assessment_providers.dart';
import 'widgets/life_area_card.dart';
import 'widgets/life_area_wheel_chart.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Tela 1 do fluxo Conhecer na lente do paciente — Blocos 2 e 3.
/// (O Bloco 1 vive na tabela `patients` e será integrado separadamente; o
/// Bloco 4 é exclusivo do terapeuta.)
class InitialAssessmentPatientPage extends ConsumerStatefulWidget {
  const InitialAssessmentPatientPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  ConsumerState<InitialAssessmentPatientPage> createState() =>
      _InitialAssessmentPatientPageState();
}

class _InitialAssessmentPatientPageState
    extends ConsumerState<InitialAssessmentPatientPage> {
  // Bloco 1
  final _preferredName = TextEditingController();
  final _occupation = TextEditingController();
  final _livesWith = TextEditingController();
  final _medicationNotes = TextEditingController();
  final _psychiatristNotes = TextEditingController();
  final _importantToKnow = TextEditingController();
  DateTime? _birthDate;
  bool _hasChildren = false;
  bool _usesMedication = false;
  bool _psychiatricFollowup = false;
  String? _fullName;

  // Bloco 2
  final _reason = TextEditingController();
  final _duration = TextEditingController();
  final _discomfort = TextEditingController();
  final _expectations = TextEditingController();
  final _relatedEvent = TextEditingController();

  // Bloco 3 — estado das 12 áreas
  final Map<LifeArea, int?> _scores = {};
  final Map<LifeArea, int?> _sufferings = {};
  final Map<LifeArea, TextEditingController> _guided = {};

  bool _initialized = false;

  InitialAssessmentContext get _ctx => InitialAssessmentContext(
        role: widget.role,
        patientId: widget.patientId,
      );

  @override
  void dispose() {
    for (final c in [
      _preferredName,
      _occupation,
      _livesWith,
      _medicationNotes,
      _psychiatristNotes,
      _importantToKnow,
      _reason,
      _duration,
      _discomfort,
      _expectations,
      _relatedEvent,
      ..._guided.values,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _initFromData(InitialAssessment data) {
    if (_initialized) return;

    final basics = data.basics;
    _fullName = basics?.fullName;
    _preferredName.text = basics?.preferredName ?? '';
    _occupation.text = basics?.occupation ?? '';
    _livesWith.text = basics?.livesWith ?? '';
    _medicationNotes.text = basics?.medicationNotes ?? '';
    _psychiatristNotes.text = basics?.psychiatristNotes ?? '';
    _importantToKnow.text = basics?.importantToKnow ?? '';
    _birthDate = basics?.birthDate;
    _hasChildren = basics?.hasChildren ?? false;
    _usesMedication = basics?.usesMedication ?? false;
    _psychiatricFollowup = basics?.psychiatricFollowup ?? false;

    final intake = data.intake;
    _reason.text = intake?.reasonForSeeking ?? '';
    _duration.text = intake?.problemDuration ?? '';
    _discomfort.text = intake?.mainDiscomfort ?? '';
    _expectations.text = intake?.expectations ?? '';
    _relatedEvent.text = intake?.relatedEvent ?? '';

    for (final area in kLifeAreasInOrder) {
      final a = data.lifeAreaFor(area);
      _scores[area] = a.score;
      _sufferings[area] = a.suffering;
      _guided[area] = TextEditingController(text: a.guidedAnswer ?? '');
    }
    _initialized = true;
  }

  List<LifeAreaAssessment> _collectAreas() {
    final result = <LifeAreaAssessment>[];
    for (final area in kLifeAreasInOrder) {
      final score = _scores[area];
      final suffering = _sufferings[area];
      final guided = _guided[area]?.text.trim();
      final hasAny =
          score != null || suffering != null || (guided ?? '').isNotEmpty;
      if (!hasAny) continue;
      result.add(LifeAreaAssessment(
        area: area,
        score: score,
        suffering: suffering,
        guidedAnswer: (guided ?? '').isEmpty ? null : guided,
      ));
    }
    return result;
  }

  String? _nullIfEmpty(String value) {
    final t = value.trim();
    return t.isEmpty ? null : t;
  }

  Future<void> _pickBirthDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 30, now.month, now.day),
      firstDate: DateTime(now.year - 120),
      lastDate: now,
      helpText: 'Data de nascimento',
    );
    if (picked != null) setState(() => _birthDate = picked);
  }

  Future<void> _save() async {
    final notifier = ref.read(initialAssessmentMutationProvider(_ctx).notifier);
    try {
      await notifier.savePatientBasics(
        preferredName: _nullIfEmpty(_preferredName.text),
        birthDate: _birthDate,
        occupation: _nullIfEmpty(_occupation.text),
        livesWith: _nullIfEmpty(_livesWith.text),
        hasChildren: _hasChildren,
        usesMedication: _usesMedication,
        medicationNotes:
            _usesMedication ? _nullIfEmpty(_medicationNotes.text) : null,
        psychiatricFollowup: _psychiatricFollowup,
        psychiatristNotes:
            _psychiatricFollowup ? _nullIfEmpty(_psychiatristNotes.text) : null,
        importantToKnow: _nullIfEmpty(_importantToKnow.text),
      );
      await notifier.saveIntake(
        reasonForSeeking: _reason.text.trim(),
        problemDuration: _duration.text.trim(),
        mainDiscomfort: _discomfort.text.trim(),
        expectations: _expectations.text.trim(),
        relatedEvent: _relatedEvent.text.trim(),
      );
      await notifier.saveLifeAreas(_collectAreas());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avaliação salva.')),
      );
    } catch (e) {
      if (!mounted) return;
      showErrorBanner(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(initialAssessmentProvider(_ctx));
    final saving = ref.watch(initialAssessmentMutationProvider(_ctx)).isLoading;

    return AppScaffold(
      title: 'Como você está hoje?',
      accent: AppColors.turquoise,
      body: AsyncStateBody<InitialAssessment>(
        asyncValue: async,
        onRetry: () => ref.invalidate(initialAssessmentProvider(_ctx)),
        dataBuilder: (data) {
          _initFromData(data);
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _blocoHeader(
                    context,
                    'Conhecendo você',
                    'Antes de começarmos, queremos conhecer um pouco sobre você.',
                  ),
                  if ((_fullName ?? '').isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Nome',
                          helperText: 'Para alterar, fale com seu psicólogo.',
                        ),
                        child: Text(_fullName!),
                      ),
                    ),
                  _field(_preferredName, 'Como prefere ser chamado(a)?'),
                  _birthDateField(context),
                  _field(_occupation, 'Profissão'),
                  _field(_livesWith, 'Com quem você mora?'),
                  _switchTile(
                    'Tem filhos?',
                    _hasChildren,
                    (v) => setState(() => _hasChildren = v),
                  ),
                  _switchTile(
                    'Faz uso de medicação?',
                    _usesMedication,
                    (v) => setState(() => _usesMedication = v),
                  ),
                  if (_usesMedication)
                    _field(_medicationNotes, 'Qual medicação? (opcional)'),
                  _switchTile(
                    'Tem acompanhamento psiquiátrico?',
                    _psychiatricFollowup,
                    (v) => setState(() => _psychiatricFollowup = v),
                  ),
                  if (_psychiatricFollowup)
                    _field(_psychiatristNotes,
                        'Detalhes do acompanhamento (opcional)'),
                  _field(
                    _importantToKnow,
                    'Existe algo importante sobre você que gostaria que seu '
                    'terapeuta soubesse?',
                  ),
                  const SizedBox(height: 24),
                  _blocoHeader(
                    context,
                    'O que está acontecendo?',
                    'Conte um pouco sobre o que está acontecendo na sua vida e o '
                        'que fez você procurar terapia neste momento.',
                  ),
                  _field(_reason, 'O que fez você procurar terapia agora?'),
                  _field(_duration, 'Há quanto tempo isso acontece?'),
                  _field(_discomfort, 'O que mais incomoda hoje?'),
                  _field(_expectations,
                      'O que espera que seja diferente após a terapia?'),
                  _field(_relatedEvent,
                      'Existe algum acontecimento importante relacionado a isso?'),
                  const SizedBox(height: 24),
                  _blocoHeader(
                    context,
                    'Como está sua vida hoje?',
                    'As pessoas costumam viver momentos diferentes em cada área '
                        'da vida. Avalie como você percebe cada uma delas neste momento.',
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardColor,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.navy.withValues(alpha: 0.07),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: LifeAreaWheelChart(scores: _scores),
                      ),
                    ),
                  ),
                  for (final area in kLifeAreasInOrder)
                    LifeAreaCard(
                      area: area,
                      score: _scores[area],
                      suffering: _sufferings[area],
                      guidedController: _guided[area]!,
                      onScoreChanged: (v) => setState(() => _scores[area] = v),
                      onSufferingChanged: (v) =>
                          setState(() => _sufferings[area] = v),
                    ),
                  const SizedBox(height: 12),
                  ClayCard(
                    child: ListTile(
                      leading: const Icon(Icons.history_edu_outlined),
                      title: const Text('Minha História'),
                      subtitle: const Text(
                          'Conte os momentos marcantes da sua vida.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push(InitialAssessmentRoutes.patientHistory),
                    ),
                  ),
                  ClayCard(
                    child: ListTile(
                      leading: const Icon(Icons.family_restroom_outlined),
                      title: const Text('Minha Família'),
                      subtitle: const Text(
                          'As pessoas da sua história e como eram essas relações.'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () =>
                          context.push(InitialAssessmentRoutes.patientFamily),
                    ),
                  ),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: FilledButton.icon(
                  onPressed: saving ? null : _save,
                  icon: saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(saving ? 'Salvando...' : 'Salvar avaliação'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _blocoHeader(BuildContext context, String title, String subtitle) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(subtitle,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: AppColors.textSecondary, height: 1.4)),
        ],
      ),
    );
  }

  Widget _field(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        minLines: 1,
        maxLines: 4,
        textInputAction: TextInputAction.newline,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _birthDateField(BuildContext context) {
    final loc = MaterialLocalizations.of(context);
    final date = _birthDate;
    final age = date == null ? null : PatientBasics(birthDate: date).age;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: _pickBirthDate,
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'Data de nascimento',
            suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18),
            helperText: age == null ? null : '$age anos',
          ),
          child: Text(
            date == null ? 'Toque para selecionar' : loc.formatFullDate(date),
            style: date == null
                ? TextStyle(color: Theme.of(context).hintColor)
                : null,
          ),
        ),
      ),
    );
  }

  Widget _switchTile(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        title: Text(label),
        contentPadding: EdgeInsets.zero,
        dense: true,
      ),
    );
  }
}
