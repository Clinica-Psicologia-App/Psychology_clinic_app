import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/parental_contexts.dart';
import '../domain/questionnaire.dart';
import '../domain/questionnaire_response_context.dart';
import '../domain/reference_period.dart';
import '../providers/questionnaires_providers.dart';
import 'questionnaire_routes.dart';

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
  bool _includeMother = true;
  bool _includeFather = true;
  bool _includeOther = false;
  final _otherController = TextEditingController();

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final orientation =
        widget.questionnaire.referencePeriod.patientOrientationMessage;

    return AppScaffold(
      title: 'Antes de começar',
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                widget.questionnaire.name,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (widget.questionnaire.description != null &&
                  widget.questionnaire.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  widget.questionnaire.description!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              if (orientation != null) ...[
                const SizedBox(height: 24),
                Card(
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
              if (widget.questionnaire.patientSpecificGuidance != null) ...[
                const SizedBox(height: 16),
                Card(
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
              if (widget.questionnaire.isParentalStyles) ...[
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Para quem voce deseja responder?',
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        CheckboxListTile(
                          value: _includeMother,
                          onChanged: (value) => setState(
                            () => _includeMother = value ?? false,
                          ),
                          title: const Text('Mae'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          value: _includeFather,
                          onChanged: (value) => setState(
                            () => _includeFather = value ?? false,
                          ),
                          title: const Text('Pai'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        CheckboxListTile(
                          value: _includeOther,
                          onChanged: (value) => setState(
                            () => _includeOther = value ?? false,
                          ),
                          title: const Text('Outro'),
                          contentPadding: EdgeInsets.zero,
                          controlAffinity: ListTileControlAffinity.leading,
                        ),
                        if (_includeOther) ...[
                          const SizedBox(height: 8),
                          TextField(
                            controller: _otherController,
                            decoration: const InputDecoration(
                              labelText: 'Qual figura parental?',
                              border: OutlineInputBorder(),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
              const Spacer(),
              FilledButton(
                onPressed: _starting ? null : _onStart,
                child: _starting
                    ? const SizedBox(
                        height: 22,
                        width: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Iniciar questionário'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _starting ? null : () => context.pop(),
                child: const Text('Voltar'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onStart() async {
    if (widget.questionnaire.isParentalStyles) {
      final error = validateParentalContextSelection(
        includeMother: _includeMother,
        includeFather: _includeFather,
        includeOther: _includeOther,
        otherLabel: _otherController.text,
      );
      if (error != null) {
        showErrorBanner(
          context,
          Exception(error),
        );
        return;
      }
    }

    setState(() => _starting = true);

    try {
      final contexts = widget.questionnaire.isParentalStyles
          ? buildParentalContextInputs(
              includeMother: _includeMother,
              includeFather: _includeFather,
              includeOther: _includeOther,
              otherLabel: _otherController.text,
            )
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
