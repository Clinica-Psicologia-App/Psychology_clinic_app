import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_animations.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/finish_questionnaire_result.dart';
import 'questionnaire_routes.dart';

class QuestionnaireSuccessPage extends StatefulWidget {
  const QuestionnaireSuccessPage({
    super.key,
    required this.result,
    required this.role,
    this.patientId,
  });

  final FinishQuestionnaireResult result;
  final ProfileRole role;
  final String? patientId;

  @override
  State<QuestionnaireSuccessPage> createState() =>
      _QuestionnaireSuccessPageState();
}

class _QuestionnaireSuccessPageState extends State<QuestionnaireSuccessPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _badgeScale;
  late final Animation<double> _ring;
  late final Animation<double> _check;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _badgeScale = Tween<double>(begin: 0.4, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.elasticOut),
      ),
    );
    _ring = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
    );
    _check = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.25, 0.75, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final completed = widget.result.completedAt;
    final dateLabel = completed != null
        ? MaterialLocalizations.of(context).formatFullDate(completed)
        : null;
    final animate = AppAnimations.shouldAnimate(context);

    return AppScaffold(
      title: 'Concluído',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 16),
            _SuccessBadge(
              badgeScale:
                  animate ? _badgeScale : const AlwaysStoppedAnimation(1),
              ring: animate ? _ring : const AlwaysStoppedAnimation(1),
              check: animate ? _check : const AlwaysStoppedAnimation(1),
            ),
            const SizedBox(height: 28),
            MotionReveal(
              delay: const Duration(milliseconds: 240),
              child: Column(
                children: [
                  Text(
                    'Questionário enviado',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    widget.result.questionnaireName,
                    style: theme.textTheme.titleMedium,
                    textAlign: TextAlign.center,
                  ),
                  if (dateLabel != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Concluído em $dateLabel',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            MotionReveal(
              delay: const Duration(milliseconds: 340),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Suas respostas foram registradas. A interpretação '
                          'clínica será revisada pelo profissional responsável '
                          '— não há resultado automático nesta versão.',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Spacer(),
            MotionReveal(
              delay: const Duration(milliseconds: 420),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => context.go(
                        QuestionnaireRoutes.list(
                          role: widget.role,
                          patientId: widget.patientId,
                        ),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Text('Voltar aos questionários'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (widget.role == ProfileRole.patient)
                    TextButton(
                      onPressed: () => context.go('/patient'),
                      child: const Text('Ir para início'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessBadge extends StatelessWidget {
  const _SuccessBadge({
    required this.badgeScale,
    required this.ring,
    required this.check,
  });

  final Animation<double> badgeScale;
  final Animation<double> ring;
  final Animation<double> check;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return AnimatedBuilder(
      animation: Listenable.merge([badgeScale, ring, check]),
      builder: (context, _) {
        return SizedBox(
          width: 140,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140 * ring.value,
                height: 140 * ring.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.08 * ring.value),
                ),
              ),
              Container(
                width: 108 * ring.value,
                height: 108 * ring.value,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: primary.withValues(alpha: 0.14 * ring.value),
                ),
              ),
              Transform.scale(
                scale: badgeScale.value,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primary,
                    boxShadow: [
                      BoxShadow(
                        color: primary.withValues(alpha: 0.35),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.check_rounded,
                      size: 48 * check.value.clamp(0.0, 1.0),
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
