import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../daily_monitors/presentation/daily_monitor_routes.dart';
import '../../daily_monitors/providers/daily_monitors_providers.dart';
import '../../patients/providers/patients_providers.dart';
import '../domain/coping_card.dart';
import '../providers/coping_cards_provider.dart';

class CopingCardsPage extends ConsumerWidget {
  const CopingCardsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) => Scaffold(
        appBar: AppBar(title: const Text('Cartões de enfrentamento')),
        body: AsyncStateBody<List<CopingCard>>(
          asyncValue: ref.watch(myCopingCardsProvider),
          onRetry: () {
            final patientId = ref.read(myPatientIdProvider).valueOrNull;
            if (patientId != null) {
              ref.invalidate(patientDetailProvider(patientId));
            }
            ref.invalidate(myCopingCardsProvider);
          },
          emptyMessage:
              'Ainda não há resultados YCI ou YRAI disponíveis para montar seus cartões.',
          dataBuilder: (cards) => ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              const Text(
                  'Cartões de reflexão baseados na última aplicação disponível de cada questionário. Escolha um tema para levar à sessão e registre suas reflexões no Diário.'),
              const SizedBox(height: AppSpacing.md),
              for (final card in cards)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: ClayCard(
                      child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(card.topic,
                              style: Theme.of(context).textTheme.titleMedium),
                          Text(
                              'Origem: ${card.source}${card.completedAt == null ? '' : ' · ${MaterialLocalizations.of(context).formatFullDate(card.completedAt!.toLocal())}'}'),
                          const SizedBox(height: AppSpacing.sm),
                          Text(card.observation),
                          const SizedBox(height: AppSpacing.sm),
                          const Text(CopingCard.reflection),
                          const Text(CopingCard.nextStep),
                          TextButton.icon(
                            onPressed: () =>
                                context.push(DailyMonitorRoutes.patientCreate),
                            icon: const Icon(Icons.edit_note_outlined),
                            label: const Text('Registrar no Diário'),
                          ),
                        ]),
                  )),
                ),
            ],
          ),
        ),
      );
}
