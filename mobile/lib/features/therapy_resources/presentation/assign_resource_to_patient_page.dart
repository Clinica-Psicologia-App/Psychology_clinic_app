import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../patients/providers/patients_providers.dart';
import '../../profile/domain/profile_role.dart';
import '../providers/therapy_resources_providers.dart';
import 'widgets/therapy_resource_widgets.dart';

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
      body: resourceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Recurso não encontrado.')),
        data: (resource) {
          if (resource == null) {
            return const Center(child: Text('Recurso não encontrado.'));
          }

          return MotionReveal(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TherapyResourceTile(resource: resource, onTap: null),
                  const SizedBox(height: 16),
                  patientAsync.when(
                    data: (p) => Text(
                      p != null
                          ? 'Liberar para: ${p.fullName}'
                          : 'Paciente não encontrado',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  if (resource.description != null &&
                      resource.description!.trim().isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(resource.description!),
                  ],
                  const Spacer(),
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
