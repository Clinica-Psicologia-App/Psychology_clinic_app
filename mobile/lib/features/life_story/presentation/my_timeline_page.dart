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

/// Trilha vertical dos acontecimentos (spec §15), agrupada por fase da vida:
/// cada capítulo ganha um cabeçalho e os acontecimentos viram cards ricos.
class _TimelineTrail extends StatelessWidget {
  const _TimelineTrail({required this.events, this.showToday = true});
  final List<LifeTimelineEvent> events;
  final bool showToday;

  @override
  Widget build(BuildContext context) {
    // Monta a lista de "linhas": um cabeçalho quando a fase muda em relação ao
    // evento anterior + os cards. Como a ordem chega agrupada por fase (mesma
    // fase adjacente), o consecutivo já produz um cabeçalho por capítulo.
    final rows = <Widget>[];
    LifeChapter? current;
    bool sawAny = false;
    for (final event in events) {
      final chapter = event.lifeChapter;
      if (!sawAny || chapter != current) {
        rows.add(_ChapterHeaderNode(chapter: chapter));
        current = chapter;
        sawAny = true;
      }
      rows.add(_EventCardNode(event: event));
    }
    if (showToday) rows.add(const _TodayNode());

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 18, 16, 100),
      itemCount: rows.length,
      itemBuilder: (context, i) => rows[i],
    );
  }
}

/// Largura da coluna da trilha (dot/linha) à esquerda dos cards.
const double _kRailWidth = 30;

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

/// Cor e fundo tonal por fase da vida (Opção C).
({Color accent, Color bg, Color text}) _chapterColors(LifeChapter? chapter) =>
    switch (chapter) {
      LifeChapter.earlyYears => (
          accent: const Color(0xFFD85A30),
          bg: const Color(0xFFFAECE7),
          text: const Color(0xFF993C1D),
        ),
      LifeChapter.childhood => (
          accent: const Color(0xFFD85A30),
          bg: const Color(0xFFFAECE7),
          text: const Color(0xFF993C1D),
        ),
      LifeChapter.adolescence => (
          accent: const Color(0xFFBA7517),
          bg: const Color(0xFFFAEEDA),
          text: const Color(0xFF854F0B),
        ),
      LifeChapter.adulthood => (
          accent: const Color(0xFF1D9E75),
          bg: const Color(0xFFE1F5EE),
          text: const Color(0xFF0F6E56),
        ),
      _ => (
          accent: const Color(0xFF378ADD),
          bg: const Color(0xFFE6F1FB),
          text: const Color(0xFF185FA5),
        ),
    };

/// Rótulo curto de idade (ex: "30a" ou "Adolescência").
String _shortAgeLabel(LifeTimelineEvent event) {
  if (event.agePrecision?.name == 'approximate') {
    return event.lifeChapter?.label ?? '';
  }
  if (event.ageAtEvent != null) return '${event.ageAtEvent}a';
  return event.lifeChapter?.label ?? '';
}

/// Cabeçalho de capítulo (fase da vida): selo na trilha + nome + faixa etária.
class _ChapterHeaderNode extends StatelessWidget {
  const _ChapterHeaderNode({required this.chapter});
  final LifeChapter? chapter;

  @override
  Widget build(BuildContext context) {
    final colors = _chapterColors(chapter);
    final detail = _chapterDetailColors(chapter);
    final name = chapter?.label ?? 'Outros momentos';
    final range = _chapterRange(chapter);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: _kRailWidth,
            child: Stack(
              children: [
                // Linha vertical contínua (atrás do selo).
                Positioned(
                  left: (_kRailWidth - 3) / 2,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: Container(color: colors.accent.withValues(alpha: 0.28)),
                ),
                // Selo do capítulo.
                Positioned(
                  left: (_kRailWidth - 24) / 2,
                  top: 0,
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      shape: BoxShape.circle,
                      border:
                          Border.all(color: AppColors.background, width: 3),
                    ),
                    child: Icon(detail.icon, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Flexible(
                    child: Text(
                      name.toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                        color: colors.text,
                      ),
                    ),
                  ),
                  if (range.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Text(
                      range,
                      style: const TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted,
                      ),
                    ),
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

/// Card rico de um acontecimento na trilha (densidade completa).
class _EventCardNode extends StatelessWidget {
  const _EventCardNode({required this.event});
  final LifeTimelineEvent event;

  @override
  Widget build(BuildContext context) {
    final colors = _chapterColors(event.lifeChapter);
    final ageLabel = _shortAgeLabel(event);
    final impact = event.emotionalImpact;
    final category =
        event.categories.isNotEmpty ? event.categories.first.label : null;
    final meaning = (event.meaning ?? '').trim();

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Trilha: linha contínua + nó do evento.
          SizedBox(
            width: _kRailWidth,
            child: Stack(
              children: [
                Positioned(
                  left: (_kRailWidth - 3) / 2,
                  top: 0,
                  bottom: 0,
                  width: 3,
                  child: Container(color: colors.accent.withValues(alpha: 0.28)),
                ),
                Positioned(
                  left: (_kRailWidth - 14) / 2,
                  top: 12,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: colors.accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.navy.withValues(alpha: 0.15),
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => _showEventDetail(context, event),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(color: const Color(0xFFE4EAF3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(height: 3, color: colors.accent),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (ageLabel.isNotEmpty) ...[
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: colors.bg,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        ageLabel,
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: colors.text,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                  Expanded(
                                    child: Text(
                                      event.title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.navy,
                                        height: 1.3,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if ((event.description ?? '').trim().isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  event.description!.trim(),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                    height: 1.4,
                                  ),
                                ),
                              ],
                              if (event.emotions.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 5,
                                  runSpacing: 5,
                                  children: [
                                    for (final e in event.emotions)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: AppColors.surfaceTint,
                                          borderRadius:
                                              BorderRadius.circular(20),
                                        ),
                                        child: Text(
                                          '${e.emoji} ${e.label}',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                              if (impact != null) ...[
                                const SizedBox(height: 9),
                                Row(
                                  children: [
                                    const Text(
                                      'Impacto',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                          value: (impact / 10).clamp(0.0, 1.0),
                                          minHeight: 5,
                                          backgroundColor: _impactColor(impact)
                                              .withValues(alpha: 0.15),
                                          color: _impactColor(impact),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '$impact/10',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: _impactColor(impact),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (category != null || meaning.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    if (category != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 3),
                                        decoration: BoxDecoration(
                                          color: colors.bg,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          category,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            color: colors.text,
                                          ),
                                        ),
                                      ),
                                    if (meaning.isNotEmpty)
                                      Expanded(
                                        child: Padding(
                                          padding: EdgeInsets.only(
                                              left: category != null ? 8 : 0),
                                          child: Text(
                                            '"$meaning"',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10.5,
                                              fontStyle: FontStyle.italic,
                                              color: AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _impactColor(int v) {
    if (v >= 7) return AppColors.error;
    if (v >= 4) return AppColors.warning;
    return AppColors.success;
  }
}

/// Faixa etária aproximada de cada capítulo, exibida no cabeçalho.
String _chapterRange(LifeChapter? chapter) => switch (chapter) {
      LifeChapter.earlyYears => '0 – 5 anos',
      LifeChapter.childhood => '6 – 12 anos',
      LifeChapter.adolescence => '13 – 17 anos',
      LifeChapter.adulthood => '18+ anos',
      _ => '',
    };

class _TodayNode extends StatelessWidget {
  const _TodayNode();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: _kRailWidth,
          child: Center(
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.navy,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.background, width: 3),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.navy,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            'HOJE',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }
}

/// Relato completo do acontecimento — Opção C: minimalista com ações em lista.
void _showEventDetail(BuildContext context, LifeTimelineEvent event) {
  final chapter = event.lifeChapter;
  final chapterColors = _chapterDetailColors(chapter);

  final ageLabel = event.agePrecision?.name == 'approximate'
      ? (chapter?.label ?? 'Idade aproximada')
      : (event.ageAtEvent != null
          ? '${event.ageAtEvent} anos'
          : (chapter?.label ?? ''));

  final periodLabel = [
    if (chapter != null) chapter.label,
    if (ageLabel.isNotEmpty && ageLabel != chapter?.label) ageLabel,
  ].join(' · ');

  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              // Ícone do capítulo + período + título
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: chapterColors.bg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(chapterColors.icon,
                        size: 22, color: chapterColors.accent),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (periodLabel.isNotEmpty)
                          Text(periodLabel,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: chapterColors.accent,
                                  letterSpacing: .2)),
                        const SizedBox(height: 3),
                        Text(event.title,
                            style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                                height: 1.2)),
                      ],
                    ),
                  ),
                ],
              ),
              // Descrição
              if ((event.description ?? '').trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Text(event.description!.trim(),
                    style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.55)),
              ],
              // Metadados inline (emoções, impacto, aprofundamento)
              const SizedBox(height: 16),
              if (event.emotions.isEmpty)
                _metaInline(Icons.sentiment_satisfied_alt_outlined,
                    'Nenhuma emoção registrada',
                    muted: true)
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: event.emotions
                        .map(
                          (e) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.background,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(e.emoji,
                                    style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 5),
                                Text(
                                  e.label,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ),
              if (event.emotionalImpact != null)
                _metaInline(Icons.bar_chart_rounded,
                    'Impacto ${event.emotionalImpact}/10'),
              if (event.categories.isNotEmpty)
                _metaInline(Icons.grid_view_rounded,
                    event.categories.map((c) => c.label).join(' · ')),
              if (event.needs.isNotEmpty)
                _metaInline(Icons.volunteer_activism_outlined,
                    event.needs.map((n) => n.label).join(' · ')),
              if ((event.meaning ?? '').trim().isNotEmpty)
                _metaInline(Icons.lightbulb_outline,
                    '"${event.meaning!.trim()}"'),
              if (event.stillInfluences != null)
                _metaInline(Icons.refresh_rounded,
                    'Ainda influencia: ${event.stillInfluences!.label}'),
              // Separador
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Divider(height: 1, color: AppColors.border),
              ),
              // Ações em lista
              _actionTile(
                iconBg: const Color(0xFFE0F2F1),
                icon: event.hasDeepenData
                    ? Icons.edit_outlined
                    : Icons.search_rounded,
                iconColor: AppColors.turquoise,
                label: event.hasDeepenData
                    ? 'Editar aprofundamento'
                    : 'Aprofundar este momento',
                subtitle: event.hasDeepenData
                    ? 'Ver ou alterar reflexões registradas'
                    : 'Explorar com o psicólogo',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  context.push(LifeStoryRoutes.deepen, extra: event);
                },
              ),
              const SizedBox(height: 8),
              _actionTile(
                iconBg: const Color(0xFFEBF4FF),
                icon: Icons.edit_note_rounded,
                iconColor: AppColors.blue,
                label: 'Editar acontecimento',
                subtitle: 'Corrigir título, emoções ou descrição',
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  // TODO: rota de edição do evento
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

/// Uma linha de metadado com ícone à esquerda.
Widget _metaInline(IconData icon, String value, {bool muted = false}) =>
    Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: 13.5,
                    color: muted ? AppColors.textMuted : AppColors.textPrimary,
                    height: 1.45)),
          ),
        ],
      ),
    );

/// Linha de ação (Opção C).
Widget _actionTile({
  required Color iconBg,
  required IconData icon,
  required Color iconColor,
  required String label,
  required String subtitle,
  required VoidCallback onTap,
}) =>
    Material(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration:
                    BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textPrimary)),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  size: 20, color: AppColors.textMuted),
            ],
          ),
        ),
      ),
    );

/// Cores e ícone para o ícone do capítulo no detalhe.
({Color accent, Color bg, IconData icon}) _chapterDetailColors(
    LifeChapter? chapter) =>
    switch (chapter) {
      LifeChapter.earlyYears => (
          accent: const Color(0xFFD85A30),
          bg: const Color(0xFFFFF0EB),
          icon: Icons.child_care,
        ),
      LifeChapter.childhood => (
          accent: const Color(0xFFD85A30),
          bg: const Color(0xFFFFF0EB),
          icon: Icons.directions_run,
        ),
      LifeChapter.adolescence => (
          accent: const Color(0xFFBA7517),
          bg: const Color(0xFFFFF8EC),
          icon: Icons.school,
        ),
      LifeChapter.adulthood => (
          accent: const Color(0xFF1D9E75),
          bg: const Color(0xFFECFBF5),
          icon: Icons.person,
        ),
      LifeChapter.today => (
          accent: const Color(0xFF378ADD),
          bg: const Color(0xFFEBF4FF),
          icon: Icons.location_on,
        ),
      _ => (
          accent: AppColors.textMuted,
          bg: const Color(0xFFF5F5F5),
          icon: Icons.help_outline,
        ),
    };
