import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/gradient_progress_indicator.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/parental_contexts.dart';
import '../domain/questionnaire_response_context.dart';
import '../domain/questionnaire_session.dart';
import '../providers/questionnaires_providers.dart';
import 'questionnaire_routes.dart';
import 'widgets/question_input_widget.dart';

class QuestionnaireAnswerPage extends ConsumerStatefulWidget {
  const QuestionnaireAnswerPage({
    super.key,
    required this.session,
    required this.role,
    this.patientId,
  });

  final QuestionnaireSession session;
  final ProfileRole role;
  final String? patientId;

  @override
  ConsumerState<QuestionnaireAnswerPage> createState() =>
      _QuestionnaireAnswerPageState();
}

class _QuestionnaireAnswerPageState
    extends ConsumerState<QuestionnaireAnswerPage> {
  late final Map<String, int> _answers = {};
  int _currentIndex = 0;
  int _currentContextIndex = 0;
  String? _fieldError;
  bool _saving = false;
  bool _finishing = false;

  QuestionnaireSession get session => widget.session;
  bool get _hasPendingAnswers => _answers.isNotEmpty;
  bool get _isParentalFlow =>
      session.questionnaire.isParentalStyles && session.hasContexts;
  QuestionnaireResponseContext? get _currentContext =>
      _isParentalFlow ? session.contexts[_currentContextIndex] : null;
  String get _currentAnswerKey =>
      _answerKey(session.questions[_currentIndex].id, _currentContext?.id);

  @override
  Widget build(BuildContext context) {
    final questions = session.questions;
    if (questions.isEmpty) {
      return AppScaffold(
        title: session.questionnaire.name,
        body: const Center(
          child: Text('Este questionário não possui perguntas ativas.'),
        ),
      );
    }

    final question = questions[_currentIndex];
    final progress = (_currentIndex + 1) / questions.length;
    final isLastQuestion = _currentIndex == questions.length - 1;
    final isLastContext =
        !_isParentalFlow || _currentContextIndex == session.contexts.length - 1;
    final isLast = isLastQuestion && isLastContext;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final leave = await _confirmLeave();
        if (leave && context.mounted) {
          context.pop();
        }
      },
      child: AppScaffold(
        title: session.questionnaire.name,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.md,
                AppSpacing.sm,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_isParentalFlow) ...[
                    _ParentalContextProgress(
                      contexts: session.contexts,
                      answers: _answers,
                      totalQuestions: questions.length,
                      currentContextId: _currentContext?.id,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                  ],
                  Row(
                    children: [
                      Expanded(
                        child: GradientProgressIndicator(
                          value: progress,
                          label:
                              'Pergunta ${_currentIndex + 1} de ${questions.length}',
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '${_currentIndex + 1}/${questions.length}',
                        style: Theme.of(context).textTheme.labelLarge,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _isParentalFlow
                        ? 'Respondendo sobre: ${_currentContext?.label ?? 'Figura parental'}'
                        : 'Pergunta ${question.code}',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  switchInCurve: Curves.easeOutCubic,
                  switchOutCurve: Curves.easeInCubic,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.03, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Column(
                    key: ValueKey('${_currentIndex}_${_currentContext?.id}'),
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppInfoCard(
                        title: _isParentalFlow
                            ? 'Pergunta sobre ${_currentContext?.label ?? 'figura parental'}'
                            : 'Pergunta ${question.code}',
                        body: _isParentalFlow
                            ? normalizeParentalQuestionText(question.text)
                            : question.text,
                        icon: Icons.help_outline,
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      QuestionInputWidget(
                        question: question,
                        value: _answers[_currentAnswerKey],
                        errorText: _fieldError,
                        onChanged: (v) {
                          setState(() {
                            _answers[_currentAnswerKey] = v;
                            _fieldError = null;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: Row(
                children: [
                  if (_currentIndex > 0)
                    OutlinedButton(
                      onPressed: _saving || _finishing
                          ? null
                          : () => setState(() {
                                _currentIndex--;
                                _fieldError = null;
                              }),
                      child: const Text('Anterior'),
                    ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _saving || _finishing
                        ? null
                        : () => isLast ? _finish() : _saveAndNext(),
                    child: _saving || _finishing
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            isLast
                                ? 'Finalizar'
                                : isLastQuestion && _isParentalFlow
                                    ? 'Próxima figura'
                                    : 'Próxima',
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmLeave() async {
    if (!_hasPendingAnswers) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sair do questionário?'),
        content: const Text(
          'Você já respondeu algumas perguntas. As respostas salvas '
          'permanecem no rascunho, mas o progresso nesta tela será perdido.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Continuar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sair'),
          ),
        ],
      ),
    );

    return result ?? false;
  }

  Future<void> _saveAndNext() async {
    final question = session.questions[_currentIndex];
    final value = _answers[_currentAnswerKey];
    final validation = question.validateAnswer(value);
    if (validation != null) {
      setState(() => _fieldError = validation);
      return;
    }

    setState(() {
      _saving = true;
      _fieldError = null;
    });

    try {
      await ref.read(questionnairesRepositoryProvider).submitAnswer(
            responseId: session.responseId,
            questionId: question.id,
            answerValue: value!,
            responseContextId: _currentContext?.id,
          );

      if (!mounted) return;
      setState(() {
        if (_currentIndex == session.questions.length - 1 && _isParentalFlow) {
          _currentContextIndex++;
          _currentIndex = 0;
        } else {
          _currentIndex++;
        }
        _fieldError = null;
      });
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _finish() async {
    final question = session.questions[_currentIndex];
    final value = _answers[_currentAnswerKey];
    final validation = question.validateAnswer(value);
    if (validation != null) {
      setState(() => _fieldError = validation);
      return;
    }

    if (_isParentalFlow) {
      for (final context in session.contexts) {
        for (final q in session.questions) {
          if (!_answers.containsKey(_answerKey(q.id, context.id))) {
            setState(() {
              _fieldError =
                  'Responda todas as figuras parentais antes de finalizar.';
            });
            return;
          }
        }
      }
    } else {
      for (final q in session.questions) {
        if (!_answers.containsKey(_answerKey(q.id, null))) {
          setState(() {
            _fieldError = 'Responda todas as perguntas antes de finalizar.';
          });
          return;
        }
      }
    }

    setState(() => _finishing = true);

    try {
      await ref.read(questionnairesRepositoryProvider).submitAnswer(
            responseId: session.responseId,
            questionId: question.id,
            answerValue: value!,
            responseContextId: _currentContext?.id,
          );

      final result = await ref
          .read(
            finishQuestionnaireProvider(
              FinishQuestionnaireArgs(
                responseId: session.responseId,
                questionnaireName: session.questionnaire.name,
              ),
            ).notifier,
          )
          .submit();

      if (!mounted) return;

      context.go(
        QuestionnaireRoutes.success(
          role: widget.role,
          patientId: widget.patientId,
        ),
        extra: result,
      );
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  String _answerKey(String questionId, String? contextId) {
    return contextId == null ? questionId : '$contextId::$questionId';
  }
}

class _ParentalContextProgress extends StatelessWidget {
  const _ParentalContextProgress({
    required this.contexts,
    required this.answers,
    required this.totalQuestions,
    required this.currentContextId,
  });

  final List<QuestionnaireResponseContext> contexts;
  final Map<String, int> answers;
  final int totalQuestions;
  final String? currentContextId;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: contexts.map((item) {
        final progress = progressForContext(
          contextId: item.id,
          answers: answers,
          totalQuestions: totalQuestions,
        );
        final isCurrent = item.id == currentContextId;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      item.label,
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                            fontWeight:
                                isCurrent ? FontWeight.w700 : FontWeight.w500,
                          ),
                    ),
                  ),
                  Text('${(progress * 100).round()}%'),
                ],
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(value: progress),
            ],
          ),
        );
      }).toList(),
    );
  }
}
