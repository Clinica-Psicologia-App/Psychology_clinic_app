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
import 'widgets/life_chapter_style.dart';
import 'widgets/timeline_event_editor.dart';
import 'widgets/timeline_spine.dart';

/// Tela 2 do fluxo Conhecer — lente do terapeuta.
/// Espinha contínua do nascimento até hoje: a idade é o nó sobre o fio e os
/// capítulos são marcos no próprio fio, em vez de faixas que cortam a leitura.
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
    // Atualiza o selo "anotado" do nó após fechar o sheet.
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

    final rows = <Widget>[const TimelineBirthCap()];

    void addChapter(LifeChapter? chapter, List<TimelineEntry> entries) {
      rows.add(TimelineChapterMarker(
        chapter: chapter,
        onAdd: () => showTimelineEventEditor(
          context: context,
          ctx: _ctx,
          initialChapter: chapter,
        ),
      ));
      if (entries.isEmpty) {
        rows.add(const TimelineEmptyChapterHint());
        return;
      }
      for (final entry in entries) {
        rows.add(TimelineEventNode(
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

    rows.add(const TimelineTodayCap());

    return ListView(
      padding: const EdgeInsets.only(top: 10, bottom: 24),
      children: rows,
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
    final m = styleForChapter(widget.chapter);
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
