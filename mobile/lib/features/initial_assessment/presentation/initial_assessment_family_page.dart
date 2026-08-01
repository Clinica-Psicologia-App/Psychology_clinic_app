import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/genogram_enums.dart';
import '../domain/genogram_person_entry.dart';
import '../domain/patient_family.dart';
import '../providers/patient_family_providers.dart';
import 'widgets/genogram_person_editor.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Tela 3 do fluxo Conhecer na lente do paciente — "Minha Família": pessoas do
/// genograma + clima familiar + padrões transgeracionais.
class InitialAssessmentFamilyPage extends ConsumerStatefulWidget {
  const InitialAssessmentFamilyPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  ConsumerState<InitialAssessmentFamilyPage> createState() =>
      _InitialAssessmentFamilyPageState();
}

class _InitialAssessmentFamilyPageState
    extends ConsumerState<InitialAssessmentFamilyPage> {
  final Set<FamilyClimateTrait> _climate = {};
  final Set<TransgenerationalPattern> _patterns = {};
  bool _initialized = false;
  bool _savingContext = false;

  InitialAssessmentContext get _ctx =>
      InitialAssessmentContext(role: widget.role, patientId: widget.patientId);

  void _initFrom(PatientFamily family) {
    if (_initialized) return;
    _climate.addAll(family.context.familyClimate);
    _patterns.addAll(family.context.transgenerationalPatterns);
    _initialized = true;
  }

  Future<void> _saveContext() async {
    setState(() => _savingContext = true);
    try {
      await ref
          .read(patientFamilyMutationProvider(_ctx).notifier)
          .saveFamilyContext(
            familyClimate: _climate.toList(),
            patterns: _patterns.toList(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Informações da família salvas.')),
      );
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _savingContext = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(patientFamilyProvider(_ctx));

    return AppScaffold(
      title: 'Minha Família',
      body: AsyncStateBody<PatientFamily>(
        asyncValue: async,
        onRetry: () => ref.invalidate(patientFamilyProvider(_ctx)),
        dataBuilder: (family) {
          _initFrom(family);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            children: [
              Text(
                'Agora vamos conhecer as pessoas que fizeram parte da sua '
                'história e como eram suas relações com elas.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.4,
                    ),
              ),
              const SizedBox(height: 16),
              for (final person in family.people)
                _PersonCard(ctx: _ctx, person: person),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerLeft,
                child: FilledButton.tonalIcon(
                  onPressed: () =>
                      showGenogramPersonEditor(context: context, ctx: _ctx),
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Adicionar pessoa'),
                ),
              ),
              const SizedBox(height: 24),
              _ClimateSection(
                selected: _climate,
                onToggle: (t) => setState(() {
                  if (!_climate.remove(t)) _climate.add(t);
                }),
              ),
              const SizedBox(height: 20),
              _PatternsSection(
                selected: _patterns,
                onToggle: (p) => setState(() {
                  if (!_patterns.remove(p)) _patterns.add(p);
                }),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _savingContext ? null : _saveContext,
                  icon: _savingContext
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_savingContext
                      ? 'Salvando...'
                      : 'Salvar informações da família'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PersonCard extends StatelessWidget {
  const _PersonCard({required this.ctx, required this.person});

  final InitialAssessmentContext ctx;
  final GenogramPersonEntry person;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final meta = <String>[
      if ((person.relationshipToPatient ?? '').isNotEmpty)
        person.relationshipToPatient!,
      if (person.bondQuality != null) person.bondQuality!.label,
      if (person.emotionalPresence != null)
        'Presença ${person.emotionalPresence}/10',
    ];

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        onTap: () => showGenogramPersonEditor(
            context: context, ctx: ctx, person: person),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (person.isCaregiver == true)
                    const Padding(
                      padding: EdgeInsets.only(right: 6),
                      child: Icon(Icons.volunteer_activism_outlined,
                          size: 16, color: AppColors.turquoise),
                    ),
                  Expanded(
                    child: Text(person.fullName,
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ),
                  if (person.isDeceased)
                    const Icon(Icons.local_florist_outlined,
                        size: 15, color: AppColors.textMuted),
                ],
              ),
              if (meta.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(meta.join(' · '),
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: AppColors.textSecondary)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClimateSection extends StatelessWidget {
  const _ClimateSection({required this.selected, required this.onToggle});

  final Set<FamilyClimateTrait> selected;
  final ValueChanged<FamilyClimateTrait> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Na sua família era comum...',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final trait in FamilyClimateTrait.values)
              FilterChip(
                label: Text(trait.label),
                selected: selected.contains(trait),
                onSelected: (_) => onToggle(trait),
              ),
          ],
        ),
      ],
    );
  }
}

class _PatternsSection extends StatelessWidget {
  const _PatternsSection({required this.selected, required this.onToggle});

  final Set<TransgenerationalPattern> selected;
  final ValueChanged<TransgenerationalPattern> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Existe histórico na sua família de...',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pattern in TransgenerationalPattern.values)
              FilterChip(
                label: Text(pattern.label),
                selected: selected.contains(pattern),
                onSelected: (_) => onToggle(pattern),
              ),
          ],
        ),
      ],
    );
  }
}
