import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../domain/personality_assessment.dart';
import '../providers/personality_assessment_providers.dart';
import 'personality_dashboard_page.dart';

/// Visão do PACIENTE dos perfis que o terapeuta compartilhou. Só as faixas
/// (sem números, sem síntese) — os dados já vêm filtrados pela view.
class PatientPersonalityPage extends ConsumerWidget {
  const PatientPersonalityPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(patientSharedPersonalityProvider);
    return AppScaffold(
      title: 'Personalidade',
      accent: AppColors.purple,
      body: AsyncStateBody<List<PersonalityAssessment>>(
        asyncValue: async,
        onRetry: () => ref.invalidate(patientSharedPersonalityProvider),
        emptyIcon: Icons.psychology_alt_outlined,
        emptyMessage:
            'Nenhum perfil compartilhado pelo seu psicólogo por enquanto.',
        dataBuilder: (list) => ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 32),
          children: [
            _intro(context),
            const SizedBox(height: 12),
            for (final a in list) ...[
              _title(context, a),
              const SizedBox(height: 8),
              ProfilePanel(assessment: a),
              const SizedBox(height: 4),
              for (final d in a.instrumentDef.domains)
                DomainCard(domain: d, result: a.results.forDomain(d.code)),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _intro(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(13),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Aqui aparece o resultado de personalidade que seu psicólogo '
              'compartilhou com você. Ele é um apoio à sua terapia — converse '
              'com seu profissional sobre o que ele significa.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _title(BuildContext context, PersonalityAssessment a) {
    final theme = Theme.of(context);
    String date() {
      final d = a.appliedOn;
      if (d == null) return '';
      String two(int x) => x.toString().padLeft(2, '0');
      return ' · ${two(d.day)}/${two(d.month)}/${d.year}';
    }

    return Text(
      '${a.instrumentDef.name}${date()}',
      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w800),
    );
  }
}
