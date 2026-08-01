import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_empty_state.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/async_state_body.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../profile/domain/profile_role.dart';
import '../../questionnaires/presentation/questionnaire_routes.dart';
import '../../results/presentation/result_routes.dart';
import '../../therapy_resources/presentation/therapy_resource_routes.dart';
import '../domain/patient.dart';
import '../providers/patients_providers.dart';
import 'patient_routes.dart';

/// Tela de escolha rápida de paciente, usada quando um atalho do workspace
/// precisa de um paciente antes de abrir o módulo (ex.: "Liberar para
/// paciente", "Resultados").
///
/// Diferente de `PatientsPage`, que é a tela de *gestão* da carteira: aqui
/// não há cadastro, convite, filtros nem status — só busca e uma lista densa,
/// porque a única ação possível é escolher alguém e seguir.
class PatientPickerPage extends ConsumerStatefulWidget {
  const PatientPickerPage({
    super.key,
    required this.role,
    required this.intent,
  });

  final ProfileRole role;
  final PatientSelectionIntent intent;

  @override
  ConsumerState<PatientPickerPage> createState() => _PatientPickerPageState();
}

class _PatientPickerPageState extends ConsumerState<PatientPickerPage> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open(Patient patient) {
    context.push(
      switch (widget.intent) {
        PatientSelectionIntent.none ||
        PatientSelectionIntent.formulation =>
          PatientRoutes.detail(widget.role, patient.id),
        PatientSelectionIntent.questionnaires => QuestionnaireRoutes.list(
            role: widget.role,
            patientId: patient.id,
          ),
        PatientSelectionIntent.results => ResultRoutes.list(
            role: widget.role,
            patientId: patient.id,
          ),
        PatientSelectionIntent.therapyResources =>
          TherapyResourceRoutes.staffList(
            role: widget.role,
            patientId: patient.id,
          ),
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final style = _PickerStyle.of(widget.intent);
    final listState = ref.watch(patientsListProvider);

    return AppScaffold(
      title: style.title,
      subtitle: style.subtitle,
      useResponsivePadding: true,
      body: AsyncStateBody<List<Patient>>(
        asyncValue: listState,
        onRetry: () => ref.read(patientsListProvider.notifier).refresh(),
        emptyMessage: 'Nenhum paciente cadastrado ainda.',
        dataBuilder: (patients) {
          final normalized = _query.trim().toLowerCase();
          final matches = patients.where((patient) {
            if (!patient.isActive) return false;
            if (normalized.isEmpty) return true;
            return patient.fullName.toLowerCase().contains(normalized) ||
                (patient.email?.toLowerCase().contains(normalized) ?? false);
          }).toList();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.sm,
                ),
                child: _PickerSearchField(
                  controller: _controller,
                  accent: style.accent,
                  onChanged: (value) => setState(() => _query = value),
                  onClear: () {
                    _controller.clear();
                    setState(() => _query = '');
                  },
                ),
              ),
              Expanded(
                child: matches.isEmpty
                    ? Center(
                        child: AppEmptyState(
                          icon: Icons.search_off_outlined,
                          title: 'Nenhum paciente',
                          message: 'Nenhum paciente ativo corresponde à busca.',
                          action: TextButton.icon(
                            onPressed: () {
                              _controller.clear();
                              setState(() => _query = '');
                            },
                            icon: const Icon(Icons.close),
                            label: const Text('Limpar busca'),
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.md,
                          0,
                          AppSpacing.md,
                          AppSpacing.xxl,
                        ),
                        itemCount: matches.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: AppSpacing.xs),
                        itemBuilder: (context, index) {
                          final patient = matches[index];
                          return MotionReveal(
                            delay: staggerDelay(index),
                            child: _PickerRow(
                              patient: patient,
                              accent: style.accent,
                              onTap: () => _open(patient),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PickerSearchField extends StatelessWidget {
  const _PickerSearchField({
    required this.controller,
    required this.accent,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final Color accent;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ClayCard(
      accentColor: accent,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(
          hintText: 'Buscar paciente',
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
          enabledBorder: InputBorder.none,
          filled: false,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          prefixIcon: Icon(Icons.search, color: accent),
          suffixIcon: controller.text.isEmpty
              ? null
              : IconButton(
                  tooltip: 'Limpar busca',
                  onPressed: onClear,
                  icon: const Icon(Icons.close),
                ),
        ),
      ),
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.patient,
    required this.accent,
    required this.onTap,
  });

  final Patient patient;
  final Color accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return MotionSurface(
      onTap: onTap,
      borderRadius: AppRadius.lgAll,
      child: ClayCard(
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.lgAll,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent.withValues(alpha: 0.12),
                    boxShadow: AppShadows.clay(accent),
                  ),
                  child: Text(
                    _initials(patient.fullName),
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: accent,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    patient.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: accent.withValues(alpha: 0.7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _initials(String fullName) {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters.first.toUpperCase();
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

class _PickerStyle {
  const _PickerStyle({
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final String title;
  final String subtitle;
  final Color accent;

  static _PickerStyle of(PatientSelectionIntent intent) {
    return switch (intent) {
      PatientSelectionIntent.none => const _PickerStyle(
          title: 'Escolher paciente',
          subtitle: 'Toque para abrir',
          accent: AppColors.blue,
        ),
      PatientSelectionIntent.questionnaires => const _PickerStyle(
          title: 'Liberar questionário',
          subtitle: 'Toque no paciente para abrir os instrumentos',
          accent: AppColors.turquoise,
        ),
      PatientSelectionIntent.results => const _PickerStyle(
          title: 'Ver resultados',
          subtitle: 'Toque no paciente para abrir os resultados',
          accent: AppColors.purple,
        ),
      PatientSelectionIntent.formulation => const _PickerStyle(
          title: 'Formulação clínica',
          subtitle: 'Toque no paciente para abrir a formulação do caso',
          accent: AppColors.turquoise,
        ),
      PatientSelectionIntent.therapyResources => const _PickerStyle(
          title: 'Recursos terapêuticos',
          subtitle: 'Toque no paciente para abrir os materiais',
          accent: AppColors.cyan,
        ),
    };
  }
}
