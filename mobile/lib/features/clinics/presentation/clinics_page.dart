import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_exception.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/app_motion.dart';
import '../../../shared/widgets/app_page_header.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/responsive_content.dart';
import '../../../shared/widgets/status_chip.dart';
import '../domain/clinic_summary.dart';
import '../providers/clinics_providers.dart';
import 'package:terapia_esquema/shared/widgets/clay_card.dart';

class ClinicsPage extends ConsumerWidget {
  const ClinicsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(clinicsProvider);

    return AppScaffold(
      title: 'Clínicas',
      accent: AppColors.blue,
      subtitle: 'Clínicas e profissionais individuais',
      actions: [
        IconButton(
          tooltip: 'Atualizar',
          onPressed: () => ref.read(clinicsProvider.notifier).refresh(),
          icon: const Icon(Icons.refresh),
        ),
      ],
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text(
              e is AppException
                  ? userMessageFor(e)
                  : 'Erro ao carregar clínicas.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (clinics) => _ClinicsList(
          clinics: clinics,
          onToggleActive: (clinic) => _toggleActive(context, ref, clinic),
          onDelete: (clinic) => _deleteClinic(context, ref, clinic),
          onCreate: () => _showCreateClinicSheet(context, ref),
        ),
      ),
    );
  }

  Future<void> _showCreateClinicSheet(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final result = await showModalBottomSheet<_CreateClinicResult>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.navy.withValues(alpha: 0.36),
      builder: (_) => UncontrolledProviderScope(
        container: ProviderScope.containerOf(context),
        child: const _CreateClinicSheet(),
      ),
    );

    if (result == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Criando clínica...')),
    );

    await ref.read(clinicsProvider.notifier).createClinic(
          name: result.name,
          clinicType: result.clinicType,
          document: result.document,
          email: result.email,
          phone: result.phone,
        );

    if (!context.mounted) return;
    final error = ref.read(clinicsProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? 'Clínica criada com sucesso.'
              : userMessageFor(mapToAppException(error)),
        ),
      ),
    );
  }

  Future<void> _toggleActive(
    BuildContext context,
    WidgetRef ref,
    ClinicSummary clinic,
  ) async {
    final nextActive = !clinic.isActive;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:
            Text('${nextActive ? 'Ativar' : 'Inativar'} ${clinic.typeLabel}'),
        content: Text(
          'Deseja ${nextActive ? 'ativar' : 'inativar'} ${clinic.name}? '
          'Isso impacta a operação dos usuários vinculados.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(nextActive ? 'Ativar' : 'Inativar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    await ref.read(clinicsProvider.notifier).setActive(
          clinicId: clinic.id,
          isActive: nextActive,
        );

    if (!context.mounted) return;
    final error = ref.read(clinicsProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? '${clinic.typeLabel} ${nextActive ? 'ativada' : 'inativada'} com sucesso.'
              : userMessageFor(mapToAppException(error)),
        ),
      ),
    );
  }

  Future<void> _deleteClinic(
    BuildContext context,
    WidgetRef ref,
    ClinicSummary clinic,
  ) async {
    if (clinic.userCount > 0 || clinic.patientCount > 0) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Não é possível excluir'),
          content: Text(
            'A ${clinic.typeLabel.toLowerCase()} ${clinic.name} possui '
            '${clinic.userCount} usuário(s) e ${clinic.patientCount} '
            'paciente(s) vinculados. Para produção, o caminho seguro é '
            'inativar a clínica ou remover os vínculos antes da exclusão.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendi'),
            ),
          ],
        ),
      );
      return;
    }

    final confirmationName = await showDialog<String>(
      context: context,
      builder: (context) => _DeleteClinicDialog(clinic: clinic),
    );

    if (confirmationName == null || !context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Excluindo clínica...')),
    );

    await ref.read(clinicsProvider.notifier).deleteClinic(
          clinicId: clinic.id,
          confirmationName: confirmationName,
        );

    if (!context.mounted) return;
    final error = ref.read(clinicsProvider).error;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          error == null
              ? '${clinic.typeLabel} excluída com sucesso.'
              : userMessageFor(mapToAppException(error)),
        ),
      ),
    );
  }
}

class _ClinicsList extends StatelessWidget {
  const _ClinicsList({
    required this.clinics,
    required this.onToggleActive,
    required this.onDelete,
    required this.onCreate,
  });

  final List<ClinicSummary> clinics;
  final ValueChanged<ClinicSummary> onToggleActive;
  final ValueChanged<ClinicSummary> onDelete;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final active = clinics.where((clinic) => clinic.isActive).length;
    final inactive = clinics.length - active;
    final personal = clinics.where((clinic) => clinic.isPersonal).length;
    final institutional = clinics.length - personal;

    return ResponsiveContent(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.xl),
        children: [
          AppPageHeader(
            icon: Icons.apartment_outlined,
            title: 'Clínicas e consultórios',
            subtitle:
                'Gerencie os cadastros institucionais. A equipe e os psicólogos vinculados ficam no módulo separado de Psicólogos e administradores.',
            metadata: [
              StatusChip(
                label: '${clinics.length} cadastro(s)',
                tone: AppStatusTone.info,
                icon: Icons.business_outlined,
              ),
              StatusChip(
                label: '$institutional clínica(s)',
                tone: AppStatusTone.success,
                icon: Icons.apartment_outlined,
              ),
              if (personal > 0)
                StatusChip(
                  label: '$personal individual(is)',
                  tone: AppStatusTone.neutral,
                  icon: Icons.person_pin_circle_outlined,
                ),
              StatusChip(
                label: '$active ativa(s)',
                tone: AppStatusTone.completed,
                icon: Icons.check_circle_outline,
              ),
              if (inactive > 0)
                StatusChip(
                  label: '$inactive inativa(s)',
                  tone: AppStatusTone.warning,
                  icon: Icons.pause_circle_outline,
                ),
            ],
            primaryAction: FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Nova clínica'),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const AppSectionHeader(
            title: 'Cadastros institucionais',
            subtitle:
                'Use esta lista para ativar, inativar ou excluir cadastros sem vínculos clínicos.',
          ),
          const SizedBox(height: AppSpacing.sm),
          if (clinics.isEmpty)
            const _EmptyClinicsCard()
          else
            MotionStaggered(
              children: [
                for (final clinic in clinics)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ClinicCard(
                      clinic: clinic,
                      onToggleActive: () => onToggleActive(clinic),
                      onDelete: () => onDelete(clinic),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _ClinicCard extends StatelessWidget {
  const _ClinicCard({
    required this.clinic,
    required this.onToggleActive,
    required this.onDelete,
  });

  final ClinicSummary clinic;
  final VoidCallback onToggleActive;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final accent = clinic.isPersonal ? AppColors.purple : AppColors.blue;

    return MotionSurface(
      borderRadius: AppRadius.lgAll,
      child: ClayCard(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: AppRadius.mdAll,
                ),
                child: Icon(
                  clinic.isPersonal
                      ? Icons.person_pin_circle_outlined
                      : Icons.apartment_outlined,
                  color: accent,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      clinic.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        _StatusChip(label: clinic.typeLabel, color: accent),
                        _StatusChip(
                          label: clinic.isActive ? 'Ativa' : 'Inativa',
                          color: clinic.isActive
                              ? AppColors.success
                              : AppColors.disabled,
                        ),
                        _StatusChip(
                          label: '${clinic.userCount} usuários',
                          color: AppColors.cyan,
                        ),
                        _StatusChip(
                          label: '${clinic.patientCount} pacientes',
                          color: AppColors.info,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: clinic.isActive,
                onChanged: (_) => onToggleActive(),
              ),
              PopupMenuButton<_ClinicAction>(
                tooltip: 'Ações',
                onSelected: (action) {
                  switch (action) {
                    case _ClinicAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _ClinicAction.delete,
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: AppColors.error),
                        SizedBox(width: AppSpacing.sm),
                        Text('Excluir cadastro'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DeleteClinicDialog extends StatefulWidget {
  const _DeleteClinicDialog({required this.clinic});

  final ClinicSummary clinic;

  @override
  State<_DeleteClinicDialog> createState() => _DeleteClinicDialogState();
}

class _DeleteClinicDialogState extends State<_DeleteClinicDialog> {
  final _controller = TextEditingController();

  bool get _matchesClinicName => _controller.text.trim() == widget.clinic.name;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Excluir cadastro da clínica'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Essa ação remove definitivamente o cadastro "${widget.clinic.name}".',
          ),
          const SizedBox(height: AppSpacing.sm),
          const Text(
            'Só é permitido excluir clínicas sem usuários, pacientes ou dados clínicos vinculados.',
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Digite exatamente o nome da clínica para confirmar:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xs),
          TextField(
            controller: _controller,
            decoration: InputDecoration(
              hintText: widget.clinic.name,
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          onPressed: _matchesClinicName
              ? () => Navigator.of(context).pop(_controller.text.trim())
              : null,
          icon: const Icon(Icons.delete_outline),
          label: const Text('Excluir'),
        ),
      ],
    );
  }
}

enum _ClinicAction { delete }

class _CreateClinicResult {
  const _CreateClinicResult({
    required this.name,
    required this.clinicType,
    this.document,
    this.email,
    this.phone,
  });

  final String name;
  final String clinicType;
  final String? document;
  final String? email;
  final String? phone;
}

class _CreateClinicSheet extends StatefulWidget {
  const _CreateClinicSheet();

  @override
  State<_CreateClinicSheet> createState() => _CreateClinicSheetState();
}

class _CreateClinicSheetState extends State<_CreateClinicSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _documentController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _documentController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final availableHeight =
        MediaQuery.sizeOf(context).height - MediaQuery.paddingOf(context).top;

    return AnimatedPadding(
      duration: AppAnimations.fast,
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Align(
        alignment: Alignment.bottomCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: availableHeight * 0.92),
          child: Material(
            color: AppColors.surface,
            elevation: 18,
            shadowColor: AppColors.navy.withValues(alpha: 0.18),
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppRadius.xxl),
            ),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 32,
                          height: 4,
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withValues(alpha: 0.55),
                            borderRadius: BorderRadius.circular(999),
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Nova clínica',
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Cadastre uma clínica ou consultório com equipe. '
                        'Para psicólogos autônomos, use "Novo usuário" e selecione "Profissional individual".',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(labelText: 'Nome *'),
                        textInputAction: TextInputAction.next,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                                ? 'Informe o nome.'
                                : null,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _documentController,
                        decoration: const InputDecoration(
                          labelText: 'CNPJ / CPF (opcional)',
                        ),
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'E-mail de contato (opcional)',
                        ),
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      TextFormField(
                        controller: _phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Telefone (opcional)',
                        ),
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      SizedBox(
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _submit,
                          icon: const Icon(Icons.check),
                          label: const Text('Criar clínica'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      _CreateClinicResult(
        name: _nameController.text.trim(),
        clinicType: 'clinic',
        document: _documentController.text.trim().isEmpty
            ? null
            : _documentController.text.trim(),
        email: _emailController.text.trim().isEmpty
            ? null
            : _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
      backgroundColor: color.withValues(alpha: 0.10),
      side: BorderSide(color: color.withValues(alpha: 0.18)),
    );
  }
}

class _EmptyClinicsCard extends StatelessWidget {
  const _EmptyClinicsCard();

  @override
  Widget build(BuildContext context) {
    return const ClayCard(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: Center(child: Text('Nenhuma clínica encontrada.')),
      ),
    );
  }
}
