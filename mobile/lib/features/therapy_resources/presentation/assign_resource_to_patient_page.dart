import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/therapy_resources_providers.dart';
import 'widgets/therapy_resource_widgets.dart';
import '../../../shared/widgets/brand_loading.dart';

class AssignResourceToPatientPage extends ConsumerStatefulWidget {
  const AssignResourceToPatientPage({
    super.key,
    required this.role,
    required this.patientId,
    required this.resourceId,
  });

  final ProfileRole role;
  final String patientId;
  final String resourceId;

  @override
  ConsumerState<AssignResourceToPatientPage> createState() =>
      _AssignResourceToPatientPageState();
}

class _AssignResourceToPatientPageState
    extends ConsumerState<AssignResourceToPatientPage> {
  bool _assigning = false;

  @override
  Widget build(BuildContext context) {
    final resourceAsync = ref.watch(
      FutureProvider(
        (ref) => ref
            .read(therapyResourcesRepositoryProvider)
            .getResourceById(widget.resourceId),
      ),
    );
    final patientAsync = ref.watch(patientDetailProvider(widget.patientId));

    return AppScaffold(
      title: 'Liberar recurso',
      accent: AppColors.purple,
      body: resourceAsync.when(
        loading: () => const BrandLoader(),
        error: (_, __) => const Center(child: Text('Recurso não encontrado.')),
        data: (resource) {
          if (resource == null) {
            return const Center(child: Text('Recurso não encontrado.'));
          }

          return MotionReveal(
            child: SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.md,
                  AppSpacing.xxxl,
                ),
                children: [
                  patientAsync.when(
                    data: (p) => AppPageHeader(
                      title: 'Liberar recurso',
                      subtitle: p != null
                          ? 'Confirme a liberação deste material para ${p.fullName}.'
                          : 'Confirme a liberação deste material para o paciente.',
                      icon: Icons.lock_open_outlined,
                      metadata: [
                        Chip(label: Text(resource.type.label)),
                      ],
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => AppPageHeader(
                      title: 'Liberar recurso',
                      subtitle:
                          'Confirme a liberação deste material para o paciente.',
                      icon: Icons.lock_open_outlined,
                      metadata: [
                        Chip(label: Text(resource.type.label)),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const AppSectionHeader(
                    title: 'Material selecionado',
                    subtitle:
                        'Revise o recurso antes de confirmar o acesso do paciente.',
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TherapyResourceTile(resource: resource, onTap: null),
                  if (resource.description != null &&
                      resource.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.lg),
                    AppInfoCard(
                      title: 'Descrição',
                      body: resource.description!,
                      icon: Icons.notes_outlined,
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  FilledButton.icon(
                    onPressed: _assigning ? null : _assign,
                    icon: _assigning
                        ? const SizedBox.shrink()
                        : const Icon(Icons.check),
                    label: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: _assigning
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Confirmar liberação'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _assign() async {
    setState(() => _assigning = true);
    try {
      await ref
          .read(
            assignResourceProvider(
              AssignResourceArgs(
                role: widget.role,
                patientId: widget.patientId,
                resourceId: widget.resourceId,
              ),
            ).notifier,
          )
          .assign();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Recurso liberado com sucesso.')),
      );
      context.pop();
    } catch (e) {
      if (mounted) {
        showErrorBanner(context, e);
      }
    } finally {
      if (mounted) setState(() => _assigning = false);
    }
  }
}
