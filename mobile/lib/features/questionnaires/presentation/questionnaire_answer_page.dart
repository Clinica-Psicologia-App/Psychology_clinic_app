import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
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
    this.previewMode = false,
  });

  final QuestionnaireSession session;
  final ProfileRole role;
  final String? patientId;

  /// Pré-visualização do catálogo (platform admin): o fluxo é percorrido
  /// normalmente, mas nada é enviado ao backend.
  final bool previewMode;

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
  bool _justSaved = false;
  Timer? _savedFeedbackTimer;

  @override
  void dispose() {
    _savedFeedbackTimer?.cancel();
    super.dispose();
  }

  void _showSavedFeedback() {
    _savedFeedbackTimer?.cancel();
    setState(() => _justSaved = true);
    _savedFeedbackTimer = Timer(const Duration(seconds: 2), () {
      if (mounted) setState(() => _justSaved = false);
    });
  }

  /// Frase gentil que acompanha o progresso (acolhe o respondente).
  String _encouragement(double progress) {
    if (progress >= 0.99) return 'Última pergunta — quase lá!';
    if (progress >= 0.75) return 'Reta final, continue assim.';
    if (progress >= 0.4) return 'Você está indo muito bem.';
    return 'Sem pressa — uma de cada vez.';
  }

  /// Direção da transição entre perguntas: 1 = avançando (entra da direita),
  /// -1 = voltando (entra da esquerda).
  int _direction = 1;

  QuestionnaireSession get session => widget.session;
  bool get _isPreview => widget.previewMode;
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
        accent: AppColors.blue,
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
        accent: AppColors.blue,
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
                  if (_isPreview) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.visibility_outlined, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pré-visualização: as respostas não serão salvas.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
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
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(Icons.spa_outlined,
                          size: 13, color: AppColors.textMuted),
                      const SizedBox(width: 5),
                      Text(
                        _encouragement(progress),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  const Positioned.fill(child: _QuestionnaireBackdrop()),
                  LayoutBuilder(
                    builder: (context, constraints) => SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  // Centraliza verticalmente quando o conteúdo é curto (uma
                  // pergunta por vez), mas continua rolável em textos longos.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: math.max(
                        0,
                        constraints.maxHeight - AppSpacing.md * 2,
                      ),
                    ),
                    child: Center(
                  child: ConstrainedBox(
                    // Focus mode: uma pergunta por vez, largura de leitura
                    // confortável em vez de esticar em telas largas.
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.formMaxWidth,
                    ),
                    child: AnimatedSwitcher(
                      duration: AppAnimations.block,
                      switchInCurve: AppAnimations.enterCurve,
                      switchOutCurve: AppAnimations.exitCurve,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: Offset(0.05 * _direction, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Column(
                        key: ValueKey(
                          '${_currentIndex}_${_currentContext?.id}',
                        ),
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
                    ),
                  ),
                ),
                  ],
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
                                _direction = -1;
                                _currentIndex--;
                                _fieldError = null;
                              }),
                      child: const Text('Anterior'),
                    ),
                  Expanded(
                    child: Center(
                      child: AnimatedOpacity(
                        opacity: _justSaved ? 1 : 0,
                        duration: AppAnimations.resolve(
                          context,
                          AppAnimations.fast,
                        ),
                        child: Semantics(
                          liveRegion: true,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.check_circle_outline,
                                size: 16,
                                color: AppColors.success,
                              ),
                              const SizedBox(width: AppSpacing.xxs),
                              Text(
                                'Resposta salva',
                                style: Theme.of(context)
                                    .textTheme
                                    .labelMedium
                                    ?.copyWith(color: AppColors.success),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
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
      if (!_isPreview) {
        await ref.read(questionnairesRepositoryProvider).submitAnswer(
              responseId: session.responseId,
              questionId: question.id,
              answerValue: value!,
              responseContextId: _currentContext?.id,
            );
      }

      if (!mounted) return;
      setState(() {
        _direction = 1;
        if (_currentIndex == session.questions.length - 1 && _isParentalFlow) {
          _currentContextIndex++;
          _currentIndex = 0;
        } else {
          _currentIndex++;
        }
        _fieldError = null;
      });
      _showSavedFeedback();
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
      if (_isPreview) {
        if (!mounted) return;
        await _showPreviewFinishedDialog();
        return;
      }

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

  /// Encerramento da pré-visualização. Não navega para a tela de sucesso: o
  /// preview roda fora do fluxo clínico e não gerou resultado algum.
  Future<void> _showPreviewFinishedDialog() async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pré-visualização concluída'),
        content: const Text(
          'Nenhuma resposta foi salva — este questionário foi apenas '
          'visualizado para conferência do conteúdo.',
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
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

/// Fundo suave (formas orgânicas discretas da paleta) por trás do conteúdo —
/// deixa a tela mais acolhedora sem competir com a pergunta.
class _QuestionnaireBackdrop extends StatelessWidget {
  const _QuestionnaireBackdrop();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRect(
        child: Stack(
          children: [
            Positioned(
              top: -50,
              right: -40,
              child: _blob(150, AppColors.turquoise.withValues(alpha: 0.08)),
            ),
            Positioned(
              bottom: -30,
              left: -36,
              child: _blob(120, AppColors.cyan.withValues(alpha: 0.07)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _blob(double size, Color color) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}
