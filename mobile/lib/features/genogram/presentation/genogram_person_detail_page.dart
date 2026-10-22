import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../patient_timeline/domain/patient_timeline_event.dart';
import '../../patient_timeline/presentation/patient_timeline_routes.dart';
import '../../patient_timeline/presentation/widgets/patient_timeline_widgets.dart';
import '../../patient_timeline/providers/patient_timeline_providers.dart';
import '../../patients/presentation/widgets/patient_context_header.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/genogram_data.dart';
import '../domain/genogram_gender.dart';
import '../domain/genogram_person.dart';
import '../domain/genogram_relationship.dart';
import '../domain/genogram_relationship_type.dart';
import '../providers/genogram_providers.dart';
import 'genogram_routes.dart';
import '../../../shared/widgets/brand_loading.dart';

class GenogramPersonDetailPage extends ConsumerWidget {
  const GenogramPersonDetailPage({
    super.key,
    required this.role,
    required this.personId,
    this.patientId,
  });

  final ProfileRole role;
  final String personId;
  final String? patientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final personAsync = ref.watch(genogramPersonDetailProvider(personId));

    return personAsync.when(
      loading: () => AppScaffold(
        title: 'Pessoa',
        accent: AppColors.success,
        body: const BrandLoader(),
      ),
      error: (_, __) => AppScaffold(
        title: 'Pessoa',
        accent: AppColors.success,
        body: Center(
          child: FilledButton(
            onPressed: () =>
                ref.invalidate(genogramPersonDetailProvider(personId)),
            child: const Text('Tentar novamente'),
          ),
        ),
      ),
      data: (person) {
        if (person == null) {
          return AppScaffold(
            title: 'Pessoa',
            accent: AppColors.success,
            body: const Center(child: Text('Pessoa não encontrada.')),
          );
        }

        return AppCanopyScaffold(
          body: _PersonDetailBody(
            person: person,
            role: role,
            patientId: patientId,
            onChanged: () {
              ref.invalidate(genogramPersonDetailProvider(personId));
              _refreshLists(ref);
            },
          ),
        );
      },
    );
  }

  void _refreshLists(WidgetRef ref) {
    if (role == ProfileRole.patient) {
      ref.read(myGenogramProvider.notifier).refresh();
    } else if (patientId != null) {
      ref.invalidate(
        staffGenogramProvider(
          StaffGenogramContext(role: role, patientId: patientId!),
        ),
      );
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _PersonDetailBody extends ConsumerStatefulWidget {
  const _PersonDetailBody({
    required this.person,
    required this.role,
    required this.patientId,
    required this.onChanged,
  });

  final GenogramPerson person;
  final ProfileRole role;
  final String? patientId;
  final VoidCallback onChanged;

  @override
  ConsumerState<_PersonDetailBody> createState() => _PersonDetailBodyState();
}

class _PersonDetailBodyState extends ConsumerState<_PersonDetailBody> {
  bool _navigating = false;

  String get _editRoute => widget.role == ProfileRole.patient
      ? GenogramRoutes.patientPersonEdit(widget.person.id)
      : GenogramRoutes.personEditFor(
          widget.patientId ?? widget.person.patientId,
          widget.person.id,
        );

  Future<void> _push(String route, {bool returnsResult = false}) async {
    if (_navigating || !mounted) return;
    setState(() => _navigating = true);
    try {
      if (returnsResult) {
        final updated = await context.push<bool>(route);
        if (mounted && updated == true) widget.onChanged();
      } else {
        await context.push(route);
        if (mounted) widget.onChanged();
      }
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final person = widget.person;
    final role = widget.role;
    final patientId = widget.patientId;

    final genogramAsync = role == ProfileRole.patient
        ? ref.watch(myGenogramProvider)
        : ref.watch(
            staffGenogramProvider(
              StaffGenogramContext(
                role: role,
                patientId: patientId!,
              ),
            ),
          );

    return genogramAsync.when(
      loading: () => const BrandLoader(),
      error: (_, __) => const Center(child: Text('Erro ao carregar relações.')),
      data: (data) {
        final linked =
            data.relationships.where((r) => r.involvesPerson(person.id)).toList();

        final bodyContent = Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.md,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (patientId != null) ...[
                AppPageHeader(
                  icon: Icons.person_outline_rounded,
                  title: person.displayName,
                  subtitle: 'Pessoa no genograma',
                  metadata: [
                    if (person.relationshipToPatient != null &&
                        person.relationshipToPatient!.trim().isNotEmpty)
                      _TagChip(person.relationshipToPatient!.trim()),
                    if (person.gender != null)
                      _TagChip(person.gender!.label),
                    if (person.lifeSpanLabel != null)
                      _TagChip(person.lifeSpanLabel!),
                    if (person.isDeceased) const _TagChip('Falecido'),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (person.isSensitive) ...[
                const AppInfoCard(
                  title: 'Dados sensíveis',
                  body:
                      'As informações foram ocultadas na visualização principal.',
                  icon: Icons.lock_outline,
                  tone: AppInfoCardTone.error,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (person.notes != null &&
                  person.notes!.trim().isNotEmpty) ...[
                AppInfoCard(
                  title: 'Observações',
                  body: person.notes!.trim(),
                  icon: Icons.notes_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              _SectionLabel(
                '${linked.length} relação${linked.length == 1 ? '' : 'ões'} vinculada${linked.length == 1 ? '' : 's'}',
              ),
              const SizedBox(height: AppSpacing.sm),
              if (linked.isEmpty)
                const AppInfoCard(
                  title: 'Nenhuma relação cadastrada',
                  body:
                      'Ainda não há vínculo registrado com esta pessoa.',
                  icon: Icons.account_tree_outlined,
                )
              else
                Column(
                  children: [
                    for (final r in linked) ...[
                      _RelationshipNaturalCard(
                        relationship: r,
                        currentPerson: person,
                        data: data,
                        onTap: _navigating
                            ? null
                            : () => _push(
                                  role == ProfileRole.patient
                                      ? GenogramRoutes
                                          .patientRelationshipDetail(r.id)
                                      : GenogramRoutes
                                          .relationshipDetailFor(
                                              patientId!, r.id),
                                ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                    ],
                  ],
                ),
              const SizedBox(height: AppSpacing.xl),
              const AppSectionHeader(
                title: 'Linha do tempo',
                subtitle: 'Acontecimentos registrados desta pessoa.',
              ),
              const SizedBox(height: AppSpacing.sm),
              _PersonTimelineSection(
                person: person,
                role: role,
                patientId: patientId,
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
          ),
        );

        final editBtn = Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: FilledButton.icon(
            onPressed: _navigating
                ? null
                : () => _push(_editRoute, returnsResult: true),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Editar pessoa'),
          ),
        );

        if (patientId != null) {
          return MotionReveal(
            child: Column(
              children: [
                Expanded(
                  child: CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(
                        child: PatientContextHeader(
                          patientId: patientId!,
                          pageTitle: 'GENOGRAMA',
                          role: role,
                          accentColor: AppColors.cyan,
                          actions: [
                            PatientHeaderActionBtn(
                              icon: Icons.edit_outlined,
                              label: 'Editar',
                              onTap: _navigating
                                  ? null
                                  : () => _push(_editRoute, returnsResult: true),
                            ),
                          ],
                        ),
                      ),
                      SliverToBoxAdapter(child: bodyContent),
                    ],
                  ),
                ),
                editBtn,
              ],
            ),
          );
        }

        return MotionReveal(
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _PersonHeroHeader(
                      person: person,
                      onEdit: _navigating
                          ? null
                          : () => _push(_editRoute, returnsResult: true),
                    ),
                    bodyContent,
                  ],
                ),
              ),
              editBtn,
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Hero header — gradiente com avatar, nome e tags

class _PersonHeroHeader extends StatelessWidget {
  const _PersonHeroHeader({
    required this.person,
    this.onEdit,
  });

  final GenogramPerson person;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF063530), Color(0xFF1D9E75)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top bar com back + label + editar
          Padding(
            padding: EdgeInsets.fromLTRB(12, topInset + 10, 12, 0),
            child: Row(
              children: [
                _HeroIconButton(
                  onPressed: () => context.pop(),
                  child: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 16, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Text(
                  'Genograma',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const Spacer(),
                if (onEdit != null)
                  TextButton.icon(
                    onPressed: onEdit,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20)),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 14),
                    label: const Text('Editar',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          // Avatar + nome + tags
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _PersonAvatar(person: person),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        person.displayName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 21,
                            ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Pessoa no genograma',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          if (person.relationshipToPatient != null &&
                              person.relationshipToPatient!.trim().isNotEmpty)
                            _HeroChip(person.relationshipToPatient!.trim()),
                          if (person.gender != null)
                            _HeroChip(person.gender!.label),
                          if (person.lifeSpanLabel != null)
                            _HeroChip(person.lifeSpanLabel!),
                          if (person.isDeceased) const _HeroChip('Falecido'),
                        ],
                      ),
                    ],
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

class _PersonAvatar extends StatelessWidget {
  const _PersonAvatar({required this.person});

  final GenogramPerson person;

  @override
  Widget build(BuildContext context) {
    final initials = _initials(person.displayName);
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.38), width: 2),
      ),
      alignment: Alignment.center,
      child: person.isSensitive
          ? const Icon(Icons.lock_outline, color: Colors.white, size: 24)
          : Text(
              initials,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 20,
              ),
            ),
    );
  }
}

class _HeroChip extends StatelessWidget {
  const _HeroChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
        ),
      );
}

class _HeroIconButton extends StatelessWidget {
  const _HeroIconButton({required this.onPressed, required this.child});
  final VoidCallback onPressed;
  final Widget child;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onPressed,
        child: Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.18),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: child,
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip compacto para metadados de pessoa no AppPageHeader

class _TagChip extends StatelessWidget {
  const _TagChip(this.label);
  final String label;

  @override
  Widget build(BuildContext context) => Chip(
        label: Text(label),
        labelStyle: Theme.of(context).textTheme.labelSmall,
        padding: EdgeInsets.zero,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        visualDensity: VisualDensity.compact,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Label de seção estilo capsule

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w700,
            ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Card de relação — barra lateral colorida + linguagem natural

class _RelationshipNaturalCard extends StatelessWidget {
  const _RelationshipNaturalCard({
    required this.relationship,
    required this.currentPerson,
    required this.data,
    this.onTap,
  });

  final GenogramRelationship relationship;
  final GenogramPerson currentPerson;
  final GenogramData data;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final type = relationship.relationshipType;
    final barColor = _barColor(type);
    final badgeBg = _badgeBg(type);
    final badgeFg = _badgeFg(type);
    final categoryLabel = _categoryLabel(type);
    final sentence = _buildSentence(relationship, currentPerson, data);
    final highlightName = currentPerson.displayName;

    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              // Barra lateral colorida
              Container(
                width: 3,
                height: 42,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Conteúdo
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _HighlightedText(
                      sentence: sentence,
                      highlight: highlightName,
                      highlightColor: const Color(0xFF1D9E75),
                      baseStyle: Theme.of(context).textTheme.bodyMedium!.copyWith(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        categoryLabel,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: badgeFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Seta
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.chevron_right_rounded,
                    size: 18, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Texto com nome da pessoa em destaque (verde)
class _HighlightedText extends StatelessWidget {
  const _HighlightedText({
    required this.sentence,
    required this.highlight,
    required this.highlightColor,
    required this.baseStyle,
  });

  final String sentence;
  final String highlight;
  final Color highlightColor;
  final TextStyle baseStyle;

  @override
  Widget build(BuildContext context) {
    final parts = sentence.split(highlight);
    if (parts.length == 1) return Text(sentence, style: baseStyle);

    return RichText(
      text: TextSpan(
        children: [
          for (int i = 0; i < parts.length; i++) ...[
            TextSpan(text: parts[i], style: baseStyle),
            if (i < parts.length - 1)
              TextSpan(
                text: highlight,
                style: baseStyle.copyWith(
                  color: highlightColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers

String _initials(String name) {
  final parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts[0][0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

String _buildSentence(
  GenogramRelationship r,
  GenogramPerson currentPerson,
  GenogramData data,
) {
  final currentName = currentPerson.displayName;
  final otherId = r.otherPersonId(currentPerson.id);
  final otherName = otherId != null ? data.personNameById(otherId) : 'Pessoa';
  final isCurrentA = r.personAId == currentPerson.id;

  switch (r.relationshipType) {
    case GenogramRelationshipType.parentChild:
      if (isCurrentA) {
        // currentPerson is the parent
        final parentWord = _parentWord(currentPerson.gender);
        return '$currentName é $parentWord de $otherName';
      } else {
        // otherPerson is the parent
        final otherPerson =
            otherId != null ? _findPerson(data, otherId) : null;
        final parentWord = _parentWord(otherPerson?.gender);
        return '$otherName é $parentWord de $currentName';
      }
    case GenogramRelationshipType.sibling:
      return '$currentName e $otherName são irmãos(ãs)';
    case GenogramRelationshipType.twin:
      return '$currentName e $otherName são gêmeos(as)';
    case GenogramRelationshipType.spouse:
      return '$currentName casado(a) com $otherName';
    case GenogramRelationshipType.exSpouse:
      return '$currentName ex-cônjuge de $otherName';
    case GenogramRelationshipType.separation:
      return '$currentName separado(a) de $otherName';
    case GenogramRelationshipType.conflict:
      return '$currentName tem relação conflituosa com $otherName';
    case GenogramRelationshipType.distant:
      return '$currentName tem relação distante com $otherName';
    case GenogramRelationshipType.neutral:
      return '$currentName tem relação neutra com $otherName';
    case GenogramRelationshipType.close:
      return '$currentName tem relação próxima com $otherName';
    case GenogramRelationshipType.closeAndConflict:
      return '$currentName tem relação próxima e conflituosa com $otherName';
    case GenogramRelationshipType.ruptured:
      return 'Vínculo rompido entre $currentName e $otherName';
    case GenogramRelationshipType.other:
      return '$currentName — vínculo com $otherName';
  }
}

String _parentWord(GenogramGender? gender) {
  if (gender == GenogramGender.male) return 'pai';
  if (gender == GenogramGender.female) return 'mãe';
  return 'pai/mãe';
}

GenogramPerson? _findPerson(GenogramData data, String id) {
  for (final p in data.people) {
    if (p.id == id) return p;
  }
  return null;
}

String _categoryLabel(GenogramRelationshipType type) {
  switch (type) {
    case GenogramRelationshipType.parentChild:
    case GenogramRelationshipType.sibling:
    case GenogramRelationshipType.twin:
      return 'Parentesco';
    case GenogramRelationshipType.spouse:
    case GenogramRelationshipType.exSpouse:
    case GenogramRelationshipType.separation:
      return 'Conjugal';
    case GenogramRelationshipType.conflict:
    case GenogramRelationshipType.closeAndConflict:
    case GenogramRelationshipType.ruptured:
      return 'Conflito';
    case GenogramRelationshipType.close:
    case GenogramRelationshipType.neutral:
    case GenogramRelationshipType.distant:
      return 'Vínculo emocional';
    case GenogramRelationshipType.other:
      return 'Outro';
  }
}

Color _barColor(GenogramRelationshipType type) {
  switch (type) {
    case GenogramRelationshipType.parentChild:
    case GenogramRelationshipType.sibling:
    case GenogramRelationshipType.twin:
      return AppColors.success;
    case GenogramRelationshipType.spouse:
    case GenogramRelationshipType.exSpouse:
    case GenogramRelationshipType.separation:
      return const Color(0xFFD85A30);
    case GenogramRelationshipType.conflict:
    case GenogramRelationshipType.closeAndConflict:
    case GenogramRelationshipType.ruptured:
      return AppColors.warning;
    case GenogramRelationshipType.close:
    case GenogramRelationshipType.neutral:
    case GenogramRelationshipType.distant:
      return AppColors.blue;
    case GenogramRelationshipType.other:
      return AppColors.disabled;
  }
}

Color _badgeBg(GenogramRelationshipType type) {
  switch (type) {
    case GenogramRelationshipType.parentChild:
    case GenogramRelationshipType.sibling:
    case GenogramRelationshipType.twin:
      return AppColors.successContainer;
    case GenogramRelationshipType.spouse:
    case GenogramRelationshipType.exSpouse:
    case GenogramRelationshipType.separation:
      return const Color(0xFFFAECE7);
    case GenogramRelationshipType.conflict:
    case GenogramRelationshipType.closeAndConflict:
    case GenogramRelationshipType.ruptured:
      return AppColors.warningContainer;
    case GenogramRelationshipType.close:
    case GenogramRelationshipType.neutral:
    case GenogramRelationshipType.distant:
      return AppColors.surfaceTintBlue;
    case GenogramRelationshipType.other:
      return AppColors.disabledSurface;
  }
}

Color _badgeFg(GenogramRelationshipType type) {
  switch (type) {
    case GenogramRelationshipType.parentChild:
    case GenogramRelationshipType.sibling:
    case GenogramRelationshipType.twin:
      return AppColors.onSuccessContainer;
    case GenogramRelationshipType.spouse:
    case GenogramRelationshipType.exSpouse:
    case GenogramRelationshipType.separation:
      return const Color(0xFF993C1D);
    case GenogramRelationshipType.conflict:
    case GenogramRelationshipType.closeAndConflict:
    case GenogramRelationshipType.ruptured:
      return AppColors.onWarningContainer;
    case GenogramRelationshipType.close:
    case GenogramRelationshipType.neutral:
    case GenogramRelationshipType.distant:
      return AppColors.onInfoContainer;
    case GenogramRelationshipType.other:
      return AppColors.textMuted;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Linha do tempo da pessoa (sem alterações)

class _PersonTimelineSection extends ConsumerStatefulWidget {
  const _PersonTimelineSection({
    required this.person,
    required this.role,
    required this.patientId,
  });

  final GenogramPerson person;
  final ProfileRole role;
  final String? patientId;

  @override
  ConsumerState<_PersonTimelineSection> createState() =>
      _PersonTimelineSectionState();
}

class _PersonTimelineSectionState
    extends ConsumerState<_PersonTimelineSection> {
  bool _navigating = false;

  Future<void> _openEvent(PatientTimelineEvent event) async {
    if (_navigating || !mounted) return;
    setState(() => _navigating = true);
    try {
      await context.push(
        widget.role == ProfileRole.patient
            ? PatientTimelineRoutes.patientDetail(event.id)
            : PatientTimelineRoutes.staffDetailFor(
                widget.patientId ?? widget.person.patientId,
                event.id,
              ),
      );
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final eventsAsync = ref.watch(
      timelineEventsForPersonProvider(
        TimelineEventsForPersonContext(
          patientId: widget.person.patientId,
          personId: widget.person.id,
        ),
      ),
    );

    return eventsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
        child: Center(child: BrandLoader()),
      ),
      error: (_, __) => const AppInfoCard(
        title: 'Erro ao carregar a linha do tempo',
        body: 'Não foi possível carregar os eventos desta pessoa.',
        icon: Icons.error_outline,
        tone: AppInfoCardTone.error,
      ),
      data: (events) {
        if (events.isEmpty) {
          return const AppInfoCard(
            title: 'Nenhum evento vinculado',
            body:
                'Nenhum acontecimento da linha do tempo está associado a '
                'esta pessoa ainda. É possível vincular ao editar um evento.',
            icon: Icons.event_note_outlined,
          );
        }

        return Column(
          children: [
            for (var i = 0; i < events.length; i++)
              PatientTimelineEventTile(
                event: events[i],
                isFirst: i == 0,
                isLast: i == events.length - 1,
                onTap: _navigating ? null : () => _openEvent(events[i]),
              ),
          ],
        );
      },
    );
  }
}
