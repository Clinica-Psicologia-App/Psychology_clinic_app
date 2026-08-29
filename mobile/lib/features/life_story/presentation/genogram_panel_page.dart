import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../domain/family_context.dart';
import '../domain/family_person.dart';
import '../domain/genogram_relationship_enums.dart';
import '../domain/life_story_enums.dart';
import '../providers/life_story_providers.dart';
import 'life_story_routes.dart';
import '../../genogram/presentation/genogram_routes.dart';
import '../../profile/domain/profile_role.dart';
import '../../../shared/widgets/brand_loading.dart';

/// Painel do terapeuta — Genograma (spec §41). Reúne, para uma pessoa/paciente,
/// os blocos de síntese do que o paciente registrou na Tela 3, e é o ponto de
/// entrada para o cartão clínico de cada figura (§40).
///
/// O bloco "Comentários Clínicos" (nível painel) e o genograma gráfico completo
/// (§36–38) entram depois — o gráfico com sua própria etapa e o comentário de
/// painel junto da Síntese/Hipóteses (§42–43), mesma classe de campo editável.
class GenogramPanelPage extends ConsumerWidget {
  const GenogramPanelPage({super.key, required this.patientId});

  final String patientId;

  /// Necessidades associadas a apoio, segurança, aceitação, incentivo e
  /// cuidado — base do bloco "Recursos e Fatores Protetores".
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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final familyAsync = ref.watch(familyForPatientProvider(patientId));
    final contextAsync = ref.watch(familyContextForPatientProvider(patientId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.navy,
        foregroundColor: Colors.white,
        title: const Text('Genograma',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      ),
      body: familyAsync.when(
        loading: () => const BrandLoader(),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: OutlinedButton(
              onPressed: () =>
                  ref.invalidate(familyForPatientProvider(patientId)),
              child: const Text('Tentar de novo'),
            ),
          ),
        ),
        data: (people) {
          final famContext = contextAsync.asData?.value ?? const FamilyContext();
          final caregivers = people
              .where((p) =>
                  p.caregiverRole == CaregiverRole.important ||
                  p.caregiverRole == CaregiverRole.partial)
              .toList();
          final withBond =
              people.where((p) => p.hasRelationshipData).toList();
          final protective = [
            for (final p in people)
              if (p.receivedNeeds.any(_protectiveNeeds.contains))
                (p, p.receivedNeeds.where(_protectiveNeeds.contains).toList()),
          ];

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
            children: [
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: FilledButton.icon(
                  onPressed: () => context.push(
                    LifeStoryRoutes.developmentalSynthesis,
                    extra: patientId,
                  ),
                  icon: const Icon(Icons.auto_stories_outlined, size: 18),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.navy,
                    minimumSize: const Size.fromHeight(48),
                  ),
                  label: const Text('Síntese Desenvolvimental'),
                ),
              ),
              // Superfície de edição: cadastrar/editar pessoas e relações. Este
              // painel é a visão; o construtor detalhado abre a partir daqui, de
              // modo que ver e editar convivem num só lugar.
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: OutlinedButton.icon(
                  onPressed: () => context.push(
                    GenogramRoutes.staffList(
                      role: ProfileRole.psychologist,
                      patientId: patientId,
                    ),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(46),
                  ),
                  label: const Text('Editar pessoas e relações'),
                ),
              ),
              // Bootstrap: infere os vínculos estruturais (casamento, pai/mãe–
              // filho) a partir dos papéis, para o terapeuta só confirmar.
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextButton.icon(
                  onPressed: () => context.push(
                    GenogramRoutes.staffBootstrap(
                      role: ProfileRole.psychologist,
                      patientId: patientId,
                    ),
                  ),
                  icon: const Icon(Icons.auto_fix_high_outlined, size: 18),
                  label: const Text('Sugerir vínculos a partir dos papéis'),
                ),
              ),
              _StructureBlock(people: people, patientId: patientId),
              if (caregivers.isNotEmpty)
                _FiguresBlock(people: caregivers, patientId: patientId),
              if (withBond.isNotEmpty) _BondsBlock(people: withBond),
              if (withBond.isNotEmpty) _NeedsBlock(people: withBond),
              if (famContext.climateTraits.isNotEmpty ||
                  (famContext.climateNote ?? '').trim().isNotEmpty)
                _ClimateBlock(context: famContext),
              if (famContext.hasPatterns != null ||
                  famContext.patternTraits.isNotEmpty)
                _PatternsBlock(context: famContext),
              if (protective.isNotEmpty) _ProtectiveBlock(items: protective),
            ],
          );
        },
      ),
    );
  }
}

// ── Blocos ───────────────────────────────────────────────────────────────────

class _Block extends StatelessWidget {
  const _Block({required this.title, this.subtitle, required this.child});
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
          Text(title.toUpperCase(),
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                  color: AppColors.turquoise)),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          const SizedBox(height: 12),
          child,
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

class _StructureBlock extends StatelessWidget {
  const _StructureBlock({required this.people, required this.patientId});
  final List<FamilyPerson> people;
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return _Block(
      title: 'Estrutura Familiar',
      subtitle: '${people.length} '
          '${people.length == 1 ? "pessoa identificada" : "pessoas identificadas"}. '
          'Toque para abrir o cartão da pessoa.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          OutlinedButton.icon(
            onPressed: () => context.push(
              LifeStoryRoutes.genogramDiagram,
              extra: patientId,
            ),
            icon: const Icon(Icons.account_tree_outlined, size: 18),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.navy,
              side: const BorderSide(color: AppColors.border),
              minimumSize: const Size.fromHeight(44),
            ),
            label: const Text('Ver genograma gráfico'),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final p in people) _PersonPill(person: p)],
          ),
        ],
      ),
    );
  }
}

class _FiguresBlock extends StatelessWidget {
  const _FiguresBlock({required this.people, required this.patientId});
  final List<FamilyPerson> people;
  final String patientId;

  @override
  Widget build(BuildContext context) {
    return _Block(
      title: 'Figuras Significativas de Cuidado/Apego',
      subtitle: 'Identificadas a partir dos dados do paciente.',
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [for (final p in people) _PersonPill(person: p)],
      ),
    );
  }
}

class _BondsBlock extends StatelessWidget {
  const _BondsBlock({required this.people});
  final List<FamilyPerson> people;

  @override
  Widget build(BuildContext context) {
    return _Block(
      title: 'Vínculos',
      subtitle: 'Proximidade, conflito e evolução da relação.',
      child: Column(
        children: [
          for (final p in people)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.fullName,
                      style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.navy)),
                  const SizedBox(height: 6),
                  if (p.closeness != null)
                    _MiniScore(label: 'Proximidade', value: p.closeness!),
                  if (p.conflict != null)
                    _MiniScore(label: 'Conflito', value: p.conflict!),
                  if (p.bondType != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(p.bondType!.label,
                          style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary)),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _MiniScore extends StatelessWidget {
  const _MiniScore({required this.label, required this.value});
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value / 10,
                minHeight: 6,
                backgroundColor: const Color(0xFFE7EBF0),
                valueColor: const AlwaysStoppedAnimation(AppColors.turquoise),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text('$value/10',
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy)),
        ],
      ),
    );
  }
}

class _NeedsBlock extends StatelessWidget {
  const _NeedsBlock({required this.people});
  final List<FamilyPerson> people;

  @override
  Widget build(BuildContext context) {
    return _Block(
      title: 'Necessidades Emocionais',
      subtitle: 'Indicadores de atendimento e frustração por figura.',
      child: Column(
        children: [
          for (final p in people)
            if (p.receivedNeeds.isNotEmpty || p.wishedMoreNeeds.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.fullName,
                        style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy)),
                    const SizedBox(height: 6),
                    if (p.receivedNeeds.isNotEmpty)
                      _NeedLine(
                        color: const Color(0xFF2E7D6B),
                        label: 'Atendidas',
                        value: p.receivedNeeds.map((n) => n.label).join(', '),
                      ),
                    if (p.wishedMoreNeeds.isNotEmpty)
                      _NeedLine(
                        color: const Color(0xFFB5651D),
                        label: 'Frustração',
                        value:
                            p.wishedMoreNeeds.map((n) => n.label).join(', '),
                      ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _NeedLine extends StatelessWidget {
  const _NeedLine({
    required this.color,
    required this.label,
    required this.value,
  });
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 5, right: 6),
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          SizedBox(
            width: 74,
            child: Text(label,
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700, color: color)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.navy, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

class _ClimateBlock extends StatelessWidget {
  const _ClimateBlock({required this.context});
  final FamilyContext context;

  @override
  Widget build(BuildContext ctx) {
    return _Block(
      title: 'Clima Familiar',
      subtitle: 'Características predominantes da família de origem.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _WrapChips(labels: context.climateTraits.map((c) => c.label).toList()),
          if ((context.climateNote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Text('"${context.climateNote!.trim()}"',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _PatternsBlock extends StatelessWidget {
  const _PatternsBlock({required this.context});
  final FamilyContext context;

  @override
  Widget build(BuildContext ctx) {
    return _Block(
      title: 'Padrões Transgeracionais',
      subtitle: 'Padrões identificados pelo paciente e gerações relacionadas.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (context.hasPatterns != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text('Percebe repetições: ${context.hasPatterns!.label}',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy)),
            ),
          if (context.patternTraits.isNotEmpty)
            _WrapChips(
                labels: context.patternTraits.map((p) => p.label).toList()),
          if (context.patternGenerations.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'Gerações: '
              '${context.patternGenerations.map((g) => g.label).join(", ")}',
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary),
            ),
          ],
          if ((context.patternsNote ?? '').trim().isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('"${context.patternsNote!.trim()}"',
                style: const TextStyle(
                    fontSize: 12.5,
                    fontStyle: FontStyle.italic,
                    color: AppColors.textSecondary)),
          ],
        ],
      ),
    );
  }
}

class _ProtectiveBlock extends StatelessWidget {
  const _ProtectiveBlock({required this.items});
  final List<(FamilyPerson, List<RelationalNeed>)> items;

  @override
  Widget build(BuildContext context) {
    return _Block(
      title: 'Recursos e Fatores Protetores',
      subtitle:
          'Pessoas e relações associadas a apoio, segurança, aceitação, '
          'incentivo e cuidado.',
      child: Column(
        children: [
          for (final (person, needs) in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined,
                          size: 16, color: Color(0xFF2E7D6B)),
                      const SizedBox(width: 6),
                      Text(person.fullName,
                          style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(needs.map((n) => n.label).join(', '),
                      style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                          height: 1.35)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _WrapChips extends StatelessWidget {
  const _WrapChips({required this.labels});
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
