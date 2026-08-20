import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/life_story_enums.dart';
import '../domain/life_timeline_event.dart';
import '../providers/life_story_providers.dart';
import 'life_story_routes.dart';

/// Resultado visual da Linha do Tempo — trilha vertical (spec §15).
/// Quando vazia, mostra o convite de abertura (spec §3).
class MyTimelinePage extends ConsumerWidget {
  const MyTimelinePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(myTimelineProvider);
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.turquoise,
        onPressed: () => context.push(LifeStoryRoutes.newEvent),
        icon: const Icon(Icons.add),
        label: const Text('Adicionar acontecimento'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(16, topInset + 10, 16, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.turquoise, AppColors.cyan, AppColors.blue],
              ),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: () => context.pop(),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 10),
                Text('Minha História',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Expanded(
            child: timelineAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Não conseguimos carregar agora.',
                          style: TextStyle(color: AppColors.textSecondary)),
                      const SizedBox(height: 12),
                      OutlinedButton(
                        onPressed: () => ref.invalidate(myTimelineProvider),
                        child: const Text('Tentar de novo'),
                      ),
                    ],
                  ),
                ),
              ),
              data: (events) => events.isEmpty
                  ? _EmptyInvite(
                      onStart: () => context.push(LifeStoryRoutes.newEvent))
                  : _TimelineTrail(events: events),
            ),
          ),
        ],
      ),
    );
  }
}

/// Abertura — convite quando ainda não há acontecimentos (spec §3).
class _EmptyInvite extends StatelessWidget {
  const _EmptyInvite({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timeline_outlined,
                size: 48, color: AppColors.turquoise),
            const SizedBox(height: 18),
            const Text('Vamos construir sua Linha do Tempo',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy)),
            const SizedBox(height: 12),
            const Text(
              'Algumas experiências marcam nossa história e ajudam a '
              'compreender quem somos hoje. Vamos registrar momentos '
              'importantes da sua vida, dos primeiros anos até o momento '
              'atual. Podem ser experiências difíceis, felizes, mudanças, '
              'conquistas ou pessoas que marcaram você.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 13.5, color: AppColors.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onStart,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.turquoise,
                minimumSize: const Size(220, 50),
              ),
              child: const Text('Começar minha história'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Trilha vertical dos acontecimentos (spec §15).
class _TimelineTrail extends StatelessWidget {
  const _TimelineTrail({required this.events});
  final List<LifeTimelineEvent> events;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      itemCount: events.length + 1,
      itemBuilder: (context, i) {
        if (i == events.length) return const _TodayNode();
        return _EventNode(
          event: events[i],
          isFirst: i == 0,
        );
      },
    );
  }
}

class _EventNode extends StatelessWidget {
  const _EventNode({required this.event, required this.isFirst});
  final LifeTimelineEvent event;
  final bool isFirst;

  String get _ageLabel {
    if (event.agePrecision?.name == 'approximate') {
      return event.lifeChapter?.label ?? 'Idade aproximada';
    }
    if (event.ageAtEvent != null) return '${event.ageAtEvent} anos';
    return event.lifeChapter?.label ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final emotions = event.emotions.map((e) => e.label).join(' · ');
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 13,
                height: 13,
                margin: const EdgeInsets.only(top: 3),
                decoration: const BoxDecoration(
                  color: AppColors.turquoise,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(width: 2, color: AppColors.borderStrong),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_ageLabel.isNotEmpty)
                    Text(_ageLabel,
                        style: const TextStyle(
                            color: AppColors.turquoise,
                            fontWeight: FontWeight.w700,
                            fontSize: 12)),
                  const SizedBox(height: 2),
                  Text(event.title,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy)),
                  if (emotions.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(emotions,
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textSecondary)),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayNode extends StatelessWidget {
  const _TodayNode();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 13,
          height: 13,
          margin: const EdgeInsets.only(top: 3),
          decoration: const BoxDecoration(
            color: AppColors.navy,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 14),
        const Text('HOJE',
            style: TextStyle(
                color: AppColors.navy,
                fontWeight: FontWeight.w800,
                fontSize: 13,
                letterSpacing: 1)),
      ],
    );
  }
}
