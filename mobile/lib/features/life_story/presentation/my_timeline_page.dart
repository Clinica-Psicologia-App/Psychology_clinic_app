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
      padding: const EdgeInsets.fromLTRB(12, 20, 16, 96),
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

class _EventNode extends StatelessWidget {
  const _EventNode({required this.event, required this.isFirst});
  final LifeTimelineEvent event;
  final bool isFirst;

  @override
  Widget build(BuildContext context) {
    final colors = _chapterColors(event.lifeChapter);
    final ageLabel = _shortAgeLabel(event);
    final emotions = event.emotions.map((e) => e.label).join(' · ');
    final category = event.categories.isNotEmpty
        ? event.categories.first.label
        : null;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coluna de idade — largura fixa alinhada à direita
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 8),
              child: Text(
                ageLabel,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.text,
                ),
              ),
            ),
          ),
          // Linha central: ponto + traço vertical
          Column(
            children: [
              Container(
                width: 9,
                height: 9,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: colors.accent,
                  shape: BoxShape.circle,
                ),
              ),
              Expanded(
                child: Container(
                  width: 1.5,
                  color: colors.accent.withValues(alpha: 0.22),
                  margin: const EdgeInsets.only(top: 3),
                ),
              ),
            ],
          ),
          const SizedBox(width: 10),
          // Conteúdo
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: InkWell(
                onTap: () => _showEventDetail(context, event),
                borderRadius: BorderRadius.circular(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 2),
                    Text(
                      event.title,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.navy,
                        height: 1.3,
                      ),
                    ),
                    if (emotions.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        emotions,
                        style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (category != null) ...[
                      const SizedBox(height: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: colors.bg,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          category,
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                            color: colors.text,
                          ),
                        ),
                      ),
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
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(width: 46),
        Container(
          width: 9,
          height: 9,
          decoration: const BoxDecoration(
            color: AppColors.navy,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        const Text(
          'HOJE',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 12,
            letterSpacing: 1,
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

  final emoText = event.emotions.isNotEmpty
      ? event.emotions.map((e) => e.label).join(' · ')
      : null;

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
              _metaInline(Icons.sentiment_satisfied_alt_outlined,
                  emoText ?? 'Nenhuma emoção registrada',
                  muted: emoText == null),
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
