import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/clay_card.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../clinics/domain/clinic_summary.dart';
import '../../clinics/providers/clinics_providers.dart';
import '../data/admin_entitlements_repository.dart';
import '../providers/admin_entitlements_providers.dart';

/// Permissões de módulo por clínica (platform_admin): libera módulos aos
/// psicólogos independentemente do plano comercial.
class AdminPlansPage extends ConsumerWidget {
  const AdminPlansPage({super.key});

  static const route = '/platform/plans';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clinicsAsync = ref.watch(clinicsProvider);

    return AppScaffold(
      title: 'Planos e permissões',
      accent: AppColors.blue,
      subtitle: 'Liberar módulos por clínica',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.read(clinicsProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: ResponsiveContent(
        child: clinicsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Text(_message(e), textAlign: TextAlign.center),
            ),
          ),
          data: (clinics) => ListView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.xl, AppSpacing.lg, AppSpacing.xl, AppSpacing.xxl),
            children: [
              const AppPageHeader(
                icon: Icons.tune_outlined,
                title: 'Liberação de módulos',
                subtitle:
                    'Ligue ou desligue módulos por clínica. O que estiver ligado '
                    'fica disponível para os psicólogos daquela clínica, '
                    'independentemente do plano.',
              ),
              const SizedBox(height: AppSpacing.lg),
              if (clinics.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 80),
                  child: Center(child: Text('Nenhuma clínica cadastrada.')),
                )
              else
                for (final c in clinics) _ClinicTile(clinic: c),
            ],
          ),
        ),
      ),
    );
  }
}

class _ClinicTile extends ConsumerWidget {
  const _ClinicTile({required this.clinic});
  final ClinicSummary clinic;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final entAsync = ref.watch(clinicEntitlementsAdminProvider(clinic.id));

    return ClayCard(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Theme(
        // Remove as linhas divisórias padrão do ExpansionTile.
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          childrenPadding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.md),
          leading: CircleAvatar(
            backgroundColor: AppColors.surfaceTintPurple,
            child: Icon(Icons.apartment_outlined, color: AppColors.purple),
          ),
          title: Text(clinic.name,
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          subtitle: Text(
            '${clinic.userCount} profissional(is) · ${clinic.patientCount} paciente(s)',
            style:
                theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted),
          ),
          children: [
            entAsync.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AppSpacing.md),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Text(_message(e)),
              ),
              data: (enabledMap) => Column(
                children: [
                  for (final f in adminManageableFeatures)
                    _FeatureSwitch(
                      clinicId: clinic.id,
                      feature: f,
                      // Ausência de linha = permissivo (padrão true no app).
                      value: enabledMap[f.key] ?? true,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureSwitch extends ConsumerStatefulWidget {
  const _FeatureSwitch({
    required this.clinicId,
    required this.feature,
    required this.value,
  });
  final String clinicId;
  final AdminFeatureDef feature;
  final bool value;

  @override
  ConsumerState<_FeatureSwitch> createState() => _FeatureSwitchState();
}

class _FeatureSwitchState extends ConsumerState<_FeatureSwitch> {
  late bool _value = widget.value;
  bool _busy = false;

  @override
  void didUpdateWidget(covariant _FeatureSwitch old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _value = widget.value;
  }

  Future<void> _toggle(bool v) async {
    setState(() {
      _value = v;
      _busy = true;
    });
    try {
      await ref.read(entitlementMutationProvider.notifier).setEnabled(
            clinicId: widget.clinicId,
            feature: widget.feature,
            enabled: v,
          );
    } catch (e) {
      if (mounted) {
        setState(() => _value = !v); // desfaz o otimismo
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_message(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: _value,
      onChanged: _busy ? null : _toggle,
      title: Text(widget.feature.name,
          style: theme.textTheme.bodyMedium
              ?.copyWith(fontWeight: FontWeight.w600)),
      subtitle: Text(widget.feature.description,
          style:
              theme.textTheme.bodySmall?.copyWith(color: AppColors.textMuted)),
    );
  }
}

String _message(Object error) =>
    error.toString().replaceFirst(RegExp(r'^AppException\([^)]*\):\s*'), '');
