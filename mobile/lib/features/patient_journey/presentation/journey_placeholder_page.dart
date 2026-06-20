import 'package:flutter/material.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../domain/journey_step.dart' show JourneyStep, buildPatientJourneySteps;
import '../domain/journey_step_id.dart';

class JourneyPlaceholderPage extends StatelessWidget {
  const JourneyPlaceholderPage({
    super.key,
    required this.title,
    this.subtitle,
  });

  factory JourneyPlaceholderPage.forStep(JourneyStepId step) {
    final steps = buildPatientJourneySteps(null);
    JourneyStep? match;
    for (final s in steps) {
      if (s.id == step) {
        match = s;
        break;
      }
    }
    return JourneyPlaceholderPage(
      title: match?.title ?? 'Módulo',
      subtitle: match?.subtitle,
    );
  }

  final String title;
  final String? subtitle;

  static const _message = 'Funcionalidade prevista para próxima versão.';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AppScaffold(
      title: title,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.construction_outlined,
                size: 64,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 24),
              Text(
                _message,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleMedium,
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 16),
                Text(
                  subtitle!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => Navigator.of(context).maybePop(),
                child: const Text('Voltar à trilha'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
