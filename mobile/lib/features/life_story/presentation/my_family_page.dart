import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../coach/domain/coach_step.dart';
import '../../coach/domain/coach_tour.dart';
import '../../coach/providers/coach_providers.dart';
import '../domain/family_person.dart';
import '../domain/life_story_enums.dart';
import '../providers/life_story_providers.dart';
import 'life_story_routes.dart';
import 'widgets/flow_ui.dart';
import '../../../shared/widgets/brand_loading.dart';

/// Tela 3 "Minha Família" — lista das pessoas da história do paciente, com a
/// integração à Linha do Tempo ("aparece em N momentos"). Textos literais da
/// spec (§18–20). A camada emocional e o genograma gráfico vêm depois.
class MyFamilyPage extends ConsumerStatefulWidget {
  const MyFamilyPage({super.key});

  @override
  ConsumerState<MyFamilyPage> createState() => _MyFamilyPageState();
}

class _MyFamilyPageState extends ConsumerState<MyFamilyPage> {
  final _fabKey = GlobalKey();
  final _titleKey = GlobalKey();
  bool _tourRequested = false;

  CoachTour _tour() => CoachTour(
        id: 'tour_minha_familia',
        steps: [
          CoachStep(
            id: 'oque',
            text:
                'Aqui você reúne as pessoas importantes da sua história — a sua '
                'família e quem marcou a sua vida.',
            pose: MascotPose.wave,
            targetKey: _titleKey,
          ),
          CoachStep(
            id: 'adicionar',
            text:
                'Use "Adicionar pessoa" para incluir cada uma, com o parentesco '
                'e um pouco sobre a relação de vocês.',
            pose: MascotPose.point,
            targetKey: _fabKey,
          ),
          const CoachStep(
            id: 'ligacao',
            text:
                'Quem já apareceu na sua Linha do Tempo também aparece aqui. '
                'Toque numa pessoa para conhecer e completar a história dela. 🙂',
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
    final familyAsync = ref.watch(myFamilyProvider);
    final theme = Theme.of(context);
    final topInset = MediaQuery.paddingOf(context).top;

    // Aguarda o provider resolver para que o FAB já esteja na árvore quando
    // o tour chegar no step "adicionar".
    if (!_tourRequested && familyAsync.hasValue) {
      _tourRequested = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _startTour());
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: familyAsync.maybeWhen(
        data: (people) => people.isEmpty
            ? null
            : FloatingActionButton.extended(
                key: _fabKey,
                backgroundColor: AppColors.turquoise,
                onPressed: () => _openAddPerson(context, ref),
                icon: const Icon(Icons.person_add_alt),
                label: const Text('Adicionar pessoa'),
              ),
        orElse: () => null,
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
                  child: Text('Minha Família',
                      key: _titleKey,
                      style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white, fontWeight: FontWeight.w700)),
                ),
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
            child: familyAsync.when(
              loading: () => const BrandLoader(),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: OutlinedButton(
                    onPressed: () => ref.invalidate(myFamilyProvider),
                    child: const Text('Tentar de novo'),
                  ),
                ),
              ),
              data: (people) => people.isEmpty
                  ? _FamilyInvite(onStart: () => _openAddPerson(context, ref))
                  : _FamilyList(
                      people: people,
                      onOpenContext: () async {
                        final ctx = await ref
                            .read(myFamilyContextProvider.future);
                        if (context.mounted) {
                          context.push(LifeStoryRoutes.familyContext,
                              extra: ctx);
                        }
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openAddPerson(BuildContext context, WidgetRef ref) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
    ),
    builder: (_) => const _AddFamilyPersonSheet(),
  );
}

/// Abertura — convite quando ainda não há pessoas (spec §18).
class _FamilyInvite extends StatelessWidget {
  const _FamilyInvite({required this.onStart});
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.family_restroom_outlined,
                size: 48, color: AppColors.turquoise),
            const SizedBox(height: 18),
            const Text(
              'Quem foram as pessoas importantes da sua história e como eram '
              'essas relações?',
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                  height: 1.3),
            ),
            const SizedBox(height: 12),
            const Text(
              'Agora vamos conhecer um pouco melhor as pessoas que fizeram '
              'parte da sua história e como eram suas relações com elas. '
              'Algumas pessoas já podem ter aparecido na sua Linha do Tempo. '
              'Você poderá completar essas informações e acrescentar outras '
              'pessoas importantes.',
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
              child: const Text('Conhecer minha família'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Lista das pessoas identificadas (spec §19).
class _FamilyList extends StatelessWidget {
  const _FamilyList({required this.people, required this.onOpenContext});
  final List<FamilyPerson> people;
  final VoidCallback onOpenContext;

  @override
  Widget build(BuildContext context) {
    final withEvents = people.where((p) => p.eventCount > 0).toList();
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 96),
      children: [
        if (withEvents.isNotEmpty)
          const Padding(
            padding: EdgeInsets.only(bottom: 12, left: 4),
            child: Text(
              'Algumas pessoas importantes já apareceram na sua história.',
              style: TextStyle(
                  fontSize: 13.5, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        for (final p in people) _PersonCard(person: p),
        const SizedBox(height: 8),
        _ContextCard(onTap: onOpenContext),
      ],
    );
  }
}

/// Atalho para o clima e os padrões da família (§32–33).
class _ContextCard extends StatelessWidget {
  const _ContextCard({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF2FBFA),
          border: Border.all(color: AppColors.turquoise.withValues(alpha: 0.4)),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            Icon(Icons.home_outlined, color: AppColors.turquoise),
            SizedBox(width: 12),
            Expanded(
              child: Text('O clima e os padrões da minha família',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.navy)),
            ),
            Icon(Icons.chevron_right, color: AppColors.turquoise),
          ],
        ),
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.person});
  final FamilyPerson person;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () => context.push(
          LifeStoryRoutes.personCard,
          extra: person,
        ),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFDDE7F7),
            child: Text(person.initials,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, color: Color(0xFF2E5A9E))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(person.fullName,
                          style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.navy)),
                    ),
                    if (person.isDeceased) ...[
                      const SizedBox(width: 6),
                      const Icon(Icons.local_florist_outlined,
                          size: 14, color: AppColors.textMuted),
                    ],
                  ],
                ),
                if (person.role != null)
                  Text(person.role!.label,
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                if (person.eventCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    person.eventCount == 1
                        ? 'Aparece em 1 momento da sua história'
                        : 'Aparece em ${person.eventCount} momentos da sua história',
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.turquoise),
                  ),
                ],
              ],
            ),
          ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Folha "Adicionar uma pessoa" (spec §20) — nome, parentesco, gênero, idade,
/// falecimento. Sem perguntas de vínculo aqui (vêm no aprofundar da relação).
class _AddFamilyPersonSheet extends ConsumerStatefulWidget {
  const _AddFamilyPersonSheet();

  @override
  ConsumerState<_AddFamilyPersonSheet> createState() =>
      _AddFamilyPersonSheetState();
}

class _AddFamilyPersonSheetState extends ConsumerState<_AddFamilyPersonSheet> {
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _deathAgeController = TextEditingController();
  RelationshipRole? _role;
  PersonGender? _gender;
  DeceasedStatus? _deceased;
  bool _busy = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _deathAgeController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _busy) return;
    setState(() => _busy = true);
    final person = FamilyPerson(
      id: '',
      fullName: name,
      role: _role,
      gender: _gender,
      ageApprox: int.tryParse(_ageController.text.trim()),
      deceasedStatus: _deceased,
      deathAge: _deceased == DeceasedStatus.yes
          ? int.tryParse(_deathAgeController.text.trim())
          : null,
    );
    try {
      await ref.read(saveFamilyPersonProvider.notifier).create(person);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busy = false);
        showErrorBanner(context, e);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(18, 18, 18, 18 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quem você gostaria de acrescentar?',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy)),
            const SizedBox(height: 16),
            flowLabel('Nome'),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              onChanged: (_) => setState(() {}),
              decoration: flowFieldDecoration('Nome da pessoa'),
            ),
            const SizedBox(height: 16),
            flowLabel('Essa pessoa é seu/sua...'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final r in kRelationshipRolesInOrder)
                  FlowChip(
                    label: r.label,
                    selected: _role == r,
                    onTap: () => setState(() => _role = _role == r ? null : r),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            flowLabel('Gênero'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final g in kPersonGendersInOrder)
                  FlowChip(
                    label: g.label,
                    selected: _gender == g,
                    onTap: () =>
                        setState(() => _gender = _gender == g ? null : g),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            flowLabel('Idade'),
            const SizedBox(height: 6),
            TextField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: flowFieldDecoration('anos (opcional)'),
            ),
            const SizedBox(height: 16),
            flowLabel('Essa pessoa é falecida?'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final d in kDeceasedStatusInOrder)
                  FlowChip(
                    label: d.label,
                    selected: _deceased == d,
                    onTap: () =>
                        setState(() => _deceased = _deceased == d ? null : d),
                  ),
              ],
            ),
            if (_deceased == DeceasedStatus.yes) ...[
              const SizedBox(height: 12),
              flowLabel('Com que idade faleceu?'),
              const SizedBox(height: 6),
              TextField(
                controller: _deathAgeController,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(3),
                ],
                decoration: flowFieldDecoration('anos (opcional)'),
              ),
            ],
            const SizedBox(height: 22),
            FilledButton(
              onPressed:
                  _nameController.text.trim().isNotEmpty && !_busy ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.turquoise,
                minimumSize: const Size.fromHeight(48),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Text('Adicionar'),
            ),
          ],
        ),
      ),
    );
  }
}
