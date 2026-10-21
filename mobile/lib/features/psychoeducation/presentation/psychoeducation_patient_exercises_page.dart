import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/clay_card.dart';
import '../domain/exercise_definition.dart';
import '../domain/exercise_definitions_data.dart';
import '../domain/psychoeducation_module.dart';
import '../providers/psychoeducation_providers.dart';

/// Read-only view mounted exclusively under the psychologist patient routes.
class PsychoeducationPatientExercisesPage extends ConsumerWidget {
  const PsychoeducationPatientExercisesPage(
      {super.key, required this.patientId});

  final String patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final responses = ref.watch(patientExerciseResponsesProvider(patientId));
    final modules = ref.watch(psychoeducationJourneyProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Exercícios respondidos')),
      body: AsyncStateBody<(List<PsychoeducationModule>,)>(
        asyncValue: modules.whenData((value) => (value,)),
        onRetry: () => ref.invalidate(psychoeducationJourneyProvider),
        dataBuilder: (data) => AsyncStateBody<List<ExerciseResponse>>(
          asyncValue: responses,
          onRetry: () =>
              ref.invalidate(patientExerciseResponsesProvider(patientId)),
          emptyMessage: 'Este paciente ainda não respondeu exercícios.',
          dataBuilder: (items) => ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, index) {
              final response = items[index];
              final matches = data.$1.where((m) => m.id == response.moduleId);
              final module = matches.isEmpty ? null : matches.first;
              final definition = kExerciseDefinitions[module?.number];
              final prompts = {
                for (final step in definition?.steps ?? <ExerciseStep>[])
                  for (final field in step.fields) field.key: field.prompt,
              };
              return ClayCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(definition?.title ?? module?.title ?? 'Exercício',
                          style: Theme.of(context).textTheme.titleMedium),
                      Text(
                          'Última resposta: ${MaterialLocalizations.of(context).formatFullDate(response.updatedAt.toLocal())} · ${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(response.updatedAt.toLocal()), alwaysUse24HourFormat: true)}'),
                      const SizedBox(height: AppSpacing.sm),
                      for (final entry in response.responses.entries)
                        if (_answer(entry.value).trim().isNotEmpty)
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                    prompts[entry.key] ??
                                        (entry.key.endsWith('_other')
                                            ? 'Outro'
                                            : entry.key),
                                    style:
                                        Theme.of(context).textTheme.labelLarge),
                                Text(_answer(entry.value)),
                              ],
                            ),
                          ),
                      if (response.difficultyScale != null)
                        Text('Como foi: ${response.difficultyScale}'),
                      if (response.wantsToTalk != null)
                        Text(
                            'Quer conversar na sessão: ${response.wantsToTalk! ? 'Sim' : 'Não'}'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static String _answer(dynamic value) => switch (value) {
        null => '',
        List values =>
          values.map(_answer).where((v) => v.isNotEmpty).join('\n'),
        bool flag => flag ? 'Sim' : 'Não',
        _ => value.toString(),
      };
}
