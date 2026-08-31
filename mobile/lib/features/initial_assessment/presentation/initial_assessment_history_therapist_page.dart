import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/life_chapter.dart';
import '../domain/patient_history.dart';
import '../domain/timeline_belief.dart';
import '../domain/timeline_entry.dart';
import '../providers/patient_history_providers.dart';
import 'widgets/timeline_event_editor.dart';

/// Tela 2 do fluxo Conhecer na lente do terapeuta.
/// Layout "Tiras": capítulos como bandas coloridas, eventos como linhas
/// compactas que expandem para revelar detalhes e campo de comentário.
class InitialAssessmentHistoryTherapistPage extends ConsumerStatefulWidget {
  const InitialAssessmentHistoryTherapistPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  ConsumerState<InitialAssessmentHistoryTherapistPage> createState() =>
      _InitialAssessmentHistoryTherapistPageState();
}

class _InitialAssessmentHistoryTherapistPageState
    extends ConsumerState<InitialAssessmentHistoryTherapistPage> {
  final Map<String, TextEditingController> _comments = {};
  bool _saving = false;
  String? _expandedId;

  InitialAssessmentContext get _ctx =>
      InitialAssessmentContext(role: widget.role, patientId: widget.patientId);

  @override
  void dispose() {
    for (final c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _commentFor(TimelineEntry entry) {
    return _comments.putIfAbsent(
      entry.id,
      () => TextEditingController(text: entry.clinicalComment ?? ''),
    );
  }

  bool _hasComment(TimelineEntry entry) {
    final ctrl = _comments[entry.id];
    if (ctrl != null) return ctrl.text.trim().isNotEmpty;
    return (entry.clinicalComment ?? '').trim().isNotEmpty;
  }

  void _toggleExpand(String id) {
    setState(() => _expandedId = _expandedId == id ? null : id);
  }

  Future<void> _saveComments(PatientHistory history) async {
    setState(() => _saving = true);
    final repo = ref.read(patientHistoryRepositoryProvider);
    try {
      for (final entry in history.entries) {
        final controller = _comments[entry.id];
        if (controller == null) continue;
        await repo.saveEntryNote(
          patientId: widget.patientId,
          eventId: entry.id,
          clinicalComment: controller.text,
        );
      }
      ref.invalidate(patientHistoryProvider(_ctx));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentários salvos.')),
      );
    } catch (e) {
      if (!mounted) return;
      showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(patientHistoryProvider(_ctx));
    final topInset = MediaQuery.paddingOf(context).top;
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
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
                    'Linha do Tempo',
                    style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: AsyncStateBody<PatientHistory>(
              asyncValue: async,
              onRetry: () => ref.invalidate(patientHistoryProvider(_ctx)),
              dataBuilder: (history) => Stack(
                children: [
                  _buildList(history),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: FilledButton.icon(
                      onPressed:
                          _saving ? null : () => _saveComments(history),
                      style: FilledButton.styleFrom(
                          backgroundColor: AppColors.turquoise),
                      icon: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.check),
                      label:
                          Text(_saving ? 'Salvando...' : 'Salvar comentários'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(PatientHistory history) {
    if (history.eventCount == 0) {
      return const Padding(
        padding: EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(height: 40),
            Icon(Icons.timeline_outlined,
                size: 44, color: AppColors.turquoise),
            SizedBox(height: 16),
            Text(
              'O paciente ainda não registrou acontecimentos.\nVocê pode adicioná-los por ele.',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      );
    }

    final rows = <Widget>[];

    void addChapter(LifeChapter? chapter, List<TimelineEntry> entries) {
      rows.add(_ChapterBand(
        chapter: chapter,
        count: entries.length,
        onAdd: () => showTimelineEventEditor(context: context, ctx: _ctx),
      ));
      for (final entry in entries) {
        rows.add(_EventStrip(
          entry: entry,
          chapter: chapter,
          isExpanded: _expandedId == entry.id,
          hasComment: _hasComment(entry),
          onTap: () => _toggleExpand(entry.id),
        ));
        rows.add(AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          child: _expandedId == entry.id
              ? _ExpandedContent(
                  entry: entry,
                  chapter: chapter,
                  controller: _commentFor(entry),
                  ctx: _ctx,
                )
              : const SizedBox.shrink(),
        ));
      }
    }

    for (final chapter in kLifeChaptersInOrder) {
      addChapter(chapter, history.entriesFor(chapter));
    }
    if (history.unchaptered.isNotEmpty) {
      addChapter(null, history.unchaptered);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: rows,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paleta por capítulo
// ─────────────────────────────────────────────────────────────────────────────

({Color accent, Color bg, Color text, IconData icon}) _chapterMeta(
        LifeChapter? chapter) =>
    switch (chapter) {
      LifeChapter.childhood => (
          accent: const Color(0xFFD85A30),
          bg: const Color(0xFFFAECE7),
          text: const Color(0xFF7D2F12),
          icon: Icons.child_care_rounded,
        ),
      LifeChapter.adolescence => (
          accent: const Color(0xFFB97010),
          bg: const Color(0xFFFAEEDA),
          text: const Color(0xFF7A4408),
          icon: Icons.school_rounded,
        ),
      LifeChapter.adulthood => (
          accent: const Color(0xFF1B9A6E),
          bg: const Color(0xFFE1F5EE),
          text: const Color(0xFF0D6044),
          icon: Icons.work_outline_rounded,
        ),
      LifeChapter.maturity => (
          accent: const Color(0xFF7240C0),
          bg: const Color(0xFFEDE5FA),
          text: const Color(0xFF432875),
          icon: Icons.self_improvement_rounded,
        ),
      LifeChapter.today => (
          accent: const Color(0xFF378ADD),
          bg: const Color(0xFFE6F1FB),
          text: const Color(0xFF185FA5),
          icon: Icons.place_rounded,
        ),
      _ => (
          accent: AppColors.textMuted,
          bg: const Color(0xFFF5F5F5),
          text: AppColors.textSecondary,
          icon: Icons.circle_outlined,
        ),
    };

// ─────────────────────────────────────────────────────────────────────────────
// Banda de capítulo
// ─────────────────────────────────────────────────────────────────────────────

class _ChapterBand extends StatelessWidget {
  const _ChapterBand({
    required this.chapter,
    required this.count,
    required this.onAdd,
  });

  final LifeChapter? chapter;
  final int count;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final m = _chapterMeta(chapter);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: m.bg,
        border: Border(
          top: BorderSide(color: m.accent.withValues(alpha: .2)),
          bottom: BorderSide(color: m.accent.withValues(alpha: .15)),
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Container(width: 3, color: m.accent),
            const SizedBox(width: 10),
            Icon(m.icon, size: 16, color: m.accent),
            const SizedBox(width: 7),
            Expanded(
              child: Text(
                chapter?.label ?? 'Outros acontecimentos',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: m.text),
              ),
            ),
            if (count > 0) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: m.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: m.text),
                ),
              ),
            ],
            IconButton(
              icon: Icon(Icons.add, size: 18, color: m.accent),
              onPressed: onAdd,
              tooltip: 'Adicionar acontecimento',
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tira de evento (colapsada)
// ─────────────────────────────────────────────────────────────────────────────

class _EventStrip extends StatelessWidget {
  const _EventStrip({
    required this.entry,
    required this.chapter,
    required this.isExpanded,
    required this.hasComment,
    required this.onTap,
  });

  final TimelineEntry entry;
  final LifeChapter? chapter;
  final bool isExpanded;
  final bool hasComment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = _chapterMeta(chapter);
    final ageLabel =
        entry.ageAtEvent != null ? '${entry.ageAtEvent}a' : '—';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isExpanded ? const Color(0xFFF5F8FF) : Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFEEF2F8)),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              children: [
                Container(width: 4, color: m.accent),
                const SizedBox(width: 10),
                // Idade
                SizedBox(
                  width: 26,
                  child: Text(
                    ageLabel,
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: m.text),
                  ),
                ),
                const SizedBox(width: 8),
                // Título
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    child: Text(
                      entry.title,
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Ponto de status da anotação
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: hasComment
                        ? AppColors.turquoise
                        : const Color(0xFFCDD6E4),
                  ),
                ),
                const SizedBox(width: 8),
                // Impacto
                if (entry.emotionalImpact != null)
                  Text(
                    '${entry.emotionalImpact}',
                    style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary),
                  ),
                const SizedBox(width: 6),
                Icon(
                  isExpanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                const SizedBox(width: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Conteúdo expandido
// ─────────────────────────────────────────────────────────────────────────────

class _ExpandedContent extends StatelessWidget {
  const _ExpandedContent({
    required this.entry,
    required this.chapter,
    required this.controller,
    required this.ctx,
  });

  final TimelineEntry entry;
  final LifeChapter? chapter;
  final TextEditingController controller;
  final InitialAssessmentContext ctx;

  @override
  Widget build(BuildContext context) {
    final m = _chapterMeta(chapter);
    final beliefs = entry.beliefs.map((b) => b.label).join(' · ');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FF),
        border: Border(
          left: BorderSide(color: m.accent.withValues(alpha: .35), width: 3),
          bottom: BorderSide(color: m.accent.withValues(alpha: .15)),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((entry.description ?? '').trim().isNotEmpty) ...[
              Text(
                entry.description!.trim(),
                style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    height: 1.45),
              ),
              const SizedBox(height: 7),
            ],
            if (beliefs.isNotEmpty) ...[
              Container(
                padding: const EdgeInsets.only(left: 8),
                decoration: BoxDecoration(
                  border: Border(
                      left: BorderSide(color: m.accent, width: 2)),
                ),
                child: Text(
                  beliefs,
                  style: TextStyle(
                      fontSize: 11.5,
                      fontStyle: FontStyle.italic,
                      color: m.text,
                      height: 1.4),
                ),
              ),
              const SizedBox(height: 8),
            ],
            // Campo de comentário clínico
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0FCFA),
                border: Border.all(color: const Color(0xFF9EDDDA)),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'COMENTÁRIO CLÍNICO',
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .5,
                        color: AppColors.turquoise),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: controller,
                    minLines: 2,
                    maxLines: 5,
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.navy),
                    decoration: const InputDecoration(
                      isDense: true,
                      hintText: 'Adicionar comentário…',
                      hintStyle: TextStyle(
                          color: AppColors.textMuted, fontSize: 12.5),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            // Botão editar evento
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => showTimelineEventEditor(
                    context: context, ctx: ctx, entry: entry),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit_outlined,
                          size: 13, color: AppColors.textMuted),
                      SizedBox(width: 4),
                      Text('Editar evento',
                          style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
