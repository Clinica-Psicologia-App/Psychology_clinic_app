import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../daily_monitors/providers/daily_monitors_providers.dart';
import '../../patients/presentation/widgets/patient_context_header.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/family_person.dart';
import '../domain/genogram_relationship_enums.dart';
import '../domain/life_story_enums.dart';
import 'life_story_routes.dart';

/// Cartão da pessoa — visão do paciente (spec §39). Só leitura: mostra, de forma
/// amigável e lúdica, o que o paciente já registrou sobre essa relação. Cada
/// bloco aparece apenas quando há dado. A partir daqui o paciente "conhece
/// melhor" (aprofunda/edita) a relação.
class PersonCardPage extends ConsumerWidget {
  const PersonCardPage({super.key, required this.person});

  final FamilyPerson person;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasData = person.hasRelationshipData;
    final patientIdAsync = ref.watch(myPatientIdProvider);

    final body = ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
      children: [
        // Cartão da pessoa (substituiu o header gradiente)
        _PersonMiniCard(person: person),
        const SizedBox(height: AppSpacing.md),
        if (!hasData) _EmptyRelation(person: person),
        if (person.bondType != null)
          _CardBlock(
            icon: Icons.favorite_outline,
            color: const Color(0xFFF48FB1),
            framing: 'Quando eu estava crescendo',
            label: 'Nossa relação era',
            child: Text(person.bondType!.label, style: _valueStyle),
          ),
        if (person.closeness != null)
          _CardBlock(
            icon: Icons.volunteer_activism_outlined,
            color: const Color(0xFF80CBC4),
            framing: 'Quando eu precisava',
            label: 'Quanto sentia que podia contar emocionalmente',
            child: _Score(value: person.closeness!),
          ),
        if (person.receivedNeeds.isNotEmpty)
          _CardBlock(
            icon: Icons.card_giftcard_outlined,
            color: const Color(0xFF9FA8DA),
            label: 'O que recebi',
            child: _Chips(
              labels: person.receivedNeeds.map((n) => n.label).toList(),
              color: const Color(0xFFEDEFFB),
              textColor: const Color(0xFF3F4A9E),
            ),
          ),
        if (person.wishedMoreNeeds.isNotEmpty)
          _CardBlock(
            icon: Icons.auto_awesome_outlined,
            color: const Color(0xFFFFB74D),
            label: 'O que gostaria de ter recebido mais',
            child: _Chips(
              labels: person.wishedMoreNeeds.map((n) => n.label).toList(),
              color: const Color(0xFFFFF3E0),
              textColor: const Color(0xFF9A6516),
            ),
          ),
        if (person.eventCount > 0) _MomentsBlock(person: person),
        const SizedBox(height: 20),
        if (hasData)
          OutlinedButton.icon(
            onPressed: () => context.push(
              LifeStoryRoutes.deepenRelationship,
              extra: person,
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.turquoise,
              side: const BorderSide(color: AppColors.turquoise),
              minimumSize: const Size.fromHeight(48),
            ),
            label: const Text('Completar ou editar'),
          ),
      ],
    );

    return patientIdAsync.when(
      loading: () => const AppCanopyScaffold(body: Center(child: BrandLoader())),
      error: (_, __) => const AppScaffold(
        title: 'Minha Família',
        accent: AppColors.cyan,
        body: Center(child: Text('Erro ao identificar paciente.')),
      ),
      data: (patientId) => AppCanopyScaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: PatientContextHeader(
                patientId: patientId,
                pageTitle: 'MINHA FAMÍLIA',
                role: ProfileRole.patient,
                accentColor: AppColors.cyan,
              ),
            ),
            SliverFillRemaining(hasScrollBody: true, child: body),
          ],
        ),
      ),
    );
  }
}

const _valueStyle = TextStyle(
    fontSize: 15.5,
    fontWeight: FontWeight.w600,
    color: AppColors.navy,
    height: 1.3);

/// Card que substitui o header gradiente: avatar, nome e papel da pessoa.
class _PersonMiniCard extends StatelessWidget {
  const _PersonMiniCard({required this.person});
  final FamilyPerson person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: AppColors.cyan.withValues(alpha: 0.15),
            child: Text(
              person.initials,
              style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.cyan),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        person.fullName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    if (person.isDeceased) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.local_florist_outlined,
                          size: 15, color: cs.onSurfaceVariant),
                    ],
                  ],
                ),
                if (person.role != null)
                  Text(
                    person.role!.label,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: cs.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Convite quando ainda não há camada emocional registrada.
class _EmptyRelation extends StatelessWidget {
  const _EmptyRelation({required this.person});
  final FamilyPerson person;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF2FBFA),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.35)),
      ),
      child: Column(
        children: [
          const Icon(Icons.favorite_border,
              size: 34, color: AppColors.turquoise),
          const SizedBox(height: 12),
          const Text(
            'Que tal conhecer melhor essa relação?',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.navy),
          ),
          const SizedBox(height: 8),
          const Text(
            'Vamos registrar como era esse vínculo, o que você recebeu e o que '
            'gostaria de ter recebido mais.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 13, color: AppColors.textSecondary, height: 1.5),
          ),
          const SizedBox(height: 18),
          FilledButton(
            onPressed: () => context.push(
              LifeStoryRoutes.deepenRelationship,
              extra: person,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.turquoise,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Conhecer melhor essa relação'),
          ),
        ],
      ),
    );
  }
}

/// Bloco visual de um item do cartão (símbolo + rótulo + conteúdo).
class _CardBlock extends StatelessWidget {
  const _CardBlock({
    required this.icon,
    required this.color,
    required this.label,
    required this.child,
    this.framing,
  });

  final IconData icon;
  final Color color;
  final String? framing;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 21, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (framing != null) ...[
                  Text(framing!,
                      style: const TextStyle(
                          fontSize: 11.5,
                          color: AppColors.textMuted,
                          fontStyle: FontStyle.italic)),
                  const SizedBox(height: 2),
                ],
                Text(label,
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Score extends StatelessWidget {
  const _Score({required this.value});
  final int value; // 0–10

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: value / 10,
              minHeight: 8,
              backgroundColor: const Color(0xFFE4EFEE),
              valueColor:
                  const AlwaysStoppedAnimation(Color(0xFF80CBC4)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text('$value/10',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.navy)),
      ],
    );
  }
}

class _Chips extends StatelessWidget {
  const _Chips({
    required this.labels,
    required this.color,
    required this.textColor,
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(l,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: textColor)),
          ),
      ],
    );
  }
}

class _MomentsBlock extends StatelessWidget {
  const _MomentsBlock({required this.person});
  final FamilyPerson person;

  int get count => person.eventCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FE),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFDDE7F7)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFDDE7F7),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timeline_outlined,
                size: 21, color: Color(0xFF2E5A9E)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Momentos da nossa história',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(
                    count == 1
                        ? '1 acontecimento'
                        : '$count acontecimentos',
                    style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.navy)),
              ],
            ),
          ),
          TextButton(
            onPressed: () => context.push(
              LifeStoryRoutes.personMoments,
              extra: person,
            ),
            child: const Text('Ver momentos'),
          ),
        ],
      ),
    );
  }
}
