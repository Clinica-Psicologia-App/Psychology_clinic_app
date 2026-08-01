import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env_config.dart';
import '../../../core/theme/app_animations.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/homologation_ui.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/parental_contexts.dart';
import '../domain/questionnaire.dart';
import '../domain/questionnaire_response_context.dart';
import '../domain/reference_period.dart';
import '../providers/questionnaires_providers.dart';
import 'questionnaire_routes.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

const _roleEntries = [
  ('mae', 'Mãe'),
  ('pai', 'Pai'),
  ('tia', 'Tia'),
  ('avo', 'Avó'),
  ('avoo', 'Avô'),
  ('outro', 'Outro'),
];

class QuestionnaireIntroPage extends ConsumerStatefulWidget {
  const QuestionnaireIntroPage({
    super.key,
    required this.questionnaire,
    required this.patientId,
    required this.role,
    this.staffPatientId,
  });

  final Questionnaire questionnaire;
  final String patientId;
  final ProfileRole role;
  final String? staffPatientId;

  @override
  ConsumerState<QuestionnaireIntroPage> createState() =>
      _QuestionnaireIntroPageState();
}

class _QuestionnaireIntroPageState
    extends ConsumerState<QuestionnaireIntroPage> {
  bool _starting = false;

  final _caregiverEnabled = [true, false, false];
  final _caregiverRole = <String?>[null, null, null];
  final _caregiverOtherController1 = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];
  final _caregiverOtherController2 = [
    TextEditingController(),
    TextEditingController(),
    TextEditingController(),
  ];

  @override
  void dispose() {
    for (final c in _caregiverOtherController1) {
      c.dispose();
    }
    for (final c in _caregiverOtherController2) {
      c.dispose();
    }
    super.dispose();
  }

  List<CaregiverInput> _buildCaregiverInputs() {
    return List.generate(
      3,
      (i) => CaregiverInput(
        enabled: _caregiverEnabled[i],
        role: _caregiverRole[i],
        otherText1: _caregiverOtherController1[i].text,
        otherText2: _caregiverOtherController2[i].text,
      ),
    );
  }

  Widget _buildCaregiverCard(int index) {
    final theme = Theme.of(context);
    final enabled = _caregiverEnabled[index];
    final selectedRole = _caregiverRole[index];

    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Cuidador(a) ${index + 1}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Switch(
                  value: enabled,
                  onChanged: (value) => setState(() {
                    _caregiverEnabled[index] = value;
                  }),
                ),
              ],
            ),
            AnimatedSize(
              duration: AppAnimations.resolve(context, AppAnimations.section),
              curve: AppAnimations.standardCurve,
              alignment: Alignment.topCenter,
              child: !enabled
                  ? const SizedBox(width: double.infinity)
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Divider(height: 20),
                        RadioGroup<String>(
                          groupValue: selectedRole,
                          onChanged: (value) => setState(() {
                            _caregiverRole[index] = value;
                          }),
                          child: Column(
                            children: _roleEntries.map((entry) {
                              final (key, label) = entry;
                              return RadioListTile<String>(
                                value: key,
                                title: Text(label),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              );
                            }).toList(),
                          ),
                        ),
                        if (selectedRole == 'outro') ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _caregiverOtherController1[index],
                            decoration: const InputDecoration(
                              labelText: 'Nome',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _caregiverOtherController2[index],
                            decoration: const InputDecoration(
                              labelText: 'Relação com o paciente',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orientation =
        widget.questionnaire.referencePeriod.patientOrientationMessage;
    final canStart = widget.questionnaire.canStart(
      allowUnvalidated: EnvConfig.allowsUnvalidatedInstruments,
    );

    return AppScaffold(
      title: 'Antes de começar',
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                24,
                24,
                24,
                24 + MediaQuery.of(context).viewPadding.bottom,
              ),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 48),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    MotionReveal(
                      child: Text(
                        widget.questionnaire.name,
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    if (widget.questionnaire.description != null &&
                        widget.questionnaire.description!
                            .trim()
                            .isNotEmpty) ...[
                      const SizedBox(height: 12),
                      MotionReveal(
                        delay: const Duration(milliseconds: 70),
                        child: Text(
                          widget.questionnaire.description!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                    if (!canStart) ...[
                      const SizedBox(height: 24),
                      const HomologationInfoBanner(
                        title: 'Instrumento em homologação',
                        message: 'Este questionário ainda está passando por '
                            'validação clínica e análise de licenciamento. '
                            'Ele será liberado automaticamente após a aprovação.',
                        icon: Icons.lock_clock_outlined,
                      ),
                    ],
                    if (canStart && orientation != null) ...[
                      const SizedBox(height: 24),
                      ClayCard(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.schedule_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  orientation,
                                  style: theme.textTheme.bodyLarge,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (canStart &&
                        widget.questionnaire.patientSpecificGuidance !=
                            null) ...[
                      const SizedBox(height: 16),
                      ClayCard(
                        color: theme.colorScheme.primaryContainer,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                color: theme.colorScheme.onPrimaryContainer,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  widget.questionnaire.patientSpecificGuidance!,
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (canStart && widget.questionnaire.isParentalStyles) ...[
                      const SizedBox(height: 16),
                      Text(
                        'Para quem você deseja responder?',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      MotionStaggered(
                        children: [
                          for (int i = 0; i < 3; i++)
                            Padding(
                              padding: EdgeInsets.only(bottom: i < 2 ? 8 : 0),
                              child: _buildCaregiverCard(i),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _starting || !canStart ? null : _onStart,
                      child: _starting
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(
                              canStart
                                  ? 'Iniciar questionário'
                                  : 'Indisponível para aplicação',
                            ),
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: _starting ? null : () => context.pop(),
                      child: const Text('Voltar'),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onStart() async {
    if (widget.questionnaire.isParentalStyles) {
      final inputs = _buildCaregiverInputs();
      final error = validateParentalContextSelection(caregivers: inputs);
      if (error != null) {
        showErrorBanner(context, Exception(error));
        return;
      }
    }

    setState(() => _starting = true);

    try {
      final contexts = widget.questionnaire.isParentalStyles
          ? buildParentalContextInputs(caregivers: _buildCaregiverInputs())
          : const <QuestionnaireContextInput>[];
      final session = await ref
          .read(
            startQuestionnaireProvider(
              StartQuestionnaireArgs(
                patientId: widget.patientId,
                questionnaireId: widget.questionnaire.id,
                contexts: contexts,
              ),
            ).notifier,
          )
          .start();

      if (!mounted) return;

      context.pushReplacement(
        QuestionnaireRoutes.answer(
          role: widget.role,
          patientId: widget.staffPatientId,
        ),
        extra: session,
      );
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _starting = false);
    }
  }
}
