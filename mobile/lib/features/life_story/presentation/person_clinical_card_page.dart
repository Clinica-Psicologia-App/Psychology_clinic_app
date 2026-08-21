import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_banner.dart';
import '../domain/family_person.dart';
import '../domain/genogram_relationship_enums.dart';
import '../domain/life_story_enums.dart';
import '../providers/life_story_providers.dart';
import 'life_story_routes.dart';

/// Cartão da pessoa — visão do terapeuta (spec §40). Síntese só-leitura do que
/// o paciente registrou sobre essa figura: estrutura, papel de cuidado, vínculo
/// no desenvolvimento, experiência subjetiva, indicadores de necessidades e
/// relação atual. Não inventa escores — mostra apenas os dados coletados.
///
/// "Características relatadas" e "Disponibilidade emocional" (do exemplo da spec)
/// não têm origem no fluxo atual do paciente (Etapas 5 e 6 foram retiradas), por
/// isso não aparecem. Os comentários clínicos (campo privado) entram numa etapa
/// seguinte, com armazenamento restrito à equipe.
class PersonClinicalCardPage extends ConsumerWidget {
  const PersonClinicalCardPage({super.key, required this.person});

  final FamilyPerson person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: Text(
          person.role != null
              ? '${person.fullName} — ${person.role!.label}'
              : person.fullName,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
        children: [
          _Section(
            title: 'Estrutura',
            child: Column(
              children: [
                if (person.role != null)
                  _Row(label: 'Papel', value: person.role!.label),
                _Row(label: 'Situação', value: _situationLabel),
                if (person.ageApprox != null)
                  _Row(label: 'Idade', value: '${person.ageApprox} anos'),
              ],
            ),
          ),
          if (person.caregiverRole != null)
            _Section(
              title: 'Papel desenvolvimental',
              child: _Row(
                label: 'Figura significativa de cuidado',
                value: person.caregiverRole!.label,
              ),
            ),
          if (person.closeness != null ||
              person.conflict != null ||
              person.bondType != null)
            _Section(
              title: 'Vínculo durante o desenvolvimento',
              child: Column(
                children: [
                  if (person.closeness != null)
                    _ScoreRow(label: 'Proximidade', value: person.closeness!),
                  if (person.conflict != null)
                    _ScoreRow(label: 'Conflito', value: person.conflict!),
                  if (person.bondType != null)
                    _Row(label: 'Relação descrita', value: person.bondType!.label),
                  if ((person.bondChangeNote ?? '').trim().isNotEmpty)
                    _Row(label: 'Como mudou', value: person.bondChangeNote!.trim()),
                ],
              ),
            ),
          if (person.feltInRelationship.isNotEmpty)
            _Section(
              title: 'Experiência subjetiva do paciente',
              child: _ChipList(
                labels:
                    person.feltInRelationship.map((f) => f.label).toList(),
              ),
            ),
          if (person.receivedNeeds.isNotEmpty ||
              person.wishedMoreNeeds.isNotEmpty ||
              person.gotWhatNeeded)
            _Section(
              title: 'Necessidades emocionais — indicadores',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (person.receivedNeeds.isNotEmpty) ...[
                    _NeedGroup(
                      label: 'Atendidas',
                      color: const Color(0xFF2E7D6B),
                      labels: person.receivedNeeds.map((n) => n.label).toList(),
                    ),
                    const SizedBox(height: 10),
                  ],
                  if (person.wishedMoreNeeds.isNotEmpty)
                    _NeedGroup(
                      label: 'Indicadores de frustração',
                      color: const Color(0xFFB5651D),
                      labels:
                          person.wishedMoreNeeds.map((n) => n.label).toList(),
                    ),
                  if (person.gotWhatNeeded) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'O paciente sente que recebeu o que precisava.',
                      style: TextStyle(
                          fontSize: 12.5,
                          fontStyle: FontStyle.italic,
                          color: AppColors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          if (person.currentRelationship != null ||
              (person.currentRelationshipNote ?? '').trim().isNotEmpty)
            _Section(
              title: 'Relação atual',
              child: Column(
                children: [
                  if (person.currentRelationship != null)
                    _Row(
                        label: 'Hoje',
                        value: person.currentRelationship!.label),
                  if ((person.currentRelationshipNote ?? '').trim().isNotEmpty)
                    _Row(
                        label: 'Observação do paciente',
                        value: person.currentRelationshipNote!.trim()),
                ],
              ),
            ),
          if (person.eventCount > 0)
            _Section(
              title: 'Linha do Tempo',
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      person.eventCount == 1
                          ? '1 acontecimento relacionado'
                          : '${person.eventCount} acontecimentos relacionados',
                      style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.navy),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.push(
                      LifeStoryRoutes.personMoments,
                      extra: person,
                    ),
                    child: const Text('Ver acontecimentos'),
                  ),
                ],
              ),
            ),
          _ClinicalCommentSection(person: person),
        ],
      ),
    );
  }

  String get _situationLabel {
    switch (person.deceasedStatus) {
      case DeceasedStatus.yes:
        return person.deathAge != null
            ? 'Falecida (aos ${person.deathAge} anos)'
            : 'Falecida';
      case DeceasedStatus.no:
        return 'Viva';
      case DeceasedStatus.unknown:
      case null:
        return 'Não informado';
    }
  }
}

/// Comentários clínicos (§40) — campo PRIVADO da equipe. Um comentário por
/// pessoa, editável. Só aparece/salva quando há `patientId` (contexto real do
/// terapeuta).
class _ClinicalCommentSection extends ConsumerWidget {
  const _ClinicalCommentSection({required this.person});
  final FamilyPerson person;

  Future<void> _edit(
      BuildContext context, WidgetRef ref, String? current) async {
    final patientId = person.patientId;
    if (patientId == null) return;
    final controller = TextEditingController(text: current ?? '');
    final saved = await showModalBottomSheet<bool>(
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
              const Text('Comentário clínico',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy)),
              const SizedBox(height: 4),
              const Text('Campo privado — visível apenas para a equipe.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 5,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Observação sobre esta figura...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () async {
                  final text = controller.text.trim();
                  if (text.isEmpty) return;
                  try {
                    await ref
                        .read(saveClinicalCommentProvider.notifier)
                        .submit(
                          patientId: patientId,
                          personId: person.id,
                          comment: text,
                        );
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop(true);
                  } catch (e) {
                    if (sheetContext.mounted) showErrorBanner(sheetContext, e);
                  }
                },
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.navy,
                  minimumSize: const Size.fromHeight(48),
                ),
                child: const Text('Salvar'),
              ),
            ],
          ),
        );
      },
    );
    if (saved == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentário salvo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final commentAsync = person.patientId == null
        ? const AsyncValue<String?>.data(null)
        : ref.watch(personClinicalCommentProvider(person.id));
    final comment = commentAsync.asData?.value;
    final hasComment = (comment ?? '').trim().isNotEmpty;

    return _Section(
      title: 'Comentários clínicos',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Campo privado — visível apenas para a equipe.',
              style: TextStyle(
                  fontSize: 11.5,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textMuted)),
          const SizedBox(height: 10),
          if (hasComment)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F5EF),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE6E0D2)),
              ),
              child: Text(comment!.trim(),
                  style: const TextStyle(
                      fontSize: 13.5, color: AppColors.navy, height: 1.45)),
            ),
          if (person.patientId != null) ...[
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => _edit(context, ref, comment),
                icon: Icon(hasComment ? Icons.edit_outlined : Icons.add,
                    size: 18),
                label:
                    Text(hasComment ? 'Editar observação' : 'Adicionar observação'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.child});
  final String title;
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
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.turquoise)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy)),
          ),
        ],
      ),
    );
  }
}

class _ScoreRow extends StatelessWidget {
  const _ScoreRow({required this.label, required this.value});
  final String label;
  final int value; // 0–10

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 130,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(5),
              child: LinearProgressIndicator(
                value: value / 10,
                minHeight: 7,
                backgroundColor: const Color(0xFFE7EBF0),
                valueColor: const AlwaysStoppedAnimation(AppColors.turquoise),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text('$value/10',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy)),
        ],
      ),
    );
  }
}

class _ChipList extends StatelessWidget {
  const _ChipList({required this.labels});
  final List<String> labels;

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
              color: const Color(0xFFEEF2F7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(l,
                style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy)),
          ),
      ],
    );
  }
}

class _NeedGroup extends StatelessWidget {
  const _NeedGroup({
    required this.label,
    required this.color,
    required this.labels,
  });
  final String label;
  final Color color;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 6),
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: color)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final l in labels)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(l,
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: color)),
              ),
          ],
        ),
      ],
    );
  }
}
