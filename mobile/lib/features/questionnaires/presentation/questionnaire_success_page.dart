import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/brand_constellation.dart';
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
      accent: AppColors.blue,
      body: SafeArea(
        child: Column(
          children: [
            // Conteúdo rolável: em telas baixas nada fica cortado e os
            // botões abaixo continuam sempre visíveis.
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    AppPageHeader(
                      title: isPatient
                          ? 'Respostas enviadas com sucesso!'
                          : 'Questionário enviado',
                      subtitle: isPatient
                          ? 'Obrigado por dedicar esse tempo a olhar para suas experiências. Suas respostas contribuirão para a compreensão do seu processo terapêutico.'
                          : 'As respostas foram registradas e ficarão disponíveis para revisão clínica do profissional responsável.',
                      icon: Icons.check_circle_outline,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    MotionReveal(
                      delay: const Duration(milliseconds: 340),
                      child: AppInfoCard(
                        title: isPatient
                            ? 'Para seu acompanhamento'
                            : 'Revisão clínica',
                        body: isPatient
                            ? widget.result.followUpText ??
                                'Suas respostas ficarão disponíveis para seu psicólogo e poderão contribuir para a compreensão do seu processo terapêutico.'
                            : 'A interpretação clínica será revisada pelo profissional responsável. Não há resultado automático nesta versão.',
                        icon: Icons.shield_outlined,
                        tone: AppInfoCardTone.success,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _SuccessBadge(
                      badgeScale: animate
                          ? _badgeScale
                          : const AlwaysStoppedAnimation(1),
                      ring: animate ? _ring : const AlwaysStoppedAnimation(1),
                      check:
                          animate ? _check : const AlwaysStoppedAnimation(1),
                    ),
                    const SizedBox(height: AppSpacing.md),
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
                          if (dateLabel != null) ...[
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              dateLabel,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                AppSpacing.xs,
                AppSpacing.md,
                AppSpacing.md,
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => isPatient
                          ? context.go('/patient')
                          : context.go(
                              QuestionnaireRoutes.list(
                                role: widget.role,
                                patientId: widget.patientId,
                              ),
                            ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          isPatient
                              ? 'Voltar ao meu espaço'
                              : 'Voltar aos questionários',
                        ),
                      ),
                    ),
                  ),
                  if (isPatient)
                    TextButton(
                      onPressed: () => context.go(
                        QuestionnaireRoutes.list(
                          role: widget.role,
                          patientId: widget.patientId,
                        ),
                      ),
                      child: const Text('Voltar aos questionários'),
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
              // Nodos se conectando junto com a expansão do anel — a
              // celebração ecoa a linguagem de mapa da marca.
              BrandConstellation(
                size: const Size(140, 140),
                color: primary,
                opacity: 0.30,
                progress: ring.value,
                preset: BrandConstellationPreset.orbit,
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
