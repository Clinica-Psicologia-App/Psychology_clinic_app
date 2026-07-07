import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
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

    final isPatient = widget.role == ProfileRole.patient;

    return AppScaffold(
      title: 'Concluído',
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          children: [
            AppPageHeader(
              title: isPatient
                  ? 'Pronto! Respostas enviadas'
                  : 'Questionário enviado',
              subtitle: isPatient
                  ? 'Obrigado por dedicar esse tempo. Suas respostas ajudam seu psicólogo a acompanhar você de perto.'
                  : 'As respostas foram registradas e ficarão disponíveis para revisão clínica do profissional responsável.',
              icon: Icons.check_circle_outline,
              metadata: [
                if (dateLabel != null) Chip(label: Text(dateLabel)),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
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
                    widget.result.questionnaireName,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            MotionReveal(
              delay: const Duration(milliseconds: 340),
              child: AppInfoCard(
                title: 'Revisão clínica',
                body: isPatient
                    ? 'Seu psicólogo vai revisar as respostas com calma. Não existe resposta certa ou errada — o que importa é o seu momento.'
                    : 'A interpretação clínica será revisada pelo profissional responsável. Não há resultado automático nesta versão.',
                icon: Icons.shield_outlined,
                tone: AppInfoCardTone.success,
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
