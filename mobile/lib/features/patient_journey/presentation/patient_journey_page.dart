import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../daily_monitors/providers/daily_monitors_providers.dart';
import '../../patients/presentation/widgets/patient_context_header.dart';
import '../../profile/domain/profile_role.dart';
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
    final patientIdAsync = ref.watch(myPatientIdProvider);

    return AppCanopyScaffold(
      body: patientIdAsync.when(
        loading: () => const Center(child: BrandLoader()),
        error: (_, __) => const Center(
          child: Text('Erro ao identificar paciente.'),
        ),
        data: (patientId) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PatientContextHeader(
              patientId: patientId,
              pageTitle: 'MEU PLANO',
              role: ProfileRole.patient,
              accentColor: AppColors.cyan,
            ),
            _JourneyProgressStrip(
              steps: stepsAsync.valueOrNull,
              onLegend: () => _showLegend(context),
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
                            navigateFromJourneyStep(context, ref, step),
                      ),
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
}

/// Card de progresso da trilha: anel de avanço, fase atual e etapa corrente.
/// Exibido abaixo do [PatientContextHeader] como faixa de conteúdo (sem gradiente).
class _JourneyProgressStrip extends StatelessWidget {
  const _JourneyProgressStrip({
    required this.steps,
    required this.onLegend,
  });

  final List<JourneyStep>? steps;
  final VoidCallback onLegend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final list = steps ?? const <JourneyStep>[];
    final total = list.length;
    final done = list
        .where((s) => s.availability == JourneyStepAvailability.completed)
        .length;
    final current = _currentStep(list);
    final fraction = total == 0 ? 0.0 : done / total;
    final isComplete = total > 0 && done == total;

    final eyebrow = isComplete
        ? 'TRILHA CONCLUÍDA 🎉'
        : current == null
            ? 'SUA TRILHA TERAPÊUTICA'
            : 'FASE ${current.phase.stepNumber} · '
                '${current.phase.label.toUpperCase()}';

    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(18)),
        boxShadow: [
          BoxShadow(
            color: AppColors.cyan.withValues(alpha: isDark ? 0.10 : 0.13),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.xs,
        AppSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _ProgressRing(
            fraction: fraction,
            done: done,
            total: total,
            accent: AppColors.cyan,
          ),
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
                    color: AppColors.cyan,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                _ContextLine(step: current, isComplete: isComplete),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            iconSize: 20,
            tooltip: 'Legenda',
            color: cs.onSurfaceVariant,
            onPressed: onLegend,
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
  const _ContextLine({required this.step, this.isComplete = false});

  final JourneyStep? step;
  final bool isComplete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final base = theme.textTheme.bodySmall?.copyWith(
      color: cs.onSurfaceVariant,
      height: 1.35,
    );
    if (isComplete) {
      return Text(
        'Você concluiu toda a sua trilha terapêutica!',
        style: base?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      );
    }
    if (step == null) {
      return Text('Siga os passos no seu ritmo.', style: base);
    }
    return Text.rich(
      TextSpan(
        text: 'Parado em ',
        style: base,
        children: [
          TextSpan(
            text: step!.title,
            style: base?.copyWith(
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface),
          ),
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
    this.accent,
  });

  final double fraction;
  final int done;
  final int total;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final ring = accent ?? cs.primary;
    final fg = cs.onSurface;
    return SizedBox(
      width: 52,
      height: 52,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            tween: Tween(begin: 0, end: fraction),
            builder: (context, value, _) => CircularProgressIndicator(
              value: value,
              strokeWidth: 4.5,
              backgroundColor: ring.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(ring),
              strokeCap: StrokeCap.round,
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$done',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              Container(
                width: 14,
                height: 1,
                margin: const EdgeInsets.symmetric(vertical: 1),
                color: fg.withValues(alpha: 0.3),
              ),
              Text(
                '$total',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: fg.withValues(alpha: 0.6),
                  fontWeight: FontWeight.w600,
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
