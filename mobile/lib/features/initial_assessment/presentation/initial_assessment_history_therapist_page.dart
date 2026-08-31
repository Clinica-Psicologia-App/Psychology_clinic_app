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

/// Tela 2 do fluxo Conhecer — lente do terapeuta.
/// Layout Tiras: capítulos em bandas coloridas, eventos como linhas compactas.
/// Toque num evento → bottom sheet com detalhes + comentário clínico editável.
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
      _State();
}

class _State extends ConsumerState<InitialAssessmentHistoryTherapistPage> {
  // Controladores de comentário por evento — persistem entre aberturas do sheet.
  final Map<String, TextEditingController> _comments = {};

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

  Future<void> _saveNote(TimelineEntry entry, String comment) async {
    final repo = ref.read(patientHistoryRepositoryProvider);
    await repo.saveEntryNote(
      patientId: widget.patientId,
      eventId: entry.id,
      clinicalComment: comment,
    );
    ref.invalidate(patientHistoryProvider(_ctx));
  }

  Future<void> _openDetail(
      BuildContext context, TimelineEntry entry, LifeChapter? chapter) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => _EventDetailSheet(
        entry: entry,
        chapter: chapter,
        commentController: _commentFor(entry),
        ctx: _ctx,
        onSave: (comment) => _saveNote(entry, comment),
      ),
    );
    // Atualiza o ponto de status da tira após fechar o sheet.
    if (mounted) setState(() {});
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
              dataBuilder: _buildList,
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
          hasComment: _hasComment(entry),
          onTap: () => _openDetail(context, entry, chapter),
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
      padding: const EdgeInsets.only(bottom: 24),
      children: rows,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Paleta + ícone por capítulo
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
            if (count > 0)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: m.accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$count',
                    style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w700,
                        color: m.text)),
              ),
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
    required this.hasComment,
    required this.onTap,
  });

  final TimelineEntry entry;
  final LifeChapter? chapter;
  final bool hasComment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final m = _chapterMeta(chapter);
    final ageLabel =
        entry.ageAtEvent != null ? '${entry.ageAtEvent}a' : '—';

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEEF2F8))),
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
                SizedBox(
                  width: 26,
                  child: Text(ageLabel,
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: m.text)),
                ),
                const SizedBox(width: 8),
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
                // Ponto de status: turquesa = tem anotação, cinza = sem
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
                if (entry.emotionalImpact != null)
                  Text('${entry.emotionalImpact}',
                      style: const TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary)),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right_rounded,
                    size: 18, color: AppColors.textMuted),
                const SizedBox(width: 6),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom sheet de detalhe + comentário clínico
// ─────────────────────────────────────────────────────────────────────────────

class _EventDetailSheet extends StatefulWidget {
  const _EventDetailSheet({
    required this.entry,
    required this.chapter,
    required this.commentController,
    required this.ctx,
    required this.onSave,
  });

  final TimelineEntry entry;
  final LifeChapter? chapter;
  final TextEditingController commentController;
  final InitialAssessmentContext ctx;
  final Future<void> Function(String comment) onSave;

  @override
  State<_EventDetailSheet> createState() => _EventDetailSheetState();
}

class _EventDetailSheetState extends State<_EventDetailSheet> {
  bool _saving = false;

  Future<void> _handleSave() async {
    setState(() => _saving = true);
    try {
      await widget.onSave(widget.commentController.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentário salvo.')),
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
    final entry = widget.entry;
    final m = _chapterMeta(widget.chapter);
    final beliefs = entry.beliefs.map((b) => b.label).join(' · ');
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Fase + botão editar
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: m.bg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(m.icon, size: 13, color: m.accent),
                      const SizedBox(width: 5),
                      Text(
                        widget.chapter?.label ?? 'Outros',
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: m.text),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showTimelineEventEditor(
                        context: context,
                        ctx: widget.ctx,
                        entry: entry);
                  },
                  icon: const Icon(Icons.edit_outlined, size: 14),
                  label: const Text('Editar'),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textMuted,
                    textStyle: const TextStyle(fontSize: 12),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Título
            Text(
              entry.title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: AppColors.navy,
                  height: 1.2),
            ),
            const SizedBox(height: 6),

            // Metadados: idade · impacto
            if (entry.ageAtEvent != null || entry.emotionalImpact != null)
              Wrap(
                spacing: 16,
                children: [
                  if (entry.ageAtEvent != null)
                    _MetaChip(
                        icon: Icons.cake_outlined,
                        label: '${entry.ageAtEvent} anos'),
                  if (entry.emotionalImpact != null)
                    _MetaChip(
                        icon: Icons.bar_chart_rounded,
                        label: 'Impacto ${entry.emotionalImpact}/10'),
                ],
              ),

            // Descrição
            if ((entry.description ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                entry.description!.trim(),
                style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    height: 1.55),
              ),
            ],

            // Crenças
            if (beliefs.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.only(left: 10),
                decoration: BoxDecoration(
                  border: Border(left: BorderSide(color: m.accent, width: 2.5)),
                ),
                child: Text(
                  beliefs,
                  style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: m.text,
                      height: 1.45),
                ),
              ),
            ],

            // Divisor com rótulo
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10),
                  child: Text(
                    'COMENTÁRIO CLÍNICO',
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: .6,
                        color: AppColors.turquoise),
                  ),
                ),
                Expanded(child: Divider()),
              ],
            ),
            const SizedBox(height: 12),

            // Campo de anotação
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF0FCFA),
                border: Border.all(color: const Color(0xFF9EDDDA)),
                borderRadius: BorderRadius.circular(10),
              ),
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
              child: TextField(
                controller: widget.commentController,
                minLines: 3,
                maxLines: 8,
                autofocus: false,
                style: const TextStyle(
                    fontSize: 14, color: AppColors.navy, height: 1.5),
                decoration: const InputDecoration(
                  isDense: true,
                  hintText: 'Adicionar anotação clínica…',
                  hintStyle: TextStyle(
                      color: AppColors.textMuted, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Botão salvar
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving ? null : _handleSave,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.turquoise,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: _saving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.check),
                label: Text(_saving ? 'Salvando...' : 'Salvar comentário'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: AppColors.textMuted),
        const SizedBox(width: 4),
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary)),
      ],
    );
  }
}
