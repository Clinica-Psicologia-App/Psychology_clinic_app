import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../auth/providers/auth_providers.dart';
import '../domain/journey_phase.dart';
import '../domain/journey_step.dart';
import '../domain/journey_step_availability.dart';
import '../providers/patient_journey_providers.dart';
import 'patient_journey_navigation.dart';
import 'widgets/journey_ambience.dart';
import 'widgets/journey_trail.dart';

class PatientJourneyPage extends ConsumerWidget {
  const PatientJourneyPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stepsAsync = ref.watch(patientJourneyStepsProvider);
    final profile = ref.watch(authControllerProvider).valueOrNull;
    final firstName = profile?.fullName.trim().split(RegExp(r'\s+')).first;

    return AppCanopyScaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _JourneyCanopyHeader(
            firstName: firstName,
            steps: stepsAsync.valueOrNull,
          ),
          Expanded(
            // A atmosfera fica fixa no viewport, atrás do scroll da trilha:
            // as auras respiram no lugar em vez de acompanhar o conteúdo.
            child: Stack(
              children: [
                const Positioned.fill(child: JourneyAmbience()),
                AsyncStateBody<List<JourneyStep>>(
                  asyncValue: stepsAsync,
                  onRetry: () {
                    ref.invalidate(patientJourneyProgressProvider);
                    ref.invalidate(patientJourneyStepsProvider);
                  },
                  emptyMessage: 'Nenhum passo configurado na trilha.',
                  emptyIcon: Icons.route_outlined,
                  dataBuilder: (steps) => RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(patientJourneyProgressProvider);
                      ref.invalidate(patientJourneyStepsProvider);
                      await ref.read(patientJourneyStepsProvider.future);
                    },
                    child: JourneyTrail(
                      steps: steps,
                      onStepTap: (step) =>
                          navigateFromJourneyStep(context, step),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Canopy de progresso da trilha: anel de avanço, saudação e a parada atual,
/// no mesmo gradiente das home. A legenda dos estados vira um toque ("Legenda")
/// que abre uma folha — em vez de pílulas fixas ocupando a tela.
class _JourneyCanopyHeader extends StatelessWidget {
  const _JourneyCanopyHeader({required this.firstName, required this.steps});

  final String? firstName;
  final List<JourneyStep>? steps;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    final list = steps ?? const <JourneyStep>[];
    final total = list.length;
    final done = list
        .where((s) => s.availability == JourneyStepAvailability.completed)
        .length;
    final current = _currentStep(list);
    final fraction = total == 0 ? 0.0 : done / total;

    final eyebrow = current == null
        ? 'SUA TRILHA TERAPÊUTICA'
        : 'SUA TRILHA · FASE ${current.phase.stepNumber} · '
            '${current.phase.label.toUpperCase()}';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.turquoise, AppColors.cyan, AppColors.blue],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: 0.3),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        topInset + AppSpacing.xs,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _CircleButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.of(context).maybePop(),
                tooltip: 'Voltar',
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Meu plano terapêutico',
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              _LegendButton(),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _ProgressRing(fraction: fraction, done: done, total: total),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      eyebrow,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      firstName == null ? 'Olá!' : 'Olá, $firstName',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    _ContextLine(step: current),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static JourneyStep? _currentStep(List<JourneyStep> steps) {
    for (final s in steps) {
      if (s.availability == JourneyStepAvailability.inProgress) return s;
    }
    for (final s in steps) {
      if (s.availability == JourneyStepAvailability.available) return s;
    }
    return null;
  }
}

class _ContextLine extends StatelessWidget {
  const _ContextLine({required this.step});

  final JourneyStep? step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final base = theme.textTheme.bodySmall?.copyWith(
      color: Colors.white.withValues(alpha: 0.9),
      height: 1.35,
    );
    if (step == null) {
      return Text('Siga os passos no seu ritmo.', style: base);
    }
    return Text.rich(
      TextSpan(
        text: 'Você parou em ',
        style: base,
        children: [
          TextSpan(
            text: step!.title,
            style: base?.copyWith(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: '.'),
        ],
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}

class _ProgressRing extends StatelessWidget {
  const _ProgressRing({
    required this.fraction,
    required this.done,
    required this.total,
  });

  final double fraction;
  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 62,
      height: 62,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 62,
            height: 62,
            child: TweenAnimationBuilder<double>(
              duration: const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              tween: Tween(begin: 0, end: fraction),
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 5,
                backgroundColor: Colors.white.withValues(alpha: 0.28),
                valueColor: const AlwaysStoppedAnimation(Colors.white),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$done',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Container(
                width: 16,
                height: 1.2,
                margin: const EdgeInsets.symmetric(vertical: 1),
                color: Colors.white.withValues(alpha: 0.5),
              ),
              Text(
                '$total',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w700,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withValues(alpha: 0.16),
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }
}

class _LegendButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: () => _showLegend(context),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.info_outline_rounded, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text(
                'Legenda',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

void _showLegend(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (context) {
      final theme = Theme.of(context);
      const items = <(JourneyStepAvailability, String)>[
        (
          JourneyStepAvailability.available,
          'Pronto para você começar quando quiser.'
        ),
        (JourneyStepAvailability.inProgress, 'Você já iniciou esta etapa.'),
        (JourneyStepAvailability.completed, 'Etapa concluída — bom trabalho.'),
        (
          JourneyStepAvailability.inDevelopment,
          'Em breve disponível na sua trilha.'
        ),
        (
          JourneyStepAvailability.blocked,
          'Aguardando liberação do seu psicólogo.'
        ),
      ];
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Legenda da trilha',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'O que cada estado das paradas significa.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              for (final (availability, description) in items)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StatusChip(
                        label: availability.label,
                        tone: _toneFor(availability),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

AppStatusTone _toneFor(JourneyStepAvailability availability) {
  return switch (availability) {
    JourneyStepAvailability.available => AppStatusTone.available,
    JourneyStepAvailability.inProgress => AppStatusTone.inProgress,
    JourneyStepAvailability.completed => AppStatusTone.completed,
    JourneyStepAvailability.inDevelopment => AppStatusTone.development,
    JourneyStepAvailability.blocked => AppStatusTone.blocked,
  };
}
