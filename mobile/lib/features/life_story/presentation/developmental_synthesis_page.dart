import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_banner.dart';
import '../domain/clinical_hypothesis.dart';
import '../domain/family_context.dart';
import '../domain/family_person.dart';
import '../domain/genogram_relationship_enums.dart';
import '../domain/life_story_deepen_enums.dart';
import '../domain/life_story_enums.dart';
import '../domain/life_timeline_event.dart';
import '../providers/life_story_providers.dart';
import 'life_story_routes.dart';

/// Síntese Desenvolvimental — integração das Telas 2 e 3 (spec §42). Organiza
/// os dados coletados em SETE blocos. Não produz conceitualização automática:
/// só reúne e apresenta o que o paciente registrou. As hipóteses clínicas
/// (§43) são um passo à parte, inteiramente editável pelo terapeuta.
class DevelopmentalSynthesisPage extends ConsumerWidget {
  const DevelopmentalSynthesisPage({super.key, required this.patientId});

  final String patientId;

  static const _prolongedRecurrences = {
    EventRecurrence.frequent,
    EventRecurrence.prolonged,
  };

  static const _protectiveNeeds = {
    RelationalNeed.affection,
    RelationalNeed.presence,
    RelationalNeed.protection,
    RelationalNeed.safety,
    RelationalNeed.stability,
    RelationalNeed.acceptance,
    RelationalNeed.validation,
    RelationalNeed.encouragement,
    RelationalNeed.confidence,
    RelationalNeed.understanding,
    RelationalNeed.guidance,
  };

  bool _isProlonged(LifeTimelineEvent e) =>
      _prolongedRecurrences.contains(e.eventRecurrence) ||
      e.ageFrom != null ||
      e.ageTo != null;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timelineAsync = ref.watch(timelineForPatientProvider(patientId));
    final familyAsync = ref.watch(familyForPatientProvider(patientId));
    final contextAsync = ref.watch(familyContextForPatientProvider(patientId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Síntese Desenvolvimental',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: timelineAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: OutlinedButton(
              onPressed: () =>
                  ref.invalidate(timelineForPatientProvider(patientId)),
              child: const Text('Tentar de novo'),
            ),
          ),
        ),
        data: (events) {
          final people = familyAsync.asData?.value ?? const <FamilyPerson>[];
          final famContext =
              contextAsync.asData?.value ?? const FamilyContext();
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              _intro(),
              _blockExperiences(events),
              _blockPeople(context, people),
              _blockNeeds(events, people),
              _blockFamilyContext(famContext),
              _blockPatterns(famContext),
              _blockMeanings(events),
              _blockPresentImpact(events),
              _HypothesesSection(patientId: patientId),
            ],
          );
        },
      ),
    );
  }

  Widget _intro() => const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text(
          'Organização dos dados registrados pelo paciente nas Telas 2 e 3. '
          'Não é uma conceitualização — as hipóteses ficam nos campos '
          'editáveis do terapeuta.',
          style: TextStyle(
              fontSize: 12.5, color: AppColors.textSecondary, height: 1.4),
        ),
      );

  // 1 · Experiências desenvolvimentais significativas ──────────────────────────
  Widget _blockExperiences(List<LifeTimelineEvent> events) {
    if (events.isEmpty) return const SizedBox.shrink();
    final prolonged = events.where(_isProlonged).toList();
    final punctual = events.where((e) => !_isProlonged(e)).toList();
    return _Block(
      number: 1,
      title: 'Experiências desenvolvimentais significativas',
      subtitle: 'Eventos pontuais e experiências prolongadas da Linha do Tempo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (punctual.isNotEmpty) ...[
            const _MiniLabel('Pontuais'),
            for (final e in punctual) _EventLine(event: e),
          ],
          if (prolonged.isNotEmpty) ...[
            if (punctual.isNotEmpty) const SizedBox(height: 10),
            const _MiniLabel('Prolongadas'),
            for (final e in prolonged) _EventLine(event: e),
          ],
        ],
      ),
    );
  }

  // 2 · Pessoas e figuras significativas ───────────────────────────────────────
  Widget _blockPeople(BuildContext context, List<FamilyPerson> people) {
    if (people.isEmpty) return const SizedBox.shrink();
    final caregivers = people
        .where((p) =>
            p.caregiverRole == CaregiverRole.important ||
            p.caregiverRole == CaregiverRole.partial)
        .toList();
    final protective = people
        .where((p) => p.receivedNeeds.any(_protectiveNeeds.contains))
        .toList();
    return _Block(
      number: 2,
      title: 'Pessoas e figuras significativas',
      subtitle: 'Cuidadores, figuras de apego e relações protetoras.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (caregivers.isNotEmpty) ...[
            const _MiniLabel('Figuras de cuidado/apego'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final p in caregivers) _PersonPill(person: p)],
            ),
          ],
          if (protective.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _MiniLabel('Relações protetoras'),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final p in protective) _PersonPill(person: p)],
            ),
          ],
        ],
      ),
    );
  }

  // 3 · Necessidades emocionais ────────────────────────────────────────────────
  Widget _blockNeeds(
      List<LifeTimelineEvent> events, List<FamilyPerson> people) {
    final timelineNeeds = <EmotionalNeed>{
      for (final e in events) ...e.needs,
    }.toList();
    final received = <RelationalNeed>{
      for (final p in people) ...p.receivedNeeds,
    }.toList();
    final wished = <RelationalNeed>{
      for (final p in people) ...p.wishedMoreNeeds,
    }.toList();
    if (timelineNeeds.isEmpty && received.isEmpty && wished.isEmpty) {
      return const SizedBox.shrink();
    }
    return _Block(
      number: 3,
      title: 'Necessidades emocionais',
      subtitle: 'Indicadores das experiências (Tela 2) e dos vínculos (Tela 3).',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (timelineNeeds.isNotEmpty) ...[
            const _MiniLabel('Na Linha do Tempo'),
            const SizedBox(height: 6),
            _Chips(labels: timelineNeeds.map((n) => n.label).toList()),
          ],
          if (received.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _MiniLabel('Atendidas nos vínculos'),
            const SizedBox(height: 6),
            _Chips(
                labels: received.map((n) => n.label).toList(),
                color: const Color(0xFFE7F1EC),
                textColor: const Color(0xFF2E7D6B)),
          ],
          if (wished.isNotEmpty) ...[
            const SizedBox(height: 12),
            const _MiniLabel('Indicadores de frustração'),
            const SizedBox(height: 6),
            _Chips(
                labels: wished.map((n) => n.label).toList(),
                color: const Color(0xFFF6ECE0),
                textColor: const Color(0xFFB5651D)),
          ],
        ],
      ),
    );
  }

  // 4 · Contexto familiar ──────────────────────────────────────────────────────
  Widget _blockFamilyContext(FamilyContext c) {
    if (c.climateTraits.isEmpty && (c.climateNote ?? '').trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return _Block(
      number: 4,
      title: 'Contexto familiar',
      subtitle: 'Clima emocional predominante.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (c.climateTraits.isNotEmpty)
            _Chips(labels: c.climateTraits.map((t) => t.label).toList()),
          if ((c.climateNote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('"${c.climateNote!.trim()}"',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  // 5 · Padrões transgeracionais ───────────────────────────────────────────────
  Widget _blockPatterns(FamilyContext c) {
    if (c.hasPatterns == null && c.patternTraits.isEmpty) {
      return const SizedBox.shrink();
    }
    return _Block(
      number: 5,
      title: 'Padrões transgeracionais',
      subtitle: 'Repetições percebidas em diferentes gerações.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (c.patternTraits.isNotEmpty)
            _Chips(labels: c.patternTraits.map((p) => p.label).toList()),
          if (c.patternGenerations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('Gerações: ${c.patternGenerations.map((g) => g.label).join(", ")}',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }

  // 6 · Significados relatados pelo paciente ───────────────────────────────────
  Widget _blockMeanings(List<LifeTimelineEvent> events) {
    final withMeaning =
        events.where((e) => (e.meaning ?? '').trim().isNotEmpty).toList();
    if (withMeaning.isEmpty) return const SizedBox.shrink();
    return _Block(
      number: 6,
      title: 'Significados relatados pelo paciente',
      subtitle: 'Frases espontâneas registradas na Linha do Tempo.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in withMeaning)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted)),
                  const SizedBox(height: 2),
                  Text('"${e.meaning!.trim()}"',
                      style: const TextStyle(
                          fontSize: 13.5,
                          color: AppColors.navy,
                          height: 1.4,
                          fontStyle: FontStyle.italic)),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // 7 · Repercussões atuais percebidas ─────────────────────────────────────────
  Widget _blockPresentImpact(List<LifeTimelineEvent> events) {
    final areas = <PresentArea>{
      for (final e in events) ...e.presentAreas,
    }.toList();
    if (areas.isEmpty) return const SizedBox.shrink();
    return _Block(
      number: 7,
      title: 'Repercussões atuais percebidas',
      subtitle:
          'Áreas da vida que o paciente relaciona às experiências anteriores.',
      child: _Chips(labels: areas.map((a) => a.label).toList()),
    );
  }
}

// ── Peças de UI ──────────────────────────────────────────────────────────────

class _Block extends StatelessWidget {
  const _Block({
    required this.number,
    required this.title,
    this.subtitle,
    required this.child,
  });
  final int number;
  final String title;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.navy,
                  shape: BoxShape.circle,
                ),
                child: Text('$number',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy)),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.only(left: 32),
              child: Text(subtitle!,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _MiniLabel extends StatelessWidget {
  const _MiniLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
            color: AppColors.turquoise));
  }
}

class _EventLine extends StatelessWidget {
  const _EventLine({required this.event});
  final LifeTimelineEvent event;

  String get _age {
    if (event.ageFrom != null && event.ageTo != null) {
      return '${event.ageFrom}–${event.ageTo} anos';
    }
    if (event.ageAtEvent != null) return '${event.ageAtEvent} anos';
    return event.lifeChapter?.label ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5, right: 8),
            child: Icon(Icons.circle, size: 6, color: AppColors.turquoise),
          ),
          Expanded(
            child: Text.rich(
              TextSpan(
                style: const TextStyle(
                    fontSize: 13.5, color: AppColors.navy, height: 1.35),
                children: [
                  TextSpan(
                      text: event.title,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (_age.isNotEmpty)
                    TextSpan(
                        text: '  ·  $_age',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Chip de pessoa que abre o cartão clínico (§40).
class _PersonPill extends StatelessWidget {
  const _PersonPill({required this.person});
  final FamilyPerson person;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(
        LifeStoryRoutes.therapistPersonCard,
        extra: person,
      ),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FE),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFDDE7F7)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(person.fullName,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy)),
            if (person.role != null) ...[
              const SizedBox(width: 6),
              Text('· ${person.role!.label}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary)),
            ],
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right,
                size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

/// Hipóteses para Conceitualização (§43) — campos editáveis do terapeuta,
/// abaixo da síntese. O app organiza, mas não preenche.
class _HypothesesSection extends ConsumerWidget {
  const _HypothesesSection({required this.patientId});
  final String patientId;

  Future<void> _add(
      BuildContext context, WidgetRef ref, HypothesisKind kind) async {
    final text = await _editSheet(context, title: kind.addLabel);
    if (text == null || text.trim().isEmpty) return;
    try {
      await ref.read(saveHypothesisProvider.notifier).add(
            patientId: patientId,
            kind: kind,
            body: text.trim(),
          );
    } catch (e) {
      if (context.mounted) showErrorBanner(context, e);
    }
  }

  Future<void> _openEntry(
      BuildContext context, WidgetRef ref, ClinicalHypothesis h) async {
    final result = await _editSheet(
      context,
      title: h.kind.addLabel,
      initial: h.body,
      allowDelete: true,
    );
    if (result == null) return;
    try {
      if (result == _deleteSentinel) {
        await ref
            .read(saveHypothesisProvider.notifier)
            .remove(patientId: patientId, id: h.id);
      } else if (result.trim().isNotEmpty) {
        await ref
            .read(saveHypothesisProvider.notifier)
            .edit(patientId: patientId, id: h.id, body: result.trim());
      }
    } catch (e) {
      if (context.mounted) showErrorBanner(context, e);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hypothesesAsync = ref.watch(hypothesesForPatientProvider(patientId));
    final all = hypothesesAsync.asData?.value ?? const <ClinicalHypothesis>[];

    return _Block(
      number: 8,
      title: 'Hipóteses para Conceitualização',
      subtitle:
          'Campos do terapeuta. O app organiza os dados, mas não preenche '
          'hipóteses clínicas.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in kHypothesisKindsInOrder)
                OutlinedButton.icon(
                  onPressed: () => _add(context, ref, kind),
                  icon: const Icon(Icons.add, size: 16),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.navy,
                    side: const BorderSide(color: AppColors.border),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  label: Text(kind.addLabel,
                      style: const TextStyle(fontSize: 12.5)),
                ),
            ],
          ),
          for (final kind in kHypothesisKindsInOrder)
            if (all.where((h) => h.kind == kind).isNotEmpty) ...[
              const SizedBox(height: 14),
              _MiniLabel(kind.groupLabel),
              const SizedBox(height: 6),
              for (final h in all.where((h) => h.kind == kind))
                _HypothesisCard(
                  hypothesis: h,
                  onTap: () => _openEntry(context, ref, h),
                ),
            ],
        ],
      ),
    );
  }
}

const _deleteSentinel = '__hypothesis_delete__';

/// Folha de edição de uma hipótese. Devolve o texto, `_deleteSentinel` para
/// remover, ou `null` se cancelado.
Future<String?> _editSheet(
  BuildContext context, {
  required String title,
  String initial = '',
  bool allowDelete = false,
}) {
  final controller = TextEditingController(text: initial);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (sheetContext) {
      final bottom = MediaQuery.viewInsetsOf(sheetContext).bottom;
      return Padding(
        padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy)),
            const SizedBox(height: 4),
            const Text('Campo privado — visível apenas para a equipe.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            const SizedBox(height: 14),
            TextField(
              controller: controller,
              maxLines: 5,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'Escreva a hipótese...',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                if (allowDelete)
                  TextButton.icon(
                    onPressed: () =>
                        Navigator.of(sheetContext).pop(_deleteSentinel),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.error),
                    label: const Text('Remover'),
                  ),
                const Spacer(),
                FilledButton(
                  onPressed: () {
                    final text = controller.text.trim();
                    if (text.isEmpty) return;
                    Navigator.of(sheetContext).pop(text);
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    minimumSize: const Size(120, 46),
                  ),
                  child: const Text('Salvar'),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

class _HypothesisCard extends StatelessWidget {
  const _HypothesisCard({required this.hypothesis, required this.onTap});
  final ClinicalHypothesis hypothesis;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F5EF),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFE6E0D2)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(hypothesis.body,
                  style: const TextStyle(
                      fontSize: 13.5, color: AppColors.navy, height: 1.45)),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.edit_outlined, size: 16, color: AppColors.textMuted),
          ],
        ),
      ),
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.labels,
    this.color = const Color(0xFFEEF2F7),
    this.textColor = AppColors.navy,
  });
  final List<String> labels;
  final Color color;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final l in labels)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(l,
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
          ),
      ],
    );
  }
}
