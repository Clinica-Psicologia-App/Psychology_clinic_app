import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/error_banner.dart';
import '../../profile/domain/profile_role.dart';
import '../domain/patient_resource_access.dart';
import '../domain/therapy_resource.dart';
import '../providers/therapy_resources_providers.dart';
import 'therapy_resource_routes.dart';
import 'utils/open_resource_url.dart';
import 'widgets/therapy_resource_widgets.dart';

class TherapyResourceDetailPage extends ConsumerStatefulWidget {
  const TherapyResourceDetailPage({
    super.key,
    required this.role,
    this.patientId,
    this.resourceId,
    this.accessId,
  });

  final ProfileRole role;
  final String? patientId;
  final String? resourceId;
  final String? accessId;

  @override
  ConsumerState<TherapyResourceDetailPage> createState() =>
      _TherapyResourceDetailPageState();
}

class _TherapyResourceDetailPageState
    extends ConsumerState<TherapyResourceDetailPage> {
  bool _updating = false;
  bool _markedViewed = false;

  bool get _isPatient => widget.role == ProfileRole.patient;

  @override
  void initState() {
    super.initState();
    if (_isPatient && widget.accessId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoMarkViewed());
    }
  }

  Future<void> _autoMarkViewed() async {
    if (_markedViewed || widget.accessId == null) return;
    final access = await ref
        .read(therapyResourcesRepositoryProvider)
        .getAccessById(widget.accessId!);
    if (access == null || access.viewedAt != null || !access.isActive) return;

    try {
      await ref
          .read(therapyResourcesRepositoryProvider)
          .markViewed(widget.accessId!);
      _markedViewed = true;
      ref.invalidate(resourceAccessDetailProvider(widget.accessId!));
      ref.invalidate(myReleasedResourcesProvider);
    } catch (_) {
      // RLS ou offline - não bloqueia visualização
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isPatient && widget.accessId != null) {
      return _buildPatientAccessDetail(widget.accessId!);
    }

    if (widget.resourceId != null && widget.patientId != null) {
      return _buildStaffResourceDetail(
        widget.resourceId!,
        widget.patientId!,
      );
    }

    return const AppScaffold(
      title: 'Recurso',
      accent: AppColors.purple,
      body: Center(child: Text('Parâmetros inválidos.')),
    );
  }

  Widget _buildPatientAccessDetail(String accessId) {
    final accessAsync = ref.watch(resourceAccessDetailProvider(accessId));

    return AppScaffold(
      title: 'Meu recurso',
      accent: AppColors.purple,
      body: accessAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => _errorBody(() => ref.invalidate(
              resourceAccessDetailProvider(accessId),
            )),
        data: (access) {
          if (access == null || !access.isActive) {
            return const Center(child: Text('Recurso não disponível.'));
          }
          return _DetailBody(
            resource: access.resource,
            access: access,
            isPatient: true,
            updating: _updating,
            onOpenUrl: () => openResourceUrl(context, access.resource.url),
            onMarkCompleted: access.completedAt == null
                ? () => _markCompleted(accessId)
                : null,
          );
        },
      ),
    );
  }

  Widget _buildStaffResourceDetail(String resourceId, String patientId) {
    final resourceAsync = ref.watch(
      therapyResourceDetailProvider(resourceId),
    );
    final accessAsync = ref.watch(patientResourceAccessProvider(patientId));

    return AppScaffold(
      title: 'Detalhe do recurso',
      accent: AppColors.purple,
      actions: [
        IconButton(
          tooltip: 'Editar material',
          onPressed: () => context.push(
            TherapyResourceRoutes.edit(
              role: widget.role,
              patientId: patientId,
              resourceId: resourceId,
            ),
          ),
          icon: const Icon(Icons.edit_outlined),
        ),
      ],
      body: resourceAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Erro ao carregar.')),
        data: (resource) {
          if (resource == null) {
            return const Center(child: Text('Recurso não encontrado.'));
          }

          final access = accessAsync.valueOrNull
              ?.where((a) => a.resourceId == resourceId && a.isActive)
              .firstOrNull;

          return _DetailBody(
            resource: resource,
            access: access,
            isPatient: false,
            updating: _updating,
            onOpenUrl: () => openResourceUrl(context, resource.url),
            onRevoke:
                access != null ? () => _revoke(access.id, patientId) : null,
          );
        },
      ),
    );
  }

  Widget _errorBody(VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Erro ao carregar.'),
          const SizedBox(height: 16),
          FilledButton(
              onPressed: onRetry, child: const Text('Tentar novamente')),
        ],
      ),
    );
  }

  Future<void> _markCompleted(String accessId) async {
    setState(() => _updating = true);
    try {
      await ref
          .read(therapyResourcesRepositoryProvider)
          .markCompleted(accessId);
      ref.invalidate(resourceAccessDetailProvider(accessId));
      ref.invalidate(myReleasedResourcesProvider);
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _revoke(String accessId, String patientId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bloquear acesso?'),
        content: const Text(
          'O paciente não verá mais este recurso até uma nova liberação.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Bloquear'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _updating = true);
    try {
      await ref.read(therapyResourcesRepositoryProvider).revokeAccess(accessId);
      ref.invalidate(patientResourceAccessProvider(patientId));
      if (widget.patientId != null) {
        ref.invalidate(
          staffTherapyBundleProvider(
            StaffTherapyContext(role: widget.role, patientId: patientId),
          ),
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Acesso bloqueado.')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) showErrorBanner(context, e);
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.resource,
    required this.access,
    required this.isPatient,
    required this.updating,
    required this.onOpenUrl,
    this.onMarkCompleted,
    this.onRevoke,
  });

  final TherapyResource resource;
  final PatientResourceAccess? access;
  final bool isPatient;
  final bool updating;
  final VoidCallback onOpenUrl;
  final VoidCallback? onMarkCompleted;
  final VoidCallback? onRevoke;

  @override
  Widget build(BuildContext context) {
    return MotionReveal(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.md,
          AppSpacing.xxxl,
        ),
        children: [
          AppPageHeader(
            title: resource.title,
            subtitle: isPatient
                ? 'Material liberado pelo seu psicólogo para apoiar sua prática entre as sessões.'
                : 'Material da biblioteca terapêutica associado ao acompanhamento deste paciente.',
            icon: resource.type.icon,
            metadata: [
              Chip(label: Text(resource.type.label)),
              if (access != null)
                ResourceStatusChip(status: access!.progressStatus),
            ],
          ),
          if (access != null) ...[
            const SizedBox(height: AppSpacing.xl),
            AppInfoCard(
              title: isPatient ? 'Seu acesso' : 'Acesso do paciente',
              body: access!.releasedAt != null
                  ? 'Liberado em ${MaterialLocalizations.of(context).formatFullDate(access!.releasedAt!)}.'
                  : 'Este recurso está liberado para acesso.',
              icon: Icons.lock_open_outlined,
              tone: AppInfoCardTone.info,
            ),
          ],
          if (resource.description != null &&
              resource.description!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            AppInfoCard(
              title: 'Descrição',
              body: resource.description!,
              icon: Icons.notes_outlined,
            ),
          ],
          if (resource.url != null && resource.url!.trim().isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xl),
            const AppSectionHeader(
              title: 'Link do recurso',
              subtitle: 'Abra o material em uma nova tela.',
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: onOpenUrl,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir link'),
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          if (isPatient && onMarkCompleted != null)
            FilledButton.icon(
              onPressed: updating ? null : onMarkCompleted,
              icon: const Icon(Icons.task_alt),
              label: updating
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Marcar como concluído'),
            ),
          if (!isPatient && onRevoke != null)
            OutlinedButton.icon(
              onPressed: updating ? null : onRevoke,
              icon: const Icon(Icons.block),
              label: const Text('Bloquear acesso'),
            ),
        ],
      ),
    );
  }
}

extension _FirstOrNull<E> on Iterable<E> {
  E? get firstOrNull {
    final it = iterator;
    if (!it.moveNext()) return null;
    return it.current;
  }
}
