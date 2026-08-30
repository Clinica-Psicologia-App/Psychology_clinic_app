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

/// Tela 2 do fluxo Conhecer na lente do terapeuta — mesma trilha visual do
/// paciente, acrescida de um comentário clínico editável por evento.
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
          // Cabeçalho gradiente — igual ao MyTimelinePage
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
              dataBuilder: (history) {
                return Stack(
                  children: [
                    _TrailList(
                      history: history,
                      ctx: _ctx,
                      commentFor: _commentFor,
                    ),
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 16,
                      child: FilledButton.icon(
                        onPressed:
                            _saving ? null : () => _saveComments(history),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.turquoise,
                        ),
                        icon: _saving
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.check),
                        label: Text(_saving ? 'Salvando...' : 'Salvar comentários'),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Trilha completa
// ---------------------------------------------------------------------------

class _TrailList extends StatelessWidget {
  const _TrailList({
    required this.history,
    required this.ctx,
    required this.commentFor,
  });

  final PatientHistory history;
  final InitialAssessmentContext ctx;
  final TextEditingController Function(TimelineEntry) commentFor;

  @override
  Widget build(BuildContext context) {
    final items = <Widget>[];

    for (final chapter in kLifeChaptersInOrder) {
      final entries = history.entriesFor(chapter);
      if (entries.isEmpty) continue;
      items.add(_ChapterDivider(chapter: chapter, ctx: ctx));
      for (var i = 0; i < entries.length; i++) {
        final isLast = i == entries.length - 1;
        items.add(_TrailNode(
          entry: entries[i],
          chapter: chapter,
          isLastInChapter: isLast,
          commentFor: commentFor,
          ctx: ctx,
        ));
      }
    }

    if (history.unchaptered.isNotEmpty) {
      items.add(_ChapterDivider(chapter: null, ctx: ctx));
      for (var i = 0; i < history.unchaptered.length; i++) {
        items.add(_TrailNode(
          entry: history.unchaptered[i],
          chapter: null,
          isLastInChapter: i == history.unchaptered.length - 1,
          commentFor: commentFor,
          ctx: ctx,
        ));
      }
    }

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
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary, height: 1.5),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 12, 16, 96),
      children: items,
    );
  }
}

// ---------------------------------------------------------------------------
// Cabeçalho de capítulo (separador)
// ---------------------------------------------------------------------------

class _ChapterDivider extends StatelessWidget {
  const _ChapterDivider({required this.chapter, required this.ctx});

  final LifeChapter? chapter;
  final InitialAssessmentContext ctx;

  @override
  Widget build(BuildContext context) {
    final colors = _chapterColors(chapter);
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 4),
      child: Row(
        children: [
          // alinha com a coluna de idade
          const SizedBox(width: 46),
          const SizedBox(width: 14), // espaço do dot
          Expanded(
            child: Row(
              children: [
                const SizedBox(width: 10),
                Text(
                  chapter?.label ?? 'Outros acontecimentos',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.text,
                    letterSpacing: .3,
                  ),
                ),
                const Spacer(),
                InkWell(
                  onTap: () => showTimelineEventEditor(context: context, ctx: ctx),
                  customBorder: const CircleBorder(),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: colors.bg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.add, size: 16, color: colors.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Nó da trilha — um evento + campo de comentário clínico
// ---------------------------------------------------------------------------

class _TrailNode extends StatelessWidget {
  const _TrailNode({
    required this.entry,
    required this.chapter,
    required this.isLastInChapter,
    required this.commentFor,
    required this.ctx,
  });

  final TimelineEntry entry;
  final LifeChapter? chapter;
  final bool isLastInChapter;
  final TextEditingController Function(TimelineEntry) commentFor;
  final InitialAssessmentContext ctx;

  @override
  Widget build(BuildContext context) {
    final colors = _chapterColors(chapter);
    final ageLabel = entry.ageAtEvent != null ? '${entry.ageAtEvent}a' : '';
    final beliefs = entry.beliefs.map((b) => b.label).join(' · ');

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Coluna de idade
          SizedBox(
            width: 46,
            child: Padding(
              padding: const EdgeInsets.only(top: 5, right: 8),
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
                margin: const EdgeInsets.only(top: 6),
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
          // Conteúdo + comentário clínico
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 2),
                  // Título + botão editar
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          entry.title,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.navy,
                            height: 1.3,
                          ),
                        ),
                      ),
                      InkWell(
                        onTap: () => showTimelineEventEditor(
                            context: context, ctx: ctx, entry: entry),
                        customBorder: const CircleBorder(),
                        child: const Padding(
                          padding: EdgeInsets.all(4),
                          child: Icon(Icons.edit_outlined,
                              size: 14, color: AppColors.textMuted),
                        ),
                      ),
                    ],
                  ),
                  // Metadados
                  if (entry.emotionalImpact != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Impacto ${entry.emotionalImpact}/10',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ],
                  if ((entry.description ?? '').trim().isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      entry.description!.trim(),
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.4),
                    ),
                  ],
                  if (beliefs.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EEFF),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        beliefs,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.purple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                  // Campo de comentário clínico
                  const SizedBox(height: 8),
                  TextField(
                    controller: commentFor(entry),
                    minLines: 1,
                    maxLines: 4,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Comentário clínico',
                      labelStyle: const TextStyle(
                          fontSize: 12.5, color: AppColors.textMuted),
                      isDense: true,
                      filled: true,
                      fillColor: const Color(0xFFF5FFFE),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide:
                            const BorderSide(color: AppColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                            color: AppColors.turquoise, width: 1.5),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
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
}

// ---------------------------------------------------------------------------
// Paleta de cores por capítulo
// ---------------------------------------------------------------------------

({Color accent, Color bg, Color text}) _chapterColors(LifeChapter? chapter) =>
    switch (chapter) {
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
      LifeChapter.maturity => (
          accent: const Color(0xFF7B4FC6),
          bg: const Color(0xFFF0EAFB),
          text: const Color(0xFF4E2A8A),
        ),
      LifeChapter.today => (
          accent: const Color(0xFF378ADD),
          bg: const Color(0xFFE6F1FB),
          text: const Color(0xFF185FA5),
        ),
      _ => (
          accent: AppColors.textMuted,
          bg: const Color(0xFFF5F5F5),
          text: AppColors.textSecondary,
        ),
    };
