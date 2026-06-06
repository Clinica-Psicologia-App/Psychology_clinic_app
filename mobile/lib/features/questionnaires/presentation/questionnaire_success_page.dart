import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_scaffold.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/finish_questionnaire_result.dart';
import 'questionnaire_routes.dart';

class QuestionnaireSuccessPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final completed = result.completedAt;
    final dateLabel = completed != null
        ? MaterialLocalizations.of(context).formatFullDate(completed)
        : null;

    return AppScaffold(
      title: 'Concluído',
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.check_circle_outline,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Questionário enviado',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              result.questionnaireName,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            if (dateLabel != null) ...[
              const SizedBox(height: 8),
              Text(
                'Concluído em $dateLabel',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Suas respostas foram registradas. A interpretação clínica '
                  'será revisada pelo profissional responsável — não há '
                  'resultado automático nesta versão.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            const Spacer(),
            FilledButton(
              onPressed: () => context.go(
                QuestionnaireRoutes.list(
                  role: role,
                  patientId: patientId,
                ),
              ),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                child: Text('Voltar aos questionários'),
              ),
            ),
            const SizedBox(height: 12),
            if (role == ProfileRole.patient)
              TextButton(
                onPressed: () => context.go('/patient'),
                child: const Text('Ir para início'),
              ),
          ],
        ),
      ),
    );
  }
}
