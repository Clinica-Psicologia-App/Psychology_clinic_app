import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/genogram_person_entry.dart';
import '../domain/patient_family.dart';
import '../providers/patient_family_providers.dart';
import 'widgets/genogram_person_editor.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

/// Tela 3 do fluxo Conhecer na lente do terapeuta — painéis clínicos do
/// genograma (figuras de apego, vínculos, necessidades, clima e padrões) com
/// um comentário clínico por pessoa.
class InitialAssessmentFamilyTherapistPage extends ConsumerStatefulWidget {
  const InitialAssessmentFamilyTherapistPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  ConsumerState<InitialAssessmentFamilyTherapistPage> createState() =>
      _InitialAssessmentFamilyTherapistPageState();
}

class _InitialAssessmentFamilyTherapistPageState
    extends ConsumerState<InitialAssessmentFamilyTherapistPage> {
  final Map<String, TextEditingController> _comments = {};
  bool _saving = false;

  InitialAssessmentContext get _ctx =>
      InitialAssessmentContext(role: widget.role, patientId: widget.patientId);

  @override
  void dispose() {
    for (final c in _comments.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _commentFor(GenogramPersonEntry p) {
    return _comments.putIfAbsent(
      p.id,
      () => TextEditingController(text: p.clinicalComment ?? ''),
    );
  }

  Future<void> _saveComments(PatientFamily family) async {
    setState(() => _saving = true);
    final repo = ref.read(patientFamilyRepositoryProvider);
    try {
      for (final person in family.people) {
        final controller = _comments[person.id];
        if (controller == null) continue;
        await repo.savePersonNote(
          patientId: widget.patientId,
          personId: person.id,
          clinicalComment: controller.text,
        );
      }
      ref.invalidate(patientFamilyProvider(_ctx));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Comentários salvos.')),
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
    final async = ref.watch(patientFamilyProvider(_ctx));

    return AppScaffold(
      title: 'Genograma emocional',
      accent: AppColors.turquoise,
      body: AsyncStateBody<PatientFamily>(
        asyncValue: async,
        onRetry: () => ref.invalidate(patientFamilyProvider(_ctx)),
        dataBuilder: (family) {
          return Stack(
            children: [
              ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  _caregiversSummary(context, family),
                  const SizedBox(height: 4),
                  for (final person in family.people)
                    _personCard(context, person),
                  if (family.people.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'Nenhuma pessoa registrada ainda. Você pode adicioná-las '
                        'pelo paciente.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                    ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton.tonalIcon(
                      onPressed: () =>
                          showGenogramPersonEditor(context: context, ctx: _ctx),
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('Adicionar pessoa'),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _familyContextPanel(context, family),
                ],
              ),
              Positioned(
                left: 16,
                right: 16,
                bottom: 16,
                child: FilledButton.icon(
                  onPressed: _saving ? null : () => _saveComments(family),
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check),
                  label: Text(_saving ? 'Salvando...' : 'Salvar comentários'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _caregiversSummary(BuildContext context, PatientFamily family) {
    final caregivers = family.caregivers;
    if (caregivers.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return ClayCard(
      margin: const EdgeInsets.only(bottom: 12),
      color: AppColors.surfaceTintTurquoise,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.volunteer_activism_outlined,
                    size: 16, color: AppColors.turquoise),
                const SizedBox(width: 6),
                Text('Figuras de apego',
                    style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.turquoise)),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              caregivers.map((c) => c.displayLabel).join(' · '),
              style: theme.textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _personCard(BuildContext context, GenogramPersonEntry p) {
    final theme = Theme.of(context);
    return ClayCard(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(p.displayLabel,
                      style: theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ),
                if (p.isCaregiver == true)
                  const Icon(Icons.volunteer_activism_outlined,
                      size: 15, color: AppColors.turquoise),
                InkWell(
                  onTap: () => showGenogramPersonEditor(
                      context: context, ctx: _ctx, person: p),
                  child: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.edit_outlined, size: 16),
                  ),
                ),
              ],
            ),
            _metaLine(theme, p),
            if (p.caregiverTraits.isNotEmpty)
              _chipsLine(theme, 'Perfil',
                  p.caregiverTraits.map((e) => e.label).toList()),
            if (p.feltNeeds.isNotEmpty)
              _chipsLine(
                  theme, 'Sentia', p.feltNeeds.map((e) => e.label).toList()),
            if (p.wishedNeeds.isNotEmpty)
              _chipsLine(theme, 'Gostaria',
                  p.wishedNeeds.map((e) => e.label).toList()),
            if (p.linkedEvents.isNotEmpty)
              _chipsLine(theme, 'Eventos',
                  p.linkedEvents.map((e) => e.label).toList()),
            const SizedBox(height: 8),
            TextField(
              controller: _commentFor(p),
              minLines: 1,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Comentário clínico',
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaLine(ThemeData theme, GenogramPersonEntry p) {
    final parts = <String>[
      if (p.bondQuality != null)
        'Vínculo ${p.bondQuality!.label.toLowerCase()}',
      if (p.emotionalPresence != null) 'Presença ${p.emotionalPresence}/10',
      if (p.isDeceased) 'Falecido(a)',
    ];
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Text(parts.join(' · '),
          style: theme.textTheme.labelSmall
              ?.copyWith(color: AppColors.textSecondary)),
    );
  }

  Widget _chipsLine(ThemeData theme, String label, List<String> values) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: RichText(
        text: TextSpan(
          style: theme.textTheme.bodySmall,
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            TextSpan(
              text: values.join(', '),
              style: const TextStyle(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _familyContextPanel(BuildContext context, PatientFamily family) {
    final theme = Theme.of(context);
    final climate = family.context.familyClimate;
    final patterns = family.context.transgenerationalPatterns;
    if (climate.isEmpty && patterns.isEmpty) return const SizedBox.shrink();

    return ClayCard(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Clima familiar e padrões',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w700)),
            if (climate.isNotEmpty)
              _chipsLine(theme, 'Clima', climate.map((e) => e.label).toList()),
            if (patterns.isNotEmpty)
              _chipsLine(theme, 'Padrões transgeracionais',
                  patterns.map((e) => e.label).toList()),
          ],
        ),
      ),
    );
  }
}
