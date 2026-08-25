import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../coach/domain/coach_step.dart';
import '../../coach/domain/coach_tour.dart';
import '../../coach/providers/coach_providers.dart';
import '../domain/family_person.dart';
import '../domain/life_story_deepen_enums.dart';
import '../domain/life_story_enums.dart';
import '../domain/life_timeline_event.dart';
import '../providers/life_story_providers.dart';
import 'life_story_routes.dart';
import '../../../shared/widgets/brand_loading.dart';

/// Resultado visual da Linha do Tempo — trilha vertical (spec §15).
/// Quando vazia, mostra o convite de abertura (spec §3).
///
/// Com [person] preenchida, vira "Momentos com a pessoa" (§39, "Ver
/// momentos"): mesma trilha, filtrada aos acontecimentos ligados àquela
/// pessoa pela junção `timeline_event_people`.
class MyTimelinePage extends ConsumerStatefulWidget {
  const MyTimelinePage({super.key, this.person});

  final FamilyPerson? person;

  @override
  ConsumerState<MyTimelinePage> createState() => _MyTimelinePageState();
}

class _MyTimelinePageState extends ConsumerState<MyTimelinePage> {
  final _fabKey = GlobalKey();
  final _titleKey = GlobalKey();
  bool _tourRequested = false;

  FamilyPerson? get person => widget.person;
  bool get _filtered => widget.person != null;

  CoachTour _tour() => CoachTour(
        id: 'tour_linha_do_tempo',
        steps: [
          CoachStep(
            id: 'oque',
            text:
                'Esta é a sua Linha do Tempo — os momentos que marcaram a sua '
                'história, dos primeiros anos até hoje.',
            pose: MascotPose.wave,
            targetKey: _titleKey,
          ),
          CoachStep(
            id: 'adicionar',
            text:
                'Toque em "Adicionar acontecimento" para registrar um momento '
                'importante. Um de cada vez, no seu ritmo.',
            pose: MascotPose.point,
            targetKey: _fabKey,
          ),
          const CoachStep(
            id: 'pessoas',
            text:
                'Cada momento pode se ligar às pessoas da sua família. Assim a '
                'sua história e o seu genograma conversam. Vamos começar? 🙂',
            pose: MascotPose.celebrate,
          ),
        ],
      );

  Future<void> _startTour({bool force = false}) async {
    if (!mounted) return;
    await ref
        .read(coachControllerProvider.notifier)
        .startTour(context, _tour(), force: force);
  }

  @override
  Widget build(BuildContext context) {
    final timelineAsync = ref.watch(myTimelineProvider);
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    // Auto-start só na trilha principal (não na visão filtrada por pessoa).
    if (!_filtered && !_tourRequested) {
      _tourRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTour());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: _filtered
          ? null
          : FloatingActionButton.extended(
              key: _fabKey,
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
                Expanded(
                  child: Text(
                    _filtered
                        ? 'Momentos com ${person!.fullName}'
                        : 'Minha História',
                    key: _titleKey,
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                if (!_filtered)
                  IconButton(
                    tooltip: 'Rever tutorial',
                    onPressed: () => _startTour(force: true),
                    icon: const Icon(Icons.help_outline_rounded,
                        color: Colors.white),
                  ),
              ],
            ),
          ),
          Expanded(
            child: timelineAsync.when(
              loading: () =>
                  const BrandLoader(),
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
              data: (events) {
                final shown = _filtered
                    ? events
                        .where((e) => e.peopleIds.contains(person!.id))
                        .toList()
                    : events;
                if (shown.isEmpty) {
                  return _filtered
                      ? _NoMomentsForPerson(name: person!.fullName)
                      : _EmptyInvite(
                          onStart: () =>
                              context.push(LifeStoryRoutes.newEvent));
                }
                return _TimelineTrail(events: shown, showToday: !_filtered);
              },
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
  const _TimelineTrail({required this.events, this.showToday = true});
  final List<LifeTimelineEvent> events;
  final bool showToday;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
      itemCount: events.length + (showToday ? 1 : 0),
      itemBuilder: (context, i) {
        if (showToday && i == events.length) return const _TodayNode();
        return _EventNode(
          event: events[i],
          isFirst: i == 0,
        );
      },
    );
  }
}

/// Estado vazio quando uma pessoa ainda não tem acontecimentos ligados.
class _NoMomentsForPerson extends StatelessWidget {
  const _NoMomentsForPerson({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timeline_outlined,
                size: 44, color: AppColors.turquoise),
            const SizedBox(height: 16),
            Text(
              'Ainda não há momentos da sua história ligados a $name.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.textSecondary,
                  height: 1.4),
            ),
          ],
        ),
      ),
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
              child: InkWell(
                onTap: () => _showEventDetail(context, event),
                borderRadius: BorderRadius.circular(8),
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

/// Relato completo do acontecimento (spec §15 — "abrir o relato completo"),
/// com acesso ao "Aprofundar este momento".
void _showEventDetail(BuildContext context, LifeTimelineEvent event) {
  final ageLabel = event.agePrecision?.name == 'approximate'
      ? (event.lifeChapter?.label ?? 'Idade aproximada')
      : (event.ageAtEvent != null
          ? '${event.ageAtEvent} anos'
          : (event.lifeChapter?.label ?? ''));

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (ageLabel.isNotEmpty)
              Text(ageLabel,
                  style: const TextStyle(
                      color: AppColors.turquoise,
                      fontWeight: FontWeight.w700,
                      fontSize: 13)),
            const SizedBox(height: 2),
            Text(event.title,
                style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy)),
            const SizedBox(height: 12),
            if ((event.description ?? '').trim().isNotEmpty) ...[
              Text(event.description!.trim(),
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5)),
              const SizedBox(height: 14),
            ],
            if (event.emotions.isNotEmpty)
              _detailRow('Emoções',
                  event.emotions.map((e) => e.label).join(' · ')),
            if (event.categories.isNotEmpty)
              _detailRow('Área da vida',
                  event.categories.map((c) => c.label).join(' · ')),
            if (event.needs.isNotEmpty)
              _detailRow('Do que precisava',
                  event.needs.map((n) => n.label).join(' · ')),
            if ((event.meaning ?? '').trim().isNotEmpty)
              _detailRow('Significado', event.meaning!.trim()),
            if (event.stillInfluences != null)
              _detailRow('Ainda influencia', event.stillInfluences!.label),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(sheetContext).pop();
                context.push(LifeStoryRoutes.deepen, extra: event);
              },
              icon: Icon(
                  event.hasDeepenData ? Icons.edit_outlined : Icons.add,
                  size: 18),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.turquoise,
                minimumSize: const Size.fromHeight(48),
              ),
              label: Text(event.hasDeepenData
                  ? 'Editar aprofundamento'
                  : 'Aprofundar este momento'),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _detailRow(String label, String value) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: const TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textMuted,
                  letterSpacing: 0.5)),
          const SizedBox(height: 2),
          Text(value,
              style: const TextStyle(fontSize: 13.5, color: AppColors.navy)),
        ],
      ),
    );
