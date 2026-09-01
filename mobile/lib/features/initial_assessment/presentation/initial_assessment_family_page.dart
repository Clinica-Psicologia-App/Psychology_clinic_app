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
  final _climateOtherCtrl = TextEditingController();
  final _patternsOtherCtrl = TextEditingController();
  bool _initialized = false;
  bool _savingContext = false;

  @override
  void dispose() {
    _climateOtherCtrl.dispose();
    _patternsOtherCtrl.dispose();
    super.dispose();
  }

  InitialAssessmentContext get _ctx =>
      InitialAssessmentContext(role: widget.role, patientId: widget.patientId);

  void _initFrom(PatientFamily family) {
    if (_initialized) return;
    _climate.addAll(family.context.familyClimate);
    _patterns.addAll(family.context.transgenerationalPatterns);
    _climateOtherCtrl.text = family.context.familyClimateOther ?? '';
    _patternsOtherCtrl.text =
        family.context.transgenerationalPatternsOther ?? '';
    _initialized = true;
  }

  Future<void> _saveContext() async {
    setState(() => _savingContext = true);
    try {
      final climateOther = _climateOtherCtrl.text.trim();
      final patternsOther = _patternsOtherCtrl.text.trim();
      await ref
          .read(patientFamilyMutationProvider(_ctx).notifier)
          .saveFamilyContext(
            familyClimate: _climate.toList(),
            familyClimateOther: climateOther.isEmpty ? null : climateOther,
            patterns: _patterns.toList(),
            patternsOther: patternsOther.isEmpty ? null : patternsOther,
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
      accent: AppColors.turquoise,
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
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
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
              const SizedBox(height: 8),
              TextField(
                controller: _climateOtherCtrl,
                decoration: const InputDecoration(
                  labelText: 'Outro clima familiar (opcional)',
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),
              _PatternsSection(
                selected: _patterns,
                onToggle: (p) => setState(() {
                  if (!_patterns.remove(p)) _patterns.add(p);
                }),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _patternsOtherCtrl,
                decoration: const InputDecoration(
                  labelText: 'Outro padrão transgeracional (opcional)',
                  isDense: true,
                ),
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

  Color _accentFor(BondQuality? q) => switch (q) {
        BondQuality.affectionate => const Color(0xFF1D9E75),
        BondQuality.conflictual => const Color(0xFFDC2626),
        BondQuality.distant => const Color(0xFFBA7517),
        BondQuality.ambivalent => const Color(0xFF7B5CF6),
        BondQuality.broken => const Color(0xFF64748B),
        null => AppColors.turquoise,
      };

  String _initials() {
    final parts = person.fullName.trim().split(RegExp(r'\s+'));
    final first = parts[0];
    if (parts.length == 1) {
      return first.length >= 2
          ? first.substring(0, 2).toUpperCase()
          : first.toUpperCase();
    }
    return '${first[0]}${parts[1][0]}'.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = _accentFor(person.bondQuality);

    return ClayCard(
      margin: const EdgeInsets.only(bottom: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            showGenogramPersonEditor(context: context, ctx: ctx, person: person),
        borderRadius: BorderRadius.circular(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: accent),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Avatar
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          _initials(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: accent,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  person.fullName,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                              if (person.isDeceased)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(Icons.local_florist_outlined,
                                      size: 14,
                                      color:
                                          theme.colorScheme.onSurfaceVariant),
                                ),
                            ],
                          ),
                          if ((person.relationshipToPatient ?? '').isNotEmpty)
                            Text(
                              person.relationshipToPatient!,
                              style: theme.textTheme.labelSmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant),
                            ),
                          if (person.emotionalPresence != null) ...[
                            const SizedBox(height: 5),
                            _PresenceDots(
                                value: person.emotionalPresence!,
                                color: accent),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Badge
                    if (person.bondQuality != null)
                      _BondBadge(
                          quality: person.bondQuality!, accent: accent),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PresenceDots extends StatelessWidget {
  const _PresenceDots({required this.value, required this.color});

  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(5, (i) {
        final filled = i * 2 < value;
        return Container(
          width: 6,
          height: 6,
          margin: const EdgeInsets.only(right: 3),
          decoration: BoxDecoration(
            color: filled ? color : AppColors.border,
            shape: BoxShape.circle,
          ),
        );
      }),
    );
  }
}

class _BondBadge extends StatelessWidget {
  const _BondBadge({required this.quality, required this.accent});

  final BondQuality quality;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        quality.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: accent,
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
