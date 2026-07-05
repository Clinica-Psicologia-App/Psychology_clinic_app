import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../../shared/widgets/homologation_ui.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/clinical_report_include_options.dart';
import '../providers/clinical_report_providers.dart';

class ClinicalReportOptionsPage extends ConsumerStatefulWidget {
  const ClinicalReportOptionsPage({
    super.key,
    required this.role,
    required this.patientId,
  });

  final ProfileRole role;
  final String patientId;

  @override
  ConsumerState<ClinicalReportOptionsPage> createState() =>
      _ClinicalReportOptionsPageState();
}

class _ClinicalReportOptionsPageState
    extends ConsumerState<ClinicalReportOptionsPage> {
  ClinicalReportIncludeOptions _include = ClinicalReportIncludeOptions.defaults;
  bool _generating = false;

  Future<void> _generate() async {
    if (!_include.hasAnySection) {
      showErrorBanner(
        context,
        AppException(
          code: AppExceptionCodes.validation,
          message: 'Selecione ao menos uma seção.',
        ),
      );
      return;
    }

    setState(() => _generating = true);
    try {
      final repo = ref.read(clinicalReportRepositoryProvider);
      final bytes = await repo.generatePdf(
        patientId: widget.patientId,
        include: _include,
      );
      final file = await repo.savePdfToTemp(
        bytes: bytes,
        patientId: widget.patientId,
      );
      final result = await repo.openPdfFile(file);

      if (!mounted) return;

      if (result.type != ResultType.done) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result.message.isNotEmpty
                  ? result.message
                  : 'PDF salvo em: ${file.path}',
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Relatório PDF gerado.')),
        );
      }
    } on AppException catch (e) {
      if (mounted) showErrorBanner(context, e);
    } catch (e) {
      if (mounted) {
        showErrorBanner(
          context,
          mapToAppException(e),
        );
      }
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _toggle(
    ClinicalReportIncludeOptions Function(ClinicalReportIncludeOptions) update,
  ) {
    setState(() => _include = update(_include));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final selectedCount = _selectedSectionCount();

    return AppScaffold(
      title: 'Gerar relatório',
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        children: [
          MotionStaggered(
            children: [
              AppPageHeader(
                icon: Icons.picture_as_pdf_outlined,
                title: 'Relatório clínico',
                subtitle:
                    'Monte um PDF com as seções úteis para discussão clínica, supervisão ou acompanhamento do caso.',
                metadata: [
                  StatusChip(
                    label: '$selectedCount de 8 seções',
                    tone: selectedCount == 0
                        ? AppStatusTone.warning
                        : AppStatusTone.info,
                    icon: Icons.checklist_outlined,
                  ),
                  const StatusChip(
                    label: 'Uso profissional',
                    tone: AppStatusTone.neutral,
                    icon: Icons.health_and_safety_outlined,
                  ),
                ],
                primaryAction: FilledButton.icon(
                  onPressed: _generating ? null : _generate,
                  icon: _generating
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_outlined),
                  label: Text(
                    _generating ? 'Gerando...' : 'Gerar PDF',
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              const HomologationInfoBanner(
                title: 'Apoio clínico',
                icon: Icons.picture_as_pdf_outlined,
                message:
                    'Relatório gerado como apoio clínico. A interpretação é '
                    'responsabilidade do profissional. Não constitui diagnóstico '
                    'automático.',
              ),
              const SizedBox(height: AppSpacing.lg),
              const HomologationSectionHeader(
                icon: Icons.tune_outlined,
                title: 'Conteúdo do PDF',
                subtitle:
                    'Escolha quais módulos entram no relatório deste paciente',
              ),
              const SizedBox(height: AppSpacing.sm),
              Card(
                child: Column(
                  children: [
                    _SectionSwitch(
                      icon: Icons.assignment_outlined,
                      title: 'Questionários (YSQ / YAMI)',
                      subtitle: 'Scores e datas das últimas aplicações',
                      value: _include.questionnaires,
                      onChanged: (v) =>
                          _toggle((o) => o.copyWith(questionnaires: v)),
                    ),
                    const Divider(height: 1),
                    _SectionSwitch(
                      icon: Icons.hub_outlined,
                      title: 'Mapa mental resumido',
                      subtitle: 'Visão integrada dos módulos com dados',
                      value: _include.mentalMap,
                      onChanged: (v) =>
                          _toggle((o) => o.copyWith(mentalMap: v)),
                    ),
                    const Divider(height: 1),
                    _SectionSwitch(
                      icon: Icons.flag_outlined,
                      title: 'Objetivos da terapia',
                      value: _include.goals,
                      onChanged: (v) => _toggle((o) => o.copyWith(goals: v)),
                    ),
                    const Divider(height: 1),
                    _SectionSwitch(
                      icon: Icons.report_problem_outlined,
                      title: 'Problemas',
                      value: _include.problems,
                      onChanged: (v) => _toggle((o) => o.copyWith(problems: v)),
                    ),
                    const Divider(height: 1),
                    _SectionSwitch(
                      icon: Icons.fact_check_outlined,
                      title: 'Check-ins',
                      value: _include.checkIns,
                      onChanged: (v) => _toggle((o) => o.copyWith(checkIns: v)),
                    ),
                    const Divider(height: 1),
                    _SectionSwitch(
                      icon: Icons.monitor_heart_outlined,
                      title: 'Monitor diário',
                      value: _include.dailyMonitors,
                      onChanged: (v) =>
                          _toggle((o) => o.copyWith(dailyMonitors: v)),
                    ),
                    const Divider(height: 1),
                    _SectionSwitch(
                      icon: Icons.timeline_outlined,
                      title: 'Linha do tempo',
                      value: _include.timeline,
                      onChanged: (v) => _toggle((o) => o.copyWith(timeline: v)),
                    ),
                    const Divider(height: 1),
                    _SectionSwitch(
                      icon: Icons.family_restroom_outlined,
                      title: 'Genograma',
                      value: _include.genogram,
                      onChanged: (v) => _toggle((o) => o.copyWith(genogram: v)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '$selectedCount de 8 seções selecionadas',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  int _selectedSectionCount() {
    var count = 0;
    if (_include.questionnaires) count++;
    if (_include.mentalMap) count++;
    if (_include.goals) count++;
    if (_include.problems) count++;
    if (_include.checkIns) count++;
    if (_include.dailyMonitors) count++;
    if (_include.timeline) count++;
    if (_include.genogram) count++;
    return count;
  }
}

class _SectionSwitch extends StatelessWidget {
  const _SectionSwitch({
    required this.icon,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SwitchListTile(
      secondary: Icon(icon, color: theme.colorScheme.primary),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            )
          : null,
      value: value,
      onChanged: onChanged,
    );
  }
}
