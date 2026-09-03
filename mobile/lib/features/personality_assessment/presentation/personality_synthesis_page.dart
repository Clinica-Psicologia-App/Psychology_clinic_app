import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/brand_loading.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/personality_assessment.dart';
import '../providers/personality_assessment_providers.dart';

/// Edição da síntese clínica + integração à conceitualização (Fase 2).
class PersonalitySynthesisPage extends ConsumerWidget {
  const PersonalitySynthesisPage({
    super.key,
    required this.role,
    required this.patientId,
    required this.assessmentId,
  });

  final ProfileRole role;
  final String patientId;
  final String assessmentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(personalityAssessmentByIdProvider(assessmentId));
    return async.when(
      loading: () => const AppScaffold(
        title: 'Carregando…',
        accent: AppColors.purple,
        body: BrandLoader(),
      ),
      error: (_, __) => AppScaffold(
        title: 'Erro',
        accent: AppColors.purple,
        body: Center(
          child: FilledButton(
            onPressed: () =>
                ref.invalidate(personalityAssessmentByIdProvider(assessmentId)),
            child: const Text('Tentar novamente'),
          ),
        ),
      ),
      data: (a) {
        if (a == null) {
          return const AppScaffold(
            title: 'Síntese',
            accent: AppColors.purple,
            body: Center(child: Text('Avaliação não encontrada.')),
          );
        }
        return _Form(
          patientId: patientId,
          assessmentId: assessmentId,
          initial: a,
        );
      },
    );
  }
}

class _Form extends ConsumerStatefulWidget {
  const _Form({
    required this.patientId,
    required this.assessmentId,
    required this.initial,
  });

  final String patientId;
  final String assessmentId;
  final PersonalityAssessment initial;

  @override
  ConsumerState<_Form> createState() => _FormState();
}

class _FormState extends ConsumerState<_Form> {
  late final TextEditingController _understanding;
  late final TextEditingController _relevant;
  late final TextEditingController _resources;
  late final TextEditingController _vulnerabilities;
  late final TextEditingController _hypotheses;
  late final TextEditingController _note;

  IntegrationStatus? _status;
  final Set<IntegrationLink> _links = {};
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final s = widget.initial.synthesis;
    _understanding = TextEditingController(text: s.understanding ?? '');
    _relevant = TextEditingController(text: s.relevant ?? '');
    _resources = TextEditingController(text: s.resources ?? '');
    _vulnerabilities = TextEditingController(text: s.vulnerabilities ?? '');
    _hypotheses = TextEditingController(text: s.hypotheses ?? '');
    final i = widget.initial.integration;
    _note = TextEditingController(text: i.note ?? '');
    _status = i.status;
    _links.addAll(i.links);
  }

  @override
  void dispose() {
    _understanding.dispose();
    _relevant.dispose();
    _resources.dispose();
    _vulnerabilities.dispose();
    _hypotheses.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      await ref.read(personalityAssessmentRepositoryProvider).saveSynthesis(
            id: widget.assessmentId,
            synthesis: ClinicalSynthesis(
              understanding: _understanding.text,
              relevant: _relevant.text,
              resources: _resources.text,
              vulnerabilities: _vulnerabilities.text,
              hypotheses: _hypotheses.text,
            ),
            integration: ConceptualizationIntegration(
              status: _status,
              links: _status == IntegrationStatus.yes ? _links : const {},
              note: _note.text,
            ),
          );
      ref.invalidate(personalityAssessmentByIdProvider(widget.assessmentId));
      ref.invalidate(personalityAssessmentsProvider(widget.patientId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Síntese salva.')),
      );
      context.pop(true);
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppScaffold(
      title: 'Síntese clínica',
      accent: AppColors.purple,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
              children: [
                _card(
                  icon: Icons.psychology_outlined,
                  title: 'Síntese clínica do terapeuta',
                  children: [
                    _field(_understanding,
                        'O que este perfil ajuda a compreender sobre o paciente?'),
                    _field(_relevant, 'Aspectos clinicamente relevantes'),
                    _field(_resources, 'Recursos identificados'),
                    _field(_vulnerabilities, 'Vulnerabilidades identificadas'),
                    _field(_hypotheses, 'Hipóteses a explorar em sessão'),
                  ],
                ),
                _card(
                  icon: Icons.hub_outlined,
                  title: 'Integração à conceitualização',
                  children: [
                    Text(
                      'Esses resultados ajudam a compreender algum aspecto da '
                      'conceitualização deste paciente?',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final s in IntegrationStatus.values)
                          ChoiceChip(
                            label: Text(s.label),
                            selected: _status == s,
                            onSelected: (sel) =>
                                setState(() => _status = sel ? s : null),
                          ),
                      ],
                    ),
                    if (_status == IntegrationStatus.yes) ...[
                      const SizedBox(height: 8),
                      Text('Relacionar a:',
                          style: theme.textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final l in IntegrationLink.values)
                            FilterChip(
                              label: Text(l.label),
                              selected: _links.contains(l),
                              onSelected: (sel) => setState(() {
                                if (sel) {
                                  _links.add(l);
                                } else {
                                  _links.remove(l);
                                }
                              }),
                            ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    _field(_note, 'Observação clínica'),
                  ],
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  style:
                      FilledButton.styleFrom(backgroundColor: AppColors.purple),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Salvar síntese'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(13),
        border:
            Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AppColors.purple),
              const SizedBox(width: 8),
              Expanded(
                child: Text(title,
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w800)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _field(TextEditingController c, String label) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: TextField(
          controller: c,
          minLines: 1,
          maxLines: 4,
          textCapitalization: TextCapitalization.sentences,
          decoration: InputDecoration(
            labelText: label,
            alignLabelWithHint: true,
            isDense: true,
          ),
        ),
      );
}
